# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorCategories
  def scoped_to_permissions(guardian, permission_types)
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(guardian&.user)

    permissions =
      permission_types.map { |permission| CategoryGroup.permission_types.fetch(permission) }
    groups = DiscourseAcademyRoles::ModeratorPermissions.group_ids(guardian.user)
    granted =
      CategoryGroup.where(
        permission_type: permissions,
        group_id: groups + [Group::AUTO_GROUPS[:everyone]],
      ).select(:category_id)
    scope = where.not(id: CategoryGroup.select(:category_id)).or(where(id: granted))
    if guardian.academy_can?(:internal_boards)
      role_groups = DiscourseAcademyRoles::ModeratorPermissions::ROLE_GROUP_IDS
      actor_roles =
        guardian.user.academy_role_group_ids.intersection(
          role_groups - [Group::AUTO_GROUPS[:admins]],
        )
      internal_categories =
        CategoryGroup
          .where(group_id: actor_roles, permission_type: permissions)
          .where.not(
            category_id: CategoryGroup.where.not(group_id: role_groups).select(:category_id),
          )
          .select(:category_id)
      scope = scope.or(where(id: internal_categories))
    end
    business_categories = []
    if guardian.academy_can?(:publish_activities)
      business_categories << SiteSetting.academy_activity_category.to_i
    end
    if guardian.academy_can?(:publish_official)
      business_categories << SiteSetting.academy_official_category.to_i
    end
    if guardian.academy_can?(:manage_resources)
      business_categories << DiscourseAcademyRoles::ModeratorPermissions.learning_category_id
    end
    scope.or(where(id: business_categories.select(&:positive?)))
  end
end
