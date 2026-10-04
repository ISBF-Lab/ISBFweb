# frozen_string_literal: true

class CreateIsbfAccountSwitchTables < ActiveRecord::Migration[7.0]
  def change
    create_table :isbf_account_links do |t|
      t.integer :user_a_id, null: false
      t.integer :user_b_id, null: false
      t.integer :requester_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :approved_by_id
      t.datetime :approved_at
      t.integer :rejected_by_id
      t.datetime :rejected_at
      t.integer :revoked_by_id
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :isbf_account_links, %i[user_a_id user_b_id], unique: true
    add_index :isbf_account_links, :status

    create_table :isbf_account_switch_device_grants do |t|
      t.integer :account_link_id, null: false
      t.integer :user_id, null: false
      t.string :device_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :isbf_account_switch_device_grants,
              %i[account_link_id user_id device_digest],
              unique: true,
              name: "idx_isbf_switch_grants_unique"
    add_index :isbf_account_switch_device_grants,
              %i[device_digest expires_at],
              name: "idx_isbf_switch_grants_device"

    create_table :isbf_account_switch_audit_events do |t|
      t.integer :account_link_id
      t.integer :actor_id
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :isbf_account_switch_audit_events, :account_link_id
    add_index :isbf_account_switch_audit_events, :actor_id
    add_index :isbf_account_switch_audit_events, :created_at
  end
end
