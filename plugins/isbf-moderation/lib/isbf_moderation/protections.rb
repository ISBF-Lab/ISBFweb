# frozen_string_literal: true

module IsbfModeration
  module GuardianProtection
    def can_see_post?(post)
      return false if !is_staff? && Hold.active?(post)
      super
    end

    def can_see_hidden_post?(post)
      return false if !is_staff? && Hold.active?(post)
      super
    end

    def can_unhide?(post)
      return false if Hold.active?(post)
      super
    end

    def filter_hidden_posts(records, **options)
      filtered = super
      return filtered if is_staff?
      filtered.where(<<~SQL)
        NOT EXISTS (
          SELECT 1 FROM post_custom_fields isbf_hold
          WHERE isbf_hold.post_id = posts.id AND isbf_hold.name = '#{Hold::FIELD}'
        )
      SQL
    end
  end

  module PostProtection
    def unhide!
      with_lock do
        return false if Hold.persisted?(self)
        super
      end
    end

    def publish_change_to_clients!(type, options = {})
      return super unless Notifications.deferred?

      post_id = id
      captured_options = options.deep_dup
      ActiveRecord.after_all_transactions_commit do
        Notifications.immediate do
          Post.with_deleted.find_by(id: post_id)&.publish_change_to_clients!(type, captured_options)
        end
      end
    end

    def publish_message!(channel, message, options = {})
      return super unless Notifications.deferred?

      post_id = id
      captured_message = message.deep_dup
      captured_options = options.deep_dup
      ActiveRecord.after_all_transactions_commit do
        Notifications.immediate do
          Post
            .with_deleted
            .find_by(id: post_id)
            &.publish_message!(channel, captured_message, captured_options)
        end
      end
    end
  end

  module RevisionProtection
    def remove_flags_and_unhide_post
      return if Hold.persisted?(@post)
      super
    end
  end

  module WithdrawalProtection
    def perform
      if Hold.active?(@post)
        score =
          @post.reviewable_flag&.reviewable_scores&.pending&.find_by(
            user_id: @destroyed_by.id,
            reviewable_score_type: @post_action_type_id,
          )
        if score && Audit.severe?(score)
          result = PostActionDestroyer::DestroyResult.new
          result.forbidden = true
          result.add_error(I18n.t("isbf_moderation.review_required"))
          return result
        end
      end
      super
    end
  end

  module ReviewProtection
    def build_actions(actions, guardian, args)
      return if Hold.persisted?(post) && !Policy.staff_reviewer?(guardian.user, post)
      super
    end

    def build_editable_fields(fields, guardian, args)
      return if Hold.persisted?(post) && !Policy.staff_reviewer?(guardian.user, post)
      super
    end

    def perform(performed_by, action_id, args = nil)
      return super unless Hold.persisted?(post)
      raise Discourse::InvalidAccess unless Policy.staff_reviewer?(performed_by, post)

      result = nil
      Notifications.defer do
        post.with_lock(requires_new: true) do
          @isbf_severe_reviewer_id = performed_by.id
          result = super
          raise ActiveRecord::Rollback unless result&.success?
          if result&.success? && !pending? && payload[Hold::PENDING]
            update!(payload: payload.merge(Hold::PENDING => false))
          end
        ensure
          @isbf_severe_reviewer_id = nil
        end
      end
      result
    end

    def perform_disagree(performed_by, args)
      held = Hold.persisted?(post)
      if held
        unless @isbf_severe_reviewer_id == performed_by.id &&
                 Policy.staff_reviewer?(performed_by, post)
          raise Discourse::InvalidAccess
        end
        Hold.clear!(post)
        update!(payload: payload.merge(Hold::PENDING => false))
      end

      result = super
      if held && result.success? && !post.trashed? && !post.hidden?
        Notifications.publish_after_commit(post, hidden: false)
      end
      result
    end

    private

    # Core's restore message contains the original raw body. Do not enqueue it until
    # the validated restore transaction has committed successfully.
    def notify_poster(performed_by)
      return super unless Notifications.deferred?

      reviewable_id = id
      reviewer_id = performed_by.id
      ActiveRecord.after_all_transactions_commit do
        Notifications.immediate do
          reviewable = ReviewableFlaggedPost.find_by(id: reviewable_id)
          reviewer = User.find_by(id: reviewer_id)
          reviewable.send(:notify_poster, reviewer) if reviewable && reviewer
        end
      end
    end
  end
end
