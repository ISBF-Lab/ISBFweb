# frozen_string_literal: true

class AiForumAssistantConversationSerializer < ApplicationSerializer
  attributes :id, :title, :last_posted_at, :read_only, :starred

  def title
    object.first_post&.raw.to_s.gsub(/\s+/, " ").strip.truncate(60).presence ||
      I18n.t("discourse_ai.ai_bot.default_pm_prefix")
  end

  def read_only
    object.closed || object.archived ||
      !DiscourseAi::ForumAssistant::Policy.authorized_conversation?(object, scope.user)
  end

  def include_read_only?
    @options[:detail]
  end

  def starred
    @options.fetch(:starred_ids, []).include?(object.id)
  end
end
