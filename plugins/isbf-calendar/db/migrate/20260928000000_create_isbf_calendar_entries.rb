# frozen_string_literal: true

class CreateIsbfCalendarEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :isbf_calendar_entries do |t|
      t.bigint :user_id, null: false
      t.string :title, null: false, limit: 120
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, null: false, default: false
      t.text :note
      t.timestamps
    end

    add_index :isbf_calendar_entries,
              %i[user_id starts_at],
              name: "idx_isbf_calendar_user_start"
    add_foreign_key :isbf_calendar_entries,
                    :users,
                    column: :user_id,
                    on_delete: :cascade
  end
end
