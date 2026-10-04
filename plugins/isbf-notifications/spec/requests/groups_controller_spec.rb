# frozen_string_literal: true

RSpec.describe IsbfNotifications::GroupsController do
  fab!(:recipient, :user)
  fab!(:other_recipient, :user)
  fab!(:actor, :user)

  before do
    SiteSetting.isbf_notifications_enabled = true
    freeze_time
    sign_in(recipient)
  end

  def topic_post(user: recipient)
    Fabricate(:post, topic: Fabricate(:topic, user: user), user: user)
  end

  def notice(type, post: nil, user: recipient, from: actor, at: Time.zone.now, read: false)
    Fabricate(
      :notification,
      user: user,
      notification_type: Notification.types.fetch(type),
      topic: post&.topic,
      post_number: post&.post_number,
      created_at: at,
      read: read,
      data: {
        username: from.username,
        display_username: from.username,
        topic_title: post&.topic&.title,
        message: "notifications.custom",
      }.to_json,
    )
  end

  def like(post, user, at:)
    PostAction.create!(
      post_id: post.id,
      user_id: user.id,
      post_action_type_id: PostActionType::LIKE_POST_ACTION_ID,
      created_at: at,
      updated_at: at,
    )
  end

  def groups(**params)
    get "/isbf/notifications/groups.json", params: params
    response.parsed_body
  end

  def details(post, action, **params)
    get "/isbf/notifications/groups/#{post.topic_id}/actions/#{action}.json", params: params
    response.parsed_body
  end

  it "requires a signed-in user and an enabled plugin" do
    sign_out
    reset!
    groups
    expect(response).not_to have_http_status(:ok)

    sign_in(recipient)
    SiteSetting.isbf_notifications_enabled = false
    groups
    expect(response).not_to have_http_status(:ok)
  end

  it "includes replies, individual mentions, group mentions and reactions in the mentions tab" do
    post = topic_post
    types = %i[mentioned group_mentioned replied reaction liked]
    notices = types.map { |type| notice(type, post: post) }

    all = groups(tab: "all")["groups"].first["actions"]
    expect(all.map { |action| action["key"] }).to contain_exactly(
      "mentioned",
      "replied",
      "reaction",
      "liked",
    )

    mentions = groups(tab: "mentions")["groups"].first["actions"]
    expect(mentions.map { |action| action["key"] }).to contain_exactly(
      "mentioned",
      "replied",
      "reaction",
    )
    mention_action = mentions.find { |action| action["key"] == "mentioned" }
    expect(mention_action["count"]).to eq(2)
    expect(
      mentions.flat_map { |action| action.dig("latest", "notification", "id") },
    ).not_to include(notices.last.id)
  end

  it "groups native actions by topic with their latest notification and unread state" do
    post = topic_post
    notice(:replied, post: post, at: 3.minutes.ago, read: true)
    latest_reply = notice(:replied, post: post, at: 1.minute.ago)
    mention = notice(:mentioned, post: post, at: 2.minutes.ago, read: true)

    body = groups
    expect(response).to have_http_status(:ok)
    expect(body["groups"].length).to eq(1)
    group = body["groups"].first
    expect(group["topic"]["id"]).to eq(post.topic_id)
    expect(group["unread"]).to eq(true)
    expect(group["actions"].map { |action| action["key"] }).to eq(%w[replied mentioned])
    expect(group["actions"].first).to include("count" => 2, "unread" => true)
    expect(group["actions"].first.dig("latest", "notification", "id")).to eq(latest_reply.id)
    expect(group["actions"].last.dig("latest", "notification", "id")).to eq(mention.id)
  end

  it "expands one consolidated like notification into ten unique actors, newest first" do
    post = topic_post
    likers = Fabricate.times(10, :user)
    likers.each_with_index { |liker, index| like(post, liker, at: (20 - index).minutes.ago) }
    native = notice(:liked_consolidated, post: post, from: likers.last, at: 1.minute.ago)

    action = groups["groups"].first["actions"].first
    expect(action).to include("key" => "liked", "count" => 10)
    expect(action.dig("latest", "actor", "id")).to eq(likers.last.id)
    expect(action.dig("latest", "notification", "id")).to eq(native.id)

    first = details(post, "liked", limit: 3)
    expect(response).to have_http_status(:ok)
    expect(first["entries"].map { |entry| entry.dig("actor", "id") }).to eq(
      likers.last(3).reverse.map(&:id),
    )
    expect(first["entries"].map { |entry| entry.dig("notification", "id") }.uniq).to eq([native.id])
    second = details(post, "liked", limit: 3, cursor: first["next_cursor"])
    expect(second["entries"].map { |entry| entry.dig("actor", "id") }).to eq(
      likers.reverse[3, 3].map(&:id),
    )
    expect(
      second["entries"].map { |entry| entry["key"] } &
        first["entries"].map { |entry| entry["key"] },
    ).to be_empty
  end

  it "counts the same liker once across posts in one topic and uses their latest action" do
    first_post = topic_post
    second_post = Fabricate(:post, topic: first_post.topic, user: recipient)
    like(first_post, actor, at: 5.minutes.ago)
    like(second_post, actor, at: 2.minutes.ago)
    notice(:liked, post: first_post, at: 4.minutes.ago)
    latest = notice(:liked, post: second_post, at: 1.minute.ago)

    action = groups["groups"].first["actions"].first
    expect(action["count"]).to eq(1)
    entries = details(first_post, "liked")["entries"]
    expect(entries.length).to eq(1)
    expect(entries.first.dig("actor", "id")).to eq(actor.id)
    expect(entries.first.dig("notification", "id")).to eq(latest.id)
    expect(entries.first.dig("notification", "post_number")).to eq(second_post.post_number)
  end

  it "deduplicates reaction actors across posts while preserving the latest reaction" do
    SiteSetting.discourse_reactions_enabled = true
    first_post = topic_post
    second_post = Fabricate(:post, topic: first_post.topic, user: recipient)
    second_actor = Fabricate(:user)
    [first_post, second_post].each_with_index do |post, index|
      reaction =
        DiscourseReactions::Reaction.create!(post: post, reaction_value: "smile", reaction_type: 0)
      DiscourseReactions::ReactionUser.create!(
        post: post,
        user: actor,
        reaction: reaction,
        created_at: (5 - index).minutes.ago,
      )
      notice(:reaction, post: post, at: (3 - index).minutes.ago)
    end
    reaction = DiscourseReactions::Reaction.find_by(post_id: first_post.id)
    DiscourseReactions::ReactionUser.create!(
      post: first_post,
      user: second_actor,
      reaction: reaction,
      created_at: 6.minutes.ago,
    )
    action = groups(tab: "mentions")["groups"].first["actions"].first
    expect(action["count"]).to eq(2)
    entries = details(first_post, "reaction")["entries"]
    expect(entries.map { |entry| entry.dig("actor", "id") }).to contain_exactly(
      actor.id,
      second_actor.id,
    )
    expect(entries.first.dig("notification", "post_number")).to eq(second_post.post_number)
  end

  it "retains repeated replies and mentions from the same person in action details" do
    post = topic_post
    replies = [
      notice(:replied, post: post, at: 4.minutes.ago),
      notice(:replied, post: post, at: 2.minutes.ago),
    ]
    mentions = [
      notice(:mentioned, post: post, at: 3.minutes.ago),
      notice(:group_mentioned, post: post, at: 1.minute.ago),
    ]

    expect(
      details(post, "replied")["entries"].map { |entry| entry.dig("notification", "id") },
    ).to eq(replies.reverse.map(&:id))
    expect(
      details(post, "mentioned")["entries"].map { |entry| entry.dig("notification", "id") },
    ).to eq(mentions.reverse.map(&:id))
  end

  it "paginates whole topic groups even when their notifications interleave" do
    first_post = topic_post
    second_post = topic_post
    third_post = topic_post
    notice(:replied, post: first_post, at: 1.minute.ago)
    notice(:mentioned, post: second_post, at: 2.minutes.ago)
    notice(:replied, post: third_post, at: 3.minutes.ago)
    notice(:replied, post: first_post, at: 4.minutes.ago)

    first = groups(limit: 1)
    expect(first["groups"].map { |group| group.dig("topic", "id") }).to eq([first_post.topic_id])
    expect(first["groups"].first["actions"].first["count"]).to eq(2)
    second = groups(limit: 1, cursor: first["next_cursor"])
    expect(second["groups"].map { |group| group.dig("topic", "id") }).to eq([second_post.topic_id])
    third = groups(limit: 1, cursor: second["next_cursor"])
    expect(third["groups"].map { |group| group.dig("topic", "id") }).to eq([third_post.topic_id])
    expect(third["next_cursor"]).to be_nil
  end

  it "does not reveal private topics or deleted and whisper posts to a regular recipient" do
    private_post = topic_post(user: actor)
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    private_post.topic.update!(category: private_category)
    deleted_post = topic_post(user: actor)
    deleted_post.update!(deleted_at: 1.minute.ago, deleted_by_id: actor.id)
    whisper_post = topic_post(user: actor)
    whisper_post.update!(post_type: Post.types[:whisper])
    [private_post, deleted_post, whisper_post].each { |post| notice(:mentioned, post: post) }

    expect(groups["groups"]).to be_empty
    [private_post, deleted_post, whisper_post].each do |post|
      details(post, "mentioned")
      expect(response).to have_http_status(:not_found)
    end
  end

  it "preserves non-topic native notifications as separate standalone entries" do
    first = notice(:custom, at: 2.minutes.ago)
    second = notice(:custom, at: 1.minute.ago)

    entries = groups["groups"]
    expect(entries.map { |entry| entry["kind"] }).to eq(%w[standalone standalone])
    expect(entries.map { |entry| entry.dig("latest", "notification", "id") }).to eq(
      [second.id, first.id],
    )
  end

  it "ignores a requested username and only returns the current user's notifications" do
    own = notice(:mentioned, post: topic_post)
    notice(:mentioned, post: topic_post(user: other_recipient), user: other_recipient)

    body = groups(username: other_recipient.username)
    expect(body["groups"].length).to eq(1)
    expect(body["groups"].first["actions"].first.dig("latest", "notification", "id")).to eq(own.id)
  end

  it "rejects tampered cursors and cursors from another user, tab or endpoint" do
    first_post = topic_post
    second_post = topic_post
    notice(:replied, post: first_post, at: 1.minute.ago)
    notice(:replied, post: first_post, at: 2.minutes.ago)
    notice(:mentioned, post: second_post, at: 3.minutes.ago)
    cursor = groups(limit: 1)["next_cursor"]
    expect(cursor).to be_present

    groups(cursor: "#{cursor}tampered")
    expect(response).to have_http_status(:bad_request)
    groups(cursor: cursor, tab: "mentions")
    expect(response).to have_http_status(:bad_request)
    details(first_post, "replied", cursor: cursor)
    expect(response).to have_http_status(:bad_request)
    sign_in(other_recipient)
    groups(cursor: cursor)
    expect(response).to have_http_status(:bad_request)
  end

  it "does not mark notifications read or change native counters when reading either endpoint" do
    post = topic_post
    native = notice(:mentioned, post: post)
    notification_state = recipient.notifications.order(:id).pluck(:id, :read, :updated_at)
    unread_counts = recipient.notifications.where(read: false).group(:notification_type).count
    seen_notification_id = recipient.reload.seen_notification_id

    groups
    expect(response).to have_http_status(:ok)
    details(post, "mentioned")
    expect(response).to have_http_status(:ok)

    expect(native.reload.read).to eq(false)
    expect(recipient.notifications.order(:id).pluck(:id, :read, :updated_at)).to eq(
      notification_state,
    )
    expect(recipient.notifications.where(read: false).group(:notification_type).count).to eq(
      unread_counts,
    )
    expect(recipient.reload.seen_notification_id).to eq(seen_notification_id)
  end
end
