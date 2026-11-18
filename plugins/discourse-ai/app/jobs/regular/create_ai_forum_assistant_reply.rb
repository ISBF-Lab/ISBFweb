# frozen_string_literal: true

module Jobs
  class CreateAiForumAssistantReply < ::Jobs::Base
    sidekiq_options retry: false

    def execute(args)
      request = AiForumAssistantRequest.find_by(id: args[:request_id])
      return unless request&.claim!
      tracker = DiscourseAi::Completions::TokenUsageTracker.new
      execution_context =
        DiscourseAi::Completions::ExecutionContext.new(token_usage_tracker: tracker)
      cancel_manager = DiscourseAi::Completions::CancelManager.new
      cancel_manager.start_monitor(delay: 0.2) do
        !DiscourseAi::ForumAssistant::Throttle.owned?(request.user_id, request.request_uuid) ||
          !DiscourseAi::ForumAssistant::Configuration.enabled?
      end

      begin
        Timeout.timeout([request.expires_at - Time.current, 0.1].max) do
          result =
            DiscourseAi::ForumAssistant::Answer.call(
              params: {
                request_id: request.id,
              },
              execution_context: execution_context,
              cancel_manager: cancel_manager,
            )
          raise Discourse::InvalidAccess if result.failure?
        end
      rescue StandardError => error
        cancel_manager.cancel!
        unless request.reload.status == "cancelled"
          request.finish!("failed", reason: error.is_a?(Timeout::Error) ? "timeout" : "unavailable")
          DiscourseAi::ForumAssistant::Responder.new(request).publish("unavailable")
        end
        Rails.logger.warn("Forum assistant request #{request.id} failed: #{error.class}")
      ensure
        cancel_manager.stop_monitor
        begin
          request.update_columns(input_tokens: tracker.request, output_tokens: tracker.response)
        ensure
          DiscourseAi::ForumAssistant::Throttle.release(request.user_id, request.request_uuid)
        end
      end
    end
  end
end
