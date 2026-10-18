# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF learning contributors and resource review", type: :request do
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
  let(:link) { "https://example.org/contributor-notes.pdf" }

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    SiteSetting.enable_category_group_moderation = true
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
    reviewer_group.add(category_reviewer)
    CategoryModerationGroup.create!(category_id: category.id, group_id: reviewer_group.id)
  end

  def submit(actor = admin, extra = {})
    @number = (@number || 0) + 1
    sign_in(actor)
    post "/isbf/learning/resources.json",
         params: {
           course_id: course.fetch("id"),
           title: "Contributor reference collection #{@number}",
           link: link,
         }.merge(extra)
  end

  def queue(actor = member, extra = {})
    submit(actor, extra)
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(true)
    ReviewableQueuedPost.order(:id).last
  end

  it "advertises the resource contributor and admin management contracts" do
    sign_in(member)
    get "/site.json"
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("isbf_learning")).to include(
      "resource_contributor" => true,
      "resource_admin_management" => true,
    )
  end

  it "strips contributor whitespace and preserves actual topic and post authorship" do
    submit(admin, contributor: "  数学学习小组  ")
    expect(response.status).to eq(200), response.body
    resource = response.parsed_body.fetch("resource")
    expect(resource.fetch("contributor")).to eq("数学学习小组")
    topic = Topic.find(resource.fetch("id"))
    expect(topic.custom_fields.fetch("isbf_learning_contributor")).to eq("数学学习小组")
    expect(topic.user_id).to eq(admin.id)
    expect(topic.first_post.user_id).to eq(admin.id)
  end

  [nil, "", "   "].each_with_index do |value, index|
    it "defaults blank contributor variant #{index + 1} to the submitting account name" do
      admin.update!(name: "Account display name longer than fifteen characters")
      submit(admin, contributor: value)
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("resource").fetch("contributor")).to eq(admin.name)
    end
  end

  it "falls back to username when the account has no display name" do
    admin.update!(name: nil)
    submit
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resource").fetch("contributor")).to eq(admin.username)
  end

  it "uses the original submitter for historical resources without contributor metadata" do
    submit(admin, contributor: "自定义贡献者")
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("resource").fetch("id"))
    TopicCustomField.where(topic_id: topic.id, name: "isbf_learning_contributor").delete_all
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").first.fetch("contributor")).to eq(
      admin.name.presence || admin.username,
    )
  end

  it "accepts fifteen Unicode codepoints even when they occupy more bytes" do
    submit(admin, contributor: "😀" * 15)
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resource").fetch("contributor")).to eq("😀" * 15)
  end

  [
    "😀" * 16,
    "字" * 16,
    "line\nline",
    "line\rline",
    "line\tline",
    "x\u0000",
    { name: "invalid" },
    ["invalid"],
  ].each_with_index do |value, index|
    it "rejects invalid contributor variant #{index + 1} without creating a topic or queue" do
      expect do
        expect do
          submit(member, contributor: value)
          expect(response.status).to eq(422), response.body
        end.not_to change(ReviewableQueuedPost, :count)
      end.not_to change(Topic, :count)
    end
  end

  it "serializes contributor HTML as plain text rather than generated markup" do
    value = "<b>小组</b>"
    reviewable = queue(member, contributor: value, description: "Original introduction")
    sign_in(admin)
    get "/review/#{reviewable.id}.json"
    expect(response.status).to eq(200), response.body
    expect(
      response.parsed_body.fetch("reviewable").fetch("payload").fetch("isbf_learning_contributor"),
    ).to eq(value)
    preview = Nokogiri::HTML5.fragment(response.parsed_body.fetch("reviewable").fetch("cooked"))
    expect(preview.css("b")).to be_empty
    expect(preview.text).to include(value)
    approval = reviewable.perform(admin, :approve_post)
    expect(approval.success?).to eq(true)
    topic = approval.created_post.topic.reload
    expect(topic.user_id).to eq(member.id)
    expect(topic.first_post.user_id).to eq(member.id)
    expect(topic.custom_fields.fetch("isbf_learning_description")).to eq("Original introduction")
    sign_in(member)
    get "/isbf/learning/resources.json", params: { course_id: course.fetch("id") }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("resources").first.fetch("contributor")).to eq(value)
  end

  %w[member new_member moderator category_reviewer].each do |role|
    it "queues #{role} with contributor and description attributed to the real submitter" do
      actor = public_send(role)
      reviewable = queue(actor, contributor: "学习小组", description: "Review introduction")
      expect(reviewable.target_created_by_id).to eq(actor.id)
      expect(reviewable.payload.fetch("isbf_learning_contributor")).to eq("学习小组")
      expect(reviewable.payload.fetch("isbf_learning_description")).to eq("Review introduction")
      approval = reviewable.perform(admin, :approve_post)
      expect(approval.success?).to eq(true)
      expect(approval.created_post.user_id).to eq(actor.id)
      expect(
        approval.created_post.topic.reload.custom_fields.fetch("isbf_learning_contributor"),
      ).to eq("学习小组")
    end
  end

  it "rejects a queued resource without publishing or changing its attribution" do
    reviewable = queue(member, contributor: "学习小组")
    expect do
      result = reviewable.perform(admin, :reject_post)
      expect(result.success?).to eq(true)
    end.not_to change(Topic, :count)
    expect(reviewable.reload.rejected?).to eq(true)
    expect(reviewable.target_created_by_id).to eq(member.id)
    expect(reviewable.payload.fetch("isbf_learning_contributor")).to eq("学习小组")
  end

  %w[member moderator category_reviewer].each do |role|
    it "denies #{role} native review listing, inspection, editing and approval of library resources" do
      reviewable = queue
      actor = public_send(role)
      expect(Reviewable.viewable_by(actor).where(id: reviewable.id)).to be_empty
      expect(reviewable.send(:can_review_target?, actor.guardian)).to eq(false)
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
      get "/review.json", params: { ids: [reviewable.id] }
      if response.status == 200
        expect(response.parsed_body.fetch("reviewables")).to be_empty
      else
        expect(response.status).to be_in([403, 404])
      end
      get "/review/user-menu-list.json"
      if response.status == 200
        expect(response.parsed_body.fetch("reviewables").map { |item| item["id"] }).not_to include(
          reviewable.id,
        )
      else
        expect(response.status).to be_in([403, 404])
      end
      get "/review/#{reviewable.id}.json"
      expect(response.status).to be_in([403, 404])
      put "/review/#{reviewable.id}.json",
          params: {
            version: reviewable.version,
            reviewable: {
              payload: {
                raw: "Changed content",
              },
            },
          }
      expect(response.status).to be_in([403, 404])
      put "/review/#{reviewable.id}/perform/approve_post.json",
          params: {
            version: reviewable.version,
          }
      expect(response.status).to be_in([403, 404])
      expect(reviewable.reload.pending?).to eq(true)
      expect(reviewable.payload.fetch("raw")).not_to eq("Changed content")
    end
  end

  it "denies guest access to native resource review reads" do
    result =
      NewPostManager.new(
        member,
        {
          title: "Guest review permission reference",
          raw: "Reference https://example.org/notes.pdf",
          category: category.id,
          isbf_learning_course_id: course.fetch("id"),
          isbf_learning_files: "[]",
        },
      ).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    reviewable = result.reviewable
    expect(reviewable).to be_a(ReviewableQueuedPost)
    ["/review.json", "/review/#{reviewable.id}.json", "/review/user-menu-list.json"].each do |path|
      get path
      expect(response.status).to eq(403), response.body
    end
  end

  it "keeps normal queued posts and course applications reviewable by moderators" do
    ordinary_category = Fabricate(:category)
    ordinary =
      Fabricate(
        :reviewable_queued_post_topic,
        created_by: member,
        target_created_by: member,
        category: ordinary_category,
        payload: {
          raw: "Ordinary community submission",
          title: "Ordinary queued discussion",
          category: ordinary_category.id,
        },
      )
    application = IsbfLearning::Courses.request(member, name: "大学物理", grade: 2)
    expect(
      Reviewable
        .viewable_by(moderator, preload: false)
        .where(id: [ordinary.id, application.id])
        .pluck(:id),
    ).to contain_exactly(ordinary.id, application.id)
    expect(ordinary.send(:can_review_target?, moderator.guardian)).to eq(true)
    expect(application.send(:can_review_target?, moderator.guardian)).to eq(true)
  end

  it "cannot bypass the resource queue with a client supplied reviewed flag on native posting" do
    [member, moderator].each do |actor|
      sign_in(actor)
      expect do
        post "/posts.json",
             params: {
               title: "Native reviewed flag bypass #{actor.id}",
               raw: "Reference https://example.org/notes.pdf",
               category: category.id,
               isbf_learning_course_id: course.fetch("id"),
               isbf_learning_files: "[]",
               isbf_learning_contributor: "学习小组",
               reviewed_queued_post: true,
             }
        expect(response.status).to eq(200), response.body
        expect(response.parsed_body.fetch("action")).to eq("enqueued")
      end.not_to change(Topic, :count)
      expect(ReviewableQueuedPost.order(:id).last.payload.fetch("isbf_learning_contributor")).to eq(
        "学习小组",
      )
    end
  end
end
