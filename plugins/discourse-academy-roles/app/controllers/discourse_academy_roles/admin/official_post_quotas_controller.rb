# frozen_string_literal: true

module DiscourseAcademyRoles::Admin
  class OfficialPostQuotasController < ::Admin::AdminController
    requires_plugin DiscourseAcademyRoles::PLUGIN_NAME

    before_action :ensure_developer

    def show
      render_json_dump(
        official_post_quota: DiscourseAcademyRoles::OfficialPostQuota.snapshot(target_user),
      )
    end

    def update
      RateLimiter.new(current_user, "academy-official-post-quota-update", 30, 1.minute).performed!
      render_json_dump(
        official_post_quota:
          DiscourseAcademyRoles::OfficialPostQuota.update_limit!(
            current_user,
            target_user,
            limit: params[:limit],
          ),
      )
    end

    private

    def ensure_developer
      raise Discourse::InvalidAccess unless current_user&.admin?
    end

    def target_user
      @target_user ||= User.find(params[:user_id])
    end
  end
end
