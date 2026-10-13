# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::FramesController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)
  fab!(:frame, :avatar_frame)

  before { SiteSetting.avatar_frames_enabled = true }

  describe "#index" do
    it "returns previews and award counts to administrators" do
      Fabricate(:avatar_frame_grant, frame:, user:, granted_by: admin)
      sign_in(admin)

      get "/avatar-frames/admin/frames.json"

      expect(response.status).to eq(200)
      serialized = response.parsed_body["frames"].find { |entry| entry["id"] == frame.id }
      expect(serialized).to include(
        "key" => frame.key,
        "grants_count" => 1,
        "access_mode" => "granted",
      )
      expect(serialized["image_url"]).to eq(frame.image_url)
    end

    it "rejects moderators and regular users" do
      [moderator, user].each do |actor|
        sign_in(actor)

        get "/avatar-frames/admin/frames.json"

        expect(response.status).to eq(403)
      end
    end

    it "rejects visitors" do
      get "/avatar-frames/admin/frames.json"

      expect(response.status).to eq(403)
    end
  end

  describe "#create" do
    fab!(:image) { Fabricate(:upload, width: 288, height: 288) }

    before { sign_in(admin) }

    it "registers uploaded images as a new award frame" do
      post "/avatar-frames/admin/frames.json",
           params: {
             name: "Campus star",
             image_upload_id: image.id,
             static_upload_id: image.id,
             scale: 124,
             offset_y: -4,
             confirm_calibration: true,
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body["frame"]).to include(
        "name" => "Campus star",
        "access_mode" => "granted",
        "image_upload_id" => image.id,
        "scale" => 124,
        "offset_y" => -4,
        "calibration_confirmed" => true,
      )
      expect(response.parsed_body["frame"]["key"]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it "returns an editable validation error when images are missing" do
      post "/avatar-frames/admin/frames.json", params: { name: "Campus star" }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("avatar_frames.errors.invalid_image"),
      )
    end

    it "requires explicit confirmation even when the saved confirmation field is supplied" do
      post "/avatar-frames/admin/frames.json",
           params: {
             name: "Campus star",
             image_upload_id: image.id,
             static_upload_id: image.id,
             calibration_confirmed: true,
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("avatar_frames.errors.calibration_required"),
      )
    end
  end

  describe "#update" do
    before { sign_in(admin) }

    it "changes the name and public availability while retaining the key" do
      put "/avatar-frames/admin/frames/#{frame.id}.json",
          params: {
            name: "Renamed frame",
            access_mode: "public",
            enabled: false,
          }

      expect(response.status).to eq(200)
      expect(frame.reload).to have_attributes(
        name: "Renamed frame",
        access_mode: "public",
        enabled: false,
      )
      expect(response.parsed_body["frame"]["key"]).to eq(frame.key)
    end
  end
end
