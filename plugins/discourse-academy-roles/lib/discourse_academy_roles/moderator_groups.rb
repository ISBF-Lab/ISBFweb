# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorGroups
  def visible_groups(user, order = nil, opts = nil)
    result = super
    unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(user) &&
             user.guardian.academy_can?(:manage_groups)
      return result
    end
    manageable =
      result.unscope(:where).where(
        automatic: false,
        visibility_level:
          Group.visibility_levels.values_at(:public, :logged_on_users, :members, :staff),
      )
    result.or(manageable)
  end
end
