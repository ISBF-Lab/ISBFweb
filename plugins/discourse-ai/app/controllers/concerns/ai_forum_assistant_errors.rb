# frozen_string_literal: true

module AiForumAssistantErrors
  extend ActiveSupport::Concern

  included do
    rescue_from DiscourseAi::ForumAssistant::Policy::Rejected do |error|
      status =
        case error.reason
        when "unavailable"
          :service_unavailable
        when "daily_limit", "global_limit", "cooldown", "busy"
          :too_many_requests
        else
          :unprocessable_entity
        end
      render_json_error(error.message, status: status)
    end
  end
end
