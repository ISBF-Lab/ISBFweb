# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::Frame do
  fab!(:user)

  describe "#save!" do
    fab!(:image) { Fabricate(:upload, width: 288, height: 288) }
    fab!(:replacement) { Fabricate(:upload, width: 288, height: 288) }

    it "keeps only the uploads referenced by the current frame" do
      frame = Fabricate(:uploaded_avatar_frame, image_upload: image, static_upload: image)
      expect(frame.upload_references.pluck(:upload_id)).to eq([image.id])

      frame.update!(
        image_upload: replacement,
        static_upload: replacement,
        confirm_calibration: true,
      )

      expect(frame.upload_references.reload.pluck(:upload_id)).to eq([replacement.id])
    end

    it "requires confirmation again after replacing the uploaded image" do
      frame = Fabricate(:uploaded_avatar_frame, image_upload: image, static_upload: image)

      expect(frame.update(image_upload: replacement, static_upload: replacement)).to eq(false)
      expect(frame.errors[:base]).to include(I18n.t("avatar_frames.errors.calibration_required"))
      expect(frame.reload).to have_attributes(
        image_upload_id: image.id,
        calibration_confirmed: true,
      )
    end

    it "requires confirmation again after adjusting the geometry" do
      frame = Fabricate(:uploaded_avatar_frame, image_upload: image, static_upload: image)

      expect(frame.update(offset_y: -4)).to eq(false)
      expect(frame.errors[:base]).to include(I18n.t("avatar_frames.errors.calibration_required"))
      expect(frame.reload.offset_y).to eq(0)
    end

    it "keeps an unconfirmed draft disabled until its calibration is confirmed" do
      frame = Fabricate(:uploaded_avatar_frame, enabled: false, confirm_calibration: false)
      expect(frame).not_to be_calibration_confirmed

      expect(frame.update(enabled: true)).to eq(false)
      expect(frame.reload).not_to be_enabled

      frame.update!(enabled: true, confirm_calibration: true)

      expect(frame.reload).to be_enabled
      expect(frame).to be_calibration_confirmed
    end
  end

  describe ".available_for" do
    fab!(:public_frame) { Fabricate(:avatar_frame, access_mode: "public") }
    fab!(:awarded_frame, :avatar_frame)
    fab!(:locked_frame, :avatar_frame)
    fab!(:disabled_frame) { Fabricate(:avatar_frame, access_mode: "public", enabled: false) }
    fab!(:grant) { Fabricate(:avatar_frame_grant, frame: awarded_frame, user:) }

    it "includes enabled public and awarded frames" do
      frames = [public_frame, awarded_frame, locked_frame, disabled_frame]

      expect(described_class.available_for(user).where(id: frames.map(&:id))).to contain_exactly(
        public_frame,
        awarded_frame,
      )
    end
  end
end
