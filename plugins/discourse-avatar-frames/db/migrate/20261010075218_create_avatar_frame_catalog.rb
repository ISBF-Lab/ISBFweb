# frozen_string_literal: true

class CreateAvatarFrameCatalog < ActiveRecord::Migration[8.0]
  def change
    create_table :discourse_avatar_frames_frames do |table|
      table.string :key, null: false, limit: 64
      table.string :name, null: false, default: "", limit: 100
      table.string :description, null: false, default: "", limit: 500
      table.string :access_mode, null: false, default: "granted", limit: 16
      table.string :builtin, null: false, default: "", limit: 64
      table.boolean :enabled, null: false, default: true
      table.integer :position, null: false, default: 0
      table.bigint :image_upload_id
      table.bigint :static_upload_id
      table.timestamps
    end
    add_index :discourse_avatar_frames_frames, :key, unique: true
    create_table :discourse_avatar_frames_grants do |table|
      table.bigint :frame_id, null: false
      table.bigint :user_id, null: false
      table.bigint :granted_by_id, null: false
      table.datetime :granted_at, null: false
      table.bigint :notification_id
      table.timestamps
    end
    add_index :discourse_avatar_frames_grants,
              %i[frame_id user_id],
              unique: true,
              name: "index_avatar_frame_grants_on_frame_and_user"
    add_index :discourse_avatar_frames_grants, :user_id
    create_table :discourse_avatar_frames_imports do |table|
      table.bigint :frame_id, null: false
      table.bigint :created_by_id, null: false
      table.string :status, null: false, default: "queued", limit: 16
      table.jsonb :user_ids, null: false, default: []
      table.jsonb :unmatched_entries, null: false, default: []
      table.jsonb :failures, null: false, default: []
      table.integer :matched_count, null: false, default: 0
      table.integer :unmatched_count, null: false, default: 0
      table.integer :duplicate_count, null: false, default: 0
      table.integer :processed_count, null: false, default: 0
      table.integer :granted_count, null: false, default: 0
      table.integer :skipped_count, null: false, default: 0
      table.integer :failed_count, null: false, default: 0
      table.timestamps
    end
    add_index :discourse_avatar_frames_imports, :frame_id
  end
end
