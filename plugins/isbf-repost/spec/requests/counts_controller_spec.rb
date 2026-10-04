# frozen_string_literal: true

RSpec.describe IsbfRepost::CountsController do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:source_topic, :topic)
  fab!(:repost_topic, :topic)

  before do
    SiteSetting.isbf_repost_enabled = true
    IsbfRepost::Repost.create!(
      repost_topic: repost_topic,
      source_topic: source_topic,
      user: other_user,
    )
  end

  it "counts visible repost topics" do
    sign_in(user)

    get "/isbf/reposts/counts.json", params: { topic_ids: [source_topic.id] }

    expect(response.status).to eq(200)
    expect(response.parsed_body["counts"][source_topic.id.to_s]).to eq(1)
  end

  it "stops counting a deleted repost and counts it again after recovery" do
    sign_in(user)
    repost_topic.trash!(other_user)

    get "/isbf/reposts/counts.json", params: { topic_ids: [source_topic.id] }
    expect(response.parsed_body["counts"][source_topic.id.to_s]).to eq(0)

    repost_topic.recover!
    get "/isbf/reposts/counts.json", params: { topic_ids: [source_topic.id] }
    expect(response.parsed_body["counts"][source_topic.id.to_s]).to eq(1)
  end

  it "does not reveal counts for a source the viewer cannot see" do
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    source_topic.update!(category: private_category)
    sign_in(user)

    get "/isbf/reposts/counts.json", params: { topic_ids: [source_topic.id] }

    expect(response.parsed_body["counts"][source_topic.id.to_s]).to eq(0)
  end
end
