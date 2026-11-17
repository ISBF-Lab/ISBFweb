# frozen_string_literal: true
class CreateAiForumAssistantRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_forum_assistant_quotas do |table|
      table.integer :user_id, null: false
      table.datetime :period_start, null: false
      table.integer :used, null: false, default: 0
      table.timestamps
    end
    add_index :ai_forum_assistant_quotas, %i[period_start user_id], unique: true

    create_table :ai_forum_assistant_requests do |table|
      table.integer :user_id, null: false
      table.integer :post_id
      table.integer :reply_post_id
      table.uuid :request_uuid, null: false
      table.string :question_digest, null: false
      table.datetime :period_start, null: false
      table.datetime :expires_at, null: false
      table.string :status, null: false, default: "queued"
      table.string :reason
      table.jsonb :source_refs, null: false, default: []
      table.boolean :personal_quota_refunded, null: false, default: false
      table.integer :input_tokens, null: false, default: 0
      table.integer :output_tokens, null: false, default: 0
      table.timestamps
    end
    add_index :ai_forum_assistant_requests, :request_uuid, unique: true
    add_index :ai_forum_assistant_requests, :post_id
    add_index :ai_forum_assistant_requests, %i[user_id created_at]
    add_index :ai_forum_assistant_requests, :created_at
  end
end
