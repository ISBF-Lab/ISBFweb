# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::ImportsController do
  fab!(:admin)
  fab!(:user)
  fab!(:frame, :avatar_frame)
  let(:csv_file) { Tempfile.new(%w[avatar-frame .csv]) }

  before { SiteSetting.avatar_frames_enabled = true }
  after { csv_file.close! }

  describe "#create" do
    before { sign_in(admin) }

    it "returns import matching results before awarding users" do
      csv_file.write("email\n#{user.email}\n#{user.username}\nunknown_person\n")
      csv_file.flush

      post "/avatar-frames/admin/frames/#{frame.id}/imports.json",
           params: {
             file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv"),
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body["import"]).to include(
        "status" => "queued",
        "matched_count" => 1,
        "duplicate_count" => 1,
        "unmatched_count" => 1,
      )
      expect(frame.grants).to be_empty
    end

    it "returns a validation error for malformed input" do
      csv_file.write("username\n\"unterminated\n")
      csv_file.flush

      post "/avatar-frames/admin/frames/#{frame.id}/imports.json",
           params: {
             file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv"),
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(I18n.t("avatar_frames.errors.invalid_csv"))
    end
  end

  describe "#show" do
    fab!(:import) { Fabricate(:avatar_frame_import, frame:, created_by: admin) }

    it "keeps import results visible only to administrators" do
      sign_in(user)
      get "/avatar-frames/admin/imports/#{import.id}.json"
      expect(response.status).to eq(403)

      sign_in(admin)
      get "/avatar-frames/admin/imports/#{import.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["import"]["id"]).to eq(import.id)
    end
  end
end
