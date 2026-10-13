# frozen_string_literal: true

require_relative "../support/fixtures"

require "timeout"

RSpec.describe "ISBF severe report concurrency", type: :model do
  self.use_transactional_tests = false

  around do |example|
    original_config = ActiveRecord::Base.connection_db_config.configuration_hash
    ActiveRecord::Base.establish_connection(original_config.merge(pool: 3))
    example.run
  ensure
    ActiveRecord::Base.establish_connection(original_config) if original_config
  end

  def concurrent_user(type = :user)
    username = "isbf_c_#{SecureRandom.hex(5)}"
    isbf_fabricate(type, username: username, email: "#{username}@example.com")
  end

  it "serializes simultaneous duplicate requests and publishes only after commit" do
    SiteSetting.isbf_severe_reports_enabled = true
    reporter = concurrent_user
    author = concurrent_user
    post = isbf_fabricate(:post, user: author)
    topic = post.topic
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    errors = Queue.new
    workers = []

    messages =
      MessageBus.track_publish(IsbfModeration::Notifications::CHANNEL) do
        2.times do
          workers << Thread.new do
            begin
              ActiveRecord::Base.connection_pool.with_connection do
                ready << true
                Timeout.timeout(15) { start.pop }
                results << IsbfModeration::SevereReport.new(User.find(reporter.id)).submit(
                  post_id: post.id,
                  reason: "A concurrent severe report requiring immediate staff review.",
                  confirmed: true,
                )
              end
            rescue => error
              errors << error
              ready << false
            end
          end
        end
        Timeout.timeout(15) { 2.times { ready.pop } }
        2.times { start << true }
        workers.each { |worker| worker.join(20) || raise("severe report worker timed out") }
      end

    expect(errors.size).to eq(0), errors.size.positive? ? errors.pop.full_message : nil
    first, second = Timeout.timeout(5) { [results.pop, results.pop] }
    expect(first).to eq(second)
    expect(PostAction.flags.where(post_id: post.id, user_id: reporter.id).count).to eq(1)
    expect(post.reviewable_flag.reviewable_scores.count).to eq(1)
    expect(post.reload).to be_hidden
    expect(IsbfModeration::Hold.persisted?(post)).to eq(true)
    expect(messages.size).to eq(1)
    expect(messages.first.data).to eq(post_id: post.id, topic_id: topic.id, hidden: true)
  ensure
    workers&.each do |worker|
      worker.kill if worker.alive?
      worker.join(2)
    end
    post&.destroy!
    topic&.destroy!
    reporter&.destroy!
    author&.destroy!
  end

  it "does not publish either native post changes or a hide event after a failed transaction" do
    SiteSetting.isbf_severe_reports_enabled = true
    reporter = concurrent_user
    author = concurrent_user
    post = isbf_fabricate(:post, user: author)
    topic = post.topic
    post_id = post.id
    SiteSetting.experimental_topic_category_change_notification = true
    IsbfModeration::Notifications.stubs(:publish_after_commit).raises(
      ActiveRecord::StatementInvalid,
      "failed notification registration after native hide",
    )
    queued_system_messages = Jobs::SendSystemMessage.jobs.size

    custom =
      MessageBus.track_publish(IsbfModeration::Notifications::CHANNEL) do
        tracking =
          MessageBus.track_publish("/delete") do
            native =
              MessageBus.track_publish("/topic/#{topic.id}") do
                expect {
                  IsbfModeration::SevereReport.new(reporter).submit(
                    post_id: post_id,
                    reason: "A serious report that must roll back completely on failure.",
                    confirmed: true,
                  )
                }.to raise_error(ActiveRecord::StatementInvalid)
              end
            expect(native).to be_empty
          end
        expect(tracking).to be_empty
      end
    expect(custom).to be_empty
    expect(post.reload).not_to be_hidden
    expect(post.reviewable_flag).to be_nil
    expect(Jobs::SendSystemMessage.jobs.size).to eq(queued_system_messages)
  ensure
    post&.destroy!
    topic&.destroy!
    reporter&.destroy!
    author&.destroy!
  end

  it "uses the native category audience for committed hold and restore events" do
    SiteSetting.isbf_severe_reports_enabled = true
    group = isbf_fabricate(:group, name: "isbf_c_#{SecureRandom.hex(5)}")
    author = concurrent_user
    category = isbf_fabricate(:private_category, group: group, user: author)
    reporter = concurrent_user
    moderator = concurrent_user(:moderator)
    group.users << reporter
    group.users << moderator
    post =
      isbf_fabricate(
        :post,
        user: author,
        topic: isbf_fabricate(:topic, category: category, user: author),
      )
    topic = post.topic

    messages =
      MessageBus.track_publish(IsbfModeration::Notifications::CHANNEL) do
        IsbfModeration::SevereReport.new(reporter.reload).submit(
          post_id: post.id,
          reason: "This private category content requires a serious review.",
          confirmed: true,
        )
        reviewable = post.reviewable_flag
        reviewable.perform(moderator.reload, :disagree_and_restore, version: reviewable.version)
      end

    expect(messages.map { |message| message.data[:hidden] }).to eq([true, false])
    messages.each do |message|
      expect(message.group_ids).to eq(topic.secure_audience_publish_messages[:group_ids])
      expect(message.group_ids).to include(group.id)
      expect(message.group_ids).not_to be_empty
    end
  ensure
    post&.destroy!
    topic&.destroy!
    reporter&.destroy!
    author&.destroy!
    moderator&.destroy!
    category&.destroy!
    group&.destroy!
  end
end
