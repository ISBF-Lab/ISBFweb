# frozen_string_literal: true

module DiscourseAcademyRoles::GuardianExtension
  def can_invite_to_forum?(groups = nil)
    return false if SiteSetting.academy_roles_enabled? && !is_admin?

    super
  end

  def can_merge_user?(user)
    return false unless super

    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles::StudentRegistration.exists?(user_id: user.id)
      return false
    end

    true
  end

  def can_merge_users?(source_user, target_user)
    return false unless super

    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles::StudentRegistration.exists?(
           user_id: target_user.id
         )
      return false
    end

    true
  end

  def can_admin_group?(group)
    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles.official_group?(group)
      return is_admin?
    end

    super
  end

  def can_edit_group?(group)
    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles.official_group?(group)
      return is_admin?
    end

    super
  end

  def can_create_topic_on_category?(category)
    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles.official_category?(category)
      return false unless DiscourseAcademyRoles.official_member?(user)
    end

    super
  end

  def can_edit_topic?(topic)
    if SiteSetting.academy_roles_enabled?
      official_post =
        topic&.first_post&.custom_fields&.dig(
          DiscourseAcademyRoles::OFFICIAL_POST_FIELD
        )
      if official_post && !is_staff? &&
           !DiscourseAcademyRoles.official_member?(user)
        return false
      end
    end

    super
  end

  def can_edit_post?(post)
    if SiteSetting.academy_roles_enabled? &&
         post&.custom_fields&.dig(DiscourseAcademyRoles::OFFICIAL_POST_FIELD)
      unless is_staff? || DiscourseAcademyRoles.official_member?(user)
        return false
      end
    end

    super
  end
end
