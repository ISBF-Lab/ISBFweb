# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorReviewScope
  def viewable_by(user, order: nil, preload: true)
    permissions = DiscourseAcademyRoles::ModeratorPermissions
    return super unless permissions.restricted?(user)
    guardian = user.guardian
    return none unless guardian.can_see_review_queue?

    resource_id = permissions.learning_category_id
    allowed_types = %w[ReviewableFlaggedPost ReviewableQueuedPost ReviewableUser ReviewablePost]
    content =
      where(type: allowed_types, reviewable_by_moderator: true).where.not(category_id: resource_id)
    content =
      content.or(where(type: allowed_types, reviewable_by_moderator: true, category_id: nil))
    content = content.none unless guardian.academy_can?(:review)
    resources =
      where(
        category_id: resource_id,
        type: %w[
          ReviewableQueuedPost
          ReviewableIsbfLearningCourse
          ReviewableFlaggedPost
          ReviewablePost
        ],
      )
    resources = resources.none unless guardian.academy_can?(:review_resources)
    resumes = where(type: "ReviewableIsbfResume", reviewable_by_moderator: true, category_id: nil)
    unless guardian.respond_to?(:can_review_isbf_resumes?) && guardian.can_review_isbf_resumes?
      resumes = resumes.none
    end
    alumni = where(type: "ReviewableIsbfAlumni", reviewable_by_moderator: true, category_id: nil)
    alumni = alumni.none unless guardian.academy_can?(:review_alumni)
    result =
      content
        .or(resources)
        .or(resumes)
        .or(alumni)
        .where(
          "reviewables.category_id IS NULL OR reviewables.category_id IN (?)",
          guardian.allowed_category_ids,
        )
    result = exclude_private_messages_hidden_from(result, user)
    visible_posts = guardian.reviewable_post_scope
    result =
      result.where(
        "reviewables.target_type IS DISTINCT FROM 'Post' OR reviewables.target_id IN (?)",
        visible_posts.select(:id),
      )
    ordinary_accounts = User.where(admin: false, moderator: false).where("users.id > 0")
    result =
      result.where(
        "reviewables.target_type IS DISTINCT FROM 'User' OR reviewables.target_id IN (?)",
        ordinary_accounts.select(:id),
      )
    result = result.order(order || "reviewables.score desc, reviewables.created_at desc")
    if preload
      result =
        result.includes(
          :topic,
          :target,
          :target_created_by,
          :reviewable_histories,
          reviewable_scores: :user,
          reviewable_notes: :user,
        )
    end
    result
  end
end

module DiscourseAcademyRoles::ModeratorReview
  def actions_for(guardian, args = nil)
    return super unless guardian.academy_restricted_moderator?
    return Reviewable::Actions.new(self, guardian) unless can_review_target?(guardian)
    guardian.send(:with_academy_permission) { super }
  end

  def editable_for(guardian, args = nil)
    return super unless guardian.academy_restricted_moderator?
    permission = DiscourseAcademyRoles::ModeratorPermissions.review_edit_permission(self)
    unless can_review_target?(guardian) && guardian.academy_can?(permission)
      return Reviewable::EditableFields.new(self, guardian, args)
    end
    guardian.send(:with_academy_permission) { super }
  end

  def update_fields(params, performed_by, version: nil)
    if DiscourseAcademyRoles::ModeratorPermissions.restricted?(performed_by) && params.present?
      permission = DiscourseAcademyRoles::ModeratorPermissions.review_edit_permission(self)
      raise Discourse::InvalidAccess unless performed_by.guardian.academy_can?(permission)
    end
    super
  end

  def perform(performed_by, action_id, args = nil)
    unless DiscourseAcademyRoles::ModeratorPermissions.review_action_allowed?(
             performed_by,
             self,
             action_id,
           )
      raise Discourse::InvalidAccess
    end
    super
  end

  private

  def can_review_target?(guardian)
    return super unless guardian.academy_restricted_moderator?
    if target_type == "User" &&
         !DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target)
      return false
    end
    permission = DiscourseAcademyRoles::ModeratorPermissions.review_permission(self)
    guardian.academy_can?(permission) && (!category || guardian.can_see_category?(category)) &&
      (target_type != "Post" || guardian.can_review_post?(target_post))
  end
end

module DiscourseAcademyRoles::ModeratorReviewActions
  def add(action_id, **options, &block)
    unless DiscourseAcademyRoles::ModeratorPermissions.review_action_allowed?(
             @guardian.user,
             reviewable,
             action_id,
           )
      return
    end
    super
  end
end

module DiscourseAcademyRoles::ModeratorReviewActionBuilder
  def build_penalty_actions(actions, bundle:, silence:, suspend:, user: target_user)
    return super unless guardian.academy_restricted_moderator?
    return if user.blank?

    if !user.silenced? && guardian.can_silence_user?(user)
      build_action(actions, silence, icon: "microphone-slash", bundle:, client_action: "silence")
    end
    if !user.suspended? && guardian.can_suspend?(user)
      build_action(actions, suspend, icon: "ban", bundle:, client_action: "suspend")
    end
  end
end

module DiscourseAcademyRoles::ModeratorFlaggedReview
  def build_combined_actions(actions, guardian, args)
    super
    return unless guardian.academy_restricted_moderator? && post.hidden? && !post.trashed?
    return if actions.has?(:disagree_and_restore)

    build_action(actions, :disagree_and_restore, icon: "far-eye")
  end

  def penalty_effect_for(action_id)
    effect = super
    if effect == :lifts_penalty && guardian&.academy_restricted_moderator? &&
         !guardian.can_unsilence_user?(target_created_by)
      :retains_penalty
    else
      effect
    end
  end
end
