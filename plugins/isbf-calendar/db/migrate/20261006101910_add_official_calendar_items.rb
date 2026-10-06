# frozen_string_literal: true
class AddOfficialCalendarItems < ActiveRecord::Migration[8.0]
  def change
    create_table :isbf_calendar_official_items do |table|
      table.bigint :topic_id, null: false
      table.string :title, null: false, limit: 120
      table.string :schedule_kind, null: false, default: "event"
      table.datetime :starts_at, null: false
      table.datetime :ends_at, null: false
      table.boolean :all_day, null: false, default: false
      table.boolean :cancelled, null: false, default: false
      table.integer :revision, null: false, default: 1
      table.integer :position, null: false, default: 0
      table.timestamps
    end
    add_index :isbf_calendar_official_items,
              %i[topic_id position],
              name: "idx_isbf_calendar_items_topic"

    add_column :isbf_calendar_entries, :source_item_id, :bigint
    add_column :isbf_calendar_entries,
               :schedule_kind,
               :string,
               null: false,
               default: "event"
    add_column :isbf_calendar_entries,
               :accepted_revision,
               :integer,
               null: false,
               default: 0
    add_column :isbf_calendar_entries,
               :dismissed_revision,
               :integer,
               null: false,
               default: 0
    add_column :isbf_calendar_entries,
               :notified_revision,
               :integer,
               null: false,
               default: 0
    add_index :isbf_calendar_entries,
              %i[user_id source_item_id],
              unique: true,
              where: "source_item_id IS NOT NULL",
              name: "idx_isbf_calendar_entries_source_user"
    add_index :isbf_calendar_entries, :source_item_id
  end
end
