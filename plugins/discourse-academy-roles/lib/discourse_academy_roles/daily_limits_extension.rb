# frozen_string_literal: true

module DiscourseAcademyRoles::TopicDailyLimitsExtension
  def limit_topics_per_day
    return if SiteSetting.academy_roles_enabled? && user.present?

    super
  end

  def limit_private_messages_per_day
    return if SiteSetting.academy_roles_enabled? && user.present?

    super
  end
end

module DiscourseAcademyRoles::PostDailyLimitsExtension
  def limit_posts_per_day
    return if SiteSetting.academy_roles_enabled? && user.present?

    super
  end
end

module DiscourseAcademyRoles::PostActionDailyLimitsExtension
  def post_action_rate_limiter
    return if SiteSetting.academy_roles_enabled? && is_flag? && user.present?

    super
  end
end

module DiscourseAcademyRoles::NewMemberPostingExtension
  def posted_too_much_in_topic?(topic_id)
    return false if SiteSetting.academy_roles_enabled?

    super
  end
end
