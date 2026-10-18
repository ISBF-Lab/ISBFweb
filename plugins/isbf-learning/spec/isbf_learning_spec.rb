# frozen_string_literal: true

require "rails_helper"

RSpec.shared_context "with the ISBF learning contract" do
  fab!(:category)
  fab!(:admin)
  fab!(:member) do
    Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
  end
  fab!(:new_member) do
    Fabricate(:user, active: true, approved: true, trust_level: 0, refresh_auto_groups: true)
  end

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
  end

  let(:course) do
    IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1).with_indifferent_access
  end

  def resource_payload(extra = {})
    @resource_number = (@resource_number || 0) + 1
    {
      title: "Learning resource example #{@resource_number}",
      raw: "Course reference material: https://example.org/course-notes.pdf",
      category: category.id,
      isbf_learning_course_id: course[:id],
      isbf_learning_files: "[]",
    }.merge(extra)
  end

  def publish_resource(actor = admin, extra = {})
    result = NewPostManager.new(actor, resource_payload(extra)).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    result.post
  end
end

RSpec.describe IsbfLearning do
  include_context "with the ISBF learning contract"

  it "allows moderators to add courses but queues their resource submissions" do
    moderator = Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
    added = IsbfLearning::Courses.create(moderator, name: "大学英语", grade: 2).with_indifferent_access
    result =
      NewPostManager.new(moderator, resource_payload(isbf_learning_course_id: added[:id])).perform
    expect(result.success?).to eq(true)
    expect(result.action).to eq(:enqueued)
    expect(result.post).to be_nil
    approval = result.reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    post = approval.created_post
    expect(post).to be_persisted
    expect(post.topic.reload.custom_fields["isbf_learning_course_id"]).to eq(added[:id])
  end

  it "publishes admin resources as native topics with persistent course metadata" do
    post = publish_resource
    expect(post).to be_persisted
    expect(IsbfLearning.learning_topic?(post.topic)).to eq(true)
    expect(post.topic.reload.custom_fields["isbf_learning_course_id"]).to eq(course[:id])
    expect(post.topic.custom_fields["isbf_learning_files"]).to eq([])
  end

  it "queues TL0 and TL1 submissions and preserves metadata through approval" do
    [new_member, member].each do |author|
      result = NewPostManager.new(author, resource_payload).perform
      expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
      expect(result.action).to eq(:enqueued)
      expect(result.post).to be_nil
      expect(result.reviewable).to be_a(ReviewableQueuedPost)
      expect(result.reviewable).to be_persisted
      approval = result.reviewable.perform(admin, :approve_post)
      expect(approval.success?).to eq(true)
      post = approval.created_post
      expect(post.user_id).to eq(author.id)
      expect(post.topic.reload.custom_fields["isbf_learning_course_id"]).to eq(course[:id])
      expect(post.topic.custom_fields["isbf_learning_files"]).to eq([])
    end
  end

  it "preserves Guardian's explicit hide_deleted argument while protecting guest access" do
    topic = publish_resource.topic
    [true, false].each do |hide_deleted|
      expect(member.guardian.can_see_topic?(topic, hide_deleted)).to eq(true)
      expect(Guardian.new.can_see_topic?(topic, hide_deleted)).to eq(false)
    end
    topic.update!(deleted_at: Time.zone.now)
    expect(member.guardian.can_see_topic?(topic, true)).to eq(false)
    expect(member.guardian.can_see_topic?(topic, false)).to eq(true)
  end

  it "rejects overlong resource bodies before creating a reviewable" do
    SiteSetting.max_post_length = 1000
    payload = resource_payload(raw: "#{"x" * 1001} https://example.org/course-notes.pdf")
    expect do
      result = NewPostManager.new(member, payload).perform
      expect(result.success?).to eq(false)
      expect(result.post).to be_nil
    end.not_to change(ReviewableQueuedPost, :count)
  end

  it "rejects approval after a queued resource is moved to an ordinary category" do
    result = NewPostManager.new(member, resource_payload).perform
    expect(result.action).to eq(:enqueued)
    reviewable = result.reviewable
    other = Fabricate(:category)
    reviewable.update!(category_id: other.id)
    approval = nil
    expect do
      expect do
        approval = reviewable.perform(admin, :approve_post)
      rescue Discourse::InvalidAccess, Discourse::InvalidParameters
        # Core callers may receive a permission exception or a failed action.
      end.not_to change(Post, :count)
    end.not_to change(Topic, :count)
    expect(approval.success?).to eq(false) if approval
    expect(reviewable.reload.pending?).to eq(true)
  end

  it "permits resource-only TL0 submission without changing global topic creation groups" do
    SiteSetting.create_topic_allowed_groups = "1|2"
    other = Fabricate(:category)
    other.set_permissions(trust_level_0: :full)
    other.save!
    guardian = new_member.guardian
    expect(guardian.can_create_topic_on_category?(category)).to eq(true)
    expect(guardian.can_create_topic_on_category?(other)).to eq(false)
    result = NewPostManager.new(new_member, resource_payload).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    expect(result.action).to eq(:enqueued)
    expect(SiteSetting.create_topic_allowed_groups).to eq("1|2")
  end

  it "fails closed for disabled resources and silenced users" do
    SiteSetting.create_topic_allowed_groups = "1|2"
    SiteSetting.isbf_learning_enabled = false
    expect(new_member.guardian.can_create_topic_on_category?(category)).to eq(false)
    SiteSetting.isbf_learning_enabled = true
    new_member.update!(silenced_till: 1.day.from_now)
    expect(new_member.guardian.can_create_topic_on_category?(category)).to eq(false)
  end

  it "does not allow ordinary users to bypass review through PostCreator" do
    expect do PostCreator.new(member, resource_payload).create end.to raise_error(
      Discourse::InvalidAccess,
    )
  end

  it "requires an explicit title and a valid HTTP or HTTPS resource link" do
    [
      { title: "" },
      { raw: "This submission has sufficient text but no resource link." },
      { raw: "A resource address using an unsafe scheme: javascript:alert(1)" },
      { raw: "An incomplete address without a hostname: https://" },
    ].each do |extra|
      result = NewPostManager.new(admin, resource_payload(extra)).perform
      expect(result.success?).to eq(false)
      expect(result.post).to be_nil
    end
  end

  it "rejects native public upload links even alongside a valid external resource" do
    %w[/uploads/default/original/1X/sample.pdf upload://sample.pdf].each do |link|
      result =
        NewPostManager.new(
          admin,
          resource_payload(raw: "[File](#{link}) https://example.org/valid.pdf"),
        ).perform
      expect(result.success?).to eq(false)
    end
  end

  it "rejects unknown courses and malformed file metadata before queuing" do
    [
      { isbf_learning_course_id: SecureRandom.uuid },
      { isbf_learning_course_id: "" },
      { isbf_learning_files: "null" },
      { isbf_learning_files: '{"id":"invalid"}' },
      { isbf_learning_files: '["missing-file"]' },
    ].each do |extra|
      expect do
        result = NewPostManager.new(member, resource_payload(extra)).perform
        expect(result.success?).to eq(false)
      end.not_to change(ReviewableQueuedPost, :count)
    end
  end

  it "rejects learning metadata outside the library, in replies and in private messages" do
    other = Fabricate(:category)
    original = publish_resource
    [
      { category: other.id },
      { topic_id: original.topic_id },
      { archetype: Archetype.private_message, target_usernames: member.username },
    ].each do |extra|
      result = NewPostManager.new(admin, resource_payload(extra)).perform
      expect(result.success?).to eq(false)
    end
  end

  it "prevents approved authors from editing the first post through Guardian and PostRevisor" do
    result = NewPostManager.new(member, resource_payload).perform
    post = result.reviewable.perform(admin, :approve_post).created_post
    original_raw = post.raw
    expect(member.guardian.can_edit_post?(post)).to eq(false)
    expect do
      PostRevisor.new(post).revise!(member, raw: "Changed https://example.org/other.pdf")
    end.to raise_error(Discourse::InvalidAccess)
    expect(post.reload.raw).to eq(original_raw)
    expect(admin.guardian.can_edit_post?(post)).to eq(true)
    expect(
      PostRevisor.new(post).revise!(admin, raw: "Updated notes https://example.org/revised.pdf"),
    ).to eq(true)
  end

  it "preserves ordinary native topic and reply behavior" do
    other = Fabricate(:category)
    other.set_permissions(everyone: :full)
    other.save!
    post =
      PostCreator.new(
        admin,
        title: "An ordinary discussion topic",
        raw: "An ordinary discussion without resource metadata.",
        category: other.id,
      ).create
    expect(post).to be_persisted
    expect(IsbfLearning.learning_topic?(post.topic)).to eq(false)
    expect(admin.guardian.can_edit_post?(post)).to eq(true)
    reply =
      PostCreator.new(
        admin,
        topic_id: publish_resource.topic_id,
        raw: "A discussion reply without attached course metadata.",
      ).create
    expect(reply).to be_persisted
  end

  it "restricts pending files to their owner and staff without granting anonymous access" do
    id = SecureRandom.uuid
    PluginStore.set(
      "isbf-learning",
      "file:#{id}",
      { "name" => "notes.pdf", "size" => 10, "owner_id" => member.id },
    )
    expect(IsbfLearning.file_accessible?(id, nil, Guardian.new)).to eq(false)
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(true)
    expect(IsbfLearning.file_accessible?(id, new_member, new_member.guardian)).to eq(false)
    expect(IsbfLearning.file_accessible?(id, admin, admin.guardian)).to eq(true)
  end

  it "revokes protected file access when the referenced resource is hidden, deleted or restricted" do
    id = SecureRandom.uuid
    PluginStore.set(
      "isbf-learning",
      "file:#{id}",
      { "name" => "notes.pdf", "size" => 10, "owner_id" => member.id },
    )
    result =
      NewPostManager.new(
        member,
        resource_payload(
          raw: "[Private course notes](/isbf/learning/files/#{id})",
          isbf_learning_files: [id].to_json,
        ),
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    post = result.reviewable.perform(admin, :approve_post).created_post
    expect(post.topic.reload.custom_fields["isbf_learning_course_id"]).to eq(course[:id])
    expect(post.topic.custom_fields["isbf_learning_files"]).to eq([id])
    expect(IsbfLearning.file_accessible?(id, new_member, new_member.guardian)).to eq(true)
    post.update!(hidden: true)
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(false)
    expect(IsbfLearning.file_accessible?(id, new_member, new_member.guardian)).to eq(false)
    post.update!(hidden: false, deleted_at: Time.zone.now)
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(false)
    post.update!(deleted_at: nil)
    post.topic.update!(visible: false)
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(false)
    post.topic.update!(visible: true)
    category.set_permissions(staff: :full)
    category.save!
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(false)
  end

  it "does not restore owner download access after permanently deleting a file resource" do
    id = SecureRandom.uuid
    PluginStore.set(
      "isbf-learning",
      "file:#{id}",
      { "name" => "notes.pdf", "size" => 10, "owner_id" => member.id },
    )
    result =
      NewPostManager.new(
        member,
        resource_payload(
          raw: "[Private course notes](/isbf/learning/files/#{id})",
          isbf_learning_files: [id].to_json,
        ),
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    post = result.reviewable.perform(admin, :approve_post).created_post
    topic_id = post.topic_id
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(true)
    expect(IsbfLearning.file_accessible?(id, new_member, new_member.guardian)).to eq(true)

    PostDestroyer.new(admin, post, force_destroy: true).destroy

    expect(Topic.with_deleted.exists?(topic_id)).to eq(false)
    expect(TopicCustomField.where(topic_id: topic_id, name: "isbf_learning_files")).to be_empty
    [member, new_member].each do |actor|
      expect(IsbfLearning.file_accessible?(id, actor, actor.guardian)).to eq(false)
      expect do IsbfLearning::Files.download(id, actor, actor.guardian) end.to raise_error(
        Discourse::InvalidAccess,
      )
    end
  end
end

RSpec.describe "ISBF learning HTTP permissions", type: :request do
  include_context "with the ISBF learning contract"

  it "requires login for the course and resource catalogs" do
    get "/isbf/learning/courses.json"
    expect(response.status).to eq(403)
    get "/isbf/learning/resources.json"
    expect(response.status).to eq(403)
  end

  it "allows staff to add courses and members to read them" do
    sign_in(admin)
    post "/isbf/learning/courses.json", params: { name: "大学英语", grade: 2 }
    expect(response.status).to eq(200), response.body
    created = response.parsed_body.fetch("course")
    expect(created["id"]).to match(/\A[0-9a-f-]{36}\z/)
    expect(created.slice("name", "grade")).to eq("name" => "大学英语", "grade" => 2)
    sign_in(member)
    get "/isbf/learning/courses.json"
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("courses")).to include(created)
    post "/isbf/learning/courses.json", params: { name: "Requested course", grade: 1 }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(true)
    expect(IsbfLearning::Courses.list.map { |item| item["name"] }).not_to include(
      "Requested course",
    )
  end

  it "rejects duplicate course names within a grade and grades outside 1 through 4" do
    sign_in(admin)
    course
    post "/isbf/learning/courses.json", params: { name: course[:name], grade: course[:grade] }
    expect(response.status).to eq(422)
    [0, 5, "abc"].each do |grade|
      post "/isbf/learning/courses.json", params: { name: "Invalid grade course", grade: grade }
      expect(response.status).to eq(422)
    end
  end

  it "lists only published resources from the selected course and authorized category" do
    first = publish_resource
    second_course =
      IsbfLearning::Courses.create(admin, name: "大学英语", grade: 1).with_indifferent_access
    other = publish_resource(admin, isbf_learning_course_id: second_course[:id])
    queued = NewPostManager.new(member, resource_payload).perform
    expect(queued.action).to eq(:enqueued)
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course[:id] }
    expect(response.status).to eq(200), response.body
    data = response.parsed_body
    expect(data.fetch("resources").map { |item| item["id"] }).to eq([first.topic_id])
    expect(data["has_more"]).to eq(false)
    expect(data["resources"].map { |item| item["id"] }).not_to include(other.topic_id)
    category.set_permissions(staff: :full)
    category.save!
    get "/isbf/learning/resources.json", params: { course_id: course[:id] }
    expect(response.status).to eq(403)
  end

  it "searches all library grades and courses while excluding ordinary topics" do
    matching = publish_resource(admin, title: "Unique calculus reference collection")
    other_course = IsbfLearning::Courses.create(admin, name: "物理", grade: 2).with_indifferent_access
    outside =
      publish_resource(
        admin,
        title: "Unique calculus outside selected course",
        isbf_learning_course_id: other_course[:id],
      )
    ordinary = Fabricate(:post, raw: "Unique calculus material in an ordinary topic.")
    SearchIndexer.enable
    [matching, outside, ordinary].each do |post|
      SearchIndexer.index(post, force: true)
      SearchIndexer.index(post.topic, force: true)
    end
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course[:id], q: "calculus" }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").map { |item| item["id"] }).to contain_exactly(
      matching.topic_id,
      outside.topic_id,
    )
  ensure
    SearchIndexer.disable
  end

  it "denies native HTTP edits by an approved ordinary author" do
    result = NewPostManager.new(member, resource_payload).perform
    resource = result.reviewable.perform(admin, :approve_post).created_post
    sign_in(member)
    put "/posts/#{resource.id}.json",
        params: {
          post: {
            raw: "An edited resource https://example.org/new.pdf",
          },
        }
    expect(response.status).to eq(403)
  end
end
