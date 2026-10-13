# frozen_string_literal: true

module IsbfAccountSwitch
  class AuditEvent < ActiveRecord::Base
    self.table_name = "isbf_account_switch_audit_events"

    belongs_to :account_link, optional: true
    belongs_to :actor, class_name: "User", optional: true

    def self.record!(action:, link: nil, actor: nil, request: nil, metadata: {})
      safe_metadata = metadata.stringify_keys
      if request
        safe_metadata["ip"] = request.remote_ip
        safe_metadata["user_agent"] = request.user_agent.to_s.first(255)
      end

      create!(action: action, account_link: link, actor: actor, metadata: safe_metadata)
    end
  end
end

# == Schema Information
#
# Table name: isbf_account_switch_audit_events
#
#  id              :bigint           not null, primary key
#  action          :string           not null
#  metadata        :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_link_id :integer
#  actor_id        :integer
#
# Indexes
#
#  index_isbf_account_switch_audit_events_on_account_link_id  (account_link_id)
#  index_isbf_account_switch_audit_events_on_actor_id         (actor_id)
#  index_isbf_account_switch_audit_events_on_created_at       (created_at)
#
