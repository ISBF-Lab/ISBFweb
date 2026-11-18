# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Policy
      class Rejected < StandardError
        attr_reader :reason

        def initialize(reason)
          @reason = reason.to_s
          super(I18n.t("discourse_ai.forum_assistant.errors.#{@reason}"))
        end
      end

      def self.ai_topic?(topic)
        return false unless topic&.private_message?
        topic.custom_fields[DiscourseAi::AiBot::TOPIC_AI_BOT_PM_FIELD].present? ||
          topic.custom_fields["ai_agent_id"].present? ||
          topic
            .topic_allowed_users
            .where(user_id: DiscourseAi::AiBot::EntryPoint.all_bot_ids)
            .exists?
      end

      def self.managed_topic?(topic)
        return false unless Configuration.enforced?
        return false unless topic&.private_message?
        agent_id = topic.custom_fields["ai_agent_id"]
        return agent_id.to_i == SiteSetting.ai_forum_assistant_agent.to_i if agent_id.present?
        bot_user = Configuration.bot_user
        bot_user && topic.topic_allowed_users.where(user_id: bot_user.id).exists?
      end

      def self.applies_to_post?(post)
        return false unless post.user_id&.positive? && ai_topic?(post.topic)
        Configuration.restricted?(post.user) ||
          (Configuration.enabled? && managed_topic?(post.topic))
      end

      def self.pending_question?(options)
        return false unless Configuration.available?
        unless options[:archetype] == Archetype.private_message &&
                 options[:private_message_context] == DiscourseAi::AiBot::PERSONAL_MESSAGE_CONTEXT
          return false
        end
        fields =
          (
            options.dig(:topic_opts, :custom_fields) || options[:custom_fields] || {}
          ).with_indifferent_access
        return false unless fields[:ai_agent_id].to_i == Configuration.agent.id
        names = options[:target_usernames].to_s.split(",").map(&:downcase)
        ids = Array(options[:target_user_ids]).map(&:to_i)
        names == [Configuration.bot_user.username_lower] || ids == [Configuration.bot_user.id]
      end

      def self.authorized_conversation?(topic, user)
        return false unless Configuration.available? && Configuration.allowed_user?(user)
        return false unless managed_topic?(topic) && topic.user_id == user.id
        return false unless user.guardian.can_see?(topic)
        return false if topic.topic_allowed_groups.exists?
        topic.topic_allowed_users.pluck(:user_id).sort == [user.id, Configuration.bot_user.id].sort
      end

      def self.validate_question!(post)
        raise Rejected.new(:unavailable) unless Configuration.available?
        unless authorized_conversation?(post.topic, post.user) &&
                 post.post_type == Post.types[:regular]
          raise Rejected.new(:private_conversation_required)
        end
        raw = post.raw.to_s
        if raw.blank? || raw.length > SiteSetting.ai_forum_assistant_max_question_chars
          raise Rejected.new(:question_length)
        end
        if raw.match?(%r{(?:upload://|/uploads/|/isbf/learning/files/)}i)
          raise Rejected.new(:attachments_disabled)
        end
      end

      def self.ensure_interactive_access!(user)
        if Configuration.restricted?(user)
          raise Discourse::InvalidAccess.new(
                  I18n.t("discourse_ai.forum_assistant.errors.forum_only"),
                )
        end
      end

      def self.ensure_target!(user, agent_id:, target_user:)
        return unless Configuration.restricted?(user)
        raise Rejected.new(:unavailable) unless Configuration.available?
        unless agent_id.to_i == Configuration.agent.id &&
                 target_user&.id == Configuration.bot_user.id
          raise Rejected.new(:forum_only)
        end
      end
    end
  end
end
