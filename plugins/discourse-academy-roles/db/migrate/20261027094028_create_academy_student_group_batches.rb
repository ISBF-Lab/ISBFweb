# frozen_string_literal: true

class CreateAcademyStudentGroupBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :academy_student_group_batches do |t|
      t.bigint :actor_id, null: false
      t.bigint :source_batch_id
      t.string :mode, null: false
      t.string :input_kind, null: false
      t.string :state, null: false, default: "preview"
      t.jsonb :plan, null: false, default: {}
      t.integer :duplicate_count, null: false, default: 0
      t.integer :version, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :confirmed_at
      t.datetime :finished_at
      t.timestamps
    end
    add_index :academy_student_group_batches, :actor_id
    add_index :academy_student_group_batches, :source_batch_id
    add_index :academy_student_group_batches,
              %i[state updated_at],
              name: "idx_academy_group_batches_pending"

    create_table :academy_student_group_batch_items do |t|
      t.bigint :batch_id, null: false
      t.bigint :registration_id
      t.bigint :user_id
      t.bigint :source_item_id
      t.integer :position, null: false
      t.string :student_number, null: false, limit: 64
      t.string :username, null: false, default: ""
      t.string :status, null: false, default: "ready"
      t.string :reason_code, null: false, default: ""
      t.boolean :selected, null: false, default: false
      t.boolean :display_restored, null: false, default: false
      t.jsonb :before_snapshot, null: false, default: {}
      t.jsonb :after_snapshot, null: false, default: {}
      t.jsonb :steps, null: false, default: []
      t.timestamps
    end
    add_index :academy_student_group_batch_items,
              %i[batch_id position],
              unique: true,
              name: "idx_academy_group_items_position"
    add_index :academy_student_group_batch_items,
              %i[batch_id selected status],
              name: "idx_academy_group_items_pending"
    add_index :academy_student_group_batch_items, :user_id
    add_index :academy_student_group_batch_items, :source_item_id
  end
end
