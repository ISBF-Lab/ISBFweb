# frozen_string_literal: true

module IsbfAnonymous
  class PoolAssignment < ActiveRecord::Base
    self.table_name = "isbf_anonymous_pool_assignments"

    belongs_to :master_user, class_name: "User"
    belongs_to :pool_account

    def self.author_for!(master)
      DistributedMutex.synchronize("isbf_anonymous_pool_assignment_#{master.id}") do
        assignment = find_or_initialize_by(master_user_id: master.id)
        now = Time.current
        return assignment.pool_account.user if assignment.persisted? && assignment.expires_at > now

        previous_slot = assignment.pool_account&.slot
        size = SiteSetting.isbf_anonymous_pool_size
        slot =
          PoolAccount.slot_for(
            "user:#{master.id}:#{now.to_f}",
            size: previous_slot ? size - 1 : size,
          )
        slot += 1 if previous_slot && slot >= previous_slot
        # Slot creation must commit before releasing its mutex.
        account = PoolAccount.for_slot!(slot)
        master.with_lock do
          assignment.update!(
            pool_account: account,
            started_at: now,
            expires_at: now + SiteSetting.anonymous_account_duration_minutes.minutes,
          )
        end
        account.user
      end
    end
  end
end

# == Schema Information
#
# Table name: isbf_anonymous_pool_assignments
#
#  id              :bigint           not null, primary key
#  expires_at      :datetime         not null
#  started_at      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  master_user_id  :integer          not null
#  pool_account_id :bigint           not null
#
# Indexes
#
#  index_isbf_anonymous_pool_assignments_on_master_user_id   (master_user_id) UNIQUE
#  index_isbf_anonymous_pool_assignments_on_pool_account_id  (pool_account_id)
#
