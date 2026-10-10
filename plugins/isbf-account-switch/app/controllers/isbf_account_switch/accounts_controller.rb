# frozen_string_literal: true

module IsbfAccountSwitch
  class AccountsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    before_action :ensure_enabled
    before_action :ensure_admin, except: :revoke_device

    def index
      links =
        AccountLink
          .for_user(current_user.id)
          .includes(:user_a, :user_b)
          .order(updated_at: :desc)

      render json: {
               links: links.filter_map { |link| serialize_link(link) },
               can_link_accounts: true
             }
    end

    def create
      target =
        User.find_by_username_or_email(params.require(:username).to_s.strip)
      if (error_key = target_error(target))
        return render_error(error_key)
      end

      user_a_id, user_b_id = AccountLink.ordered_ids(current_user.id, target.id)
      existing_link =
        AccountLink.find_by(user_a_id: user_a_id, user_b_id: user_b_id)
      if existing_link && !existing_link.rejected? && !existing_link.revoked?
        return render_error(:link_exists)
      end

      link =
        existing_link ||
          AccountLink.new(user_a_id: user_a_id, user_b_id: user_b_id)
      link.assign_attributes(
        requester_id: current_user.id,
        status: :pending_admin,
        approved_by_id: nil,
        approved_at: nil,
        rejected_by_id: nil,
        rejected_at: nil,
        revoked_by_id: nil,
        revoked_at: nil
      )
      link.save!
      AuditEvent.record!(
        action: "link_requested",
        link: link,
        actor: current_user,
        request: request
      )
      render json: { link: serialize_link(link.reload) }
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      render_error(:link_exists)
    end

    def revoke
      link = participant_link
      link.update!(
        status: :revoked,
        revoked_by: current_user,
        revoked_at: Time.zone.now
      )
      link.device_grants.update_all(revoked_at: Time.zone.now)
      AuditEvent.record!(
        action: "link_revoked",
        link: link,
        actor: current_user,
        request: request
      )
      render json: success_json
    end

    def verify
      link = participant_link
      unless link.approved?
        return render_error(:admin_approval_required, status: :forbidden)
      end

      target = link.other_user(current_user)
      unless target_available?(target)
        return render_error(:target_unavailable, status: :forbidden)
      end

      rate_limit_verification!(target)
      unless target.confirm_password?(params.require(:password))
        return render_error(:invalid_credentials, status: :forbidden)
      end

      second_factor_result =
        target.authenticate_second_factor(params, server_session)
      unless second_factor_result.ok
        payload =
          second_factor_result.to_h.merge(
            errors: [I18n.t("isbf_account_switch.errors.invalid_second_factor")]
          )
        if target.security_keys_enabled?
          DiscourseWebauthn.stage_challenge(target, server_session)
          payload.merge!(
            DiscourseWebauthn.allowed_credentials(target, server_session)
          )
        end
        return render json: payload, status: :forbidden
      end

      previous_user = current_user
      DeviceAuthorizer.authorize_pair!(
        cookies: cookies,
        link: link,
        request: request,
        actor: previous_user
      )
      AuditEvent.record!(
        action: "target_verified",
        link: link,
        actor: previous_user,
        request: request,
        metadata: {
          target_user_id: target.id
        }
      )
      log_on_user(target)
      render json: {
               success: true,
               redirect_url: Discourse.base_path.presence || "/"
             }
    end

    def switch
      link = participant_link
      unless link.approved?
        return render_error(:admin_approval_required, status: :forbidden)
      end

      target = link.other_user(current_user)
      unless target_available?(target)
        return render_error(:target_unavailable, status: :forbidden)
      end

      unless DeviceAuthorizer.authorized?(
               cookies: cookies,
               link: link,
               user: target
             )
        return render_error(:device_verification_required, status: :forbidden)
      end

      previous_user = current_user
      DeviceAuthorizer.touch!(cookies: cookies, link: link, user: target)
      log_on_user(target)
      AuditEvent.record!(
        action: "account_switched",
        link: link,
        actor: previous_user,
        request: request,
        metadata: {
          target_user_id: target.id
        }
      )
      render json: {
               success: true,
               redirect_url: Discourse.base_path.presence || "/"
             }
    end

    def revoke_device
      DeviceAuthorizer.revoke_from_cookie!(
        cookies: cookies,
        actor: current_user,
        request: request
      )
      render json: success_json
    end

    private

    def ensure_enabled
      raise Discourse::NotFound unless SiteSetting.isbf_account_switch_enabled
    end

    def participant_link
      link = AccountLink.includes(:user_a, :user_b).find(params[:id])
      raise Discourse::InvalidAccess unless link.participant?(current_user)

      link
    end

    def rate_limit_verification!(target)
      RateLimiter.new(
        current_user,
        "isbf-account-switch-verify-#{target.id}",
        5,
        10.minutes
      ).performed!
    end

    def render_error(key, status: :unprocessable_entity)
      render json: {
               errors: [I18n.t("isbf_account_switch.errors.#{key}")]
             },
             status: status
    end

    def serialize_link(link)
      other = link.other_user(current_user)
      return if other.nil?

      {
        id: link.id,
        status: link.status,
        requester_id: link.requester_id,
        device_authorized:
          link.approved? &&
            DeviceAuthorizer.authorized?(
              cookies: cookies,
              link: link,
              user: other
            ),
        account: {
          id: other.id,
          username: other.username,
          name: other.name,
          avatar_template: other.avatar_template.gsub("{size}", "64"),
          active: other.active?,
          suspended: other.suspended?,
          totp_enabled: other.totp_enabled?,
          backup_codes_enabled: other.backup_codes_enabled?,
          security_keys_enabled: other.security_keys_enabled?
        }
      }
    end

    def target_available?(target)
      target.present? && target.active? && !target.suspended? &&
        (!SiteSetting.must_approve_users? || target.approved? || target.admin?)
    end

    def target_error(target)
      return :invalid_target if target.blank? || target.staged?
      :same_account if target.id == current_user.id
    end
  end
end
