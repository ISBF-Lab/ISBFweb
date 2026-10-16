# frozen_string_literal: true

class CreateIsbfJoinApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :isbf_join_applications do |table|
      table.uuid :submission_id, null: false
      table.string :name, limit: 60, null: false
      table.string :student_id, limit: 40, null: false
      table.string :phone, limit: 30, null: false
      table.timestamps null: false
    end

    add_index :isbf_join_applications, :submission_id, unique: true
    add_index :isbf_join_applications, %i[created_at id], order: { created_at: :desc, id: :desc }
  end
end
