# frozen_string_literal: true

RSpec.describe "Official post quota concurrency", type: :model do
  self.use_transactional_tests = false

  before do
    @official_group = Fabricate(:group)
    @official_category = Fabricate(:category)
    SiteSetting.academy_official_group = @official_group.id
    SiteSetting.academy_official_category = @official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.auto_silence_fast_typers_on_first_post = false
    @developer = Fabricate(:admin)
    @author = Fabricate(:user, refresh_auto_groups: true)
    @official_group.add(@author)
    @official_category.set_permissions(@official_group => :full)
    DiscourseAcademyRoles::OfficialPostQuota.update_limit!(@developer, @author, limit: 1)
    @threads = []
  end

  after do
    @threads.each do |thread|
      thread.kill if thread.alive?
      thread.join
    end
    SiteSetting.academy_roles_enabled = false
    if @author
      Topic.with_deleted.where(user_id: @author.id).destroy_all
      PluginStoreRow.where(
        plugin_name: DiscourseAcademyRoles::PLUGIN_NAME,
        key: "official_post_quota:#{@author.id}",
      ).destroy_all
      @author.destroy!
    end
    @developer&.destroy!
    @official_category&.destroy!
    @official_group&.destroy!
  end

  it "allows exactly one simultaneous publication into the final available slot" do
    ready = Queue.new
    start = Queue.new
    author_id = @author.id
    category_id = @official_category.id
    @threads =
      2.times.map do |index|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            author = User.find(author_id)
            ready << true
            start.pop
            creator =
              PostCreator.new(
                author,
                title: "Concurrent official announcement #{index}",
                raw:
                  "Independent concurrent publication #{index} for the official academy community.",
                category: category_id,
                academy_official: true,
                isbf_official_campuses: '["zhuhai"]',
                isbf_official_types: '["academic"]',
                skip_rate_limits: true,
                skip_jobs: true,
              )
            post = creator.create
            { persisted: post&.persisted? == true, errors: creator.errors.full_messages }
          end
        end
      end
    2.times { ready.pop }
    2.times { start << true }
    @threads.each { |thread| raise "Concurrent publication timed out" unless thread.join(25) }
    results = @threads.map(&:value)

    expect(results.count { |result| result[:persisted] }).to eq(1)
    expect(results.reject { |result| result[:persisted] }.first[:errors]).to include(
      DiscourseAcademyRoles::OfficialPostQuota.error_message(@author),
    )
    expect(Post.with_deleted.where(user_id: author_id, post_number: 1).count).to eq(1)
    expect(DiscourseAcademyRoles::OfficialPostQuota.usage(@author)).to eq(1)
  end
end
