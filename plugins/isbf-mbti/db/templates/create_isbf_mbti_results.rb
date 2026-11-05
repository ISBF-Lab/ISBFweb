# frozen_string_literal: true

# Generated with bin/rails g plugin_migration CreateIsbfMbtiResults --plugin-name=isbf-mbti
class CreateIsbfMbtiResults < ActiveRecord::Migration[NATIVE_MIGRATION_VERSION]
  def change
    create_table :isbf_mbti_results do |table|
      table.bigint :user_id, null: false
      table.string :variant, null: false
      table.string :scoring_version, null: false
      table.string :source_commit, null: false, limit: 40
      table.string :personality_type, null: false, limit: 4
      table.jsonb :scores, null: false
      table.uuid :attempt_id, null: false
      table.string :submission_digest, null: false, limit: 64
      table.timestamps null: false
    end
    add_index :isbf_mbti_results, %i[user_id attempt_id], unique: true
    add_index :isbf_mbti_results, %i[user_id created_at id]
    add_foreign_key :isbf_mbti_results, :users, on_delete: :cascade
  end
end
