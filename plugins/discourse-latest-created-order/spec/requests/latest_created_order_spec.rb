# frozen_string_literal: true

RSpec.describe "Latest creation order" do
  fab!(:category)
  fab!(:tag)
  fab!(:older) do
    Fabricate(
      :topic,
      category: category,
      tags: [tag],
      created_at: 2.days.ago,
      bumped_at: 1.minute.ago,
    )
  end
  fab!(:newer) do
    Fabricate(:topic, category: category, tags: [tag], created_at: 1.day.ago, bumped_at: 1.day.ago)
  end

  before do
    SiteSetting.latest_topics_order_by_created = true
    SiteSetting.tagging_enabled = true
  end

  it "returns creation order from global, category, tag, and category/tag Latest endpoints" do
    [
      "/latest.json",
      "/c/#{category.slug}/#{category.id}/l/latest.json",
      "/tag/#{tag.name}/l/latest.json",
      "/tags/c/#{category.slug}/#{category.id}/#{tag.name}/l/latest.json",
    ].each do |path|
      get path

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("topic_list", "topics").map { |topic| topic["id"] }).to eq(
        [newer.id, older.id],
      )
    end
  end

  it "provides effective pin timestamps for live updates in the list's scope" do
    older.update!(pinned_at: 1.hour.ago)

    get "/latest.json"
    expect(
      response.parsed_body.dig("topic_list", "topics").last["latest_created_order_pinned_at"],
    ).to be_nil

    get "/c/#{category.slug}/#{category.id}/l/latest.json"
    expect(
      response.parsed_body.dig("topic_list", "topics").first["latest_created_order_pinned_at"],
    ).to eq(older.pinned_at.as_json)
  end

  it "omits live pin metadata when the plugin is disabled" do
    SiteSetting.latest_topics_order_by_created = false

    get "/latest.json"

    expect(response.parsed_body.dig("topic_list", "topics").first).not_to have_key(
      "latest_created_order_pinned_at",
    )
  end

  it "returns cleared pins without a priority timestamp for members" do
    user = Fabricate(:user)
    older.update!(pinned_at: 1.hour.ago, pinned_globally: true)
    Fabricate(:topic_user, topic: older, user: user, cleared_pinned_at: older.pinned_at)
    sign_in(user)

    get "/latest.json"

    topics = response.parsed_body.dig("topic_list", "topics")
    expect(topics.map { |topic| topic["id"] }).to eq([newer.id, older.id])
    expect(topics.last["latest_created_order_pinned_at"]).to be_nil
  end
end
