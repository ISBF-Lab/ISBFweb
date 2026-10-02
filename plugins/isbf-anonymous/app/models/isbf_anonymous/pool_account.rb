# frozen_string_literal: true

module IsbfAnonymous
  class PoolAccount < ActiveRecord::Base
    self.table_name = "isbf_anonymous_pool_accounts"

    belongs_to :user

    def self.for_slot!(slot)
      DistributedMutex.synchronize("isbf_anonymous_pool_slot_#{slot}") do
        find_by(slot: slot) ||
          transaction do
            username = UserNameSuggester.suggest("anonymous_#{slot + 1}")
            user =
              User.create!(
                username: username,
                name: username,
                password: SecureRandom.hex(32),
                email: "#{SecureRandom.hex(16)}@anonymous.invalid",
                skip_email_validation: true,
                active: true,
                approved: true,
                approved_at: Time.current,
                trust_level: TrustLevel[1],
                manual_locked_trust_level: TrustLevel[1],
              )
            user.user_option.update!(
              email_level: UserOption.email_level_types[:never],
              email_messages_level: UserOption.email_level_types[:never],
              email_digests: false,
              mailing_list_mode: false,
              allow_private_messages: false,
              hide_profile: true,
              hide_presence: true,
            )
            account = create!(slot: slot, user: user)
            user.association(:isbf_anonymous_pool_account).reset
            DirectoryItem.where(user_id: user.id).delete_all
            account
          end
      end
    end

    def self.slot_for(key, size: SiteSetting.isbf_anonymous_pool_size)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, key).to_i(16) % size
    end
  end
end

# == Schema Information
#
# Table name: isbf_anonymous_pool_accounts
#
#  id         :bigint           not null, primary key
#  slot       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_isbf_anonymous_pool_accounts_on_slot     (slot) UNIQUE
#  index_isbf_anonymous_pool_accounts_on_user_id  (user_id) UNIQUE
#
