# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::ProcessImport do
  describe described_class::Contract, type: :model do
    it { is_expected.not_to allow_values(nil, 0, -1).for(:import_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:recipient, :user)
    fab!(:import) do
      Fabricate(
        :avatar_frame_import,
        created_by: acting_user,
        user_ids: [recipient.id],
        matched_count: 1,
      )
    end
    let(:params) { { import_id: import.id } }
    let(:dependencies) { { guardian: acting_user.guardian } }

    context "when the actor is a regular user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "with an invalid contract" do
      let(:params) { { import_id: 0 } }

      it { is_expected.to fail_a_contract }
    end

    context "when the import is missing" do
      let(:params) { { import_id: import.id + 100_000 } }

      it { is_expected.to fail_to_find_a_model(:import) }
    end

    context "with a queued import" do
      it "grants the batch and records completion" do
        expect(result).to run_successfully
        expect(import.reload).to have_attributes(
          status: "completed",
          processed_count: 1,
          granted_count: 1,
        )
        expect(import.frame.grants.pluck(:user_id)).to eq([recipient.id])
      end
    end

    context "with a completed import" do
      before { import.update!(status: "completed", processed_count: 1) }

      it "preserves the completed progress" do
        expect { result }.not_to change { DiscourseAvatarFrames::Grant.count }
        expect(result).to run_successfully
        expect(import.reload.processed_count).to eq(1)
      end
    end
  end
end
