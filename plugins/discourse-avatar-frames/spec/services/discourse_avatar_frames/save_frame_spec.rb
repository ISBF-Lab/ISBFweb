# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::SaveFrame do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }

    it { is_expected.to validate_inclusion_of(:access_mode).in_array(%w[public granted]) }

    it { is_expected.not_to allow_value(-1).for(:position) }

    it do
      is_expected.to allow_values(50, 120.5, 300).for(:scale)
      is_expected.not_to allow_values(49.9, 300.1).for(:scale)
    end

    it "limits each offset to one avatar diameter" do
      %i[offset_x offset_y].each do |attribute|
        is_expected.to allow_values(-100, 0.25, 100).for(attribute)
        is_expected.not_to allow_values(-100.1, 100.1).for(attribute)
      end
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:image) { Fabricate(:upload, width: 288, height: 288) }
    let(:params) do
      {
        name: "Campus star",
        image_upload_id: image.id,
        static_upload_id: image.id,
        confirm_calibration: true,
      }
    end
    let(:dependencies) { { guardian: acting_user.guardian } }

    context "when the actor is a moderator" do
      fab!(:acting_user, :moderator)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "with an invalid contract" do
      let(:params) { { name: " " } }

      it { is_expected.to fail_a_contract }
    end

    context "when the edited frame is missing" do
      let(:params) { super().merge(frame_id: 100_000) }

      it { is_expected.to fail_to_find_a_model(:frame) }
    end

    context "without frame images" do
      let(:params) { { name: "Campus star" } }

      it { is_expected.to fail_with_an_invalid_model(:frame) }
    end

    context "without confirming the new image calibration" do
      let(:params) { super().except(:confirm_calibration) }

      it { is_expected.to fail_with_an_invalid_model(:frame) }
    end

    context "when saving an unconfirmed disabled draft" do
      let(:params) { super().except(:confirm_calibration).merge(enabled: false) }

      it "saves the image without making it available to users" do
        expect(result).to run_successfully
        expect(result.frame).to have_attributes(enabled: false, calibration_confirmed: false)
      end
    end

    context "with valid image uploads" do
      it "creates a frame that requires an award by default" do
        expect(result).to run_successfully
        expect(result.frame).to be_persisted
        expect(result.frame).to have_attributes(
          name: params[:name],
          access_mode: "granted",
          enabled: true,
          calibration_confirmed: true,
        )
        expect(result.frame.key).to match(/\A[0-9a-f-]{36}\z/)
      end
    end

    context "when editing existing metadata" do
      fab!(:frame) { Fabricate(:uploaded_avatar_frame, scale: 124, offset_x: 2, offset_y: -4) }
      let(:params) { { frame_id: frame.id, name: "Renamed frame" } }

      it "retains the uploaded images, calibration, grants, and selected frame" do
        user = Fabricate(:user)
        grant = Fabricate(:avatar_frame_grant, frame:, user:)
        user.custom_fields[DiscourseAvatarFrames::FIELD] = frame.key
        user.save_custom_fields
        image_ids = [frame.image_upload_id, frame.static_upload_id]

        expect(result).to run_successfully
        expect(frame.reload).to have_attributes(
          name: params[:name],
          image_upload_id: image_ids.first,
          static_upload_id: image_ids.last,
          scale: 124,
          offset_x: 2,
          offset_y: -4,
          calibration_confirmed: true,
        )
        expect(frame.grants).to contain_exactly(grant)
        expect(user.reload.custom_fields[DiscourseAvatarFrames::FIELD]).to eq(frame.key)
      end
    end

    context "when confirming new calibration on an existing frame" do
      fab!(:frame, :uploaded_avatar_frame)
      let(:params) { { frame_id: frame.id, scale: 125, offset_y: -3, confirm_calibration: true } }

      it "updates the geometry and records the confirmation" do
        expect(result).to run_successfully
        expect(frame.reload).to have_attributes(
          scale: 125,
          offset_y: -3,
          calibration_confirmed: true,
        )
      end
    end
  end
end
