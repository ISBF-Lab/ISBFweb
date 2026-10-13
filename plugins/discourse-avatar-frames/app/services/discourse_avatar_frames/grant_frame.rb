# frozen_string_literal: true

module DiscourseAvatarFrames
  class GrantFrame
    include Service::Base

    policy :can_manage

    params do
      attribute :frame_id, :integer
      attribute :user_id, :integer
      validates :frame_id, :user_id, numericality: { only_integer: true, greater_than: 0 }
    end

    model :frame
    model :user
    policy :can_award
    model :grant, :award_frame

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def fetch_frame(params:)
      Frame.find_by(id: params.frame_id)
    end

    def fetch_user(params:)
      User.find_by(id: params.user_id)
    end

    def can_award(frame:, user:)
      frame.grantable? && !DiscourseAvatarFrames.anonymous?(user)
    end

    def award_frame(frame:, user:, guardian:)
      Grant.award(frame:, user:, actor: guardian.user)
    end
  end
end
