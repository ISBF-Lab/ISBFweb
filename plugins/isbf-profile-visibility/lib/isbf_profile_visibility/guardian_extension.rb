# frozen_string_literal: true

module IsbfProfileVisibility
  module GuardianExtension
    # Only the owner's choice: unlike can_see_profile_section?, it leaves the
    # existing new-user profile restrictions to can_see_profile?.
    def profile_section_hidden?(user, section)
      return false unless IsbfProfileVisibility.enabled?
      return false if !user.is_a?(User) || is_me?(user) || is_staff?

      !!(user.user_option&.hide_profile? || IsbfProfileVisibility.hidden_by_owner?(user, section))
    end

    def can_see_profile_section?(user, section)
      can_see_profile?(user) && !profile_section_hidden?(user, section)
    end

    def restrict_user_fields?(user)
      super || profile_section_hidden?(user, :bio)
    end

    def can_see_user_actions?(user, action_types = [])
      return false if profile_section_hidden?(user, :activity)

      super
    end
  end
end
