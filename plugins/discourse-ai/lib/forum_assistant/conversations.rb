# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    module Conversations
      PAGE_SIZE = 40

      def self.for_user(user)
        topics = Topic.private_messages_for_user(user).where(user_id: user.id)
        return topics.none unless Configuration.enforced?

        agent_topics =
          TopicCustomField.where(
            name: "ai_agent_id",
            value: SiteSetting.ai_forum_assistant_agent.to_s,
          ).select(:topic_id)
        bot_topics = TopicAllowedUser.where(user_id: Configuration.bot_user&.id).select(:topic_id)
        assigned_topics = TopicCustomField.where(name: "ai_agent_id").select(:topic_id)

        topics.where(id: agent_topics).or(
          topics.where(id: bot_topics).where.not(id: assigned_topics),
        )
      end

      def self.find!(user, id)
        topic = for_user(user).find_by(id: id)
        raise Discourse::NotFound unless topic && user.guardian.can_see?(topic)
        topic
      end

      def self.request_for(topic, user)
        AiForumAssistantRequest
          .where(user_id: user.id, post_id: topic.posts.select(:id))
          .order(id: :desc)
          .first
      end

      def self.request_json(request)
        return unless request
        status = request.status
        if %w[queued running].include?(status) && request.expires_at <= Time.current
          status = "expired"
        end
        {
          id: request.id,
          post_id: request.post_id,
          reply_post_id: request.reply_post_id,
          status: status,
          expires_at: request.expires_at,
        }
      end
    end
  end
end
