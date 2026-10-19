# frozen_string_literal: true

class AddWpsSharingToIsbfResume < ActiveRecord::Migration[8.1]
  def change
    add_column :isbf_resume_shared_resumes, :download_url, :text, null: false, default: ""
    add_column :isbf_resume_shared_resumes, :contributor, :text, null: false, default: ""
    add_column :isbf_resume_shared_resumes, :student_number, :text, null: false, default: ""
    add_column :isbf_resume_shared_resumes, :contributor_user_id, :integer
    add_index :isbf_resume_shared_resumes, :contributor_user_id
  end
end
