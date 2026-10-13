# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::Grant do
  describe ".award" do
    subject(:grant) { described_class.award(frame:, user: recipient, actor:) }

    fab!(:actor, :admin)
    fab!(:recipient, :user)
    fab!(:frame, :avatar_frame)

    it "notifies the recipient and logs the award without selecting a frame" do
      expect { grant }.to change { recipient.notifications.count }.by(1).and change {
              UserHistory.where(acting_user_id: actor.id).count
            }.by(1)

      expect(grant.notification).to have_attributes(
        user: recipient,
        notification_type: Notification.types[:custom],
      )
      expect(grant.notification.data_hash).to include(
        "message" => "avatar_frames.granted",
        "frame_key" => frame.key,
        "frame_name" => frame.name,
      )
      expect(recipient.reload.custom_fields[DiscourseAvatarFrames::FIELD]).to be_blank
    end

    it "reuses an existing grant and notification on repeat awards" do
      grant

      repeated = nil
      expect do
        repeated = described_class.award(frame:, user: recipient, actor:)
      end.not_to change { recipient.notifications.count }

      expect(repeated.id).to eq(grant.id)
      expect(frame.grants.where(user: recipient).count).to eq(1)
    end
  end
end
