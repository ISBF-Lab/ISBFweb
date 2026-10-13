# frozen_string_literal: true
class AddOfficialActivityDetails < ActiveRecord::Migration[8.0]
  def change
    add_column :isbf_calendar_official_items, :location, :string, limit: 255, null: false, default: ""
    add_column :isbf_calendar_official_items, :organizer, :string, limit: 120, null: false, default: ""
    add_column :isbf_calendar_official_items, :registration_deadline_id, :bigint
    add_index :isbf_calendar_official_items, :registration_deadline_id
  end
end
