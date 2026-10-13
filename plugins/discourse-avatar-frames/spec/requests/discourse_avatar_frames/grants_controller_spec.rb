# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::GrantsController do
  fab!(:admin)
  fab!(:user)
  fab!(:frame, :avatar_frame)

  before { SiteSetting.avatar_frames_enabled = true }

  describe "#create" do
    before { sign_in(admin) }

    it "grants by username and returns the existing award on a second request" do
      post "/avatar-frames/admin/frames/#{frame.id}/grants.json",
           params: {
             username: user.username,
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body["newly_granted"]).to eq(true)
      expect(response.parsed_body["grant"]["user"]["id"]).to eq(user.id)
      grant_id = response.parsed_body["grant"]["id"]

      post "/avatar-frames/admin/frames/#{frame.id}/grants.json", params: { user_id: user.id }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("newly_granted" => false)
      expect(response.parsed_body["grant"]["id"]).to eq(grant_id)
    end

    it "rejects grant mutations by regular users" do
      sign_in(user)

      post "/avatar-frames/admin/frames/#{frame.id}/grants.json", params: { user_id: user.id }

      expect(response.status).to eq(403)
      expect(frame.grants).to be_empty
    end
  end

  describe "#index" do
    before { sign_in(admin) }

    it "lists awarded users with the total count" do
      Fabricate(:avatar_frame_grant, frame:, user:, granted_by: admin)

      get "/avatar-frames/admin/frames/#{frame.id}/grants.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["total"]).to eq(1)
      expect(response.parsed_body["grants"].map { |grant| grant["user"]["id"] }).to eq([user.id])
    end
  end

  describe "#destroy" do
    before { sign_in(admin) }

    it "returns an empty success response after revocation" do
      Fabricate(:avatar_frame_grant, frame:, user:, granted_by: admin)

      delete "/avatar-frames/admin/frames/#{frame.id}/grants/#{user.id}.json"

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
      expect(frame.grants).to be_empty
    end
  end
end
