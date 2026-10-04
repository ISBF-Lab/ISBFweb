# frozen_string_literal: true

require_relative "../support/fixtures"

RSpec.describe "ISBF held content privacy", type: :request do
  fab!(:reporter) { isbf_fabricate(:user) }
  fab!(:author) { isbf_fabricate(:user) }
  fab!(:reader) { isbf_fabricate(:user) }
  fab!(:moderator) { isbf_fabricate(:moderator) }
  fab!(:topic) { isbf_fabricate(:topic) }
  fab!(:held_post) do
    isbf_fabricate(
      :post,
      topic: topic,
      user: author,
      raw: "SECRET_HELD_BODY Original content must remain private.",
    )
  end

  before do
    SiteSetting.isbf_severe_reports_enabled = true
    IsbfModeration::SevereReport.new(reporter).submit(
      post_id: held_post.id,
      reason: "SECRET_REPORT_REASON This report requires a staff decision.",
      confirmed: true,
    )
  end

  it "denies direct raw, cooked, expansion and revision APIs for reader, author and guest" do
    [reader, author, nil].each do |viewer|
      if viewer
        sign_in(viewer)
      else
        sign_out
        reset!
      end
      [
        "/posts/#{held_post.id}.json",
        "/posts/#{held_post.id}/cooked.json",
        "/posts/#{held_post.id}/expand.json",
        "/posts/#{held_post.id}/revisions/latest.json",
        "/raw/#{topic.id}/#{held_post.post_number}",
      ].each do |path|
        get path
        expect(response).not_to have_http_status(:ok)
        expect(response.body).not_to include("SECRET_HELD_BODY")
      end
    end
  end

  it "redacts every serializer body even when a caller supplies the held model directly" do
    [reader, author, nil].each do |viewer|
      guardian = Guardian.new(viewer)
      basic = BasicPostSerializer.new(held_post.reload, scope: guardian, root: false).as_json
      full =
        PostSerializer.new(
          held_post,
          scope: guardian,
          root: false,
          add_raw: true,
          add_excerpt: true,
        ).as_json

      expect(basic[:cooked]).to eq(IsbfModeration::Hold.notice)
      expect(full[:cooked]).to eq(IsbfModeration::Hold.notice)
      expect(full[:raw]).to be_nil
      expect(full[:excerpt]).to eq(IsbfModeration::Hold.notice)
      expect(full[:can_see_hidden_post]).to eq(false)
      expect(full.to_json).not_to include("SECRET_HELD_BODY")
    end
  end

  it "removes held bodies from topic streams, excerpts, search and author activity" do
    sign_in(author)
    get "/t/#{topic.id}.json"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("SECRET_HELD_BODY")
    expect(response.body).to include(IsbfModeration::Hold.notice)

    get "/t/#{topic.id}/posts.json", params: { post_ids: [held_post.id] }
    expect(response.body).not_to include("SECRET_HELD_BODY")
    get "/t/#{topic.id}/excerpts.json", params: { post_ids: [held_post.id] }
    expect(response.body).not_to include("SECRET_HELD_BODY")
    get "/user_actions.json", params: { username: author.username, filter: "4,5" }
    expect(response.body).not_to include("SECRET_HELD_BODY")
    get "/search.json", params: { q: "SECRET_HELD_BODY" }
    expect(response.body).not_to include("SECRET_HELD_BODY Original")
  end

  it "retains native staff access and keeps protections enabled after the submission switch is off" do
    sign_in(moderator)
    get "/posts/#{held_post.id}.json"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("SECRET_HELD_BODY")
    SiteSetting.isbf_severe_reports_enabled = false
    sign_in(author)
    get "/posts/#{held_post.id}.json"
    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include("SECRET_HELD_BODY")
  end

  it "redacts activity falling back to a held OP when target_post_id and hidden are null" do
    first_post = isbf_fabricate(:post, user: author, raw: "SECRET_HELD_OP Original first post.")
    UserAction.create!(
      action_type: UserAction::NEW_TOPIC,
      user_id: author.id,
      acting_user_id: author.id,
      target_topic_id: first_post.topic_id,
      target_post_id: nil,
    )
    IsbfModeration::SevereReport.new(reporter).submit(
      post_id: first_post.id,
      reason: "This first post requires a serious staff review.",
      confirmed: true,
    )
    sign_in(author)

    get "/user_actions.json", params: { username: author.username, filter: "4" }
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("SECRET_HELD_OP")
    expect(response.body).to include(IsbfModeration::Hold.notice)
  end

  it "redacts nonstaff category moderators' reviewable bodies, reasons, conversations and notes" do
    SiteSetting.enable_category_group_moderation = true
    group = isbf_fabricate(:group)
    group.users << reader
    isbf_fabricate(:category_moderation_group, category: topic.category, group: group)
    held_post.reviewable_flag.reviewable_notes.create!(
      user: moderator,
      content: "SECRET_HELD_BODY Quoted in a moderation note.",
    )
    sign_in(reader.reload)
    reviewable = held_post.reviewable_flag
    get "/review/#{reviewable.id}.json"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("SECRET_HELD_BODY", "SECRET_REPORT_REASON")
    expect(response.body).to include(IsbfModeration::Hold.notice)
    get "/review.json", params: { additional_filters: "{}", category_id: topic.category_id }
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("SECRET_HELD_BODY", "SECRET_REPORT_REASON")
    expect(response.body).to include(IsbfModeration::Hold.notice)
    expect(reviewable.actions_for(reader.guardian).bundles).to be_empty
    expect {
      reviewable.perform(reader, :disagree_and_restore, version: reviewable.version)
    }.to raise_error(Discourse::InvalidAccess)
    expect(reviewable.reload).to be_pending
    expect(held_post.reload).to be_hidden
  end

  it "leaves ordinary category moderation permissions and hidden post behavior intact" do
    SiteSetting.enable_category_group_moderation = true
    group = isbf_fabricate(:group)
    group.users << reader
    isbf_fabricate(:category_moderation_group, category: topic.category, group: group)
    ordinary = isbf_fabricate(:post, topic: topic, user: author)
    result = PostActionCreator.inappropriate(moderator, ordinary)
    ordinary.hide!(PostActionType.types[:inappropriate])

    expect(author.guardian.can_see_hidden_post?(ordinary)).to eq(true)
    expect(reader.reload.guardian.can_review_post?(ordinary)).to eq(true)
    expect(result.reviewable.actions_for(reader.guardian).bundles).not_to be_empty
    expect(result.reviewable.perform(reader, :disagree_and_restore)).to be_success
    expect(ordinary.reload).not_to be_hidden
    expect(held_post.reload).to be_hidden
  end
end
