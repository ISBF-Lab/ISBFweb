# frozen_string_literal: true

class AiForumAssistantRequest < ActiveRecord::Base
  self.table_name = "ai_forum_assistant_requests"

  belongs_to :user
  belongs_to :post, -> { with_deleted }, optional: true
  belongs_to :reply_post, -> { with_deleted }, class_name: "Post", optional: true

  TERMINAL_STATUSES = %w[completed refused clarified not_found failed expired cancelled].freeze

  after_commit :publish_conversation_update, on: %i[create update]

  def self.admit!(user:, post:, reply_post: nil)
    configuration = DiscourseAi::ForumAssistant::Configuration
    policy = DiscourseAi::ForumAssistant::Policy
    throttle = DiscourseAi::ForumAssistant::Throttle
    policy.validate_question!(post)
    request_uuid = SecureRandom.uuid
    throttle.acquire!(user, request_uuid)
    period_start = configuration.period_start

    begin
      global_quota =
        AiForumAssistantQuota.for_period(AiForumAssistantQuota::GLOBAL_USER_ID, period_start)
      global_quota.with_lock do
        user_quota = AiForumAssistantQuota.for_period(user.id, period_start)
        user_quota.lock!
        if global_quota.used >= SiteSetting.ai_forum_assistant_global_daily_limit
          raise policy::Rejected.new(:global_limit)
        end
        if user_quota.used >= SiteSetting.ai_forum_assistant_daily_limit
          raise policy::Rejected.new(:daily_limit)
        end

        request =
          create!(
            user_id: user.id,
            post_id: post.persisted? ? post.id : nil,
            reply_post_id: reply_post&.id,
            request_uuid: request_uuid,
            question_digest: Digest::SHA256.hexdigest(post.raw),
            period_start: period_start,
            expires_at: Time.current + SiteSetting.ai_forum_assistant_timeout_seconds.seconds,
          )
        global_quota.increment!(:used)
        user_quota.increment!(:used)
        request
      end
    rescue StandardError
      throttle.release(user.id, request_uuid)
      raise
    end
  end

  def claim!
    with_lock do
      return false unless status == "queued"
      unless expires_at > Time.current &&
               DiscourseAi::ForumAssistant::Throttle.owned?(user_id, request_uuid)
        update!(status: "expired", reason: "expired")
        refund_personal_quota!
        return false
      end
      update!(status: "running")
      true
    end
  end

  def finish!(new_status, reason: nil)
    with_lock do
      return false if TERMINAL_STATUSES.include?(status)
      update!(status: new_status, reason: reason)
      refund_personal_quota! if %w[failed expired].include?(new_status)
    end
  ensure
    DiscourseAi::ForumAssistant::Throttle.release(user_id, request_uuid)
  end

  def refund_personal_quota!
    return if personal_quota_refunded
    quota = AiForumAssistantQuota.for_period(user_id, period_start)
    quota.with_lock { quota.update!(used: [quota.used - 1, 0].max) }
    update!(personal_quota_refunded: true)
  end

  private

  def publish_conversation_update
    return unless post_id
    topic_id = post&.topic_id
    return unless topic_id
    MessageBus.publish(
      "/discourse-ai/forum-assistant/user/#{user_id}",
      {
        conversation_id: topic_id,
        request: DiscourseAi::ForumAssistant::Conversations.request_json(self),
      },
      user_ids: [user_id],
    )
  end
end

# == Schema Information
#
# Table name: ai_forum_assistant_requests
#
#  id                      :bigint           not null, primary key
#  expires_at              :datetime         not null
#  input_tokens            :integer          default(0), not null
#  output_tokens           :integer          default(0), not null
#  period_start            :datetime         not null
#  personal_quota_refunded :boolean          default(FALSE), not null
#  question_digest         :string           not null
#  reason                  :string
#  request_uuid            :uuid             not null
#  source_refs             :jsonb            not null
#  status                  :string           default("queued"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  post_id                 :integer
#  reply_post_id           :integer
#  user_id                 :integer          not null
#
# Indexes
#
#  index_ai_forum_assistant_requests_on_created_at              (created_at)
#  index_ai_forum_assistant_requests_on_post_id                 (post_id)
#  index_ai_forum_assistant_requests_on_request_uuid            (request_uuid) UNIQUE
#  index_ai_forum_assistant_requests_on_user_id_and_created_at  (user_id,created_at)
#
