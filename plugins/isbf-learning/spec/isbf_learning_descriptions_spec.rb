# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF learning resource descriptions", type: :request do
  fab!(:category)
  fab!(:admin)
  fab!(:member) do
    Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
  end

  let(:course) { IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1) }
  let(:link) { "https://example.org/notes.pdf" }

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
  end

  def submit_resource(actor = admin, extra = {})
    @submission_number = (@submission_number || 0) + 1
    sign_in(actor)
    post "/isbf/learning/resources.json",
         params: {
           course_id: course.fetch("id"),
           title: "Course reference material #{@submission_number}",
           link: link,
         }.merge(extra)
  end

  def published_topic
    Topic.find(response.parsed_body.fetch("resource").fetch("id"))
  end

  it "publishes a staff introduction in the native topic and resource contract" do
    introduction = "第一章的例题与解答\n附有课堂复习笔记"
    submit_resource(admin, description: introduction)
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resource").fetch("description")).to eq(introduction)
    topic = published_topic
    expect(topic.custom_fields["isbf_learning_description"]).to eq(introduction)
    expect(topic.first_post.raw).to include(introduction)
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").first.fetch("description")).to eq(introduction)
  end

  it "preserves an ordinary applicant's introduction through native queued approval" do
    introduction = "复习重点：极限与连续"
    expect do
      submit_resource(member, description: introduction)
      expect(response.status).to eq(200), response.body
    end.not_to change(Topic, :count)
    expect(response.parsed_body.fetch("pending")).to eq(true)
    reviewable = ReviewableQueuedPost.order(:id).last
    expect(reviewable.payload.fetch("isbf_learning_description")).to eq(introduction)
    expect(reviewable.payload.fetch("raw")).to include(introduction)
    approval = reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    topic = approval.created_post.topic.reload
    expect(topic.custom_fields["isbf_learning_description"]).to eq(introduction)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").first.fetch("description")).to eq(introduction)
    [member, admin].each do |viewer|
      expect(TopicQuery.new(viewer).list_latest.topics.map(&:id)).not_to include(topic.id)
    end
  end

  [{}, { description: "" }, { description: " \r\n\t " }].each_with_index do |extra, index|
    it "keeps an omitted or empty introduction empty for variant #{index + 1}" do
      submit_resource(admin, extra)
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("resource").fetch("description")).to eq("")
      expect(published_topic.custom_fields["isbf_learning_description"]).to eq("")
    end
  end

  it "returns an empty introduction for a historical link topic without the custom field" do
    submit_resource
    expect(response.status).to eq(200), response.body
    topic = published_topic
    TopicCustomField.where(topic_id: topic.id, name: "isbf_learning_description").delete_all
    expect(topic.reload.custom_fields).not_to have_key("isbf_learning_description")
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").first.fetch("description")).to eq("")
  end

  it "counts Unicode characters rather than bytes at the 300 character limit" do
    introduction = "😀" * 300
    submit_resource(admin, description: introduction)
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resource").fetch("description")).to eq(introduction)
    expect(published_topic.custom_fields["isbf_learning_description"]).to eq(introduction)
  end

  [
    "字" * 301,
    "😀" * 301,
    { text: "invalid" },
    ["invalid"],
    "text\u0000",
  ].each_with_index do |introduction, index|
    it "rejects invalid introduction #{index + 1} without posting or queuing" do
      expect do
        expect do
          submit_resource(member, description: introduction)
          expect(response.status).to eq(422), response.body
        end.not_to change(ReviewableQueuedPost, :count)
      end.not_to change(Topic, :count)
    end
  end

  it "renders multiline HTML and Markdown introductions as escaped plain text" do
    introduction =
      "<script>alert('x')</script>\r\n<img src=x onerror=alert(1)>\r\n[unsafe](javascript:alert(1)) **bold**"
    submit_resource(admin, description: introduction)
    expect(response.status).to eq(200), response.body
    normalized = introduction.gsub("\r\n", "\n")
    expect(response.parsed_body.fetch("resource").fetch("description")).to eq(normalized)
    topic = published_topic
    expect(topic.custom_fields["isbf_learning_description"]).to eq(normalized)
    raw = topic.first_post.raw
    expect(raw).to include("&lt;script&gt;", "&lt;img", "\\[unsafe\\]", "\\*\\*bold\\*\\*")
    cooked = Nokogiri::HTML5.fragment(topic.first_post.cooked)
    expect(cooked.css("script, img, strong")).to be_empty
    expect(cooked.css("a").map { |anchor| anchor["href"] }).to eq([link])
    expect(cooked.text).to include(
      "<script>alert('x')</script>",
      "[unsafe](javascript:alert(1)) **bold**",
    )
  end

  it "finds terms appearing only in the introduction within the library search" do
    submit_resource(admin, description: "Quasiconvexity reference exercises")
    expect(response.status).to eq(200), response.body
    topic = published_topic
    ordinary =
      Fabricate(:post, raw: "Quasiconvexity in a community discussion outside the library.")
    SearchIndexer.enable
    [topic.first_post, ordinary].each do |item|
      SearchIndexer.index(item, force: true)
      SearchIndexer.index(item.topic, force: true)
    end
    sign_in(member)
    get "/isbf/learning/resources.json", params: { q: "quasiconvexity" }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").map { |item| item["id"] }).to eq([topic.id])
  ensure
    SearchIndexer.disable
  end

  it "denies an approved ordinary author's native introduction revision" do
    submit_resource(member, description: "Original introduction")
    expect(response.status).to eq(200), response.body
    reviewable = ReviewableQueuedPost.order(:id).last
    approval = reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    resource = approval.created_post
    sign_in(member)
    put "/posts/#{resource.id}.json",
        params: {
          post: {
            isbf_learning_description: "Changed introduction",
          },
        }
    expect(response.status).to eq(403), response.body
    expect(resource.topic.reload.custom_fields["isbf_learning_description"]).to eq(
      "Original introduction",
    )
    expect do
      PostRevisor.new(resource).revise!(member, isbf_learning_description: "Changed introduction")
    end.to raise_error(Discourse::InvalidAccess)
  end
end
