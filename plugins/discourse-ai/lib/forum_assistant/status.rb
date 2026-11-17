# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Status
      def initialize(user)
        @user = user
      end

      def as_json(*)
        available = Configuration.available? && Configuration.allowed_user?(@user)
        used = available ? AiForumAssistantQuota.used_by(@user.id) : 0
        global_used =
          available ? AiForumAssistantQuota.used_by(AiForumAssistantQuota::GLOBAL_USER_ID) : 0
        blocked_until = Throttle.blocked_until(@user.id)
        busy = Throttle.active?(@user.id)
        {
          enabled: Configuration.enabled?,
          configured: Configuration.available?,
          restricted: Configuration.restricted?(@user),
          can_ask:
            available && !blocked_until && !busy &&
              used < SiteSetting.ai_forum_assistant_daily_limit &&
              global_used < SiteSetting.ai_forum_assistant_global_daily_limit,
          remaining_today: [SiteSetting.ai_forum_assistant_daily_limit - used, 0].max,
          daily_limit: SiteSetting.ai_forum_assistant_daily_limit,
          resets_at: Configuration.resets_at.iso8601,
          blocked_until: blocked_until&.iso8601,
          busy: busy,
          active_conversation_id:
            (
              if busy
                AiForumAssistantRequest
                  .joins(:post)
                  .where(user_id: @user.id, status: %w[queued running])
                  .where("ai_forum_assistant_requests.expires_at > ?", Time.current)
                  .order(id: :desc)
                  .pick("posts.topic_id")
              else
                nil
              end
            ),
          global_limit_reached: global_used >= SiteSetting.ai_forum_assistant_global_daily_limit,
          entry_url: "/discourse-ai/ai-bot/conversations",
          agent: available ? Configuration.agent_option : nil,
        }
      end
    end
  end
end
