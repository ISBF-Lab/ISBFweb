# frozen_string_literal: true

class CreateIsbfReposts < ActiveRecord::Migration[7.0]
  def change
    create_table :isbf_reposts do |table|
      table.bigint :source_topic_id, null: false
      table.bigint :repost_topic_id, null: false
      table.bigint :user_id, null: false
      table.timestamps null: false
    end

    add_index :isbf_reposts, :source_topic_id
    add_index :isbf_reposts, :repost_topic_id, unique: true
    add_index :isbf_reposts, :user_id
  end
end
