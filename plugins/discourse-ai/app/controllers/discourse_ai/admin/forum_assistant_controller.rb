# frozen_string_literal: true

module DiscourseAi
  module Admin
    class ForumAssistantController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        page = params[:page].to_i.clamp(0, 10_000)
        requests = AiForumAssistantRequest.includes(:user).order(id: :desc)
        if params[:username].present?
          user = User.find_by(username_lower: params[:username].to_s.downcase.first(60))
          requests = requests.where(user_id: user&.id)
        end
        rows = requests.offset(page * 50).limit(51).to_a
        render json: {
                 requests: serialize_data(rows.first(50), AiForumAssistantRequestSerializer),
                 has_more: rows.length > 50,
                 global_used: AiForumAssistantQuota.used_by(AiForumAssistantQuota::GLOBAL_USER_ID),
                 global_limit: SiteSetting.ai_forum_assistant_global_daily_limit,
               }
      end

      def clear_cooldown
        user = User.find(params.require(:user_id))
        DiscourseAi::ForumAssistant::Throttle.clear_cooldown(user.id)
        StaffActionLogger.new(current_user).log_custom(
          "forum_assistant_clear_cooldown",
          user_id: user.id,
        )
        head :no_content
      end
    end
  end
end
