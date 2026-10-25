# frozen_string_literal: true

module DiscourseAcademyRoles::OfficialPostQuotaCreator
  protected

  def transaction(&create_post)
    return super unless official_quota_creation?

    super do
      # Keep native rollback handling in the original transaction, without a nested with_lock.
      quota_user = User.lock.find(@user.id)
      now = Time.current
      quota = DiscourseAcademyRoles::OfficialPostQuota
      used = quota.usage(quota_user, now: now)

      if quota.limited?(quota_user, used)
        @post.errors.add(:base, quota.error_message(quota_user, now: now))
        add_errors_from(@post)
        raise ActiveRecord::Rollback
      end

      create_post.call

      if @post.persisted? && @post.is_first_post? &&
           DiscourseAcademyRoles.official_category?(@post.topic.category_id) &&
           !SharedDraft.exists?(topic_id: @post.topic_id)
        quota.record_success!(quota_user, used: used, now: now)
      end
    end
  end

  private

  def official_quota_creation?
    return false unless SiteSetting.academy_roles_enabled? && @user&.id&.positive? && new_topic?
    return false if @opts[:shared_draft].present? && @opts[:shared_draft] != "false"

    options = @opts[:topic_opts].is_a?(Hash) ? @opts.merge(@opts[:topic_opts]) : @opts
    options[:archetype] != Archetype.private_message &&
      DiscourseAcademyRoles.official_category?(options[:category])
  end
end
