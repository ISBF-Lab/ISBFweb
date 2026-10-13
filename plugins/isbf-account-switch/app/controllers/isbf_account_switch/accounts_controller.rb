# frozen_string_literal: true

module IsbfAccountSwitch
  class AccountsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    before_action :ensure_enabled
    before_action :ensure_admin, only: %i[create revoke]
    before_action :ensure_switch_access,
                  only: %i[index request_email_code verify switch]
    before_action :prepare_verification, only: %i[request_email_code verify]
    before_action :rate_limit_email_code_request, only: :request_email_code

    def index
      links = AccountLink.for_user(current_user.id)
      links = links.approved unless current_user.admin?
      links = links.includes(:user_a, :user_b).order(updated_at: :desc)

      render json: {
               links: links.filter_map { |link| serialize_link(link) },
               can_link_accounts: current_user.admin?
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

    def request_email_code
      if !email_code_enabled?
        return render_error(:email_code_unavailable, status: :forbidden)
      end

      code =
        DeviceVerificationCode.issue!(
          link: @verification_link,
          actor: current_user,
          target: @verification_target,
          server_session: server_session
        )
      Jobs.enqueue(
        :send_email_login_code,
        to_address: code.email,
        code: code.code
      )
      render json:
               success_json.merge(
                 expires_in: DeviceVerificationCode::VALID_FOR.to_i
               )
    end

    def verify
      link = @verification_link
      target = @verification_target
      verification_method = params[:verification_method].presence || "password"

      rate_limit_verification!(target)
      case verification_method
      when "password"
        unless target.confirm_password?(params.require(:password))
          return render_error(:invalid_credentials, status: :forbidden)
        end
      when "email_code"
        if !email_code_enabled?
          return render_error(:email_code_unavailable, status: :forbidden)
        end

        code = params[:email_code]
        code = code.strip if code.is_a?(String)
        verification_code =
          DeviceVerificationCode.for_session(
            link: link,
            actor: current_user,
            target: target,
            server_session: server_session
          )
        unless code.is_a?(String) &&
                 code.match?(
                   /\A\d{#{DeviceVerificationCode::CODE_LENGTH}}\z/o
                 ) && verification_code&.verify(code)
          return render_error(:invalid_email_code, status: :forbidden)
        end
      else
        return render_error(:invalid_verification_method, status: :bad_request)
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

      if verification_code && !verification_code.consume!
        return render_error(:invalid_email_code, status: :forbidden)
      end
      server_session.delete(DeviceVerificationCode.session_key(link))

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
          target_user_id: target.id,
          verification_method: verification_method
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

    def ensure_switch_access
      unless current_user.guardian.can_switch_linked_accounts?
        raise Discourse::InvalidAccess
      end
    end

    def participant_link
      link = AccountLink.includes(:user_a, :user_b).find(params[:id])
      raise Discourse::InvalidAccess unless link.participant?(current_user)

      link
    end

    def prepare_verification
      @verification_link = participant_link
      if !@verification_link.approved?
        return render_error(:admin_approval_required, status: :forbidden)
      end

      @verification_target = @verification_link.other_user(current_user)
      if !target_available?(@verification_target)
        render_error(:target_unavailable, status: :forbidden)
      end
    end

    def email_code_enabled?
      SiteSetting.enable_local_logins &&
        SiteSetting.enable_local_logins_via_email &&
        !SiteSetting.enable_discourse_connect &&
        UpcomingChanges.enabled_for_user?(
          :enable_local_logins_via_code,
          current_user
        )
    end

    def rate_limit_email_code_request
      RateLimiter.new(
        current_user,
        "isbf-account-switch-code-minute",
        1,
        1.minute,
        apply_limit_to_staff: true
      ).performed!
      RateLimiter.new(
        nil,
        "isbf-account-switch-code-target-#{@verification_target.id}",
        3,
        1.hour
      ).performed!
      RateLimiter.new(
        nil,
        "isbf-account-switch-code-ip-#{request.remote_ip}",
        6,
        1.hour
      ).performed!
    end

    def rate_limit_verification!(target)
      RateLimiter.new(
        current_user,
        "isbf-account-switch-verify-#{target.id}",
        5,
        10.minutes,
        apply_limit_to_staff: true
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
          security_keys_enabled: other.security_keys_enabled?,
          email_code_enabled: email_code_enabled?
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
