# frozen_string_literal: true

module IsbfModeration
  module AiReview
    KEY = "isbf_ai_moderation"

    def self.apply!(post, result, fingerprint:, model_id:)
      reviewable =
        ReviewableFlaggedPost.needs_review!(
          target: post,
          topic: post.topic,
          target_created_by: post.user,
          created_by: Discourse.system_user,
          reviewable_by_moderator: true,
          potential_spam: false,
        )
      reviewable.lock!
      details =
        result.merge(
          "fingerprint" => fingerprint,
          "model_id" => model_id,
          "rules_version" => AiClassifier::RULES_VERSION,
          "scanned_at" => Time.current.utc.iso8601(6),
        )
      reviewable.add_score(
        Discourse.system_user,
        PostActionType.types[:notify_moderators],
        reason: "isbf_ai_moderation",
        context: { KEY => details }.to_json,
        force_review: true,
      )
      reviewable.update!(
        payload: (reviewable.payload || {}).merge(KEY => details),
        reviewable_by_moderator: true,
        force_review: true,
      )
      Hold.set!(post, reviewable)
      post.hide!(PostActionType.types[:notify_moderators], custom_message: :isbf_ai_post_hidden)
      raise ActiveRecord::RecordInvalid.new(post) unless post.hidden?
      Notifications.publish_after_commit(post, hidden: true)
    end

    def self.details(score)
      return unless score.reason == KEY
      JSON.parse(score.context.to_s)[KEY]
    rescue JSON::ParserError
      nil
    end
  end
end
