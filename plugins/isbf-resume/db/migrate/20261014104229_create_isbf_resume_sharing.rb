# frozen_string_literal: true

class CreateIsbfResumeSharing < ActiveRecord::Migration[8.0]
  def change
    create_table :isbf_resume_shared_resumes do |t|
      t.integer :user_id, null: false
      t.string :storage_key, null: false
      t.string :file_sha256, limit: 64, null: false
      t.bigint :file_bytes, null: false
      t.integer :pages, null: false
      t.string :status, null: false, default: "pending"
      t.text :title, null: false, default: ""
      t.text :industry, null: false, default: ""
      t.text :position, null: false, default: ""
      t.text :salary, null: false, default: ""
      t.text :experience, null: false, default: ""
      t.text :submitted_description, null: false, default: ""
      t.text :description, null: false, default: ""
      t.text :uploader_name, null: false, default: ""
      t.text :uploader_username, null: false, default: ""
      t.integer :lock_version, null: false, default: 0
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :isbf_resume_shared_resumes, :storage_key, unique: true
    add_index :isbf_resume_shared_resumes,
              %i[status reviewed_at id],
              name: "isbf_resume_shares_published"
    add_index :isbf_resume_shared_resumes,
              %i[status created_at id],
              name: "isbf_resume_shares_queue"
    add_index :isbf_resume_shared_resumes,
              %i[user_id created_at id],
              name: "isbf_resume_shares_owner"

    create_table :isbf_resume_share_reviews do |t|
      t.bigint :shared_resume_id, null: false
      t.integer :reviewer_id, null: false
      t.text :reviewer_name, null: false
      t.text :reviewer_username, null: false
      t.string :decision, null: false
      t.text :original_description, null: false, default: ""
      t.text :previous_description, null: false, default: ""
      t.text :description, null: false, default: ""
      t.timestamps
    end

    add_index :isbf_resume_share_reviews,
              %i[shared_resume_id id],
              name: "isbf_resume_review_history"
  end
end
