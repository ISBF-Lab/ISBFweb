# frozen_string_literal: true

# name: discourse-academy-roles
# about: Closed academy membership and official publishing
# version: 0.1.0
# authors: Discourse

require_relative "app/validators/academy_roles_enabled_validator"

enabled_site_setting :academy_roles_enabled

register_asset "stylesheets/common/academy-roles.scss"

module ::DiscourseAcademyRoles
  OFFICIAL_POST_FIELD = "academy_official_post"
  ACTIVITY_LEVEL_FIELD = "academy_activity_level"
  LV3_SINCE_FIELD = "academy_lv3_since"
  LV3_CHECKED_AT_FIELD = "academy_lv3_checked_at"
end

after_initialize do
  require_relative "lib/discourse_academy_roles"
  require_relative "lib/discourse_academy_roles/guardian_extension"
  require_relative "lib/discourse_academy_roles/topic_category_extension"
  require_relative "lib/discourse_academy_roles/daily_limits_extension"
  require_relative "lib/discourse_academy_roles/activity_level"

  register_post_custom_field_type(DiscourseAcademyRoles::OFFICIAL_POST_FIELD, :boolean)
  TopicView.default_post_custom_fields << DiscourseAcademyRoles::OFFICIAL_POST_FIELD
  register_user_custom_field_type(DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD, :integer)
  register_user_custom_field_type(DiscourseAcademyRoles::LV3_SINCE_FIELD, :string, max_length: 40)
  register_user_custom_field_type(
    DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD,
    :string,
    max_length: 40,
  )
  add_permitted_post_create_param :academy_official, :string
  NewPostManager.add_plugin_payload_attribute(:academy_official)

  Invite.validate do
    if SiteSetting.academy_roles_enabled? && max_redemptions_allowed != 1
      errors.add(:max_redemptions_allowed, I18n.t("academy_roles.single_use_invite"))
    end
    if SiteSetting.academy_roles_enabled? && (email.present? || domain.present?)
      errors.add(:email, I18n.t("academy_roles.unbound_invite"))
    end
  end

  Topic.validate do
    next unless SiteSetting.academy_roles_enabled? && persisted? && will_save_change_to_category_id?

    unless DiscourseAcademyRoles.valid_topic_category?(self, category_id)
      errors.add(:category_id, I18n.t("academy_roles.official_category_move"))
    end
  end

  reloadable_patch do
    Guardian.prepend(DiscourseAcademyRoles::GuardianExtension)
    Topic.prepend(DiscourseAcademyRoles::TopicCategoryExtension)
    Topic.prepend(DiscourseAcademyRoles::TopicDailyLimitsExtension)
    Post.prepend(DiscourseAcademyRoles::PostDailyLimitsExtension)
    PostAction.prepend(DiscourseAcademyRoles::PostActionDailyLimitsExtension)
    User.prepend(DiscourseAcademyRoles::NewMemberPostingExtension)
  end

  on(:before_create_post) do |post, options|
    DiscourseAcademyRoles.validate_post(post, options) if SiteSetting.academy_roles_enabled?
  end

  on(:post_created) do |post, options|
    DiscourseAcademyRoles.mark_official_post(post, options) if SiteSetting.academy_roles_enabled?
  end

  register_modifier(:posts_controller_create_user) do |user, options|
    DiscourseAcademyRoles.ensure_valid_post!(user, options) if SiteSetting.academy_roles_enabled?
    user
  end

  on(:user_created) do |user|
    DiscourseAcademyRoles.lock_member_trust_level(user) if SiteSetting.academy_roles_enabled?
  end

  add_to_serializer(:post, :academy_official_post) do
    post_custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] == true
  end

  add_to_serializer(:user, :academy_activity_level) do
    object.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i
  end

  add_to_serializer(:admin_user, :academy_activity_level) do
    object.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i
  end

  add_to_serializer(:user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end

  add_to_serializer(:current_user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end
end
