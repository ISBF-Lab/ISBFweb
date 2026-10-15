# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorGuardian
  def academy_restricted_moderator?
    DiscourseAcademyRoles::ModeratorPermissions.restricted?(user)
  end

  def academy_can?(permission)
    DiscourseAcademyRoles::ModeratorPermissions.allowed?(user, permission)
  end

  def academy_has_management_permissions?
    DiscourseAcademyRoles::ModeratorPermissions.for(user).values.any?
  end

  def is_staff?
    academy_restricted_moderator? ? !!@academy_permission_context : super
  end

  def is_moderator?
    academy_restricted_moderator? ? !!@academy_permission_context : super
  end

  def is_category_group_moderator?(category)
    academy_restricted_moderator? ? false : super
  end

  def can_see_review_queue?
    return super unless academy_restricted_moderator?
    academy_can?(:review) || academy_can?(:review_resources) || academy_can?(:review_resumes)
  end

  def secure_category_ids
    academy_restricted_moderator? ? user.secure_category_ids : super
  end

  def allowed_category_ids
    academy_restricted_moderator? ?
      Category.where(read_restricted: false).pluck(:id) + secure_category_ids :
      super
  end

  def can_create_post?(topic)
    @can_create_post = {} if academy_restricted_moderator?
    super
  end

  def can_review_post?(post)
    return super unless academy_restricted_moderator?
    return false if post&.user_deleted? && !academy_can?(:hidden_content)
    post &&
      academy_can?(
        (
          if DiscourseAcademyRoles::ModeratorPermissions.resource?(post.topic)
            :review_resources
          else
            :review
          end
        ),
      ) && can_see_post?(post)
  end

  def can_review_topic?(topic)
    return super unless academy_restricted_moderator?
    topic &&
      academy_can?(
        DiscourseAcademyRoles::ModeratorPermissions.resource?(topic) ? :review_resources : :review,
      ) && can_see_topic?(topic)
  end

  def reviewable_post_scope
    return super unless academy_restricted_moderator?
    return Post.none unless can_see_review_queue?
    records =
      Post
        .with_deleted
        .secured(self)
        .where(topic_id: visible_topic_scope(Topic.with_deleted).select(:id))
    if academy_can?(:hidden_content)
      records
    else
      records.where(deleted_at: nil, hidden: false, user_deleted: false)
    end
  end

  def visible_topic_scope(scope, deleted: :visible)
    if academy_restricted_moderator? && academy_can?(:hidden_content) && deleted == :visible
      deleted = :include
    end
    super
  end

  def can_see_all_hidden_posts?(category = nil)
    academy_restricted_moderator? ? academy_can?(:hidden_content) : super
  end

  def can_see_deleted_post?(post)
    return super unless academy_restricted_moderator?
    post && post.trashed? && academy_can?(:hidden_content) &&
      can_see_topic?(post.topic || Topic.with_deleted.find_by(id: post.topic_id), false)
  end

  def can_see_deleted_posts?(category = nil)
    academy_restricted_moderator? ? academy_can?(:hidden_content) : super
  end

  def can_see_deleted_topics?(category)
    academy_restricted_moderator? ?
      academy_can?(:hidden_content) && can_see_category?(category) :
      super
  end

  def can_see_deleted_posts_for_user?
    academy_restricted_moderator? ?
      academy_can?(:hidden_content) && academy_can?(:user_admin) :
      super
  end

  def can_see_topic?(topic, hide_deleted = true)
    return super unless academy_restricted_moderator? && topic&.private_message?
    return false if hide_deleted && topic.deleted_at && !academy_can?(:hidden_content)
    topic.allowed_users.where(id: user.id).exists? ||
      topic
        .allowed_groups
        .where(id: DiscourseAcademyRoles::ModeratorPermissions.group_ids(user, internal: true))
        .exists?
  end

  def private_message_topic_scope(scope)
    return super unless academy_restricted_moderator?
    groups = DiscourseAcademyRoles::ModeratorPermissions.group_ids(user, internal: true)
    scope.where(id: TopicAllowedUser.where(user_id: user.id).select(:topic_id)).or(
      scope.where(id: TopicAllowedGroup.where(group_id: groups).select(:topic_id)),
    )
  end

  def can_create_group?
    return super unless academy_restricted_moderator?
    academy_can?(:manage_groups)
  end

  def can_see_groups?(groups)
    if academy_restricted_moderator? && academy_can?(:manage_groups) && groups.present? &&
         groups.none?(&:automatic?)
      return with_academy_permission { super }
    end
    super
  end

  def can_see_group_members?(group)
    if academy_restricted_moderator? && academy_can?(:manage_groups) && group && !group.automatic?
      return with_academy_permission { super }
    end
    super
  end

  def can_admin_group?(group)
    return super unless academy_restricted_moderator?
    group && !group.automatic? && academy_can?(:manage_groups) && can_see_group?(group)
  end

  def can_edit_group?(group)
    return super unless academy_restricted_moderator?
    group && !group.automatic? &&
      (
        academy_can?(:manage_groups) ||
          group.group_users.where(user_id: user.id, owner: true).exists?
      )
  end

  def can_create_category?(parent = nil)
    return super unless academy_restricted_moderator?
    academy_can?(:manage_categories) && (!parent || can_see_category?(parent))
  end

  def can_edit_category?(category)
    return super unless academy_restricted_moderator?
    academy_can?(:manage_categories) && can_see_category?(category)
  end

  def can_edit_serialized_category?(category_id:, read_restricted:)
    return super unless academy_restricted_moderator?
    academy_can?(:manage_categories) &&
      can_see_serialized_category?(category_id: category_id, read_restricted: read_restricted)
  end

  def can_delete_all_posts_and_topics?
    academy_restricted_moderator? ? academy_can?(:delete_others) : super
  end

  def can_create_whisper?
    return super unless academy_restricted_moderator?
    user.academy_non_role_whisperer?
  end

  def is_in_edit_post_groups?
    academy_restricted_moderator? ? academy_can?(:edit_others) : super
  end

  def is_in_edit_topic_groups?
    academy_restricted_moderator? ? academy_can?(:manage_topics) : super
  end

  def can_edit_post?(post)
    return super unless academy_restricted_moderator?
    return false unless post && can_see_post?(post)
    if post.is_first_post? && DiscourseAcademyRoles::ModeratorPermissions.resource?(post.topic)
      return academy_can?(:manage_resources)
    end
    academy_can?(:edit_others) ? with_academy_permission { super } : super
  end

  def can_edit_topic?(topic)
    return super unless academy_restricted_moderator?
    return false unless can_see_topic?(topic)
    if DiscourseAcademyRoles::ModeratorPermissions.resource?(topic)
      return academy_can?(:manage_resources)
    end
    academy_can?(:manage_topics) ? with_academy_permission { super } : super
  end

  def can_delete_post?(post)
    return super unless academy_restricted_moderator?
    return false unless post && can_see_post?(post)
    super
  end

  def can_delete_topic?(topic)
    return super unless academy_restricted_moderator?
    return false unless can_see_topic?(topic)
    if DiscourseAcademyRoles::ModeratorPermissions.resource?(topic)
      return academy_can?(:manage_resources) && !topic.trashed? && !topic.is_category_topic?
    end
    super
  end

  def can_recover_post?(post)
    return super unless academy_restricted_moderator?
    topic = post&.topic || (post && Topic.with_deleted.find_by(id: post.topic_id))
    return false unless topic && can_see_topic?(topic, false)
    if post.is_first_post? && DiscourseAcademyRoles::ModeratorPermissions.resource?(topic)
      return academy_can?(:manage_resources)
    end
    return super if is_my_own?(post) && !post.deleted_at
    academy_can?(:delete_others) && !!post.deleted_at
  end

  def can_recover_topic?(topic)
    return super unless academy_restricted_moderator?
    return false unless topic && can_see_topic?(topic, false)
    permission =
      (
        if DiscourseAcademyRoles::ModeratorPermissions.resource?(topic)
          :manage_resources
        else
          :delete_others
        end
      )
    academy_can?(permission) && !!topic.deleted_at
  end

  def can_moderate_topic?(topic)
    return super unless academy_restricted_moderator?
    topic && academy_can?(:manage_topics) && can_see_topic?(topic)
  end

  def can_move_topic_to_category?(category)
    return super unless academy_restricted_moderator?
    if DiscourseAcademyRoles::ModeratorPermissions.resource?(
         Category.find_by(id: category.is_a?(Category) ? category.id : category),
       )
      return academy_can?(:manage_resources)
    end
    category = Category.find_by(id: category) unless category.is_a?(Category)
    return false unless can_see_category?(category)
    if category.id == SiteSetting.academy_activity_category.to_i &&
         !academy_can?(:publish_activities)
      return false
    end
    academy_can?(:manage_topics) ? with_academy_permission { super } : super
  end

  def can_see_group_messages?(group)
    return super unless academy_restricted_moderator?
    if group && DiscourseAcademyRoles::ModeratorPermissions::ROLE_GROUP_IDS.include?(group.id)
      return academy_can?(:internal_boards)
    end
    super
  end

  def can_see_emails?
    academy_restricted_moderator? ? academy_can?(:view_emails) : super
  end

  def can_check_emails?(target)
    academy_restricted_moderator? ? target.present? && academy_can?(:view_emails) : super
  end

  def can_see_staff_info?(target)
    academy_restricted_moderator? ? target.present? && academy_can?(:user_admin) : super
  end

  def can_see_ip?
    academy_restricted_moderator? ? false : super
  end

  %i[can_suspend? can_unsuspend?].each do |method|
    define_method(method) do |target|
      return super(target) unless academy_restricted_moderator?
      academy_can?(:suspend_users) &&
        DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
        with_academy_permission { super(target) }
    end
  end

  %i[can_silence_user? can_unsilence_user?].each do |method|
    define_method(method) do |target|
      return super(target) unless academy_restricted_moderator?
      academy_can?(:silence_users) &&
        DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
        with_academy_permission { super(target) }
    end
  end

  %i[
    can_edit_user?
    can_edit_username?
    can_edit_name?
    can_grant_title?
    can_change_primary_group?
  ].each do |method|
    define_method(method) do |target, *args|
      return super(target, *args) unless academy_restricted_moderator? && !is_me?(target)
      academy_can?(:edit_users) &&
        DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
        with_academy_permission { super(target, *args) }
    end
  end

  def can_edit_email?(target)
    return super unless academy_restricted_moderator? && !is_me?(target)
    false
  end

  def can_delete_user?(target)
    return super unless academy_restricted_moderator? && !is_me?(target)
    academy_can?(:delete_users) &&
      DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
      with_academy_permission { super }
  end

  def can_delete_all_posts?(target)
    return super unless academy_restricted_moderator?
    academy_can?(:delete_others) &&
      DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
      with_academy_permission { super }
  end

  def can_anonymize_user?(target)
    return super unless academy_restricted_moderator?
    academy_can?(:anonymize_users) &&
      DiscourseAcademyRoles::ModeratorPermissions.ordinary_account?(target) &&
      with_academy_permission { super }
  end

  {
    can_lock_post?: :edit_others,
    can_unhide?: :review,
    can_move_posts?: :manage_topics,
    can_archive_topic?: :manage_topics,
    can_close_topic?: :manage_topics,
    can_open_topic?: :manage_topics,
    can_split_merge_topic?: :manage_topics,
    can_pin_unpin_topic?: :manage_topics,
    can_toggle_topic_visibility?: :manage_topics,
    can_convert_topic?: :manage_topics,
    can_banner_topic?: :manage_topics,
    can_change_archetype?: :manage_topics,
    can_set_topic_timer?: :manage_topics,
    can_update_bumped_at?: :manage_topics,
    can_change_post_timestamps?: :edit_others,
    can_change_post_type?: :edit_others,
  }.each do |method, permission|
    define_method(method) do |*args, **kwargs|
      return super(*args, **kwargs) unless academy_restricted_moderator?
      resource = args.first
      return false if resource.is_a?(Topic) && !can_see_topic?(resource)
      return false if resource.is_a?(Post) && !can_see_post?(resource)
      if (resource.is_a?(Topic) || resource.is_a?(Post)) &&
           DiscourseAcademyRoles::ModeratorPermissions.resource?(
             resource.is_a?(Post) ? resource.topic : resource,
           ) && !academy_can?(:manage_resources)
        return false
      end
      academy_can?(permission) && with_academy_permission { super(*args, **kwargs) }
    end
  end

  private

  def can_see_post_topic?(post)
    academy_restricted_moderator? ? !!post.topic && can_see_topic?(post.topic) : super
  end

  def secure_category_ids_set
    academy_restricted_moderator? ? secure_category_ids.to_set : super
  end

  def with_academy_permission
    previous = @academy_permission_context
    @academy_permission_context = true
    yield
  ensure
    @academy_permission_context = previous
  end
end
