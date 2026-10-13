# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::RevokeFrame do
  describe described_class::Contract, type: :model do
    it { is_expected.not_to allow_values(nil, 0, -1).for(:frame_id) }
    it { is_expected.not_to allow_values(nil, 0, -1).for(:user_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:recipient, :user)
    fab!(:frame, :avatar_frame)
    fab!(:grant) { Fabricate(:avatar_frame_grant, frame:, user: recipient) }
    let(:params) { { frame_id: frame.id, user_id: recipient.id } }
    let(:dependencies) { { guardian: acting_user.guardian } }

    context "when the actor is a regular user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "with an invalid contract" do
      let(:params) { { frame_id: 0, user_id: recipient.id } }

      it { is_expected.to fail_a_contract }
    end

    context "when the grant is missing" do
      let(:params) { { frame_id: frame.id, user_id: recipient.id + 100_000 } }

      it { is_expected.to fail_to_find_a_model(:grant) }
    end

    context "when the awarded frame is selected" do
      before do
        recipient.custom_fields[DiscourseAvatarFrames::FIELD] = frame.key
        recipient.save!
      end

      it "revokes the award and clears the user's selection" do
        expect(result).to run_successfully
        expect(DiscourseAvatarFrames::Grant.exists?(frame:, user: recipient)).to eq(false)
        expect(recipient.reload.custom_fields[DiscourseAvatarFrames::FIELD]).to be_blank
      end
    end

    context "when the selected frame has become public" do
      before do
        frame.update!(access_mode: "public")
        recipient.custom_fields[DiscourseAvatarFrames::FIELD] = frame.key
        recipient.save!
      end

      it "preserves the publicly available selection" do
        expect(result).to run_successfully
        expect(recipient.reload.custom_fields[DiscourseAvatarFrames::FIELD]).to eq(frame.key)
      end
    end
  end
end
