# frozen_string_literal: true

module IsbfAccountSwitch
  class DeviceAuthorizer
    class << self
      def authorized?(cookies:, link:, user:)
        return false unless link.approved? && link.participant?(user)

        raw = read_cookie(cookies)
        return false if raw.blank?

        grants_for(user: user, raw: raw).exists?
      end

      def authorize_pair!(cookies:, link:, request:, actor:)
        raw = read_cookie(cookies) || SecureRandom.hex(32)
        write_cookie(cookies, raw)
        expires_at = authorization_days.days.from_now

        [link.user_a_id, link.user_b_id].each do |user_id|
          grant =
            DeviceGrant.find_or_initialize_by(
              account_link_id: link.id,
              user_id: user_id,
              device_digest: digest(raw)
            )
          grant.assign_attributes(
            expires_at: expires_at,
            revoked_at: nil,
            last_used_at: Time.zone.now
          )
          grant.save!
        end

        AuditEvent.record!(
          action: "device_authorized",
          link: link,
          actor: actor,
          request: request,
          metadata: {
            expires_at: expires_at.iso8601
          }
        )
      end

      def touch!(cookies:, link:, user:)
        return unless link.approved? && link.participant?(user)

        raw = read_cookie(cookies)
        return if raw.blank?

        grants_for(user: user, raw: raw).update_all(last_used_at: Time.zone.now)
      end

      def revoke_from_cookie!(cookies:, actor:, request:)
        raw = read_cookie(cookies)
        return if raw.blank?

        grants = DeviceGrant.active.where(device_digest: digest(raw))
        link_ids = grants.distinct.pluck(:account_link_id)
        grants.update_all(revoked_at: Time.zone.now)
        link_ids.each do |link_id|
          AuditEvent.record!(
            action: "device_authorization_revoked",
            link: AccountLink.find_by(id: link_id),
            actor: actor,
            request: request
          )
        end
        cookies.delete(DEVICE_COOKIE)
      end

      private

      def authorization_days
        SiteSetting.isbf_account_switch_device_authorization_days
      end

      def digest(raw)
        Digest::SHA256.hexdigest(raw)
      end

      def grants_for(user:, raw:)
        DeviceGrant.active.where(
          account_link: AccountLink.approved.for_user(user.id),
          user: user,
          device_digest: digest(raw)
        )
      end

      def read_cookie(cookies)
        cookies.encrypted[DEVICE_COOKIE]
      end

      def write_cookie(cookies, raw)
        cookies.encrypted[DEVICE_COOKIE] = {
          value: raw,
          expires: authorization_days.days.from_now,
          httponly: true,
          secure: SiteSetting.force_https,
          same_site: :lax
        }
      end
    end
  end
end
