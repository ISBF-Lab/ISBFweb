# frozen_string_literal: true

RSpec.describe Jobs::AvatarFramesImport do
  describe "#execute" do
    fab!(:actor, :admin)
    fab!(:existing_recipient, :user)
    fab!(:new_recipient, :user)
    fab!(:frame, :avatar_frame)
    fab!(:existing_grant) do
      Fabricate(:avatar_frame_grant, frame:, user: existing_recipient, granted_by: actor)
    end
    fab!(:import) do
      Fabricate(
        :avatar_frame_import,
        frame:,
        created_by: actor,
        user_ids: [existing_recipient.id, new_recipient.id],
        matched_count: 2,
      )
    end

    around do |example|
      stub_const(DiscourseAvatarFrames::ProcessImport, :BATCH_SIZE, 1) { example.run }
    end

    it "counts existing grants and preserves completed results during a retry" do
      expect do
        described_class.new.execute(import_id: import.id)
        described_class.new.execute(import_id: import.id)
      end.to change { new_recipient.notifications.count }.by(1)

      expect(import.reload).to have_attributes(
        status: "completed",
        processed_count: 2,
        granted_count: 1,
        skipped_count: 1,
        failed_count: 0,
      )
      expect(frame.grants.pluck(:user_id)).to contain_exactly(
        existing_recipient.id,
        new_recipient.id,
      )
    end

    it "fails queued work when its administrator loses permission" do
      actor.update!(admin: false)

      described_class.new.execute(import_id: import.id)

      expect(import.reload).to have_attributes(
        status: "failed",
        processed_count: 0,
        failed_count: 2,
      )
      expect(frame.grants.pluck(:user_id)).to eq([existing_recipient.id])
      expect(new_recipient.notifications).to be_empty
    end
  end
end
