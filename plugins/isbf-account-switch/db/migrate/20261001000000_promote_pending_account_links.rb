# frozen_string_literal: true

class PromotePendingAccountLinks < ActiveRecord::Migration[7.0]
  def up
    change_column_default :isbf_account_links, :status, from: 0, to: 1
    execute <<~SQL
      INSERT INTO isbf_account_switch_audit_events
        (account_link_id, actor_id, action, metadata, created_at, updated_at)
      SELECT id, NULL, 'link_queued_for_admin', '{}'::jsonb, NOW(), NOW()
      FROM isbf_account_links
      WHERE status = 0
    SQL
    execute "UPDATE isbf_account_links SET status = 1, updated_at = NOW() WHERE status = 0"
  end

  def down
    change_column_default :isbf_account_links, :status, from: 1, to: 0
  end
end
