# frozen_string_literal: true

RSpec.describe IsbfViews::ImpressionsController do
  fab!(:viewer, :user)
  fab!(:second_viewer, :user)
  fab!(:topic)

  before { SiteSetting.isbf_views_enabled = true }

  def record(topic_ids)
    post "/isbf/views/impressions.json", params: { topic_ids: topic_ids }
  end

  it "records a signed-in viewer once across repeated requests" do
    sign_in(viewer)

    2.times { record([topic.id]) }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"][topic.id.to_s]).to eq(1)
    expect(IsbfViews::Impression.where(topic_id: topic.id, user_id: viewer.id).count).to eq(1)
  end

  it "includes existing topic visits without counting the same account twice" do
    TopicViewItem.add(topic.id, "127.0.0.1", viewer.id)
    sign_in(viewer)

    record([topic.id])
    expect(response.parsed_body["counts"][topic.id.to_s]).to eq(1)

    sign_in(second_viewer)
    record([topic.id])
    expect(response.parsed_body["counts"][topic.id.to_s]).to eq(2)
  end

  it "does not record or reveal a topic the viewer cannot see" do
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    topic.update!(category: private_category)
    sign_in(viewer)

    record([topic.id])

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["counts"]).to eq({})
    expect(IsbfViews::Impression.where(topic_id: topic.id)).to be_empty
  end

  it "rejects anonymous and oversized requests" do
    record([topic.id])
    expect(response).not_to have_http_status(:ok)

    sign_in(viewer)
    record((1..51).to_a)
    expect(response).not_to have_http_status(:ok)
  end
end
