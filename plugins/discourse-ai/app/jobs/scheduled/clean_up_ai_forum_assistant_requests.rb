# frozen_string_literal: true

module Jobs
  class CleanUpAiForumAssistantRequests < ::Jobs::Scheduled
    every 1.minute

    def execute(args)
      AiForumAssistantRequest
        .where(status: %w[queued running])
        .where("expires_at <= ?", Time.current)
        .find_each { |request| request.finish!("expired", reason: "timeout") }
      cutoff = SiteSetting.ai_forum_assistant_log_retention_days.days.ago
      AiForumAssistantRequest.where("created_at < ?", cutoff).delete_all
      AiForumAssistantQuota.where("period_start < ?", cutoff).delete_all
    end
  end
end
