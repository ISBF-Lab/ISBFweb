# frozen_string_literal: true

module IsbfModeration
  module CreatorPermissions
    # This bypass is confined to this explicit reporting policy. Core's ordinary flag policy,
    # staff take_action and queue_for_review privileges are never changed.
    def post_can_act?
      Policy.can_report?(@created_by, @post, guardian: guardian)
    end
  end

  class SevereReport
    def initialize(user, guardian = Guardian.new(user))
      @user = user
      @guardian = guardian
    end

    def submit(post_id:, reason:, confirmed:)
      reason = validate!(post_id, reason, confirmed)
      unless SiteSetting.isbf_severe_reports_enabled && Policy.normal_user?(@user)
        raise Discourse::InvalidAccess
      end

      post = Post.find_by(id: post_id)
      unless Policy.forum_post?(post) && @guardian.can_see_topic?(post.topic)
        raise Discourse::NotFound
      end

      response = nil
      Notifications.defer do
        post.with_lock(requires_new: true) do
          reviewable = ReviewableFlaggedPost.find_by(target: post)
          reviewable&.lock!
          duplicate =
            reviewable
              &.reviewable_scores
              &.where(user_id: @user.id)
              &.any? { |score| Audit.severe?(score) }
          if duplicate && Hold.persisted?(post)
            response = response_for(post, reviewable)
            next
          end

          # Recheck category membership, deletion, hidden state and account eligibility under lock.
          raise Discourse::InvalidAccess unless Policy.can_report?(@user, post, guardian: @guardian)

          action, score = existing_report(post, reviewable)
          original_resolution = nil
          if action
            PostAction.limit_action!(@user, post, action.post_action_type_id)
            consume_daily_limit!(action)
            raise Discourse::InvalidAccess if score.blank?
            reviewable, original_resolution = reopen_report(reviewable, action, score)
          else
            result =
              creator_class.new(
                @user,
                post,
                PostActionType.types[:notify_moderators],
                reason: "isbf_severe_report",
              ).perform
            if result.failed? || result.reviewable.blank? || result.reviewable_score.blank?
              raise Discourse::InvalidAccess
            end

            reviewable = result.reviewable
            score = result.reviewable_score
            unless result.post_action.post_action_rate_limiter
              consume_daily_limit!(result.post_action)
            end
          end

          timestamp = Time.zone.now.utc.iso8601(6)
          Audit.record!(score, reason, timestamp, original_resolution: original_resolution)
          payload =
            (reviewable.payload || {}).merge(
              Hold::PENDING => true,
              Hold::LATEST => timestamp,
              Hold::SCORES => (Array(reviewable.payload&.dig(Hold::SCORES)) | [score.id]),
            )
          reviewable.update!(payload: payload, force_review: true)
          Hold.set!(post, reviewable)
          post.hide!(score.reviewable_score_type, custom_message: :isbf_severe_post_hidden)
          raise ActiveRecord::RecordInvalid.new(post) unless post.hidden?

          Notifications.publish_after_commit(post, hidden: true)
          response = response_for(post, reviewable)
        end
      end
      response
    end

    private

    def validate!(post_id, reason, confirmed)
      unless post_id.is_a?(Integer) && post_id.positive? && post_id <= 2_147_483_647
        raise Discourse::InvalidParameters.new(:post_id)
      end
      raise Discourse::InvalidParameters.new(:reason) unless reason.is_a?(String)
      normalized_reason = reason.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
      unless normalized_reason.length.between?(10, 2000)
        raise Discourse::InvalidParameters.new(:reason)
      end
      raise Discourse::InvalidParameters.new(:confirmed) unless confirmed == true
      normalized_reason
    end

    def creator_class
      # Rails can reload Core classes. Build against the current native superclass.
      Class.new(::PostActionCreator) { include CreatorPermissions }
    end

    def daily_limiter(action)
      return action.post_action_rate_limiter if action.post_action_rate_limiter

      limit = SiteSetting.max_flags_per_day
      if @user.trust_level >= 2
        multiplier =
          SiteSetting.get("tl#{@user.trust_level}_additional_flags_per_day_multiplier").to_f
        limit = (limit * [multiplier, 1.0].max).to_i
      end
      RateLimiter.new(@user, "create_flag", limit, 1.day.to_i)
    end

    def consume_daily_limit!(action)
      limiter = daily_limiter(action)
      limiter.performed!
      ActiveRecord::Base.current_transaction.after_rollback { limiter.rollback! }
    end

    def existing_report(post, reviewable)
      actions =
        PostAction
          .flags
          .where(post_id: post.id, user_id: @user.id)
          .order(created_at: :desc, id: :desc)
          .lock
          .to_a
      scores =
        (
          if reviewable
            reviewable
              .reviewable_scores
              .where(user_id: @user.id)
              .reorder(created_at: :desc, id: :desc)
              .to_a
          else
            []
          end
        )
      if active =
           actions.find { |action|
             action.agreed_at.nil? && action.disagreed_at.nil? && action.deferred_at.nil?
           }
        return [
          active,
          scores.find do |score|
            score.pending? && score.reviewable_score_type == active.post_action_type_id
          end
        ]
      end

      scores.each do |score|
        next if Audit.severe?(score)
        if action =
             actions.find { |candidate|
               candidate.post_action_type_id == score.reviewable_score_type
             }
          return action, score
        end
      end
      [nil, nil]
    end

    def reopen_report(reviewable, action, score)
      return reviewable, nil if reviewable.pending? && score.pending?

      original_resolution = {
        "reviewable_status" => reviewable.status,
        "score" => score.attributes.slice("status", "reviewed_by_id", "reviewed_at"),
        "post_action" =>
          action.attributes.slice(
            "agreed_at",
            "agreed_by_id",
            "disagreed_at",
            "disagreed_by_id",
            "deferred_at",
            "deferred_by_id",
          ),
      }
      reviewable =
        ReviewableFlaggedPost.needs_review!(
          created_by: @user,
          target: action.post,
          topic: action.post.topic,
          reviewable_by_moderator: true,
          potential_spam: false,
          potentially_illegal: false,
        )
      score.update!(status: :pending, reviewed_by_id: nil, reviewed_at: nil)
      action.update!(
        agreed_at: nil,
        agreed_by_id: nil,
        disagreed_at: nil,
        disagreed_by_id: nil,
        deferred_at: nil,
        deferred_by_id: nil,
      )
      reviewable.recalculate_score
      [reviewable, original_resolution]
    end

    def response_for(post, reviewable)
      { post_id: post.id, hidden: true, reviewable_id: reviewable.id }
    end
  end
end
