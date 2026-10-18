# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF learning resource administration", type: :request do
  fab!(:category)
  fab!(:admin)
  fab!(:moderator) do
    Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) { Fabricate(:user, active: true, approved: true, refresh_auto_groups: true) }
  fab!(:new_member) do
    Fabricate(:user, active: true, approved: true, trust_level: 0, refresh_auto_groups: true)
  end
  fab!(:category_reviewer) do
    Fabricate(:user, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:reviewer_group, :group)

  let(:course) { IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1) }

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    SiteSetting.enable_category_group_moderation = true
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
    reviewer_group.add(category_reviewer)
    CategoryModerationGroup.create!(category_id: category.id, group_id: reviewer_group.id)
  end

  def create_resource(actor = admin, extra = {})
    @number = (@number || 0) + 1
    result =
      NewPostManager.new(
        actor,
        {
          title: "Resource administration reference #{@number}",
          raw: "Reference material https://example.org/notes.pdf",
          category: category.id,
          isbf_learning_course_id: course.fetch("id"),
          isbf_learning_files: "[]",
          isbf_learning_contributor: "学习小组",
        }.merge(extra),
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    return result.post if result.post
    approval = result.reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    approval.created_post
  end

  def list_resources(actor = admin, extra = {})
    sign_in(actor)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }.merge(extra)
    expect(response.status).to eq(200), response.body
    response.parsed_body.fetch("resources")
  end

  it "only advertises deletion to admins with native Guardian permission" do
    post = create_resource
    [member, new_member, moderator, category_reviewer].each do |actor|
      expect(list_resources(actor).first.fetch("can_delete")).to eq(false)
    end
    expect(list_resources.first.fetch("can_delete")).to eq(
      admin.guardian.can_delete_topic?(post.topic),
    )
    Guardian.any_instance.stubs(:can_delete_topic?).returns(false)
    expect(list_resources.first.fetch("can_delete")).to eq(false)
    delete "/isbf/learning/resources/#{post.topic_id}.json"
    expect(response.status).to eq(403), response.body
    expect(post.topic.reload.deleted_at).to be_nil
  end

  [nil, "member", "new_member", "moderator", "category_reviewer"].each do |role|
    it "denies library deletion by #{role || "guests"}" do
      post = create_resource(member)
      sign_in(public_send(role)) if role
      delete "/isbf/learning/resources/#{post.topic_id}.json"
      expect(response.status).to eq(403), response.body
      expect(post.reload.deleted_at).to be_nil
      expect(post.topic.reload.deleted_at).to be_nil
    end
  end

  %w[member moderator category_reviewer].each do |role|
    it "denies #{role} native topic and first-post deletion and editing" do
      post = create_resource(member)
      actor = public_send(role)
      expect(actor.guardian.can_delete_topic?(post.topic)).to eq(false)
      expect(actor.guardian.can_delete_post?(post)).to eq(false)
      expect(actor.guardian.can_edit_post?(post)).to eq(false)
      expect(actor.guardian.can_edit_topic?(post.topic)).to eq(false)
      sign_in(actor)
      delete "/t/#{post.topic_id}.json"
      expect(response.status).to be_in([403, 422])
      delete "/posts/#{post.id}.json"
      expect(response.status).to eq(403), response.body
      put "/posts/#{post.id}.json", params: { post: { raw: "Changed https://example.org/new.pdf" } }
      expect(response.status).to eq(403), response.body
      expect(post.reload.deleted_at).to be_nil
      expect(post.topic.reload.deleted_at).to be_nil
    end
  end

  it "denies non-admin movement of community topics into the learning category" do
    [member, moderator, category_reviewer].each do |actor|
      expect(actor.guardian.can_move_topic_to_category?(category)).to eq(false)
    end
    expect(admin.guardian.can_move_topic_to_category?(category)).to eq(true)
  end

  it "soft deletes through native PostDestroyer without honoring force_destroy or losing resource metadata" do
    post = create_resource
    topic = post.topic
    topic_id = topic.id
    post_id = post.id
    sign_in(admin)
    expect do
      expect do
        delete "/isbf/learning/resources/#{topic_id}.json", params: { force_destroy: true }
        expect(response.status).to eq(200), response.body
      end.not_to change { Topic.with_deleted.count }
    end.not_to change { Post.with_deleted.count }
    expect(Topic.with_deleted.find(topic_id).deleted_at).to be_present
    expect(Post.with_deleted.find(post_id).deleted_at).to be_present
    expect(
      Topic.with_deleted.find(topic_id).custom_fields.fetch("isbf_learning_contributor"),
    ).to eq("学习小组")
    expect(list_resources(member)).to be_empty
    expect(list_resources(admin)).to be_empty
  end

  it "returns an error when native deletion does not soft delete the resource" do
    post = create_resource
    PostDestroyer.any_instance.stubs(:destroy).returns(nil)
    sign_in(admin)
    delete "/isbf/learning/resources/#{post.topic_id}.json"
    expect(response.status).to eq(422), response.body
    expect(post.reload.deleted_at).to be_nil
    expect(post.topic.reload.deleted_at).to be_nil
  end

  it "denies non-library topics, private messages, missing courses, malformed and unknown ids" do
    ordinary = Fabricate(:post)
    pm = Fabricate(:private_message_post, user: admin)
    missing_course = create_resource
    TopicCustomField.where(
      topic_id: missing_course.topic_id,
      name: "isbf_learning_course_id",
    ).delete_all
    sign_in(admin)
    [
      ordinary.topic_id,
      pm.topic_id,
      missing_course.topic_id,
      "invalid",
      "#{ordinary.topic_id}x",
      999_999_999,
    ].each do |id|
      delete "/isbf/learning/resources/#{id}.json"
      expected = id.to_s.match?(/\A[1-9]\d{0,18}\z/) ? [403, 404, 422] : [400]
      expect(response.status).to be_in(expected)
    end
    [ordinary, pm, missing_course].each do |post|
      expect(post.reload.deleted_at).to be_nil
      expect(post.topic.reload.deleted_at).to be_nil
    end
  end

  it "revokes private file access on deletion and restores it only after admin recovery" do
    id = SecureRandom.uuid
    PluginStore.set(
      "isbf-learning",
      "file:#{id}",
      {
        "id" => id,
        "name" => "notes.pdf",
        "size" => 10,
        "owner_id" => member.id,
        "url" => "/isbf/learning/files/#{id}",
      },
    )
    post =
      create_resource(
        member,
        raw: "[Private notes](/isbf/learning/files/#{id})",
        isbf_learning_files: [id].to_json,
      )
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(true)
    sign_in(admin)
    delete "/isbf/learning/resources/#{post.topic_id}.json"
    expect(response.status).to eq(200), response.body
    [member, new_member].each do |actor|
      expect(IsbfLearning.file_accessible?(id, actor, actor.guardian)).to eq(false)
      expect { IsbfLearning::Files.download(id, actor, actor.guardian) }.to raise_error(
        Discourse::InvalidAccess,
      )
    end
    [member, moderator, category_reviewer].each do |actor|
      guardian = actor.guardian
      expect(guardian.can_recover_post?(Post.with_deleted.find(post.id))).to eq(false)
      expect(guardian.can_recover_topic?(Topic.with_deleted.find(post.topic_id))).to eq(false)
      sign_in(actor)
      put "/posts/#{post.id}/recover.json"
      expect(response.status).to be_in([403, 404]), response.body
      put "/t/#{post.topic_id}/recover.json"
      expect(response.status).to be_in([403, 404]), response.body
      expect(Post.with_deleted.find(post.id).deleted_at).to be_present
      expect(Topic.with_deleted.find(post.topic_id).deleted_at).to be_present
    end
    sign_in(admin)
    put "/t/#{post.topic_id}/recover.json"
    expect(response.status).to eq(200), response.body
    expect(IsbfLearning.file_accessible?(id, member, member.guardian)).to eq(true)
    expect(list_resources(member).map { |item| item["id"] }).to eq([post.topic_id])
    expect(PluginStore.get("isbf-learning", "file:#{id}")).to be_present
  end

  it "omits deleted resources from search and fills list pages with remaining resources" do
    posts = 21.times.map { create_resource }
    SearchIndexer.enable
    posts.each do |post|
      SearchIndexer.index(post, force: true)
      SearchIndexer.index(post.topic, force: true)
    end
    first_page = list_resources(member)
    expect(first_page.length).to eq(20)
    expect(response.parsed_body.fetch("has_more")).to eq(true)
    expect(list_resources(member, page: 1).length).to eq(1)
    sign_in(admin)
    deleted = posts.last
    delete "/isbf/learning/resources/#{deleted.topic_id}.json"
    expect(response.status).to eq(200), response.body
    remaining = list_resources(member)
    expect(remaining.length).to eq(20)
    expect(remaining.map { |item| item["id"] }).not_to include(deleted.topic_id)
    expect(response.parsed_body.fetch("has_more")).to eq(false)
    expect(list_resources(member, page: 1)).to be_empty
    expect(list_resources(member, q: "administration").map { |item| item["id"] }).not_to include(
      deleted.topic_id,
    )
  ensure
    SearchIndexer.disable
  end
end
