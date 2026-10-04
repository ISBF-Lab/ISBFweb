# frozen_string_literal: true

require_relative "../support/fixtures"

RSpec.describe IsbfModeration::SevereReportsController, type: :request do
  fab!(:reporter) { isbf_fabricate(:user) }
  fab!(:author) { isbf_fabricate(:user) }
  fab!(:staff) { isbf_fabricate(:moderator) }
  fab!(:forum_post) { isbf_fabricate(:post, user: author) }

  before do
    SiteSetting.isbf_severe_reports_enabled = true
    reporter.update!(trust_level: 0)
    sign_in(reporter)
  end

  def report(post = forum_post, **overrides)
    post "/isbf/moderation/severe-reports.json",
         params: {
           post_id: post.id,
           reason: "This content contains a serious and immediate community concern.",
           confirmed: true,
         }.merge(overrides),
         as: :json
  end

  it "lets TL0 submit a native flag and atomically holds the first post and topic" do
    SiteSetting.flag_post_allowed_groups = Group::AUTO_GROUPS[:trust_level_1].to_s
    expect(reporter.guardian.post_can_act?(forum_post, :notify_moderators)).to eq(false)

    report

    expect(response).to have_http_status(:ok)
    reviewable = forum_post.reviewable_flag
    expect(response.parsed_body).to eq(
      "post_id" => forum_post.id,
      "hidden" => true,
      "reviewable_id" => reviewable.id,
    )
    expect(forum_post.reload).to be_hidden
    expect(forum_post.topic.reload).not_to be_visible
    expect(reviewable.reload).to be_pending
    expect(reviewable.force_review).to eq(true)
    expect(reviewable.payload[IsbfModeration::Hold::PENDING]).to eq(true)
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(true)
    action = PostAction.flags.find_by(post_id: forum_post.id, user_id: reporter.id)
    expect(action.staff_took_action).to eq(false)
    expect(reviewable.reviewable_scores.count).to eq(1)
    expect(IsbfModeration::Audit.details(reviewable.reviewable_scores.first)["reason"]).to include(
      "serious and immediate",
    )
  end

  it "supports replies and staff authored posts without enabling ordinary staff flagging" do
    SiteSetting.allow_flagging_staff = false
    reply = isbf_fabricate(:post, topic: forum_post.topic, user: staff)
    report(reply)

    expect(response).to have_http_status(:ok)
    expect(reply.reload).to be_hidden
    expect(forum_post.topic.reload).to be_visible
    expect(reporter.guardian.post_can_act?(isbf_fabricate(:post, user: staff), :spam)).to eq(false)
  end

  it "allows staff to submit through the same policy" do
    sign_in(staff)
    report
    expect(response).to have_http_status(:ok)
    expect(forum_post.reviewable_flag).to be_pending
    expect(PostAction.flags.find_by(post_id: forum_post.id).staff_took_action).to eq(false)
  end

  it "requires login and rejects the submission switch being off" do
    sign_out
    reset!
    report
    expect(response).not_to have_http_status(:ok)
    sign_in(reporter)
    SiteSetting.isbf_severe_reports_enabled = false
    report
    expect(response).not_to have_http_status(:ok)
    expect(forum_post.reload).not_to be_hidden
    expect(forum_post.reviewable_flag).to be_nil
  end

  it "rejects silenced, suspended and anonymous pseudoaccounts" do
    reporter.update!(silenced_till: 1.day.from_now)
    report
    expect(response).not_to have_http_status(:ok)
    reporter.update!(silenced_till: nil, suspended_till: 1.day.from_now)
    report
    expect(response).not_to have_http_status(:ok)
    expect(forum_post.reload).not_to be_hidden

    allow(reporter).to receive(:anonymous?).and_return(true)
    expect(IsbfModeration::Policy.normal_user?(reporter)).to eq(false)
  end

  it "rejects inaccessible categories, private messages, system posts and deleted posts" do
    private_category = isbf_fabricate(:private_category, group: isbf_fabricate(:group))
    inaccessible = isbf_fabricate(:post, topic: isbf_fabricate(:topic, category: private_category))
    private_post = isbf_fabricate(:private_message_post, user: author)
    system_post =
      isbf_fabricate(:post, topic: forum_post.topic, post_type: Post.types[:small_action])
    deleted = isbf_fabricate(:post)
    deleted.trash!
    [inaccessible, private_post, system_post, deleted].each do |target|
      report(target)
      expect(response).not_to have_http_status(:ok)
      expect(target.reload).not_to be_hidden
    end
  end

  it "accepts membership in a restricted category without granting access to other categories" do
    group = isbf_fabricate(:group)
    category = isbf_fabricate(:private_category, group: group)
    target = isbf_fabricate(:post, topic: isbf_fabricate(:topic, category: category))
    group.users << reporter
    sign_in(reporter.reload)
    report(target)
    expect(response).to have_http_status(:ok)
  end

  it "validates the reason length, explicit boolean confirmation and integer ID" do
    [nil, true, "short", " " * 15, "\u3000" * 10, "x" * 2001].each do |reason|
      report(reason: reason)
      expect(response).to have_http_status(:bad_request), "reason: #{reason.inspect}"
    end
    [nil, false, "true", 1].each do |confirmed|
      report(confirmed: confirmed)
      expect(response).to have_http_status(:bad_request)
    end
    [0, -1, "1", 1.1, true].each do |post_id|
      report(post_id: post_id)
      expect(response).to have_http_status(:bad_request)
    end
    report(user_id: staff.id)
    expect(response).to have_http_status(:bad_request)
    expect(forum_post.reload).not_to be_hidden
  end

  it "makes duplicate submissions idempotent without changing the reason or consuming a new flag" do
    report
    original = response.parsed_body
    reviewable = forum_post.reviewable_flag
    context = reviewable.reviewable_scores.first.context
    latest = reviewable.payload[IsbfModeration::Hold::LATEST]
    report(reason: "A duplicate request with a different explanation.")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(original)
    expect(reviewable.reviewable_scores.count).to eq(1)
    expect(reviewable.reviewable_scores.first.reload.context).to eq(context)
    expect(reviewable.reload.payload[IsbfModeration::Hold::LATEST]).to eq(latest)
  end

  it "keeps native per-day and per-post rate limiting" do
    RateLimiter.enable
    SiteSetting.max_flags_per_day = 1
    report
    expect(response).to have_http_status(:ok)
    second = isbf_fabricate(:post, user: author)
    report(second)
    expect(response).to have_http_status(:too_many_requests)
    expect(second.reload).not_to be_hidden
    expect(second.reviewable_flag).to be_nil
  end
end
