# frozen_string_literal: true

class DiscourseAcademyRoles::OfficialPostQuotaPublication < ActiveSupport::CurrentAttributes
  attribute :topic_id, :author_id
end

module DiscourseAcademyRoles::OfficialPostQuotaPublisher
  def publish!
    unless SiteSetting.academy_roles_enabled? &&
             DiscourseAcademyRoles.official_category?(@category_id) &&
             SharedDraft.exists?(topic_id: @topic.id)
      return super
    end

    DiscourseAcademyRoles::OfficialPostQuotaPublication.set(
      topic_id: @topic.id,
      author_id: @topic.user_id,
    ) { super }
  end
end

module DiscourseAcademyRoles::OfficialPostQuotaTimestampChanger
  def change!(&publish_topic)
    context = DiscourseAcademyRoles::OfficialPostQuotaPublication
    return super unless context.topic_id == @topic.id && context.author_id&.positive?

    super do |topic|
      quota_user = User.lock.find(context.author_id)
      unless SharedDraft.exists?(topic_id: topic.id)
        raise Discourse::InvalidParameters,
              I18n.t("academy_roles.official_post_quota.already_published")
      end

      quota = DiscourseAcademyRoles::OfficialPostQuota
      now = Time.current
      used = quota.usage(quota_user, now: now)
      if quota.limited?(quota_user, used)
        raise Discourse::InvalidAccess, quota.error_message(quota_user, now: now)
      end

      publish_topic.call(topic)
      unless DiscourseAcademyRoles.official_category?(topic.reload.category_id) &&
               !SharedDraft.exists?(topic_id: topic.id)
        raise ActiveRecord::RecordNotSaved, "Official draft was not published"
      end

      quota.record_success!(quota_user, used: used, now: now)
    end
  end
end
