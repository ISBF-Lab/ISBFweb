# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Answer
      include Service::Base

      params do
        attribute :request_id, :integer
        validates :request_id, presence: true
      end

      model :request
      policy :authorized_conversation
      model :decision
      policy :request_active
      step :record_decision
      only_if(:out_of_scope?) { step :record_violation }
      only_if(:allowed?) do
        model :evidence
        only_if(:has_evidence?) { step :stream_answer }
        only_if(:no_evidence?) { step :report_not_found }
      end
      only_if(:out_of_scope?) { step :refuse_question }
      only_if(:ambiguous?) { step :clarify_question }

      private

      def fetch_request(params:)
        AiForumAssistantRequest.includes(:user, post: :topic, reply_post: :topic).find_by(
          id: params.request_id,
          status: "running",
        )
      end

      def authorized_conversation(request:)
        request.post && !request.post.deleted_at && request.post.user_id == request.user_id &&
          Digest::SHA256.hexdigest(request.post.raw) == request.question_digest &&
          Policy.authorized_conversation?(request.post.topic, request.user)
      end

      def fetch_decision(request:, execution_context:, cancel_manager:)
        QuestionClassifier.call(
          post: request.post,
          user: request.user,
          request_id: request.id,
          execution_context: execution_context,
          cancel_manager: cancel_manager,
        )
      end

      def request_active(request:)
        request.reload.status == "running" &&
          Throttle.owned?(request.user_id, request.request_uuid) && Configuration.available?
      end

      def record_decision(request:, decision:)
        request.update!(reason: decision.reason)
      end

      def out_of_scope?(decision:)
        decision.action == "deny"
      end

      def allowed?(decision:)
        decision.action == "allow"
      end

      def ambiguous?(decision:)
        decision.action == "clarify"
      end

      def record_violation(request:)
        Throttle.record_violation(request.user_id, request.request_uuid)
      end

      def fetch_evidence(request:, decision:)
        Evidence.new(user: request.user, decision: decision).retrieve
      end

      def has_evidence?(evidence:)
        evidence.sources.present?
      end

      def no_evidence?(evidence:)
        evidence.sources.empty?
      end

      def stream_answer(request:, evidence:, decision:, execution_context:, cancel_manager:)
        request.update!(source_refs: evidence.references)
        Responder.new(request).stream(
          evidence: evidence,
          decision: decision,
          execution_context: execution_context,
          cancel_manager: cancel_manager,
        )
        request.finish!("completed")
      end

      def report_not_found(request:)
        Responder.new(request).publish("not_found")
        request.finish!("not_found", reason: "no_sources")
      end

      def refuse_question(request:, decision:)
        Responder.new(request).publish("refused")
        request.finish!("refused", reason: decision.reason)
      end

      def clarify_question(request:)
        Responder.new(request).publish("clarify")
        request.finish!("clarified", reason: "ambiguous")
      end
    end
  end
end
