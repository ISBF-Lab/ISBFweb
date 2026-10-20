# frozen_string_literal: true

# name: isbf-notifications
# about: Groups native notifications by topic and action.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Notifications
# required_version: 3.2.0

enabled_site_setting :isbf_notifications_enabled

after_initialize do
  module ::IsbfNotifications
    BADGE_STYLE_FIELD = "isbf_notification_badge_style"
    BADGE_STYLES = %w[number dot].freeze
    FILTER_FIELD = "isbf_notification_filter"
    FILTERS = %w[all unread].freeze

    class Engine < ::Rails::Engine
      engine_name "isbf-notifications"
      isolate_namespace IsbfNotifications
    end
  end
  require_relative "lib/isbf_notifications/grouped_notifications"

  register_user_custom_field_type(IsbfNotifications::BADGE_STYLE_FIELD, :string, max_length: 6)
  register_editable_user_custom_field(IsbfNotifications::BADGE_STYLE_FIELD)
  register_user_custom_field_type(IsbfNotifications::FILTER_FIELD, :string, max_length: 6)
  register_editable_user_custom_field(IsbfNotifications::FILTER_FIELD)

  add_model_callback(:user, :validate) do
    next if custom_fields_clean?

    style = custom_fields[IsbfNotifications::BADGE_STYLE_FIELD]
    if !style.nil? && IsbfNotifications::BADGE_STYLES.exclude?(style)
      errors.add(:base, I18n.t("isbf_notifications.invalid_badge_style"))
    end

    filter = custom_fields[IsbfNotifications::FILTER_FIELD]
    if !filter.nil? && IsbfNotifications::FILTERS.exclude?(filter)
      errors.add(:base, I18n.t("isbf_notifications.invalid_filter"))
    end
  end

  add_to_serializer(:current_user, :isbf_notification_badge_style) do
    object.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD] == "dot" ? "dot" : "number"
  end

  add_to_serializer(:current_user, :isbf_notification_filter) do
    object.custom_fields[IsbfNotifications::FILTER_FIELD] == "unread" ? "unread" : "all"
  end

  class ::IsbfNotifications::GroupsController < ::ApplicationController
    requires_login
    requires_plugin "isbf-notifications"

    def index
      render json: service.groups(cursor: params[:cursor], limit: page_limit)
    end

    def show
      topic_id = Integer(params[:topic_id], exception: false)
      raise Discourse::InvalidParameters.new(:topic_id) unless topic_id&.positive?
      render json:
               service.details(
                 topic_id: topic_id,
                 action: params[:notification_action],
                 cursor: params[:cursor],
                 limit: page_limit,
               )
    end

    private

    def page_limit
      fetch_limit_from_params(default: 20, max: 50)
    end

    def service
      raise Discourse::NotFound unless SiteSetting.isbf_notifications_enabled
      guardian.ensure_can_see_notifications!(current_user)
      IsbfNotifications::GroupedNotifications.new(
        current_user,
        guardian,
        tab: params[:tab] || "all",
        filter: params[:filter] || "all",
      )
    end
  end

  IsbfNotifications::Engine.routes.draw do
    get "/groups" => "groups#index"
    get "/groups/:topic_id/actions/:notification_action" => "groups#show"
  end
  Discourse::Application.routes.append do
    mount ::IsbfNotifications::Engine, at: "/isbf/notifications"
  end
end
