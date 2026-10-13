# frozen_string_literal: true

RSpec.describe "Avatar frames", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: 0) }
  fab!(:other_user, :user)
  fab!(:frame, :avatar_frame)

  before do
    SiteSetting.avatar_frames_enabled = true
    DiscourseAvatarFrames::Cache.reset
    sign_in(user)
  end

  it "saves and removes a frame through profile preferences" do
    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: "bubble" } }

    expect(response.status).to eq(200)
    expect(response.parsed_body["user"]["avatar_frame"]).to eq("bubble")
    expect(user.reload.custom_fields["avatar_frame"]).to eq("bubble")

    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: "" } }

    expect(response.status).to eq(200)
    expect(response.parsed_body["user"]["avatar_frame"]).to be_nil
    expect(user.reload.custom_fields["avatar_frame"]).to be_blank
  end

  it "rejects unknown selections and edits to another user's preferences" do
    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: "../unknown" } }

    expect(response.status).to eq(422)
    expect(user.reload.custom_fields["avatar_frame"]).to be_blank

    put "/u/#{other_user.username}.json", params: { custom_fields: { avatar_frame: "bubble" } }

    expect(response.status).to eq(403)
    expect(other_user.reload.custom_fields["avatar_frame"]).to be_blank
  end

  it "requires an award before selecting a restricted frame" do
    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: frame.key } }

    expect(response.status).to eq(422)
    expect(user.reload.custom_fields["avatar_frame"]).to be_blank

    Fabricate(:avatar_frame_grant, frame:, user:)
    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: frame.key } }

    expect(response.status).to eq(200)
    expect(response.parsed_body["user"]["avatar_frame"]).to eq(frame.key)
  end

  it "hides disabled frames while allowing unrelated profile changes" do
    Fabricate(:avatar_frame_grant, frame:, user:)
    put "/u/#{user.username}.json", params: { custom_fields: { avatar_frame: frame.key } }
    expect(response.status).to eq(200)

    frame.update!(enabled: false)
    put "/u/#{user.username}.json",
        params: {
          bio_raw: "Updated biography",
          custom_fields: {
            avatar_frame: frame.key,
          },
        }

    expect(response.status).to eq(200)
    expect(user.reload.user_profile.bio_raw).to eq("Updated biography")
    expect(response.parsed_body["user"]["avatar_frame"]).to be_nil
  end

  it "preserves preferences when the feature is disabled" do
    user.custom_fields["avatar_frame"] = "bubble"
    user.save!
    SiteSetting.avatar_frames_enabled = false

    put "/u/#{user.username}.json", params: { bio_raw: "Updated biography" }

    expect(response.status).to eq(200)
    expect(response.parsed_body["user"]).not_to have_key("avatar_frame")
    expect(user.reload.custom_fields["avatar_frame"]).to eq("bubble")
  end

  it "returns frames alongside topic authors" do
    authors = [user, other_user, Fabricate(:user)]
    topics = authors.map { |author| Fabricate(:topic, user: author) }
    authors.each do |author|
      author.custom_fields["avatar_frame"] = "bubble"
      author.save!
    end

    get "/latest.json"

    expect(response.status).to eq(200)
    serialized = response.parsed_body["users"].index_by { |author| author["id"] }
    expect(authors.map { |author| serialized[author.id]["avatar_frame"] }).to eq(
      %w[bubble bubble bubble],
    )
    expect(response.parsed_body["topic_list"]["topics"].map { |topic| topic["id"] }).to include(
      *topics.map(&:id),
    )
  end

  it "keeps native anonymous identities independent of their owner" do
    user.custom_fields["avatar_frame"] = "bubble"
    user.save!
    other_user.custom_fields["avatar_frame"] = "bubble"
    other_user.save!
    Fabricate(:avatar_frame_anonymous_identity, user: other_user, master_user: user)

    get "/u/#{other_user.username}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["user"]["avatar_frame"]).to be_nil
  end

  it "returns linked account frames only to administrators" do
    SiteSetting.isbf_account_switch_enabled = true
    other_user.custom_fields["avatar_frame"] = "terrarium"
    other_user.save!
    Fabricate(
      :isbf_account_link,
      user_a: user,
      user_b: other_user,
      requester: user,
      status: :approved,
    )

    get "/isbf/account-switch/accounts.json"

    expect(response.status).to eq(403)

    user.update!(admin: true)
    get "/isbf/account-switch/accounts.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["links"].first["account"]["avatar_frame"]).to eq("terrarium")
  end
end
