# frozen_string_literal: true

module DiscourseAvatarFrames
  class Grant < ActiveRecord::Base
    self.table_name = "discourse_avatar_frames_grants"

    belongs_to :frame, class_name: "DiscourseAvatarFrames::Frame"
    belongs_to :user, class_name: "::User"
    belongs_to :granted_by, class_name: "::User"
    belongs_to :notification, class_name: "::Notification", optional: true

    validates :granted_at, presence: true
    validates :user_id, uniqueness: { scope: :frame_id }
    validate :validate_award, on: :create

    after_create :record_award
    after_commit { DiscourseAvatarFrames::Cache.reset }

    def self.award(frame:, user:, actor:)
      frame.with_lock do
        frame.grants.find_by(user:) ||
          frame.grants.create(user:, granted_by: actor, granted_at: Time.current)
      end
    end

    private

    def validate_award
      unless granted_by&.admin? && frame&.grantable? && user && user.id.positive? &&
               !DiscourseAvatarFrames.anonymous?(user)
        errors.add(:base, I18n.t("avatar_frames.errors.unavailable"))
      end
    end

    def record_award
      notice =
        Notification.create!(
          user:,
          notification_type: Notification.types[:custom],
          data: {
            message: "avatar_frames.granted",
            frame_key: frame.key,
            frame_name: frame.name,
            name_key: frame.name_key,
            display_username: granted_by.username,
          }.to_json,
        )
      update_column(:notification_id, notice.id)
      StaffActionLogger.new(granted_by).log_custom(
        "avatar_frame_granted",
        target_user_id: user.id,
        frame_key: frame.key,
        frame_name: frame.name,
      )
    end
  end
end
