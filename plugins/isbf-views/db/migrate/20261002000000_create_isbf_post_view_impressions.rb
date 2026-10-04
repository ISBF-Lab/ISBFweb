# frozen_string_literal: true

class CreateIsbfPostViewImpressions < ActiveRecord::Migration[7.0]
  def change
    create_table :isbf_post_view_impressions do |table|
      table.bigint :post_id, null: false
      table.bigint :user_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :isbf_post_view_impressions, %i[post_id user_id], unique: true
    add_index :isbf_post_view_impressions, :user_id
  end
end
