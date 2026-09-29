# frozen_string_literal: true

RSpec.describe "ISBF anonymous posts" do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:category)

  before do
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.anonymous_posting_allowed_groups = "1|2|10"
  end

  def publish_anonymously(
    author,
    title: "An anonymous campus discussion",
    topic_id: nil
  )
    sign_in(author)
    params = {
      raw: "A sufficiently long anonymous discussion post.",
      isbf_anonymous: "true"
    }
    if topic_id
      params[:topic_id] = topic_id
    else
      params[:title] = title
      params[:category] = category.id
    end
    post "/posts.json", params: params
    Post.order(:id).last
  end

  it "publishes under a shadow identity and locks author edits" do
    published = publish_anonymously(user)

    expect(response.status).to eq(200)
    expect(published.user_id).not_to eq(user.id)
    expect(IsbfAnonymous.master_for(published.user_id)).to eq(user)
    expect(published.custom_fields[IsbfAnonymous::POST_FIELD]).to eq(true)
    expect(user.guardian.can_edit?(published)).to eq(false)
    expect(user.guardian.can_delete?(published.topic)).to eq(false)
    expect(published.user.guardian.can_edit?(published)).to eq(false)
    expect(published.user.guardian.can_delete?(published.topic)).to eq(false)
    expect(Fabricate(:admin).guardian.can_edit?(published)).to eq(true)
    expect(response.body).not_to include(user.username)
  end

  it "publishes an anonymous reply and lists only the owner's marked posts" do
    topic = Fabricate(:topic, category: category)
    published = publish_anonymously(user, topic_id: topic.id)
    publish_anonymously(
      other_user,
      title: "Another anonymous campus discussion"
    )
    sign_in(user)

    get "/isbf-anonymous/api/posts.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["posts"].map { |row| row["id"] }).to include(
      published.id
    )
    expect(response.parsed_body["posts"].size).to eq(1)
    expect(user.guardian.can_edit?(published)).to eq(false)
    expect(user.guardian.can_delete?(published)).to eq(false)
  end

  it "rejects restricted categories and private messages" do
    restricted = Fabricate(:private_category, group: Fabricate(:group))
    sign_in(user)
    post "/posts.json",
         params: {
           title: "Restricted anonymous topic",
           raw: "A sufficiently long anonymous discussion post.",
           category: restricted.id,
           isbf_anonymous: "true"
         }
    expect(response.status).to eq(403)

    post "/posts.json",
         params: {
           title: "Private anonymous message",
           raw: "A sufficiently long anonymous discussion post.",
           archetype: Archetype.private_message,
           target_recipients: other_user.username,
           isbf_anonymous: "true"
         }
    expect(response.status).to eq(403)
  end

  it "clears the original account's draft after publishing" do
    Draft.set(user, Draft::NEW_TOPIC, 0, { reply: "Saved draft" }.to_json)
    sign_in(user)
    post "/posts.json",
         params: {
           title: "A draft-backed anonymous topic",
           raw: "A sufficiently long anonymous discussion post.",
           category: category.id,
           draft_key: Draft::NEW_TOPIC,
           isbf_anonymous: "true"
         }

    expect(response.status).to eq(200)
    expect(
      Draft.where(user_id: user.id, draft_key: Draft::NEW_TOPIC)
    ).not_to exist
    expect(DraftSequence.current(user, Draft::NEW_TOPIC)).to eq(1)
  end

  it "notifies the original account when someone replies" do
    published = publish_anonymously(user)
    reply =
      PostCreator.create!(
        other_user,
        topic_id: published.topic_id,
        raw: "A sufficiently long reply to the anonymous author."
      )
    PostAlerter.post_created(reply)

    expect(
      Notification.where(
        user_id: user.id,
        topic_id: published.topic_id,
        post_number: reply.post_number,
        notification_type: Notification.types[:replied]
      )
    ).to exist
  end

  it "preserves the marker and original draft through queued post approval" do
    SiteSetting.approve_post_count = 1
    Draft.set(user, Draft::NEW_TOPIC, 0, { reply: "Queued draft" }.to_json)
    sign_in(user)
    post "/posts.json",
         params: {
           title: "An anonymous queued campus topic",
           raw: "A sufficiently long anonymous discussion post.",
           category: category.id,
           isbf_anonymous: "true"
         }

    reviewable = ReviewableQueuedPost.order(:id).last
    expect(reviewable.payload["isbf_anonymous"]).to eq("true")
    expect(IsbfAnonymous.master_for(reviewable.target_created_by_id)).to eq(
      user
    )

    reviewable.perform(Fabricate(:admin), :approve_post)
    approved_post = reviewable.reload.target
    expect(approved_post.custom_fields[IsbfAnonymous::POST_FIELD]).to eq(true)
    expect(
      Notification.where(
        user_id: user.id,
        topic_id: approved_post.topic_id,
        notification_type: Notification.types[:post_approved]
      )
    ).to exist
  end

  it "sends rejection feedback only to the original account" do
    SiteSetting.approve_post_count = 1
    sign_in(user)
    post "/posts.json",
         params: {
           title: "An anonymous topic awaiting review",
           raw: "A sufficiently long anonymous discussion post.",
           category: category.id,
           isbf_anonymous: "true"
         }
    reviewable = ReviewableQueuedPost.order(:id).last

    expect do
      reviewable.perform(Fabricate(:admin), :reject_post)
    end.to change {
      Topic.where(archetype: Archetype.private_message).count
    }.by(1)

    message = Topic.where(archetype: Archetype.private_message).order(:id).last
    expect(message.allowed_users).to include(user)
    expect(message.allowed_users).not_to include(reviewable.target_created_by)
  end

  it "keeps the standalone list private and blocks full-session switching" do
    get "/isbf-anonymous/api/posts.json"
    expect(response.status).not_to eq(200)

    sign_in(user)
    get "/isbf-anonymous/posts"
    expect(response.status).to eq(200)

    post "/u/toggle-anon.json"
    expect(response.status).to eq(403)
  end
end
