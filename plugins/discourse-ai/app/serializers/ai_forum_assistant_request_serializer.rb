# frozen_string_literal: true

class AiForumAssistantRequestSerializer < ApplicationSerializer
  attributes :id,
             :user_id,
             :username,
             :post_id,
             :reply_post_id,
             :status,
             :reason,
             :source_refs,
             :created_at,
             :personal_quota_refunded,
             :input_tokens,
             :output_tokens

  def username
    object.user&.username
  end
end
