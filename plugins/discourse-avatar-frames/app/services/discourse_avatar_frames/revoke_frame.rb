# frozen_string_literal: true

module DiscourseAvatarFrames
  class RevokeFrame
    include Service::Base

    policy :can_manage

    params do
      attribute :frame_id, :integer
      attribute :user_id, :integer
      validates :frame_id, :user_id, numericality: { only_integer: true, greater_than: 0 }
    end

    model :grant

    transaction do
      only_if :requires_award? do
        step :clear_selection
      end
      step :revoke_frame
      step :log_revocation
    end

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def fetch_grant(params:)
      Grant.includes(:frame, :user).find_by(frame_id: params.frame_id, user_id: params.user_id)
    end

    def requires_award?(grant:)
      grant.frame.access_mode == "granted"
    end

    def clear_selection(grant:)
      UserCustomField.where(user_id: grant.user_id, name: FIELD, value: grant.frame.key).delete_all
    end

    def revoke_frame(grant:)
      grant.destroy!
    end

    def log_revocation(grant:, guardian:)
      StaffActionLogger.new(guardian.user).log_custom(
        "avatar_frame_revoked",
        target_user_id: grant.user_id,
        frame_key: grant.frame.key,
        frame_name: grant.frame.name,
      )
    end
  end
end
