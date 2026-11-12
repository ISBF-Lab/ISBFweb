# frozen_string_literal: true

# name: discourse-academy-roles
# about: Closed academy membership and official publishing
# version: 0.2.0
# authors: Discourse

require_relative "app/validators/academy_roles_enabled_validator"

enabled_site_setting :academy_roles_enabled
add_admin_route "academy_roles.admin.title", "discourse-academy-roles", use_new_show_route: true

register_asset "stylesheets/common/academy-roles.scss"
register_asset "stylesheets/common/academy-auth.scss"
register_asset "stylesheets/common/academy-official-post-quota.scss"
register_svg_icon "pause"
register_svg_icon "play"

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

    module StudentGroups
    end

    module StudentInvites
      module Action
      end
    end
  end

  %w[
    app/models/discourse_academy_roles/student_registration
    lib/discourse_academy_roles/student_groups
    app/models/discourse_academy_roles/student_group_batch
    app/models/discourse_academy_roles/student_group_batch_item
    lib/discourse_academy_roles/student_groups/input
    lib/discourse_academy_roles/student_groups/groups
    lib/discourse_academy_roles/student_groups/snapshot
    lib/discourse_academy_roles/student_groups/preview
    lib/discourse_academy_roles/student_groups/confirmation
    lib/discourse_academy_roles/student_groups/runner
    app/jobs/regular/academy_student_group_batch
    app/jobs/scheduled/recover_academy_student_group_batches
    app/services/discourse_academy_roles/student_groups/create_preview
    app/services/discourse_academy_roles/student_groups/confirm_batch
    app/serializers/discourse_academy_roles/student_group_batch_serializer
    app/serializers/discourse_academy_roles/student_group_batch_item_serializer
    app/controllers/discourse_academy_roles/admin/student_group_batches_controller
    lib/discourse_academy_roles/student_invite_csv
    app/services/discourse_academy_roles/student_invite_contract
    app/services/discourse_academy_roles/create_student_invite
    app/services/discourse_academy_roles/student_invites/action/issue_batch
    app/services/discourse_academy_roles/bulk_create_student_invites
    app/services/discourse_academy_roles/reissue_student_invite
    app/services/discourse_academy_roles/revoke_student_invite
    app/services/discourse_academy_roles/set_initial_password
    app/services/discourse_academy_roles/dismiss_password_setup
    app/serializers/discourse_academy_roles/student_registration_serializer
    app/serializers/discourse_academy_roles/student_invite_batch_serializer
    app/controllers/discourse_academy_roles/admin/student_invites_controller
    app/controllers/discourse_academy_roles/admin/moderator_permissions_controller
    app/controllers/discourse_academy_roles/admin/official_post_quotas_controller
    app/controllers/discourse_academy_roles/password_setup_controller
  ].each { |path| require_relative path }

  DiscourseAcademyRoles::Engine.routes.draw do
    resource :password_setup,
             path: "password-setup",
             controller: "password_setup",
             only: %i[update destroy]

    namespace :admin do
      get "activity-levels" => "activity_levels#show"
      put "activity-levels" => "activity_levels#update"
      get "activity-levels/recalculation" => "activity_levels#status"
      get "activity-levels/deletion-impact" => "activity_levels#deletion_impact"
      post "activity-levels/recalculate" => "activity_levels#recalculate"
      resources :student_group_batches, path: "student-group-batches", only: %i[index show] do
        get :options, on: :collection
        post :preview, on: :collection
        post :execute, on: :member
        post :retry, on: :member
        post "undo-preview", action: :undo_preview, on: :member
        get :download, on: :member
      end
      get "moderator-permissions" => "moderator_permissions#index"
      get "users/:user_id/official-post-quota" => "official_post_quotas#show"
      put "users/:user_id/official-post-quota" => "official_post_quotas#update"
      resources :student_invites, path: "student-invites", only: %i[index create destroy] do
        post :reissue, on: :member
        post :bulk, on: :collection
      end
    end
  end

  Discourse::Application.routes.append do
    get "/admin/plugins/discourse-academy-roles/moderator-permissions" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-invites" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-invites/new" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-invites/bulk" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-group-batches" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/student-group-batches/:batch_id" =>
          "admin/plugins#index",
        :constraints => AdminConstraint.new
    get "/admin/plugins/discourse-academy-roles/activity-levels" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    mount ::DiscourseAcademyRoles::Engine, at: "/academy-roles"
  end

  require_relative "lib/discourse_academy_roles"
  require_relative "lib/discourse_academy_roles/guardian_extension"
  require_relative "lib/discourse_academy_roles/password_setup"
  require_relative "lib/discourse_academy_roles/name_color"
  require_relative "lib/discourse_academy_roles/topic_category_extension"
  require_relative "lib/discourse_academy_roles/daily_limits_extension"
  require_relative "lib/discourse_academy_roles/official_post_quota"
  require_relative "lib/discourse_academy_roles/official_post_quota_creator"
  require_relative "lib/discourse_academy_roles/official_post_quota_publisher"
  require_relative "lib/discourse_academy_roles/activity_levels"
  BadgeGranter.prepend(DiscourseAcademyRoles::ActivityLevels::LevelBadges::ManualGrant)
  require_relative "app/jobs/regular/academy_recalculate_activity_levels"
  require_relative "app/jobs/scheduled/academy_activity_levels"
  require_relative "lib/discourse_academy_roles/activity_level"
  require_relative "app/services/discourse_academy_roles/activity_levels/save_configuration"
  require_relative "app/services/discourse_academy_roles/activity_levels/retry_recalculation"
  require_relative "app/serializers/discourse_academy_roles/activity_level_recalculation_serializer"
  require_relative "app/serializers/discourse_academy_roles/activity_level_configuration_serializer"
  require_relative "app/controllers/discourse_academy_roles/admin/activity_levels_controller"
  require_relative "lib/discourse_academy_roles/student_invite_extension"
  require_relative "lib/discourse_academy_roles/moderator_permissions"
  require_relative "lib/discourse_academy_roles/moderator_user"
  require_relative "lib/discourse_academy_roles/moderator_categories"
  require_relative "lib/discourse_academy_roles/moderator_groups"
  require_relative "lib/discourse_academy_roles/moderator_topics"
  require_relative "lib/discourse_academy_roles/moderator_guardian"
  require_relative "lib/discourse_academy_roles/moderator_reviews"
  require_relative "lib/discourse_academy_roles/moderator_controllers"
  require_relative "lib/discourse_academy_roles/moderator_client_permissions"
  require_relative "lib/discourse_academy_roles/moderator_post_destroyer"

  Rails.application.config.filter_parameters += %i[student_numbers prefix]

  register_post_custom_field_type(DiscourseAcademyRoles::OFFICIAL_POST_FIELD, :boolean)
  TopicView.default_post_custom_fields << DiscourseAcademyRoles::OFFICIAL_POST_FIELD
  register_user_custom_field_type(DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD, :integer)
  register_user_custom_field_type(DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD, :string)
  register_user_custom_field_type(DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD, :boolean)

  add_model_callback(:user_password, :after_commit, on: :create) do
    DiscourseAcademyRoles::PasswordSetup.complete_for(user)
  end
  register_user_custom_field_type(DiscourseAcademyRoles::NameColor::ENABLED_FIELD, :boolean)
  register_user_custom_field_type(
    DiscourseAcademyRoles::NameColor::COLOR_FIELD,
    :string,
    max_length: 128,
  )
  DiscourseAcademyRoles::NameColor::FIELDS.each do |field|
    register_editable_user_custom_field(field)
  end

  add_model_callback(:user, :validate) do
    DiscourseAcademyRoles::NameColor.validate(self) if SiteSetting.academy_roles_enabled?
  end

  TopicView.on_preload do |view|
    DiscourseAcademyRoles::NameColor.preload(view.posts.map(&:user).compact)
  end
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
    if SiteSetting.academy_roles_enabled? && (email.present? || domain.present?) &&
         !(defined?(IsbfAlumni::Registration) && IsbfAlumni::Registration.bound_invite?(self))
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
    UserLookup.prepend(DiscourseAcademyRoles::NameColor::UserLookupPreloader)
    UserUpdater.prepend(DiscourseAcademyRoles::NameColor::UserUpdaterExtension)
    User.prepend(DiscourseAcademyRoles::ModeratorUser)
    Guardian.prepend(DiscourseAcademyRoles::ModeratorGuardian)
    Category.singleton_class.prepend(DiscourseAcademyRoles::ModeratorCategories)
    Group.singleton_class.prepend(DiscourseAcademyRoles::ModeratorGroups)
    Topic.singleton_class.prepend(DiscourseAcademyRoles::ModeratorTopics)
    Reviewable.singleton_class.prepend(DiscourseAcademyRoles::ModeratorReviewScope)
    Reviewable.prepend(DiscourseAcademyRoles::ModeratorReview)
    Reviewable::Actions.prepend(DiscourseAcademyRoles::ModeratorReviewActions)
    ReviewableActionBuilder.prepend(DiscourseAcademyRoles::ModeratorReviewActionBuilder)
    ReviewableFlaggedPost.prepend(DiscourseAcademyRoles::ModeratorFlaggedReview)
    PostDestroyer.prepend(DiscourseAcademyRoles::ModeratorPostDestroyer)
    ApplicationController.prepend(DiscourseAcademyRoles::ModeratorControllers)
    Admin::UsersController.prepend(DiscourseAcademyRoles::ModeratorUserController)
    Admin::UsersController.before_action :academy_check_ordinary_target
    UsersController.prepend(DiscourseAcademyRoles::ModeratorProfileController)
    UsersController.before_action :academy_check_credentials_target,
                                  only: %i[remove_password revoke_account revoke_auth_token]
    CurrentUserSerializer.prepend(DiscourseAcademyRoles::ModeratorCurrentUserSerializer)
    UserSerializer.prepend(DiscourseAcademyRoles::ModeratorUserSerializer)
    ApplicationHelper.prepend(DiscourseAcademyRoles::ModeratorApplicationHelper)
    StaffConstraint.prepend(DiscourseAcademyRoles::ModeratorStaffConstraint)
    AdminConstraint.prepend(DiscourseAcademyRoles::ModeratorAdminConstraint)
    Topic.prepend(DiscourseAcademyRoles::TopicCategoryExtension)
    Topic.prepend(DiscourseAcademyRoles::TopicDailyLimitsExtension)
    PostCreator.prepend(DiscourseAcademyRoles::OfficialPostQuotaCreator)
    TopicPublisher.prepend(DiscourseAcademyRoles::OfficialPostQuotaPublisher)
    TopicTimestampChanger.prepend(DiscourseAcademyRoles::OfficialPostQuotaTimestampChanger)
    Post.prepend(DiscourseAcademyRoles::PostDailyLimitsExtension)
    PostAction.prepend(DiscourseAcademyRoles::PostActionDailyLimitsExtension)
    User.prepend(DiscourseAcademyRoles::NewMemberPostingExtension)
    Invite.prepend(DiscourseAcademyRoles::StudentInviteExtension)
    InviteRedeemer.prepend(DiscourseAcademyRoles::StudentInviteRedeemerExtension)
    InvitesController.prepend(DiscourseAcademyRoles::StudentInvitesControllerExtension)
    UserMerger.prepend(DiscourseAcademyRoles::StudentUserMergerExtension)
  end

  InvitesController.before_action only: %i[create create_multiple upload_csv] do
    if SiteSetting.academy_roles_enabled?
      render_json_error(
        I18n.t("academy_roles.student_invites.use_student_invite"),
        status: :bad_request,
      )
    end
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
    if SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles.lock_member_trust_level(user)
      DiscourseAcademyRoles::ActivityLevels.initialize_user(user)
    end
    DiscourseAcademyRoles::PasswordSetup.mark_for(user)
  end

  add_to_serializer(:post, :academy_official_post) do
    post_custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] == true
  end

  add_to_serializer(:user, :academy_activity_level) do
    DiscourseAcademyRoles::ActivityLevels.level_number(object)
  end

  add_to_serializer(:admin_user, :academy_activity_level) do
    DiscourseAcademyRoles::ActivityLevels.level_number(object)
  end

  %i[user admin_user].each do |serializer|
    add_to_serializer(serializer, :academy_activity_level_name) do
      DiscourseAcademyRoles::ActivityLevels.level_name(object)
    end
  end

  add_to_serializer(
    :admin_detailed_user,
    :academy_student_number,
    include_condition: -> { scope&.is_admin? },
  ) { DiscourseAcademyRoles::StudentRegistration.find_by(user_id: object.id)&.student_number }

  add_to_serializer(:user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end

  add_to_serializer(:user, :academy_can_see_staff_info) { !!scope&.can_see_staff_info?(object) }

  add_to_serializer(:current_user, :academy_official_member) do
    DiscourseAcademyRoles.official_member?(object)
  end

  add_to_serializer(:current_user, :academy_password_setup_pending) do
    DiscourseAcademyRoles::PasswordSetup.pending?(object) &&
      !!scope.can_setup_academy_password?(object)
  end

  add_to_serializer(:current_user, :academy_moderator_role) { object[:moderator] }

  add_to_serializer(:basic_user, :academy_display_name_color) do
    DiscourseAcademyRoles::NameColor.effective_color(user)
  end

  add_to_serializer(:site, :academy_activity_name_colors) do
    DiscourseAcademyRoles::ActivityLevels::Cosmetics.name_colors
  end

  add_to_serializer(:site, :academy_activity_levels) do
    DiscourseAcademyRoles::ActivityLevels::Cosmetics
      .configuration
      .levels
      .each_with_index
      .map { |level, number| { id: level["id"], number: number, name: level["name"] } }
  end

  %i[user current_user].each do |serializer|
    own_preferences = -> { scope.user&.id == object.id }
    add_to_serializer(
      serializer,
      :academy_activity_cosmetics,
      include_condition: own_preferences,
    ) { DiscourseAcademyRoles::ActivityLevels::Cosmetics.capabilities(object) }
    add_to_serializer(
      serializer,
      :academy_name_color_preferences,
      include_condition: own_preferences,
    ) { DiscourseAcademyRoles::NameColor.preferences(object) }
    add_to_serializer(
      serializer,
      :academy_can_wear_name_color,
      include_condition: own_preferences,
    ) { scope.can_wear_academy_name_color?(object) }
    add_to_serializer(
      serializer,
      :academy_can_customize_name_color,
      include_condition: own_preferences,
    ) { scope.can_customize_academy_name_color?(object) }
  end

  add_to_serializer(:current_user, :academy_moderator_permissions) do
    DiscourseAcademyRoles::ModeratorPermissions.for(object)
  end

  on(:site_setting_changed) do |name, _previous, _value|
    if DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.value?(name.to_sym)
      Discourse.request_refresh!
    end
  end
end
