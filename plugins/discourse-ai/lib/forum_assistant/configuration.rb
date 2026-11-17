# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Configuration
      MAX_HISTORY_QUESTIONS = 2
      MAX_SOURCE_COUNT = 8
      MAX_SOURCE_CHARACTERS = 12_000
      CLASSIFICATION_TOKENS = 512
      MAX_FALLBACK_SEARCHES = 3

      def self.enforced?
        SiteSetting.ai_forum_assistant_restrict_members || SiteSetting.ai_forum_assistant_enabled
      end

      def self.restricted?(user)
        enforced? && user.present? && !user.admin?
      end

      def self.agent
        AiAgent.find_by(id: SiteSetting.ai_forum_assistant_agent.to_i, enabled: true)
      end

      def self.model
        model_id =
          SiteSetting.ai_forum_assistant_model.presence || agent&.default_llm_id.presence ||
            SiteSetting.ai_default_llm_model.presence
        LlmModel.find_by(id: model_id.to_s.split(":").last.to_i) if model_id.present?
      end

      def self.bot_user
        agent&.user || model&.user
      end

      def self.deepseek?
        model&.provider == "open_ai" && model.url.start_with?("https://api.deepseek.com/")
      end

      def self.completion_options
        deepseek? ? { extra_model_params: { thinking: { type: "disabled" } } } : {}
      end

      def self.enabled?
        SiteSetting.discourse_ai_enabled && SiteSetting.ai_bot_enabled &&
          SiteSetting.ai_forum_assistant_enabled
      end

      def self.available?
        enabled? && agent.present? && model.present? && bot_user&.active?
      end

      def self.allowed_user?(user)
        user.present? && user.id.positive? && user.active? && !user.suspended? && !user.silenced? &&
          (!SiteSetting.must_approve_users? || user.approved?)
      end

      def self.period_start(time = Time.current)
        time.in_time_zone(SiteSetting.ai_forum_assistant_timezone).beginning_of_day.utc
      end

      def self.resets_at(time = Time.current)
        time.in_time_zone(SiteSetting.ai_forum_assistant_timezone).tomorrow.beginning_of_day.utc
      end

      def self.agent_option
        return unless available?
        {
          id: agent.id,
          name: agent.name,
          description: I18n.t("discourse_ai.forum_assistant.scope"),
          username: bot_user.username,
          force_default_llm: true,
          allow_personal_messages: true,
        }
      end

      def self.bot_option
        return unless available?
        {
          "id" => bot_user.id,
          "username" => bot_user.username,
          "has_default_llm" => true,
          "force_default_llm" => true,
          "is_agent" => true,
        }
      end
    end
  end
end
