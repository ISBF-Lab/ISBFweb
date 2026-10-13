# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorControllers
  USER_ACTIONS = {
    "index" => :user_admin,
    "show" => :user_admin,
    "penalty_history" => :user_admin,
    "suspend" => :suspend_users,
    "unsuspend" => :suspend_users,
    "suspend_bulk" => :suspend_users,
    "silence" => :silence_users,
    "unsilence" => :silence_users,
    "destroy" => :delete_users,
    "destroy_bulk" => :delete_users,
    "anonymize" => :anonymize_users,
    "add_group" => :manage_groups,
    "remove_group" => :manage_groups,
    "primary_group" => :edit_users,
    "delete_posts_batch" => :delete_others,
    "delete_posts_decider" => :delete_others,
  }.freeze

  def ensure_staff
    return super unless guardian.academy_restricted_moderator?
    permission =
      if controller_path == "admin/users"
        USER_ACTIONS[action_name]
      elsif controller_path == "admin/groups"
        :manage_groups
      end
    raise Discourse::InvalidAccess unless permission && guardian.academy_can?(permission)
  end
end

module DiscourseAcademyRoles::ModeratorUserController
  def academy_check_ordinary_target
    return unless guardian.academy_restricted_moderator?
    return if %w[index show penalty_history].include?(action_name)
    target = User.find_by(id: params[:user_id] || params[:id])
    if target && !DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target)
      raise Discourse::InvalidAccess
    end
  end
end

module DiscourseAcademyRoles::ModeratorProfileController
  def academy_check_credentials_target
    return unless guardian.academy_restricted_moderator?
    raise Discourse::InvalidAccess unless fetch_user_from_params.id == current_user.id
  end
end

module DiscourseAcademyRoles::ModeratorCurrentUserSerializer
  def staff?
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(object)
    scope.academy_has_management_permissions?
  end

  def moderator?
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(object)
    scope.academy_has_management_permissions?
  end
end

module DiscourseAcademyRoles::ModeratorStaffConstraint
  def matches?(request)
    actor = CurrentUser.lookup_from_env(request.env)
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(actor)
    actor.guardian.academy_has_management_permissions? && custom_staff_check(request)
  rescue Discourse::InvalidAccess, Discourse::ReadOnly
    false
  end
end

module DiscourseAcademyRoles::ModeratorAdminConstraint
  def matches?(request)
    actor = CurrentUser.lookup_from_env(request.env)
    if request.delete? && request.path.match?(%r{\A/admin/groups/\d+(?:\.json)?\z}) &&
         DiscourseAcademyRoles::ModeratorPermissions.restricted?(actor)
      return actor.guardian.academy_can?(:manage_groups) && custom_admin_check(request)
    end
    super
  rescue Discourse::InvalidAccess, Discourse::ReadOnly
    false
  end
end
