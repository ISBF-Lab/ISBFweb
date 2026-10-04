# frozen_string_literal: true

class CreateAcademyStudentRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_student_registrations do |t|
      t.string :student_number, limit: 64, null: false
      t.bigint :invite_id, null: false
      t.bigint :issued_by_id, null: false
      t.bigint :user_id
      t.datetime :registered_at
      t.timestamps null: false
    end

    add_index :academy_student_registrations, :student_number, unique: true
    add_index :academy_student_registrations, :invite_id, unique: true
    add_index :academy_student_registrations,
              :user_id,
              unique: true,
              where: "user_id IS NOT NULL"
  end
end
