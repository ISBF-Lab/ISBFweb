# frozen_string_literal: true

class AiForumAssistantMessageSerializer < ApplicationSerializer
  attributes :id, :post_number, :role, :raw, :cooked

  def role
    object.user_id == scope.user.id ? "user" : "assistant"
  end
end
