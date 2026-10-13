# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::UploadsController do
  fab!(:admin)
  fab!(:user)
  let(:source) do
    Rails.root.join("plugins/discourse-avatar-frames/spec/fixtures/images/closed-ring.png")
  end

  before { SiteSetting.avatar_frames_enabled = true }

  describe "#create" do
    it "returns both original and static upload objects" do
      sign_in(admin)

      post "/avatar-frames/admin/uploads.json",
           params: {
             file: Rack::Test::UploadedFile.new(source, "image/png"),
           }

      expect(response.status).to eq(201)
      original = response.parsed_body["image_upload"]
      expect(original).to include("width" => 288, "height" => 288, "extension" => "png")
      expect(response.parsed_body["static_upload"]["id"]).to eq(original["id"])
      expect(response.parsed_body["suggested_calibration"]).to include(
        "scale" => be_within(1).of(120),
        "offset_y" => be_within(0.5).of(-3.33),
      )
    end

    it "returns a useful validation error for an opaque image" do
      sign_in(admin)
      opaque = source.sub("closed-ring.png", "opaque-rgba.png")

      post "/avatar-frames/admin/uploads.json",
           params: {
             file: Rack::Test::UploadedFile.new(opaque, "image/png"),
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("avatar_frames.errors.transparency_required"),
      )
    end

    it "rejects uploads by regular users" do
      sign_in(user)

      post "/avatar-frames/admin/uploads.json",
           params: {
             file: Rack::Test::UploadedFile.new(source, "image/png"),
           }

      expect(response.status).to eq(403)
    end
  end
end
