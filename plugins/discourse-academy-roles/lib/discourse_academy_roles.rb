# frozen_string_literal: true

module DiscourseAcademyRoles
  def self.official_category?(category)
    category_id = category.is_a?(Category) ? category.id : category.to_i
    official_id = SiteSetting.academy_official_category.to_i
    official_id.positive? && category_id == official_id
  end

  def self.official_group?(group)
    group && group.id == SiteSetting.academy_official_group.to_i
  end

  def self.official_member?(user)
    return false if user.blank?
    return true if user.admin?
    if ModeratorPermissions.restricted?(user) &&
         ModeratorPermissions.allowed?(user, :publish_official)
      return true
    end

    group_id = SiteSetting.academy_official_group.to_i
    group_id.positive? && user.group_users.exists?(group_id: group_id)
  end

  def self.valid_topic_category?(topic, category_id)
    first_post = Post.find_by(topic_id: topic.id, post_number: 1)
    official_post = first_post&.custom_fields&.dig(OFFICIAL_POST_FIELD)
    official_category?(category_id) == (official_post == true)
  end

  def self.lock_member_trust_level(user)
    return if user.staged? || user.is_system_user?

    if user.trust_level != 0 || user.manual_locked_trust_level != 0
      user.update_columns(trust_level: 0, manual_locked_trust_level: 0)
      Group.user_trust_level_change!(user.id, 0)
    end

    return if user.custom_fields.key?(ACTIVITY_LEVEL_FIELD)

    user.custom_fields[ACTIVITY_LEVEL_FIELD] = 0
    user.save_custom_fields
  end

  def self.validate_post(post, options)
    official = ActiveModel::Type::Boolean.new.cast(options[:academy_official])
    return if options[:topic_id].present? && !official

    category_id =
      if options[:topic_id].present?
        Topic.where(id: options[:topic_id]).pick(:category_id)
      else
        options[:category]
      end
    official_category = official_category?(category_id)
    is_private_message =
      options[:archetype] == Archetype.private_message || post.topic&.private_message?

    if official
      if is_private_message || !official_category
        post.errors.add(:base, I18n.t("academy_roles.official_outside_category"))
      elsif !official_member?(post.user)
        post.errors.add(:base, I18n.t("academy_roles.official_membership_required"))
      else
        post.custom_fields[OFFICIAL_POST_FIELD] = true
      end
    elsif official_category && options[:topic_id].blank? && !is_private_message
      post.errors.add(:base, I18n.t("academy_roles.official_required"))
    end
  end

  def self.mark_official_post(post, options)
    return unless ActiveModel::Type::Boolean.new.cast(options[:academy_official])
    return unless official_category?(post.topic&.category_id)

    post.custom_fields[OFFICIAL_POST_FIELD] = true
    post.save_custom_fields
  end

  def self.ensure_valid_post!(user, options)
    post = Post.new(user: user)
    validate_post(post, options)
    raise Discourse::InvalidAccess.new(post.errors.full_messages.to_sentence) if post.errors.any?
  end
end
