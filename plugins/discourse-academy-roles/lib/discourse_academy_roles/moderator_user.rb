# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorUser
  def academy_role_group_ids
    @belonging_to_group_ids ||= group_users.pluck(:group_id)
  end

  def belonging_to_group_ids
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(self)
    DiscourseAcademyRoles::ModeratorPermissions.group_ids(self, internal: true)
  end

  def staff?
    DiscourseAcademyRoles::ModeratorPermissions.restricted?(self) ? false : super
  end

  def moderator?
    DiscourseAcademyRoles::ModeratorPermissions.restricted?(self) ? false : super
  end

  def whisperer?
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(self)
    academy_non_role_whisperer? ||
      (DiscourseAcademyRoles::ModeratorPermissions.allowed?(self, :hidden_content) && super)
  end

  def academy_non_role_whisperer?
    (
      academy_role_group_ids - DiscourseAcademyRoles::ModeratorPermissions::ROLE_GROUP_IDS
    ).intersect?(SiteSetting.whispers_allowed_groups_map)
  end

  def in_any_groups?(group_ids)
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(self)
    super(group_ids - DiscourseAcademyRoles::ModeratorPermissions::ROLE_GROUP_IDS)
  end

  def secure_category_ids
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(self)
    Category
      .scoped_to_permissions(guardian, %i[full create_post readonly])
      .where(read_restricted: true)
      .pluck(:id)
      .sort
  end
end
