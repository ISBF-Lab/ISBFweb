# frozen_string_literal: true

# name: discourse-academy-roles
# about: Closed academy membership and official publishing
# version: 0.2.0
# authors: Discourse

require_relative "app/validators/academy_roles_enabled_validator"

enabled_site_setting :academy_roles_enabled
add_admin_route "academy_roles.student_invites.title",
                "discourse-academy-roles",
                use_new_show_route: true

register_asset "stylesheets/common/academy-roles.scss"

module ::DiscourseAcademyRoles
  PLUGIN_NAME = "discourse-academy-roles"
  OFFICIAL_POST_FIELD = "academy_official_post"
  ACTIVITY_LEVEL_FIELD = "academy_activity_level"
  LV3_SINCE_FIELD = "academy_lv3_since"
  LV3_CHECKED_AT_FIELD = "academy_lv3_checked_at"
end

after_initialize do
  module ::DiscourseAcademyRoles
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseAcademyRoles
    end

    module Admin
    end

    module StudentInvites
      module Action
      end
    end
  end

  %w[
    app/models/discourse_academy_roles/student_registration
    lib/discourse_academy_roles/student_invite_csv
    app/services/discourse_academy_roles/student_invite_contract
    app/services/discourse_academy_roles/create_student_invite
    app/services/discourse_academy_roles/student_invites/action/issue_batch
    app/services/discourse_academy_roles/bulk_create_student_invites
    app/services/discourse_academy_roles/reissue_student_invite
    app/services/discourse_academy_roles/revoke_student_invite
    app/serializers/discourse_academy_roles/student_registration_serializer
    app/serializers/discourse_academy_roles/student_invite_batch_serializer
    app/controllers/discourse_academy_roles/admin/student_invites_controller
  ].each { |path| require_relative path }

  DiscourseAcademyRoles::Engine.routes.draw do
    namespace :admin do
      resources :student_invites,
                path: "student-invites",
                only: %i[index create destroy] do
        post :reissue, on: :member
        post :bulk, on: :collection
      end
    end
  end

  Discourse::Application.routes.append do
    get "/admin/plugins/discourse-academy-roles/student-invites" =>
          "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-invites/new" =>
          "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-invites/bulk" =>
          "admin/plugins#index",
        :constraints => AdminConstraint.new
    mount ::DiscourseAcademyRoles::Engine, at: "/academy-roles"
  end

  require_relative "lib/discourse_academy_roles"
  require_relative "lib/discourse_academy_roles/guardian_extension"
  require_relative "lib/discourse_academy_roles/topic_category_extension"
  require_relative "lib/discourse_academy_roles/daily_limits_extension"
  require_relative "lib/discourse_academy_roles/activity_level"
  require_relative "lib/discourse_academy_roles/student_invite_extension"

  register_post_custom_field_type(
    DiscourseAcademyRoles::OFFICIAL_POST_FIELD,
    :boolean
  )
  TopicView.default_post_custom_fields << DiscourseAcademyRoles::OFFICIAL_POST_FIELD
  register_user_custom_field_type(
    DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD,
    :integer
  )
  register_user_custom_field_type(
    DiscourseAcademyRoles::LV3_SINCE_FIELD,
    :string,
    max_length: 40
  )
  register_user_custom_field_type(
    DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD,
    :string,
    max_length: 40
  )
  add_permitted_post_create_param :academy_official, :string
  NewPostManager.add_plugin_payload_attribute(:academy_official)

  Invite.validate do
    if SiteSetting.academy_roles_enabled? && max_redemptions_allowed != 1
      errors.add(
        :max_redemptions_allowed,
        I18n.t("academy_roles.single_use_invite")
      )
    end
    if SiteSetting.academy_roles_enabled? && (email.present? || domain.present?)
      errors.add(:email, I18n.t("academy_roles.unbound_invite"))
    end
  end

  Topic.validate do
    unless SiteSetting.academy_roles_enabled? && persisted? &&
             will_save_change_to_category_id?
      next
    end

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
    Invite.prepend(DiscourseAcademyRoles::StudentInviteExtension)
    InviteRedeemer.prepend(
      DiscourseAcademyRoles::StudentInviteRedeemerExtension
    )
    InvitesController.prepend(
      DiscourseAcademyRoles::StudentInvitesControllerExtension
    )
    UserMerger.prepend(DiscourseAcademyRoles::StudentUserMergerExtension)
  end

  InvitesController.before_action only: %i[create create_multiple upload_csv] do
    if SiteSetting.academy_roles_enabled?
      render_json_error(
        I18n.t("academy_roles.student_invites.use_student_invite"),
        status: :bad_request
      )
    end
  end

  on(:before_create_post) do |post, options|
    if SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles.validate_post(post, options)
    end
  end

  on(:post_created) do |post, options|
    if SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles.mark_official_post(post, options)
    end
  end

  register_modifier(:posts_controller_create_user) do |user, options|
    if SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles.ensure_valid_post!(user, options)
    end
    user
  end

  on(:user_created) do |user|
    if SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles.lock_member_trust_level(user)
    end
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

  add_to_serializer(
    :admin_detailed_user,
    :academy_student_number,
    include_condition: -> { scope&.is_admin? }
  ) do
    DiscourseAcademyRoles::StudentRegistration.find_by(
      user_id: object.id
    )&.student_number
  end

  add_to_serializer(:user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end

  add_to_serializer(:current_user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end
end
