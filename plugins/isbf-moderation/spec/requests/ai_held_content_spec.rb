# frozen_string_literal: true

require_relative "../support/fixtures"

RSpec.describe "AI-held content", type: :request do
  fab!(:author) { isbf_fabricate(:user) }
  fab!(:reader) { isbf_fabricate(:user) }
  fab!(:moderator) { isbf_fabricate(:moderator) }
  fab!(:category) { isbf_fabricate(:category) }
  fab!(:post) do
    isbf_fabricate(:post, user: author, topic: isbf_fabricate(:topic, category: category))
  end
  fab!(:model) { Fabricate(:fake_model, vision_enabled: true) }

  before do
    SiteSetting.discourse_ai_enabled = true
    SiteSetting.isbf_ai_moderation_model = model.id.to_s
    SiteSetting.isbf_ai_moderation_enabled = true
    DiscourseAi::Completions::Llm.with_prepared_responses(
      [{ needs_review: true, rule: "fraud", reason: "需要核实的诈骗内容", evidence: post.raw }],
    ) { IsbfModeration::AiScanner.scan(post.id) }
  end

  it "blocks raw, cooked, expansion and history access for guests, readers and the author" do
    [reader, author, nil].each do |viewer|
      if viewer
        sign_in(viewer)
      else
        sign_out
        reset!
      end
      [
        "/posts/#{post.id}.json",
        "/posts/#{post.id}/cooked.json",
        "/posts/#{post.id}/expand.json",
        "/posts/#{post.id}/revisions/latest.json",
        "/raw/#{post.topic_id}/#{post.post_number}",
      ].each do |path|
        get path
        expect(response).not_to have_http_status(:ok)
        expect(response.body).not_to include(post.raw)
      end
    end
  end

  it "keeps bodies out of excerpts, search and activity while allowing authorized review" do
    sign_in(reader)
    get "/t/#{post.topic_id}/excerpts.json", params: { post_ids: [post.id] }
    expect(response.body).not_to include(post.raw)
    get "/user_actions.json", params: { username: author.username, filter: "4,5" }
    expect(response.body).not_to include(post.raw)
    get "/search.json", params: { q: post.raw }
    expect(response.parsed_body.fetch("posts").map { |result| result["id"] }).not_to include(
      post.id,
    )

    sign_in(moderator)
    get "/posts/#{post.id}.json"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["raw"]).to eq(post.raw) if response.parsed_body.key?("raw")
    reviewable = post.reload.reviewable_flag
    expect(
      reviewable.perform(moderator, :disagree_and_restore, version: reviewable.version),
    ).to be_success
    sign_in(author)
    get "/posts/#{post.id}.json"
    expect(response).to have_http_status(:ok)
  end
end
