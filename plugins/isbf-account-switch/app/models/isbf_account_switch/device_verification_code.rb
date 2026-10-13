# frozen_string_literal: true

module IsbfAccountSwitch
  class DeviceVerificationCode < ::EmailLoginCode
    # Keep device proofs outside the native login and password-reset scopes.
    enum :purpose, { account_switch: 1001 }, prefix: :device

    def self.issue!(link:, actor:, target:, server_session:)
      code = generate!(email: target.email, purpose: :account_switch)
      server_session.set(
        session_key(link),
        {
          code_id: code.id,
          actor_id: actor.id,
          target_id: target.id,
          email: target.email
        },
        expires: VALID_FOR.to_i
      )
      code
    end

    def self.for_session(link:, actor:, target:, server_session:)
      proof = server_session[session_key(link)]
      return if !proof.is_a?(Hash)

      proof = proof.with_indifferent_access
      return if proof[:actor_id] != actor.id || proof[:target_id] != target.id
      return if proof[:email] != target.email

      device_account_switch
        .active
        .for_email(target.email)
        .find_by(id: proof[:code_id])
    end

    def self.session_key(link)
      "isbf_account_switch_email_code_#{link.id}"
    end
  end
end
