# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF learning link sharing", type: :request do
  fab!(:category)
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

  let(:course) do
    IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1).with_indifferent_access
  end
  let(:link) { "https://example.org/course-notes.pdf?download=1#page-2" }

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
  end

  def link_payload(extra = {})
    @submission_number = (@submission_number || 0) + 1
    {
      course_id: course[:id],
      title: "Calculus reference collection #{@submission_number}",
      link: link,
    }.merge(extra)
  end

  def submit_link(actor = admin, extra = {})
    sign_in(actor)
    post "/isbf/learning/resources.json", params: link_payload(extra)
  end

  def expect_link_resource(resource, topic)
    expect(resource.fetch("id")).to eq(topic.id)
    expect(resource.fetch("links")).to eq([link])
    expect(resource.fetch("description")).to eq("")
    expect(resource.fetch("files")).to eq([])
    expect(resource.fetch("link_only")).to eq(true)
  end

  def legacy_resource
    id = SecureRandom.uuid
    PluginStore.set(
      "isbf-learning",
      "file:#{id}",
      {
        "id" => id,
        "name" => "existing-notes.pdf",
        "size" => 10,
        "owner_id" => admin.id,
        "url" => "/isbf/learning/files/#{id}",
      },
    )
    result =
      NewPostManager.new(
        admin,
        {
          title: "Legacy calculus reference collection",
          raw:
            "Existing notes [Private file](/isbf/learning/files/#{id}) https://example.org/legacy.pdf",
          category: category.id,
          isbf_learning_course_id: course[:id],
          isbf_learning_files: [id].to_json,
        },
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    [result.post, id]
  end

  it "requires login before accepting a link" do
    expect do
      post "/isbf/learning/resources.json", params: link_payload
      expect(response.status).to eq(403)
    end.not_to change(Topic, :count)
  end

  ["admin"].each do |role|
    it "publishes #{role} links directly as native topics" do
      expect do
        submit_link(public_send(role))
        expect(response.status).to eq(200), response.body
      end.not_to change(ReviewableQueuedPost, :count)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => false)
      topic = Topic.find(data.fetch("resource").fetch("id"))
      expect(topic.category_id).to eq(category.id)
      expect(topic.user_id).to eq(public_send(role).id)
      expect(topic.custom_fields["isbf_learning_course_id"]).to eq(course[:id])
      expect(topic.custom_fields["isbf_learning_link"]).to eq(link)
      expect_link_resource(data.fetch("resource"), topic)
    end
  end

  %w[new_member member moderator].each do |role|
    it "queues #{role} links and preserves metadata when admins approve them" do
      actor = public_send(role)
      expect do
        expect do
          submit_link(actor)
          expect(response.status).to eq(200), response.body
        end.to change(ReviewableQueuedPost, :count).by(1)
      end.not_to change(Topic, :count)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => true)
      expect(data["resource"]).to be_nil
      reviewable = ReviewableQueuedPost.order(:id).last
      expect(reviewable.target_created_by_id).to eq(actor.id)
      expect(reviewable.payload["isbf_learning_link"]).to eq(link)
      get "/isbf/learning/resources.json", params: { course_id: course[:id] }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("resources")).to be_empty
      sign_in(admin)
      get "/review.json", params: { type: "ReviewableQueuedPost", status: "pending" }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("reviewables").map { |item| item["id"] }).to include(
        reviewable.id,
      )
      approval = reviewable.perform(admin, :approve_post)
      expect(approval.success?).to eq(true)
      topic = approval.created_post.topic.reload
      expect(topic.user_id).to eq(actor.id)
      expect(topic.custom_fields["isbf_learning_course_id"]).to eq(course[:id])
      expect(topic.custom_fields["isbf_learning_link"]).to eq(link)
      sign_in(actor)
      get "/isbf/learning/resources.json", params: { course_id: course[:id] }
      expect(response.status).to eq(200), response.body
      expect_link_resource(
        response.parsed_body.fetch("resources").find { |item| item["id"] == topic.id },
        topic,
      )
      [actor, admin].each do |viewer|
        expect(TopicQuery.new(viewer).list_latest.topics.map(&:id)).not_to include(topic.id)
      end
    end
  end

  [
    "javascript:alert(1)",
    "ftp://example.org/notes.pdf",
    "/course-notes.pdf",
    "https://",
    "https://user:password@example.org/notes.pdf",
    "https://user@example.org/notes.pdf",
    "https://example.org/one https://example.org/two",
    " https://example.org/notes.pdf",
    "https://example.org/notes.pdf\n",
    "https://example.org/\tnotes.pdf",
    "https://example.org/notes\u0000.pdf",
    "https://example.org/#{"x" * 2048}",
  ].each_with_index do |invalid_link, index|
    it "rejects malformed or unsafe link variant #{index + 1} without posting or queuing" do
      expect do
        expect do
          submit_link(member, link: invalid_link)
          expect(response.status).to eq(422), response.body
        end.not_to change(ReviewableQueuedPost, :count)
      end.not_to change(Topic, :count)
    end
  end

  it "rejects links to this site's hostname" do
    submit_link(member, link: "https://#{Discourse.current_hostname}/t/example/123")
    expect(response.status).to eq(422), response.body
    expect(ReviewableQueuedPost.count).to eq(0)
  end

  it "accepts a single external HTTP link at the maximum length" do
    prefix = "http://example.org/"
    accepted_link = "#{prefix}#{"x" * (2048 - prefix.length)}"
    submit_link(admin, link: accepted_link)
    expect(response.status).to eq(200), response.body
    resource = response.parsed_body.fetch("resource")
    expect(resource.fetch("links")).to eq([accepted_link])
    expect(Topic.find(resource.fetch("id")).custom_fields["isbf_learning_link"]).to eq(
      accepted_link,
    )
  end

  [
    { title: nil },
    { title: "" },
    { title: "x" },
    { course_id: SecureRandom.uuid },
    { course_id: nil },
    { link: nil },
  ].each_with_index do |extra, index|
    it "rejects invalid title, course or missing link variant #{index + 1}" do
      expect do
        expect do
          submit_link(member, extra)
          expect(response.status).to eq(422), response.body
        end.not_to change(ReviewableQueuedPost, :count)
      end.not_to change(Topic, :count)
    end
  end

  it "uses only the link contract despite injected native topic parameters" do
    other = Fabricate(:category)
    submit_link(
      admin,
      raw: "Injected discussion https://example.net/unwanted",
      category: other.id,
      tags: ["injected"],
      archetype: Archetype.private_message,
      target_usernames: member.username,
      isbf_learning_files: '["injected-file"]',
    )
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    expect(topic.category_id).to eq(category.id)
    expect(topic.archetype).to eq(Archetype.default)
    expect(topic.tags).to be_empty
    expect(topic.first_post.raw).to eq(IsbfLearning.link_body(topic.title, link))
    expect(topic.first_post.raw).not_to include("Injected discussion")
    expect(topic.custom_fields["isbf_learning_files"]).to eq([])
  end

  it "queues a short link with a safe title without requiring an extra body" do
    submit_link(member, title: "Notes [one] & two", link: "https://a.co")
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(true)
    reviewable = ReviewableQueuedPost.order(:id).last
    expect(reviewable.payload["raw"]).to eq("[Notes \\[one\\] &amp; two](<https://a.co>)")
    expect(reviewable.payload["isbf_learning_link"]).to eq("https://a.co")
  end

  it "denies submission when disabled or when the category denies creation" do
    SiteSetting.isbf_learning_enabled = false
    submit_link(member)
    expect(response.status).to eq(404), response.body
    expect(ReviewableQueuedPost.count).to eq(0)
    SiteSetting.isbf_learning_enabled = true
    category.set_permissions(trust_level_0: :readonly, staff: :full)
    category.save!
    submit_link(member)
    expect(response.status).to eq(403), response.body
  end

  it "denies silenced, suspended, inactive and unapproved ordinary actors" do
    [
      { silenced_till: 1.day.from_now },
      { suspended_till: 1.day.from_now },
      { active: false },
      { approved: false },
    ].each do |attributes|
      actor =
        Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
      actor.update!(attributes)
      submit_link(actor)
      expect(response.status).to eq(403), response.body
    end
    expect(ReviewableQueuedPost.count).to eq(0)
  end

  it "excludes link and legacy resources from every community list even for staff and direct categories" do
    old_post, = legacy_resource
    submit_link(admin)
    expect(response.status).to eq(200), response.body
    link_topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    ordinary = Fabricate(:post).topic
    topics = [old_post.topic, link_topic, ordinary]
    topics.each { |topic| TopTopic.create!(topic: topic, all_score: 10) }
    TopicHotScore.update_scores
    resource_ids = [old_post.topic_id, link_topic.id]
    [member, admin].each do |viewer|
      %i[list_latest list_hot list_filter].each do |list|
        ids = TopicQuery.new(viewer, q: "").public_send(list).topics.map(&:id)
        expect(ids).to include(ordinary.id)
        expect(ids & resource_ids).to be_empty
        category_ids =
          TopicQuery.new(viewer, category: category.id, q: "").public_send(list).topics.map(&:id)
        expect(category_ids & resource_ids).to be_empty
      end
      expect(TopicQuery.new(viewer).list_top_for(:all).topics.map(&:id)).to include(ordinary.id)
      expect(TopicQuery.new(viewer).list_top_for(:all).topics.map(&:id) & resource_ids).to be_empty
      expect(
        TopicQuery.new(viewer, category: category.id).list_top_for(:all).topics.map(&:id) &
          resource_ids,
      ).to be_empty
    end
  end

  it "keeps both link and legacy file resources accessible through library browsing and native search" do
    old_post, file_id = legacy_resource
    submit_link(admin)
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    ordinary = Fabricate(:post, raw: "Calculus notes in an ordinary community topic.")
    SearchIndexer.enable
    [old_post, topic.first_post, ordinary].each do |item|
      SearchIndexer.index(item, force: true)
      SearchIndexer.index(item.topic, force: true)
    end
    sign_in(member)
    get "/isbf/learning"
    expect(response.status).to eq(200), response.body
    get "/isbf/learning/resources.json", params: { course_id: course[:id] }
    expect(response.status).to eq(200), response.body
    resources = response.parsed_body.fetch("resources")
    expect(resources.map { |item| item["id"] }).to contain_exactly(old_post.topic_id, topic.id)
    expect_link_resource(resources.find { |item| item["id"] == topic.id }, topic)
    legacy = resources.find { |item| item["id"] == old_post.topic_id }
    expect(legacy.fetch("files").map { |file| file["id"] }).to eq([file_id])
    expect(legacy.fetch("links")).to eq(["https://example.org/legacy.pdf"])
    expect(legacy.fetch("description")).to be_present
    get "/isbf/learning/resources.json", params: { q: "calculus" }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").map { |item| item["id"] }).to contain_exactly(
      old_post.topic_id,
      topic.id,
    )
    result =
      Search.new(
        "calculus isbf-learning:library in:first",
        guardian: member.guardian,
        search_type: :full_page,
        type_filter: "topic",
      ).execute
    expect(result.posts.map(&:topic_id)).to contain_exactly(old_post.topic_id, topic.id)
    expect(PluginStore.get("isbf-learning", "file:#{file_id}")).to be_present
    expect(IsbfLearning.file_accessible?(file_id, member, member.guardian)).to eq(true)
  ensure
    SearchIndexer.disable
  end

  it "hides link resources whose first post is hidden or whose category becomes inaccessible" do
    submit_link(admin)
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    topic.first_post.update!(hidden: true)
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course[:id] }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources")).to be_empty
    topic.first_post.update!(hidden: false)
    category.set_permissions(staff: :full)
    category.save!
    get "/isbf/learning/resources.json", params: { course_id: course[:id] }
    expect(response.status).to eq(403), response.body
    submit_link(member)
    expect(response.status).to eq(403), response.body
  end
end
