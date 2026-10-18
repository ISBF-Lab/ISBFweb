# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF library resources and native permissions", type: :request do
  fab!(:category)
  fab!(:learning_category, :category)
  fab!(:admin)
  fab!(:moderator) do
    Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) do
    Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
  end
  fab!(:new_member) do
    Fabricate(:user, active: true, approved: true, trust_level: 0, refresh_auto_groups: true)
  end
  fab!(:category_reviewer) do
    Fabricate(:user, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:reviewer_group, :group)

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = learning_category.id
    SiteSetting.isbf_library_enabled = true
    SiteSetting.isbf_library_category_id = category.id
    SiteSetting.enable_category_group_moderation = true
    [category, learning_category].each do |item|
      item.set_permissions(trust_level_0: :full, staff: :full)
      item.save!
    end
    reviewer_group.add(category_reviewer)
    CategoryModerationGroup.create!(category_id: category.id, group_id: reviewer_group.id)
  end

  let(:directory) { IsbfLibrary::Catalog.create(admin, kind: "category", name: "校园资料") }
  let(:group) do
    IsbfLibrary::Catalog.create(
      admin,
      kind: "group",
      name: "参考资料",
      category_id: directory.fetch("id"),
    )
  end
  let(:course) { IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1) }
  let(:link) { "https://example.org/library-notes.pdf?download=1#page-2" }

  def native_payload(extra = {})
    @number = (@number || 0) + 1
    {
      title: "Library reference collection #{@number}",
      raw: "Library reference https://example.org/library-notes.pdf",
      category: category.id,
      isbf_library_group_id: group.fetch("id"),
      isbf_library_files: "[]",
      isbf_library_contributor: "资料小组",
      isbf_library_link: "https://example.org/library-notes.pdf",
    }.merge(extra)
  end

  def publish(actor = admin, extra = {})
    result = NewPostManager.new(actor, native_payload(extra)).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    return result.post if result.post
    approval = result.reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    approval.created_post
  end

  def submit(actor = admin, extra = {})
    @number = (@number || 0) + 1
    sign_in(actor)
    post "/isbf/library/resources.json",
         params: {
           group_id: group.fetch("id"),
           title: "Library link collection #{@number}",
           link: link,
           description: "Original introduction",
           contributor: "资料小组",
         }.merge(extra)
  end

  def list(actor = member, extra = {})
    sign_in(actor)
    get "/isbf/library/resources.json", params: { group_id: group.fetch("id") }.merge(extra)
    expect(response.status).to eq(200), response.body
    response.parsed_body.fetch("resources")
  end

  def learning_post
    result =
      NewPostManager.new(
        admin,
        {
          title: "Library calculus learning reference",
          raw: "Calculus reference https://example.org/course.pdf",
          category: learning_category.id,
          isbf_learning_course_id: course.fetch("id"),
          isbf_learning_files: "[]",
        },
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    result.post
  end

  it "requires login for all resource reads and mutations" do
    get "/isbf/library/resources.json"
    expect(response.status).to eq(403), response.body
    expect do
      post "/isbf/library/resources.json",
           params: {
             group_id: group.fetch("id"),
             title: "Guest reference",
             link: link,
           }
      expect(response.status).to eq(403), response.body
    end.not_to change(Topic, :count)
    resource = publish
    delete "/isbf/library/resources/#{resource.topic_id}.json"
    expect(response.status).to eq(403), response.body
    expect(Guardian.new.can_see_topic?(resource.topic)).to eq(false)
    expect(Guardian.new.can_see_topic?(resource.topic, false)).to eq(false)
  end

  it "returns an empty resource list until a group or search is selected" do
    publish
    sign_in(member)
    get "/isbf/library/resources.json"
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources")).to be_empty
    expect(response.parsed_body.fetch("has_more")).to eq(false)
  end

  it "publishes admin links with library-only metadata and native authorship" do
    expect do
      submit
      expect(response.status).to eq(200), response.body
    end.not_to change(ReviewableQueuedPost, :count)
    data = response.parsed_body
    expect(data.slice("success", "pending")).to eq("success" => true, "pending" => false)
    resource = data.fetch("resource")
    topic = Topic.find(resource.fetch("id"))
    expect(topic.category_id).to eq(category.id)
    expect(topic.user_id).to eq(admin.id)
    expect(topic.first_post.user_id).to eq(admin.id)
    expect(resource.fetch("category")).to eq(directory.slice("id", "name").stringify_keys)
    expect(resource.fetch("group")).to eq(group.slice("id", "name", "category_id").stringify_keys)
    expect(resource.slice("links", "files", "link_only", "description", "contributor")).to eq(
      "links" => [link],
      "files" => [],
      "link_only" => true,
      "description" => "Original introduction",
      "contributor" => "资料小组",
    )
    expect(topic.custom_fields.fetch(IsbfLibrary::GROUP_FIELD)).to eq(group.fetch("id"))
    expect(topic.custom_fields.fetch(IsbfLibrary::LINK_FIELD)).to eq(link)
    expect(topic.custom_fields.keys.grep(/\Aisbf_learning_/)).to be_empty
  end

  %w[new_member member moderator category_reviewer].each do |role|
    it "queues #{role} links and preserves metadata through admin approval" do
      actor = public_send(role)
      expect do
        expect do
          submit(actor)
          expect(response.status).to eq(200), response.body
        end.to change(ReviewableQueuedPost, :count).by(1)
      end.not_to change(Topic, :count)
      expect(response.parsed_body.fetch("pending")).to eq(true)
      reviewable = ReviewableQueuedPost.order(:id).last
      expect(reviewable.target_created_by_id).to eq(actor.id)
      expect(reviewable.payload).to include(
        IsbfLibrary::GROUP_FIELD => group.fetch("id"),
        IsbfLibrary::LINK_FIELD => link,
        IsbfLibrary::DESCRIPTION_FIELD => "Original introduction",
        IsbfLibrary::CONTRIBUTOR_FIELD => "资料小组",
      )
      expect(list(actor)).to be_empty
      approval = reviewable.perform(admin, :approve_post)
      expect(approval.success?).to eq(true)
      resource = approval.created_post
      expect(resource.user_id).to eq(actor.id)
      expect(resource.topic.reload.user_id).to eq(actor.id)
      expect(resource.topic.custom_fields.fetch(IsbfLibrary::GROUP_FIELD)).to eq(group.fetch("id"))
      expect(list(actor).first.fetch("contributor")).to eq("资料小组")
    end
  end

  %w[member moderator category_reviewer].each do |role|
    it "denies #{role} native review reads, edits and approval" do
      result = NewPostManager.new(member, native_payload).perform
      expect(result.action).to eq(:enqueued)
      reviewable = result.reviewable
      actor = public_send(role)
      expect(Reviewable.viewable_by(actor).where(id: reviewable.id)).to be_empty
      expect(reviewable.actions_for(actor.guardian).has?(:approve_post)).to eq(false)
      expect { reviewable.perform(actor, :approve_post) }.to raise_error(Reviewable::InvalidAction)
      expect do
        reviewable.update_fields(
          { payload: { raw: "Changed content" } },
          actor,
          version: reviewable.version,
        )
      end.to raise_error(Discourse::InvalidAccess)
      sign_in(actor)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to be_in([403, 404]), response.body
      put "/review/#{reviewable.id}/perform/approve_post.json",
          params: {
            version: reviewable.version,
          }
      expect(response.status).to be_in([403, 404]), response.body
      expect(reviewable.reload).to be_pending
    end

    it "denies #{role} native editing, movement, deletion and recovery" do
      resource = publish(member)
      actor = public_send(role)
      guardian = actor.guardian
      expect(guardian.can_edit_post?(resource)).to eq(false)
      expect(guardian.can_edit_topic?(resource.topic)).to eq(false)
      expect(guardian.can_delete_post?(resource)).to eq(false)
      expect(guardian.can_delete_topic?(resource.topic)).to eq(false)
      expect(guardian.can_move_topic_to_category?(category)).to eq(false)
      sign_in(actor)
      put "/posts/#{resource.id}.json",
          params: {
            post: {
              raw: "Changed https://example.org/new.pdf",
            },
          }
      expect(response.status).to eq(403), response.body
      delete "/isbf/library/resources/#{resource.topic_id}.json"
      expect(response.status).to eq(403), response.body
      expect(resource.reload.deleted_at).to be_nil
      expect(resource.topic.reload.deleted_at).to be_nil
      PostDestroyer.new(admin, resource).destroy
      expect(guardian.can_recover_post?(Post.with_deleted.find(resource.id))).to eq(false)
      expect(guardian.can_recover_topic?(Topic.with_deleted.find(resource.topic_id))).to eq(false)
    end
  end

  it "cannot bypass queued posting through reviewed flags or direct PostCreator" do
    [member, moderator].each do |actor|
      sign_in(actor)
      expect do
        post "/posts.json", params: native_payload(reviewed_queued_post: true)
        expect(response.status).to eq(200), response.body
        expect(response.parsed_body.fetch("action")).to eq("enqueued")
      end.not_to change(Topic, :count)
      expect { PostCreator.new(actor, native_payload).create }.to raise_error(
        Discourse::InvalidAccess,
      )
    end
  end

  it "rejects cross-library fields, UUIDs and out-of-scope native submissions" do
    original = publish
    other = Fabricate(:category)
    [
      { isbf_library_group_id: course.fetch("id") },
      { isbf_library_group_id: directory.fetch("id") },
      { isbf_learning_course_id: course.fetch("id") },
      { isbf_learning_files: "[]" },
      { category: learning_category.id },
      { category: other.id },
      { topic_id: original.topic_id },
      { archetype: Archetype.private_message, target_usernames: member.username },
      { isbf_library_files: '["injected-file"]' },
      { isbf_library_files: "null" },
    ].each do |extra|
      expect do
        result = NewPostManager.new(admin, native_payload(extra)).perform
        expect(result.success?).to eq(false)
      end.not_to change(Topic, :count)
    end
    result =
      NewPostManager.new(
        admin,
        {
          title: "Wrong namespace course submission",
          raw: "Reference https://example.org/course.pdf",
          category: learning_category.id,
          isbf_learning_course_id: course.fetch("id"),
          isbf_learning_files: "[]",
          isbf_library_group_id: group.fetch("id"),
        },
      ).perform
    expect(result.success?).to eq(false)
  end

  [
    "javascript:alert(1)",
    "ftp://example.org/notes.pdf",
    "https://",
    "/uploads/default/original/1X/sample.pdf",
    "upload://sample.pdf",
    "https://user:password@example.org/notes.pdf",
    "https://example.org/one https://example.org/two",
  ].each_with_index do |unsafe_link, index|
    it "rejects unsafe resource link #{index + 1} before posting or queuing" do
      expect do
        expect do
          submit(member, link: unsafe_link)
          expect(response.status).to eq(422), response.body
        end.not_to change(ReviewableQueuedPost, :count)
      end.not_to change(Topic, :count)
    end
  end

  it "rejects public uploads in native raw even alongside a valid external link" do
    [
      "/uploads/default/original/1X/sample.pdf",
      "upload://sample.pdf",
      "/isbf/learning/files/#{SecureRandom.uuid}",
    ].each do |upload|
      result =
        NewPostManager.new(
          admin,
          native_payload(raw: "[File](#{upload}) https://example.org/valid.pdf"),
        ).perform
      expect(result.success?).to eq(false)
    end
  end

  it "validates missing title, group, descriptions and contributors before queuing" do
    [
      { title: "" },
      { title: "x" },
      { group_id: nil },
      { group_id: course.fetch("id") },
      { group_id: SecureRandom.uuid },
      { description: "字" * 301 },
      { description: "x\u0000" },
      { contributor: "字" * 16 },
      { contributor: "line\nline" },
      { contributor: { invalid: "name" } },
    ].each do |extra|
      expect do
        submit(member, extra)
        expect(response.status).to eq(422), response.body
      end.not_to change(ReviewableQueuedPost, :count)
    end
  end

  it "respects category visibility, creation permissions and user restrictions" do
    category.set_permissions(trust_level_0: :readonly, staff: :full)
    category.save!
    submit(member)
    expect(response.status).to eq(403), response.body
    category.set_permissions(staff: :full)
    category.save!
    get "/isbf/library/resources.json", params: { group_id: group.fetch("id") }
    expect(response.status).to eq(403), response.body
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
    [
      { silenced_till: 1.day.from_now },
      { suspended_till: 1.day.from_now },
      { active: false },
      { approved: false },
    ].each do |attributes|
      actor =
        Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
      actor.update!(attributes)
      submit(actor)
      expect(response.status).to eq(403), response.body
    end
    expect(ReviewableQueuedPost.count).to eq(0)
  end

  it "preserves admin-only restrictions and queued review classification when disabled" do
    resource = publish(member)
    queued = NewPostManager.new(member, native_payload).perform.reviewable
    SiteSetting.isbf_library_enabled = false
    [member, moderator].each do |actor|
      guardian = actor.guardian
      expect(guardian.can_edit_post?(resource)).to eq(false)
      expect(guardian.can_delete_topic?(resource.topic)).to eq(false)
      expect(Reviewable.viewable_by(actor).where(id: queued.id)).to be_empty
      expect { queued.perform(actor, :approve_post) }.to raise_error(Reviewable::InvalidAction)
    end
    sign_in(member)
    get "/isbf/library/resources.json", params: { group_id: group.fetch("id") }
    expect(response.status).to be_in([403, 404]), response.body
    SiteSetting.isbf_library_enabled = true
    SiteSetting.isbf_learning_enabled = false
    get "/isbf/library/resources.json", params: { group_id: group.fetch("id") }
    expect(response.status).to be_in([403, 404]), response.body
    expect(moderator.guardian.can_edit_post?(resource)).to eq(false)
  end

  it "allows admin title and link edits while preserving original resource attribution" do
    submit(member)
    expect(response.status).to eq(200), response.body
    resource = ReviewableQueuedPost.order(:id).last.perform(admin, :approve_post).created_post
    topic = resource.topic.reload
    created_at = topic.created_at
    sign_in(admin)
    put "/posts/#{resource.id}.json",
        params: {
          post: {
            raw: "Newest reference https://example.org/revised.pdf",
            isbf_library_link: "https://example.org/revised.pdf",
          },
          title: "Revised library reference collection",
        }
    expect(response.status).to eq(200), response.body
    topic.reload
    expect(topic.title).to eq("Revised library reference collection")
    expect(topic.user_id).to eq(member.id)
    expect(topic.created_at).to eq_time(created_at)
    expect(topic.custom_fields.fetch(IsbfLibrary::GROUP_FIELD)).to eq(group.fetch("id"))
    expect(topic.custom_fields.fetch(IsbfLibrary::CONTRIBUTOR_FIELD)).to eq("资料小组")
    expect(resource.reload.user_id).to eq(member.id)
    expect(resource.raw).to include("Newest reference")
    expect(list.first.fetch("links")).to eq(["https://example.org/revised.pdf"])
    sign_in(admin)
    put "/posts/#{resource.id}.json", params: { title: "", post: { raw: resource.raw } }
    expect(response.status).to be_in([400, 422]), response.body
    expect(topic.reload.title).to eq("Revised library reference collection")
  end

  it "preserves native learning resource metadata edits through the shared field registration" do
    group
    catalog_before =
      %w[categories groups].to_h { |key| [key, PluginStore.get(IsbfLibrary::STORE, key).deep_dup] }
    sign_in(member)
    post "/isbf/learning/resources.json",
         params: {
           course_id: course.fetch("id"),
           title: "Original learning reference collection",
           link: "https://example.org/original-course.pdf",
           description: "Original course introduction",
           contributor: "课程小组",
         }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(true)
    approval = ReviewableQueuedPost.order(:id).last.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    resource = approval.created_post.reload
    topic = resource.topic.reload
    topic_created_at = topic.created_at
    post_created_at = resource.created_at
    version = resource.version
    revised_link = "https://example.org/revised-course.pdf"
    revised_description = "Updated course introduction"
    revised_raw =
      IsbfLearning.link_body(
        "Revised learning reference collection",
        revised_link,
        revised_description,
      )

    sign_in(admin)
    put "/posts/#{resource.id}.json",
        params: {
          title: "Revised learning reference collection",
          post: {
            raw: revised_raw,
            isbf_learning_link: revised_link,
            isbf_learning_description: revised_description,
            isbf_learning_contributor: "复习小组",
          },
        }
    expect(response.status).to eq(200), response.body
    topic.reload
    resource.reload
    expect(topic.title).to eq("Revised learning reference collection")
    expect(topic.category_id).to eq(learning_category.id)
    expect(topic.user_id).to eq(member.id)
    expect(resource.user_id).to eq(member.id)
    expect(topic.created_at).to eq_time(topic_created_at)
    expect(resource.created_at).to eq_time(post_created_at)
    expect(topic.custom_fields).to include(
      IsbfLearning::COURSE_FIELD => course.fetch("id"),
      IsbfLearning::FILES_FIELD => [],
      IsbfLearning::LINK_FIELD => revised_link,
      IsbfLearning::DESCRIPTION_FIELD => revised_description,
      IsbfLearning::CONTRIBUTOR_FIELD => "复习小组",
    )
    expect(topic.custom_fields.keys.grep(/\Aisbf_library_/)).to be_empty
    expect(resource.raw).to eq(revised_raw)
    expect(resource.version).to be > version
    expect(PostRevision.where(post_id: resource.id)).to be_present
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    updated = response.parsed_body.fetch("resources").find { |item| item.fetch("id") == topic.id }
    expect(updated).to include(
      "title" => topic.title,
      "links" => [revised_link],
      "description" => revised_description,
      "contributor" => "复习小组",
    )
    catalog_before.each do |key, entries|
      expect(PluginStore.get(IsbfLibrary::STORE, key)).to eq(entries)
    end
  end

  it "soft deletes through native PostDestroyer without losing catalog or metadata" do
    resource = publish
    sign_in(admin)
    expect do
      delete "/isbf/library/resources/#{resource.topic_id}.json", params: { force_destroy: true }
      expect(response.status).to eq(200), response.body
    end.not_to change { Topic.with_deleted.count }
    expect(Post.with_deleted.find(resource.id).deleted_at).to be_present
    deleted = Topic.with_deleted.find(resource.topic_id)
    expect(deleted.deleted_at).to be_present
    expect(deleted.custom_fields.fetch(IsbfLibrary::GROUP_FIELD)).to eq(group.fetch("id"))
    expect(list).to be_empty
    expect(list(admin)).to be_empty
    expect(IsbfLibrary::Catalog.groups).to include(group)
  end

  it "refuses deletion of ordinary, learning, unknown and malformed resource IDs" do
    ordinary = Fabricate(:post)
    learning = learning_post
    sign_in(admin)
    [ordinary.topic_id, learning.topic_id, 999_999_999, "invalid"].each do |id|
      delete "/isbf/library/resources/#{id}.json"
      expect(response.status).to be_in(id == "invalid" ? [400] : [403, 404, 422]), response.body
    end
    expect(ordinary.reload.deleted_at).to be_nil
    expect(learning.reload.deleted_at).to be_nil
  end

  it "paginates published visible resources with zero-based pages" do
    resources = 21.times.map { publish }
    newest = resources.last
    expect(list.map { |item| item.fetch("id") }).to eq(resources.reverse.first(20).map(&:topic_id))
    expect(response.parsed_body.fetch("has_more")).to eq(true)
    expect(list(member, page: 1).map { |item| item.fetch("id") }).to eq([resources.first.topic_id])
    newest.update!(hidden: true)
    expect(list.length).to eq(20)
    expect(response.parsed_body.fetch("has_more")).to eq(false)
    expect(list(member, page: 1)).to be_empty
    %w[-1 invalid 1.5].each do |page|
      get "/isbf/library/resources.json", params: { group_id: group.fetch("id"), page: page }
      expect(response.status).to eq(400), response.body
    end
  end

  it "searches the whole library while separating custom searches and preserving native global search" do
    first = publish(admin, title: "Calculus library first group")
    other_directory = IsbfLibrary::Catalog.create(admin, kind: "category", name: "其他资料")
    other_group =
      IsbfLibrary::Catalog.create(
        admin,
        kind: "group",
        name: "参考资料",
        category_id: other_directory.fetch("id"),
      )
    second =
      publish(
        admin,
        title: "Calculus library second group",
        isbf_library_group_id: other_group.fetch("id"),
      )
    learning = learning_post
    ordinary = Fabricate(:post, raw: "Calculus reference in an ordinary topic.")
    SearchIndexer.enable
    [first, second, learning, ordinary].each do |item|
      SearchIndexer.index(item, force: true)
      SearchIndexer.index(item.topic, force: true)
    end
    expect(list(member, q: "calculus").map { |item| item.fetch("id") }).to contain_exactly(
      first.topic_id,
      second.topic_id,
    )
    get "/isbf/learning/resources.json", params: { q: "calculus" }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").map { |item| item.fetch("id") }).to eq(
      [learning.topic_id],
    )
    library_search =
      Search.new(
        "calculus isbf-library:library in:first",
        guardian: member.guardian,
        search_type: :full_page,
        type_filter: "topic",
      ).execute
    expect(library_search.posts.map(&:topic_id)).to contain_exactly(first.topic_id, second.topic_id)
    global_search =
      Search.new(
        "calculus in:first",
        guardian: member.guardian,
        search_type: :full_page,
        type_filter: "topic",
      ).execute
    expect(global_search.posts.map(&:topic_id)).to include(
      first.topic_id,
      second.topic_id,
      learning.topic_id,
    )
    first.update!(hidden: true)
    PostDestroyer.new(admin, second).destroy
    expect(list(member, q: "calculus")).to be_empty
  ensure
    SearchIndexer.disable
  end

  it "ignores injected native posting parameters on the dedicated link endpoint" do
    other = Fabricate(:category)
    submit(
      admin,
      raw: "Injected https://example.net/extra",
      category: other.id,
      archetype: Archetype.private_message,
      target_usernames: member.username,
      isbf_learning_course_id: course.fetch("id"),
      isbf_library_files: '["injected"]',
    )
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    expect(topic.category_id).to eq(category.id)
    expect(topic.archetype).to eq(Archetype.default)
    expect(topic.first_post.raw).not_to include("Injected")
    expect(topic.custom_fields.fetch(IsbfLibrary::FILES_FIELD)).to eq([])
    expect(topic.custom_fields.keys.grep(/\Aisbf_learning_/)).to be_empty
  end

  it "rejects anonymous native submissions and rejects queued resources without publishing" do
    result = NewPostManager.new(member, native_payload(isbf_anonymous: true)).perform
    expect(result.success?).to eq(false)
    queued = NewPostManager.new(member, native_payload).perform
    expect(queued.action).to eq(:enqueued)
    expect do
      expect(queued.reviewable.perform(admin, :reject_post).success?).to eq(true)
    end.not_to change(Topic, :count)
    expect(queued.reviewable.reload).to be_rejected
  end

  it "rejects approval after a queued resource is moved to the learning category" do
    result = NewPostManager.new(member, native_payload).perform
    expect(result.action).to eq(:enqueued)
    reviewable = result.reviewable
    reviewable.update!(category_id: learning_category.id)
    approval = nil
    expect do
      approval = reviewable.perform(admin, :approve_post)
    rescue Discourse::InvalidAccess, Discourse::InvalidParameters, Reviewable::InvalidAction
      # Native callers can receive an action failure or a permission exception.
    end.not_to change(Topic, :count)
    expect(approval.success?).to eq(false) if approval
    expect(reviewable.reload).to be_pending
  end

  it "keeps existing protected learning files readable without exposing them in library resources" do
    file_id = SecureRandom.uuid
    PluginStore.set(
      IsbfLearning::STORE,
      "file:#{file_id}",
      {
        "id" => file_id,
        "name" => "existing-notes.pdf",
        "size" => 10,
        "owner_id" => member.id,
        "url" => "/isbf/learning/files/#{file_id}",
      },
    )
    result =
      NewPostManager.new(
        member,
        {
          title: "Existing protected course collection",
          raw: "[Private notes](/isbf/learning/files/#{file_id})",
          category: learning_category.id,
          isbf_learning_course_id: course.fetch("id"),
          isbf_learning_files: [file_id].to_json,
        },
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    approval = result.reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    expect(IsbfLearning.file_accessible?(file_id, member, member.guardian)).to eq(true)
    expect(IsbfLearning.file_accessible?(file_id, new_member, new_member.guardian)).to eq(true)
    expect(IsbfLearning.file_accessible?(file_id, nil, Guardian.new)).to eq(false)
    publish
    expect(list.map { |item| item.fetch("id") }).not_to include(approval.created_post.topic_id)
    expect(PluginStore.get(IsbfLearning::STORE, "file:#{file_id}")).to be_present
  end

  it "excludes both library categories from native community lists for members and admins" do
    resource = publish
    learning = learning_post
    ordinary = Fabricate(:post).topic
    [resource.topic, learning.topic, ordinary].each do |topic|
      TopTopic.create!(topic: topic, all_score: 10)
    end
    TopicHotScore.update_scores
    ids = [resource.topic_id, learning.topic_id]
    [member, admin].each do |actor|
      %i[list_latest list_hot list_filter].each do |method|
        expect(TopicQuery.new(actor, q: "").public_send(method).topics.map(&:id)).to include(
          ordinary.id,
        )
        expect(TopicQuery.new(actor, q: "").public_send(method).topics.map(&:id) & ids).to be_empty
        [category, learning_category].each do |item|
          expect(
            TopicQuery.new(actor, category: item.id, q: "").public_send(method).topics.map(&:id) &
              ids,
          ).to be_empty
        end
      end
      expect(TopicQuery.new(actor).list_top_for(:all).topics.map(&:id) & ids).to be_empty
    end
  end
end
