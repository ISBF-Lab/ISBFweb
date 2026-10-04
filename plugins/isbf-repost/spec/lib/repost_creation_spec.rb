# frozen_string_literal: true

RSpec.describe IsbfRepost do
  fab!(:user)
  fab!(:source_topic, :topic)

  before { SiteSetting.isbf_repost_enabled = true }

  it "records each successfully published repost topic" do
    post =
      PostCreator.create!(
        user,
        raw:
          "My note\n\n[quote=\"#{source_topic.user.username}, post:1, topic:#{source_topic.id}\"]source[/quote]",
        title: "My quote repost from a campus source",
        isbf_repost_source_topic_id: source_topic.id,
      )

    expect(
      IsbfRepost::Repost.exists?(
        repost_topic_id: post.topic_id,
        source_topic_id: source_topic.id,
        user_id: user.id,
      ),
    ).to eq(true)
  end

  it "allows the same user to repost the source more than once" do
    2.times do |index|
      PostCreator.create!(
        user,
        raw: "Quote #{index}",
        title: "Campus quote repost number #{index}",
        isbf_repost_source_topic_id: source_topic.id,
      )
    end

    expect(
      IsbfRepost::Repost.where(source_topic_id: source_topic.id, user_id: user.id).count,
    ).to eq(2)
  end
end
