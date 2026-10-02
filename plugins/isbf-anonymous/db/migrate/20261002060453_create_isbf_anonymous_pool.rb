# frozen_string_literal: true

class CreateIsbfAnonymousPool < ActiveRecord::Migration[8.1]
  def change
    create_table :isbf_anonymous_pool_accounts do |t|
      t.integer :slot, null: false
      t.integer :user_id, null: false
      t.timestamps null: false
    end
    add_index :isbf_anonymous_pool_accounts, :slot, unique: true
    add_index :isbf_anonymous_pool_accounts, :user_id, unique: true

    create_table :isbf_anonymous_pool_assignments do |t|
      t.integer :master_user_id, null: false
      t.bigint :pool_account_id, null: false
      t.datetime :started_at, null: false
      t.datetime :expires_at, null: false
      t.timestamps null: false
    end
    add_index :isbf_anonymous_pool_assignments, :master_user_id, unique: true
    add_index :isbf_anonymous_pool_assignments, :pool_account_id
  end
end
