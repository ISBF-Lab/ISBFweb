# frozen_string_literal: true

RSpec.describe PostsController do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:category)
  fab!(:admin)
  fab!(:moderator)

  before do
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.anonymous_posting_allowed_groups = "1|2|10"
    SiteSetting.isbf_anonymous_pool_size = 2
    SiteSetting.isbf_anonymous_pool_enabled = true
    account = IsbfAnonymous::PoolAccount.for_slot!(0)
    [user, other_user].each do |master|
      IsbfAnonymous::PoolAssignment.create!(
        master_user: master,
        pool_account: account,
        started_at: Time.current,
        expires_at: 7.days.from_now,
      )
    end
  end

  def publish_anonymously(
    author,
    topic_id: nil,
    title: "Anonymous campus discussion",
    raw: "A sufficiently long anonymous campus discussion."
  )
    sign_in(author)
    params = {
      raw: raw,
      isbf_anonymous: "true",
      draft_key: topic_id ? "topic_#{topic_id}" : Draft::NEW_TOPIC,
    }
    params.merge!(topic_id ? { topic_id: topic_id } : { title: title, category: category.id })
    post "/posts.json", params: params
    Post.order(:id).last
  end

  describe "#create" do
    it "enforces consecutive reply limits using the real author rather than the shared account" do
      SiteSetting.max_consecutive_replies = 2
      topic = Fabricate(:topic, category: category)
      Fabricate(:post, topic: topic)
      publish_anonymously(user, topic_id: topic.id)
      publish_anonymously(
        user,
        topic_id: topic.id,
        raw: "A second sufficiently long anonymous reply in sequence.",
      )
      expect(response.status).to eq(200)

      publish_anonymously(
        user,
        topic_id: topic.id,
        raw: "A third sufficiently long anonymous reply in sequence.",
      )
      expect(response.status).to eq(422)

      publish_anonymously(other_user, topic_id: topic.id)
      expect(response.status).to eq(200)
    end

    it "silences fast typers individually without linking a staff log to their anonymous reviewable" do
      user.change_trust_level!(TrustLevel[0])
      SiteSetting.fast_typing_threshold = "high"
      SiteSetting.auto_silence_fast_typers_on_first_post = true
      SiteSetting.notify_mods_when_user_silenced = true

      publish_anonymously(user)

      expect(response.status).to eq(200), response.body
      reviewable = ReviewableQueuedPost.order(:id).last
      history =
        UserHistory.where(target_user_id: user.id, action: UserHistory.actions[:silence_user]).last
      expect(user.reload.silenced?).to eq(true)
      expect(reviewable.target_created_by.silenced?).to eq(false)
      expect(history.reviewable_id).to be_nil
    end

    it "memoizes repeated API requests after selecting an anonymous author" do
      params = {
        title: "An anonymous API campus discussion",
        raw: "A sufficiently long anonymous campus discussion from the API.",
        category: category.id,
        isbf_anonymous: "true",
      }
      headers = { HTTP_API_USERNAME: user.username, HTTP_API_KEY: Fabricate(:api_key).key }
      post "/posts.json", params: params, headers: headers
      expect(response.status).to eq(200), response.body
      original = response.parsed_body

      expect do post "/posts.json", params: params, headers: headers end.not_to change {
        Post.count
      }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body).to eq(original)
    end

    it "persists the pool author and private owner without exposing ownership in public responses" do
      sign_in(user)
      post "/posts.json",
           params: {
             :title => "Anonymous campus discussion",
             :raw => "A sufficiently long anonymous campus discussion.",
             :category => category.id,
             :isbf_anonymous => "true",
             IsbfAnonymous::OWNER_FIELD => other_user.id,
             :acting_user => other_user.id,
             :custom_fields => {
               IsbfAnonymous::OWNER_FIELD => other_user.id,
             },
           }
      published = Post.order(:id).last

      expect(response.status).to eq(200)
      expect(published.user_id).to eq(IsbfAnonymous::PoolAccount.first.user_id)
      expect(published.topic.user_id).to eq(published.user_id)
      expect(published.custom_fields[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
      expect(response.body).not_to include(IsbfAnonymous::OWNER_FIELD, user.username)
      expect(
        TopicCustomField.where(topic_id: published.topic_id, name: IsbfAnonymous::OWNER_FIELD),
      ).not_to exist
      expect(TopicUser.where(user_id: published.user_id, topic_id: published.topic_id)).not_to exist
      expect(user.guardian.can_edit?(published)).to eq(false)

      get "/t/#{published.topic_id}.json"
      expect(response.status).to eq(200)
      expect(response.body).not_to include(IsbfAnonymous::OWNER_FIELD, user.username)
    end

    it "lists each real user's posts separately when the pool author is shared" do
      own_post = publish_anonymously(user)
      other_post = publish_anonymously(other_user, title: "Another anonymous campus discussion")
      expect(own_post.user_id).to eq(other_post.user_id)

      sign_in(user)
      get "/isbf-anonymous/api/posts.json"
      expect(response.parsed_body["posts"].map { |row| row["id"] }).to eq([own_post.id])
    end

    it "applies slow mode to the owner across public and anonymous replies" do
      topic = Fabricate(:topic, category: category, slow_mode_seconds: 3600)
      publish_anonymously(user, topic_id: topic.id)
      expect(response.status).to eq(200)

      publish_anonymously(
        user,
        topic_id: topic.id,
        raw: "Another sufficiently long reply during slow mode.",
      )
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(I18n.t(:slow_mode_enabled))

      publish_anonymously(other_user, topic_id: topic.id)
      expect(response.status).to eq(200)

      sign_in(user)
      post "/posts.json",
           params: {
             topic_id: topic.id,
             raw: "A public reply during the same slow mode interval.",
           }
      expect(response.status).to eq(422)
    end

    it "enforces real user trust restrictions and blocks inactive accounts" do
      user.change_trust_level!(TrustLevel[0])
      SiteSetting.newuser_max_links = 0
      publish_anonymously(user, raw: "A long reply linking to https://example.com/campus.")
      expect(response.status).to eq(422)

      SiteSetting.anonymous_posting_allowed_groups = "1|2"
      publish_anonymously(other_user)
      expect(response.status).to eq(403)
      SiteSetting.anonymous_posting_allowed_groups = "1|2|10"
      other_user.update!(active: false)
      publish_anonymously(other_user)
      expect(response.status).not_to eq(200)
    end

    it "clears the owner's draft and sends reply alerts without notifying another pool occupant" do
      Draft.set(user, Draft::NEW_TOPIC, 0, { reply: "Saved draft" }.to_json)
      published = publish_anonymously(user)
      expect(response.status).to eq(200), response.body
      expect(Draft.where(user_id: user.id, draft_key: Draft::NEW_TOPIC)).not_to exist
      expect(DraftSequence.current(user, Draft::NEW_TOPIC)).to eq(1)

      reply = publish_anonymously(other_user, topic_id: published.topic_id)
      PostAlerter.post_created(reply)
      expect(
        Notification.where(
          topic_id: published.topic_id,
          notification_type: Notification.types[:replied],
        ).pluck(:user_id),
      ).to include(user.id)
      expect(Notification.where(user_id: other_user.id, topic_id: published.topic_id)).not_to exist
    end

    it "marks anonymous review items only for administrators" do
      SiteSetting.approve_post_count = 1
      publish_anonymously(user)
      reviewable = ReviewableQueuedPost.order(:id).last

      sign_in(moderator)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["reviewable"]).not_to have_key(IsbfAnonymous::POST_FIELD)
      expect(response.body).not_to include(IsbfAnonymous::OWNER_FIELD, user.username)

      sign_in(admin)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("reviewable", IsbfAnonymous::POST_FIELD)).to eq(true)
      expect(response.body).not_to include(IsbfAnonymous::OWNER_FIELD, user.username)
    end

    it "marks ordinary review items as non-anonymous for administrators" do
      SiteSetting.approve_post_count = 1
      sign_in(user)
      post "/posts.json",
           params: {
             title: "A public campus discussion awaiting approval",
             raw: "A sufficiently long public campus discussion awaiting approval.",
             category: category.id,
           }
      expect(response.status).to eq(200), response.body
      reviewable = ReviewableQueuedPost.order(:id).last

      sign_in(admin)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("reviewable", IsbfAnonymous::POST_FIELD)).to eq(false)
    end

    it "queues according to the real author's history and preserves ownership through approval" do
      SiteSetting.approve_post_count = 1
      publish_anonymously(user)
      reviewable = ReviewableQueuedPost.order(:id).last
      expect(reviewable.payload[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
      expect(user.reload.user_stat.pending_posts_count).to eq(1)

      sign_in(moderator)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      expect(response.body).not_to include(IsbfAnonymous::OWNER_FIELD, user.username)
      expect(reviewable.actions_for(moderator.guardian).has?(:reject_and_suspend)).to eq(false)

      reviewable.perform(moderator, :approve_post)
      approved = reviewable.reload.target
      expect(approved.custom_fields[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
      expect(
        Notification.where(
          topic_id: approved.topic_id,
          notification_type: Notification.types[:post_approved],
        ).pluck(:user_id),
      ).to eq([user.id])

      publish_anonymously(
        other_user,
        title: "Another anonymous campus discussion",
        raw: "A different real author's first anonymous campus discussion.",
      )
      expect(response.status).to eq(200), response.body
      expect(ReviewableQueuedPost.pending.count).to eq(1)

      publish_anonymously(
        user,
        title: "A subsequent anonymous campus discussion",
        raw: "An established anonymous author's next campus discussion.",
      )
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body["id"]).to be_present
      expect(ReviewableQueuedPost.pending.count).to eq(1)
    end

    it "sends rejection feedback to the real author" do
      SiteSetting.approve_post_count = 1
      publish_anonymously(user)
      reviewable = ReviewableQueuedPost.order(:id).last

      reviewable.perform(moderator, :revise_and_reject_post, revise_reason: "Needs more detail")

      messages = Topic.where(archetype: Archetype.private_message)
      expect(messages.count).to eq(2)
      expect(messages.flat_map { |topic| topic.allowed_users.pluck(:id) }).to include(user.id)
      expect(messages.flat_map { |topic| topic.allowed_users.pluck(:id) }).not_to include(
        reviewable.target_created_by_id,
        other_user.id,
      )
    end

    it "keeps duplicate detection and rate limits separate for users sharing an author" do
      RateLimiter.enable
      SiteSetting.unique_posts_mins = 5
      SiteSetting.rate_limit_create_post = 60
      SiteSetting.rate_limit_create_topic = 1
      topic = Fabricate(:topic, category: category)
      publish_anonymously(user, topic_id: topic.id)
      expect(response.status).to eq(200)

      publish_anonymously(other_user, topic_id: topic.id)
      expect(response.status).to eq(200)

      publish_anonymously(
        user,
        topic_id: topic.id,
        raw: "A second long reply from the same person during the limit.",
      )
      expect(response.status).to eq(429)
    ensure
      RateLimiter.disable
    end

    it "shares daily topic limits with the owner's public posts" do
      RateLimiter.enable
      SiteSetting.rate_limit_create_post = 1
      SiteSetting.rate_limit_create_topic = 1
      SiteSetting.tl1_max_topics_in_first_day = 1
      user.update!(created_at: 1.hour.ago)
      publish_anonymously(user)
      expect(response.status).to eq(200)

      sign_in(user)
      post "/posts.json",
           params: {
             title: "A public topic after an anonymous topic",
             raw: "A sufficiently long public campus discussion.",
             category: category.id,
           }
      expect(response.status).to eq(429)

      other_user.update!(created_at: 1.hour.ago)
      publish_anonymously(other_user, title: "Another anonymous campus discussion")
      expect(response.status).to eq(200)
    ensure
      RateLimiter.disable
    end
  end

  describe "pool account protection" do
    it "closes profiles, activity, messages and sessions and removes pool accounts from user lists" do
      pooled = IsbfAnonymous::PoolAccount.first.user
      sign_in(user)
      get "/u/#{pooled.username}.json"
      expect(response.status).to eq(403)
      get "/user_actions.json", params: { username: pooled.username }
      expect(response.status).to eq(403)
      expect(user.guardian.can_send_private_message?(pooled)).to eq(false)
      expect(moderator.guardian.can_suspend?(pooled)).to eq(false)
      expect(admin.guardian.can_delete_user?(pooled)).to eq(false)
      expect(User.real).not_to include(pooled)
      expect(User.real(allowed_bot_user_ids: [Discourse::SYSTEM_USER_ID])).not_to include(pooled)
      expect(UserSearch.new(pooled.username).search).to be_empty
      DirectoryItem.add_missing_users(:all)
      expect(DirectoryItem.where(user_id: pooled.id)).not_to exist
      expect(AdminUserIndexQuery.new.find_users).not_to include(pooled)
      sign_in(pooled)
      expect(response.status).to eq(403)
    end
  end

  describe "administrator author lookup" do
    it "keeps anonymous pending posts out of a moderator's real-account lookup" do
      SiteSetting.approve_post_count = 1
      publish_anonymously(user)
      reviewable = ReviewableQueuedPost.order(:id).last

      sign_in(moderator)
      get "/posts/#{user.username}/pending.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["pending_posts"]).to be_empty
      get "/u/#{user.username}/card.json"
      expect(response.parsed_body.dig("user", "pending_posts_count")).to eq(0)

      sign_in(user)
      get "/posts/#{user.username}/pending.json"
      expect(response.parsed_body["pending_posts"].map { |row| row["id"] }).to eq([reviewable.id])

      sign_in(admin)
      get "/posts/#{user.username}/pending.json"
      expect(response.parsed_body["pending_posts"].map { |row| row["id"] }).to eq([reviewable.id])
    end

    it "returns the real author only to administrators" do
      published = publish_anonymously(user)
      other_post = publish_anonymously(other_user, title: "Another anonymous campus discussion")
      expect(other_post.user_id).to eq(published.user_id)
      lookup = "/isbf-anonymous/api/posts/#{published.id}/author.json"
      get lookup
      expect(response.status).to eq(403)
      sign_in(moderator)
      get lookup
      expect(response.status).to eq(403)
      sign_in(admin)
      get lookup
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("author", "id")).to eq(user.id)

      get "/isbf-anonymous/api/posts/#{other_post.id}/author.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("author", "id")).to eq(other_user.id)
    end

    it "returns 404 when a post is unmarked or its author is unavailable" do
      published = publish_anonymously(user)
      ordinary = Fabricate(:post)
      published.custom_fields[IsbfAnonymous::OWNER_FIELD] = User.maximum(:id) + 1
      published.save_custom_fields

      sign_in(admin)
      get "/isbf-anonymous/api/posts/#{ordinary.id}/author.json"
      expect(response.status).to eq(404)
      get "/isbf-anonymous/api/posts/#{published.id}/author.json"
      expect(response.status).to eq(404)
    end

    it "restricts queued author lookup to administrators" do
      SiteSetting.approve_post_count = 1
      publish_anonymously(user)
      reviewable = ReviewableQueuedPost.order(:id).last
      lookup = "/isbf-anonymous/api/queued-posts/#{reviewable.id}/author.json"

      get lookup
      expect(response.status).to eq(403)
      sign_in(moderator)
      get lookup
      expect(response.status).to eq(403)
      sign_in(admin)
      get lookup
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("author", "id")).to eq(user.id)
    end
  end
end
