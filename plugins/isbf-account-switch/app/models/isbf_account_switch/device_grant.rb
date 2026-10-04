# frozen_string_literal: true

module IsbfAccountSwitch
  class DeviceGrant < ActiveRecord::Base
    self.table_name = "isbf_account_switch_device_grants"

    belongs_to :account_link
    belongs_to :user

    scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.zone.now) }
  end
end

# == Schema Information
#
# Table name: isbf_account_switch_device_grants
#
#  id              :bigint           not null, primary key
#  device_digest   :string           not null
#  expires_at      :datetime         not null
#  last_used_at    :datetime
#  revoked_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_link_id :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  idx_isbf_switch_grants_device  (device_digest,expires_at)
#  idx_isbf_switch_grants_unique  (account_link_id,user_id,device_digest) UNIQUE
#
