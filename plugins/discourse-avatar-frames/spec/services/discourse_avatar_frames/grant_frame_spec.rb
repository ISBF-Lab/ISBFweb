# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::GrantFrame do
  describe described_class::Contract, type: :model do
    it { is_expected.not_to allow_values(nil, 0, -1).for(:frame_id) }
    it { is_expected.not_to allow_values(nil, 0, -1).for(:user_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:recipient, :user)
    fab!(:frame, :avatar_frame)
    let(:params) { { frame_id: frame.id, user_id: recipient.id } }
    let(:dependencies) { { guardian: acting_user.guardian } }

    context "when the actor is a regular user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "with an invalid contract" do
      let(:params) { { frame_id: frame.id, user_id: 0 } }

      it { is_expected.to fail_a_contract }
    end

    context "when the frame is missing" do
      let(:params) { { frame_id: frame.id + 100_000, user_id: recipient.id } }

      it { is_expected.to fail_to_find_a_model(:frame) }
    end

    context "when the recipient is missing" do
      let(:params) { { frame_id: frame.id, user_id: recipient.id + 100_000 } }

      it { is_expected.to fail_to_find_a_model(:user) }
    end

    context "when the frame is public" do
      fab!(:frame) { Fabricate(:avatar_frame, access_mode: "public") }

      it { is_expected.to fail_a_policy(:can_award) }
    end

    context "when the recipient is an anonymous identity" do
      before do
        Fabricate(:avatar_frame_anonymous_identity, user: recipient, master_user: acting_user)
      end

      it { is_expected.to fail_a_policy(:can_award) }
    end

    context "with an enabled award frame" do
      it "returns the recipient's persisted grant" do
        expect(result).to run_successfully
        expect(result.grant).to have_attributes(frame:, user: recipient, granted_by: acting_user)
        expect(result.grant).to be_persisted
      end
    end
  end
end
