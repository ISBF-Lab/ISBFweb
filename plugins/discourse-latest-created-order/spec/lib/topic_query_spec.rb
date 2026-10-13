# frozen_string_literal: true

RSpec.describe TopicQuery do
  fab!(:user)
  fab!(:older) do
    Fabricate(:topic, created_at: 2.days.ago, bumped_at: 1.minute.ago, like_count: 10)
  end
  fab!(:newer) { Fabricate(:topic, created_at: 1.day.ago, bumped_at: 1.day.ago, like_count: 1) }

  before { SiteSetting.latest_topics_order_by_created = true }

  it "keeps native activity order while disabled" do
    SiteSetting.latest_topics_order_by_created = false

    expect(TopicQuery.new(user).list_latest.topics.map(&:id)).to eq([older.id, newer.id])
  end

  it "orders default Latest by creation date for visitors and members" do
    [nil, user].each do |viewer|
      expect(TopicQuery.new(viewer).list_latest.topics.map(&:id)).to eq([newer.id, older.id])
    end
  end

  it "uses descending IDs when creation dates match" do
    newer.update!(created_at: older.created_at)

    expect(TopicQuery.new(user).list_latest.topics.map(&:id)).to eq([newer.id, older.id])
  end

  it "keeps creation order after an actual reply while still updating activity" do
    Fabricate(:post, topic: older)
    admin = Fabricate(:admin)

    PostCreator.create!(admin, topic_id: older.id, raw: "A new reply to the older topic.")

    expect(older.reload.bumped_at).to be > newer.bumped_at
    expect(TopicQuery.new(user).list_latest.topics.map(&:id)).to eq([newer.id, older.id])
  end

  it "overrides a category's default sort and direction" do
    category = Fabricate(:category, sort_order: "likes", sort_ascending: true)
    older.update!(category: category)
    newer.update!(category: category)

    expect(TopicQuery.new(user, category: category.id).list_latest.topics.map(&:id)).to eq(
      [newer.id, older.id],
    )
  end

  it "keeps globally pinned topics above newer unpinned topics" do
    pinned = Fabricate(:topic, created_at: 3.days.ago, pinned_at: 1.hour.ago, pinned_globally: true)
    older.update!(pinned_at: 2.hours.ago)

    expect(TopicQuery.new(user).list_latest.topics.map(&:id)).to eq([pinned.id, newer.id, older.id])
  end

  it "keeps category pins above newer topics in that category" do
    category = Fabricate(:category)
    older.update!(category: category, pinned_at: 1.hour.ago)
    newer.update!(category: category)

    expect(TopicQuery.new(user, category: category.id).list_latest.topics.map(&:id)).to eq(
      [older.id, newer.id],
    )
  end

  it "returns cleared pins to their creation position" do
    older.update!(pinned_at: 2.hours.ago, pinned_globally: true)
    Fabricate(:topic_user, topic: older, user: user, cleared_pinned_at: 1.hour.ago)

    expect(TopicQuery.new(user).list_latest.topics.map(&:id)).to eq([newer.id, older.id])
  end

  it "paginates pinned and unpinned topics without duplicates" do
    pinned = Fabricate(:topic, created_at: 3.days.ago, pinned_at: 1.hour.ago, pinned_globally: true)
    oldest = Fabricate(:topic, created_at: 4.days.ago, bumped_at: 1.second.ago)

    first_page = TopicQuery.new(user, per_page: 2).list_latest.topics.map(&:id)
    second_page = TopicQuery.new(user, per_page: 2, page: 1).list_latest.topics.map(&:id)

    expect(first_page + second_page).to eq([pinned.id, newer.id, older.id, oldest.id])
  end

  it "preserves explicitly requested sort orders and directions" do
    [
      { order: "activity", ascending: "false" },
      { order: "likes", ascending: "false" },
      { order: "created", ascending: "true" },
    ].each do |options|
      expect(TopicQuery.new(user, options).list_latest.topics.map(&:id)).to eq([older.id, newer.id])
    end
  end

  it "treats an explicit default order as creation order" do
    expect(TopicQuery.new(user, order: "default").list_latest.topics.map(&:id)).to eq(
      [newer.id, older.id],
    )
  end

  it "preserves Hot and Top score ordering" do
    TopicHotScore.create!(topic: older, score: 10)
    TopicHotScore.create!(topic: newer, score: 1)
    TopTopic.create!(topic: older, all_score: 10)
    TopTopic.create!(topic: newer, all_score: 1)

    expect(TopicQuery.new(user).list_hot.topics.map(&:id)).to eq([older.id, newer.id])
    expect(TopicQuery.new(user).list_top_for(:all).topics.map(&:id)).to eq([older.id, newer.id])
  end

  it "keeps the same New, Unread, and Unseen lists as the disabled plugin" do
    older.update!(highest_post_number: 2)
    Fabricate(
      :topic_user,
      topic: older,
      user: user,
      last_read_post_number: 1,
      notification_level: 2,
    )

    %i[list_new list_unread list_unseen].each do |list|
      SiteSetting.latest_topics_order_by_created = false
      original_ids = TopicQuery.new(user).public_send(list).topics.map(&:id)
      SiteSetting.latest_topics_order_by_created = true

      expect(TopicQuery.new(user).public_send(list).topics.map(&:id)).to eq(original_ids)
    end
  end

  it "keeps private messages in native activity order" do
    older_message =
      Fabricate(
        :private_message_topic,
        recipient: user,
        created_at: 2.days.ago,
        bumped_at: 1.minute.ago,
      )
    newer_message =
      Fabricate(
        :private_message_topic,
        recipient: user,
        created_at: 1.day.ago,
        bumped_at: 1.day.ago,
      )
    [older_message, newer_message].each do |message|
      Fabricate(:post, topic: message, user: message.user)
    end

    expect(TopicQuery.new(user).list_private_messages(user).topics.map(&:id)).to eq(
      [older_message.id, newer_message.id],
    )
  end
end
