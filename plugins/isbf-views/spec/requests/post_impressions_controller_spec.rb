# frozen_string_literal: true

RSpec.describe IsbfViews::PostImpressionsController do
  fab!(:viewer, :user)
  fab!(:second_viewer, :user)
  fab!(:topic)
  fab!(:reply) { Fabricate(:post, topic: topic, post_number: 2) }

  before { SiteSetting.isbf_views_enabled = true }

  def record(post_ids)
    post "/isbf/views/post-impressions.json", params: { post_ids: post_ids }, as: :json
  end

  it "records the first impression and deduplicates repeated requests and IDs" do
    sign_in(viewer)

    record([reply.id.to_s, reply.id])

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)

    record([reply.id])

    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
    expect(IsbfViews::PostImpression.where(post_id: reply.id, user_id: viewer.id).count).to eq(1)
  end

  it "counts a different account once without importing existing topic views" do
    TopicViewItem.add(topic.id, "127.0.0.1", second_viewer.id)
    sign_in(viewer)
    record([reply.id])
    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)

    sign_in(second_viewer)
    2.times { record([reply.id]) }

    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 2)
    expect(IsbfViews::PostImpression.where(post_id: reply.id).count).to eq(2)
  end

  it "skips a competing insertion of the same account before the batch insert" do
    sign_in(viewer)
    allow(IsbfViews::PostImpression).to receive(
      :insert_all,
    ).and_wrap_original do |original, rows, **options|
      IsbfViews::PostImpression.create!(rows.first)
      original.call(rows, **options)
    end

    record([reply.id])

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
    expect(IsbfViews::PostImpression.where(post_id: reply.id, user_id: viewer.id).count).to eq(1)
  end

  it "requires a signed-in account" do
    record([reply.id])

    expect(response).not_to have_http_status(:ok)
    expect(IsbfViews::PostImpression.count).to eq(0)
  end

  it "returns not found when the feature is disabled" do
    sign_in(viewer)
    SiteSetting.isbf_views_enabled = false

    record([reply.id])

    expect(response).to have_http_status(:not_found)
    expect(IsbfViews::PostImpression.count).to eq(0)
  end

  it "rejects missing, non-array, empty, oversized, and non-positive integer IDs" do
    sign_in(viewer)
    invalid_inputs = [
      nil,
      reply.id,
      {},
      [],
      (1..51).to_a,
      [0],
      [-1],
      ["bad"],
      [true],
      [1.5],
      ["1.5"],
      [2**63],
    ]

    invalid_inputs.each do |ids|
      record(ids)
      expect(response).to have_http_status(:bad_request)
    end

    expect(IsbfViews::PostImpression.count).to eq(0)
  end

  it "accepts the maximum batch size" do
    sign_in(viewer)

    record(Array.new(50, reply.id))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
  end

  it "omits nonexistent posts while recording eligible replies" do
    sign_in(viewer)

    record([reply.id, Post.maximum(:id) + 1])

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
  end

  it "does not reveal inaccessible private-category posts or their existing counts" do
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    private_topic = Fabricate(:topic, category: private_category)
    private_reply = Fabricate(:post, topic: private_topic, post_number: 2)
    IsbfViews::PostImpression.create!(
      post_id: private_reply.id,
      user_id: second_viewer.id,
      created_at: Time.zone.now,
    )
    sign_in(viewer)

    record([reply.id, private_reply.id])

    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
    expect(
      IsbfViews::PostImpression.where(post_id: private_reply.id, user_id: viewer.id),
    ).to be_empty
  end

  it "does not count private-message replies even for a participant" do
    private_topic = Fabricate(:private_message_topic, user: viewer)
    private_reply = Fabricate(:post, topic: private_topic, post_number: 2, user: viewer)
    sign_in(viewer)

    record([private_reply.id])

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq({})
    expect(IsbfViews::PostImpression.count).to eq(0)
  end

  it "does not count the original post, hidden replies, deleted replies, or system events" do
    original = Fabricate(:post, topic: topic, post_number: 1)
    hidden = Fabricate(:post, topic: topic, post_number: 3, hidden: true)
    deleted = Fabricate(:post, topic: topic, post_number: 4, deleted_at: Time.zone.now)
    system_event =
      Fabricate(:post, topic: topic, post_number: 5, post_type: Post.types[:small_action])
    system_reply = Fabricate(:post, topic: topic, post_number: 6, user: Discourse.system_user)
    sign_in(viewer)

    record([reply.id, original.id, hidden.id, deleted.id, system_event.id, system_reply.id])

    expect(response.parsed_body["counts"]).to eq(reply.id.to_s => 1)
    expect(IsbfViews::PostImpression.pluck(:post_id)).to contain_exactly(reply.id)
  end

  it "does not count replies in deleted or unlisted topics" do
    topic.update!(deleted_at: Time.zone.now)
    sign_in(viewer)
    record([reply.id])
    expect(response.parsed_body["counts"]).to eq({})

    topic.update!(deleted_at: nil, visible: false)
    record([reply.id])
    expect(response.parsed_body["counts"]).to eq({})
    expect(IsbfViews::PostImpression.count).to eq(0)
  end

  it "checks native post permissions after filtering visible topics" do
    sign_in(viewer)
    allow_any_instance_of(Guardian).to receive(:can_see_post?).with(reply).and_return(false)

    record([reply.id])

    expect(response.parsed_body["counts"]).to eq({})
    expect(IsbfViews::PostImpression.count).to eq(0)
  end
end
