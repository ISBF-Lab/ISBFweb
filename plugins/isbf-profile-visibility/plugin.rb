# frozen_string_literal: true

# name: isbf-profile-visibility
# about: Lets members choose which parts of their public profile other people can see
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

enabled_site_setting :isbf_profile_visibility_enabled

register_asset "stylesheets/common/isbf-profile-visibility.scss"

module ::IsbfProfileVisibility
  PLUGIN_NAME = "isbf-profile-visibility"
  SECTIONS = %i[bio summary activity].freeze
  FIELDS = SECTIONS.to_h { |section| [section, "isbf_hide_profile_#{section}"] }.freeze

  def self.enabled?
    SiteSetting.isbf_profile_visibility_enabled && SiteSetting.allow_users_to_hide_profile
  end

  # The owner's own choice, before deciding who is allowed to look anyway.
  def self.hidden_by_owner?(user, section)
    return false unless FIELDS.key?(section)

    value = user.custom_fields[FIELDS[section]]
    value == true || HasCustomFields::Helpers::CUSTOM_FIELD_TRUE.include?(value.to_s)
  end

  def self.choices(user)
    SECTIONS.to_h { |section| [section, hidden_by_owner?(user, section)] }
  end
end

after_initialize do
  require_relative "lib/isbf_profile_visibility/guardian_extension"
  require_relative "lib/isbf_profile_visibility/user_card_fields"
  require_relative "lib/isbf_profile_visibility/endpoints"
  require_relative "lib/isbf_profile_visibility/user_onebox"
  require_relative "lib/isbf_profile_visibility/mcp_tools"

  IsbfProfileVisibility::FIELDS.each_value do |field|
    register_user_custom_field_type(field, :boolean)
    register_editable_user_custom_field(field)
  end

  add_to_serializer(
    :user,
    :isbf_profile_visibility,
    include_condition: -> { scope.can_edit?(object) },
  ) { IsbfProfileVisibility.choices(object) }

  # Webhook payloads are built for an administrator, so a viewer-relative list means nothing there.
  add_to_serializer(
    :user,
    :isbf_hidden_profile_sections,
    include_condition: -> { !is_a?(WebHookUserSerializer) },
  ) do
    IsbfProfileVisibility::SECTIONS.select do |section|
      scope.profile_section_hidden?(object, section)
    end
  end

  reloadable_patch do
    Guardian.prepend(IsbfProfileVisibility::GuardianExtension)
    UserCardSerializer.prepend(IsbfProfileVisibility::UserCardFields)
    UsersController.prepend(IsbfProfileVisibility::SummaryEndpoint)
    ListController.include(IsbfProfileVisibility::ActivityEndpoint)
    PostsController.include(IsbfProfileVisibility::ActivityEndpoint)
    Oneboxer.singleton_class.prepend(IsbfProfileVisibility::UserOnebox)
    DiscourseMcp::Tools::GetUser.singleton_class.prepend(IsbfProfileVisibility::McpUser)
    DiscourseMcp::Tools::GetUserSummary.singleton_class.prepend(IsbfProfileVisibility::McpSummary)

    UsersController.before_action :isbf_ensure_summary_visible, only: %i[summary]
    # Symbol callbacks replace themselves on reload instead of stacking up.
    ListController.before_action :isbf_ensure_activity_visible,
                                 only: %i[topics_by user_topics_feed voted_by]
    PostsController.before_action :isbf_ensure_activity_visible, only: %i[user_posts_feed]
  end

  Discourse::Application.routes.append do
    get "u/:username/profile-private" => "users#show",
        :constraints => {
          username: RouteFormat.username,
        }
  end
end
