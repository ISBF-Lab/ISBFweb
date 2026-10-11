# frozen_string_literal: true

module IsbfAnonymous
  def self.requested?(options)
    return false if options.blank?

    ActiveModel::Type::Boolean.new.cast(options[:isbf_anonymous] || options["isbf_anonymous"])
  end

  def self.master_for(shadow_user_id)
    AnonymousUser.find_by(user_id: shadow_user_id)&.master_user
  end

  def self.ensure_allowed!(user, options)
    forbidden = -> { raise Discourse::InvalidAccess.new(I18n.t("isbf_anonymous.unavailable")) }
    forbidden.call if user.blank? || user.anonymous? || !SiteSetting.allow_anonymous_mode
    if user.suspended? || !user.active? ||
         !user.in_any_groups?(SiteSetting.anonymous_posting_allowed_groups_map) ||
         (SiteSetting.must_approve_users? && !user.approved?)
      forbidden.call
    end
    forbidden.call if ActiveModel::Type::Boolean.new.cast(options[:academy_official])
    forbidden.call if options[:target_recipients].present? || options[:visible].to_s == "false"

    topic_id = options[:topic_id]
    if topic_id.present?
      topic = Topic.find_by(id: topic_id)
      forbidden.call unless topic && topic.archetype == Archetype.default
      category = topic.category
    else
      archetype = options[:archetype]
      forbidden.call if archetype.present? && archetype != Archetype.default
      category = Category.find_by(id: options[:category]) if options[:category].present?
      forbidden.call if options[:category].present? && !category
    end

    forbidden.call if category&.read_restricted?
    if SiteSetting.respond_to?(:academy_official_category) &&
         category&.id == SiteSetting.academy_official_category.to_i
      forbidden.call
    end
  end

  module Permissions
    def can_edit_post?(post)
      if !is_staff? && !(respond_to?(:academy_can?) && academy_can?(:edit_others)) &&
           post.custom_fields[IsbfAnonymous::POST_FIELD]
        return false
      end
      super
    end

    def can_delete_post?(post)
      if !is_staff? && !(respond_to?(:academy_can?) && academy_can?(:delete_others)) &&
           post.custom_fields[IsbfAnonymous::POST_FIELD]
        return false
      end
      super
    end

    def can_edit_topic?(topic)
      if !is_staff? && !(respond_to?(:academy_can?) && academy_can?(:manage_topics)) &&
           topic.first_post&.custom_fields&.dig(IsbfAnonymous::POST_FIELD)
        return false
      end
      super
    end

    def can_delete_topic?(topic)
      if !is_staff? && !(respond_to?(:academy_can?) && academy_can?(:delete_others)) &&
           topic.first_post&.custom_fields&.dig(IsbfAnonymous::POST_FIELD)
        return false
      end
      super
    end
  end

  module SessionToggle
    def toggle_anon
      return head :forbidden unless current_user&.anonymous?
      super
    end
  end
end
