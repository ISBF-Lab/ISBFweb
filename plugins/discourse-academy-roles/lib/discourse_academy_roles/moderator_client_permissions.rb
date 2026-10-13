# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorApplicationHelper
  def staff?
    return super unless guardian.academy_restricted_moderator?
    guardian.academy_has_management_permissions?
  end
end

module DiscourseAcademyRoles::ModeratorUserSerializer
  def moderator
    return super unless user_is_current_user && scope.academy_restricted_moderator?
    scope.academy_has_management_permissions?
  end
end
