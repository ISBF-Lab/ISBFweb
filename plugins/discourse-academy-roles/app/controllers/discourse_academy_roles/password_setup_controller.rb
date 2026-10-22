# frozen_string_literal: true

class DiscourseAcademyRoles::PasswordSetupController < ::ApplicationController
  requires_plugin "discourse-academy-roles"
  requires_login

  before_action :ensure_browser_session
  before_action :rate_limit_password_setup, only: :update

  def update
    DiscourseAcademyRoles::SetInitialPassword.call(
      service_params.deep_merge(trusted_session: trusted_session?),
    ) do
      on_success do |user:|
        log_on_user(user)
        render json: { success: true, no_password: false, academy_password_setup_pending: false }
      end
      on_failed_contract do |contract|
        render_json_error(contract.errors.full_messages, status: :unprocessable_entity)
      end
      on_failed_policy(:can_set_own_password) { raise Discourse::InvalidAccess }
      on_failed_policy(:password_setup_pending) do
        render json: {
                 errors: [I18n.t("academy_roles.password_setup.unavailable")],
                 error_type: "password_setup_unavailable",
               },
               status: :conflict
      end
      on_failed_policy(:trusted_session) do
        render json: {
                 errors: [I18n.t("academy_roles.password_setup.verification_required")],
                 error_type: "password_setup_verification_required",
               },
               status: :forbidden
      end
      on_failed_step(:save_password) do |user:|
        render_json_error(user.errors.full_messages, status: :unprocessable_entity)
      end
      on_failure { render_json_error(I18n.t("generic_error"), status: :unprocessable_entity) }
    end
  end

  def destroy
    DiscourseAcademyRoles::DismissPasswordSetup.call(service_params) do
      on_success { head :no_content }
      on_failed_policy(:can_dismiss_own_password_setup) { raise Discourse::InvalidAccess }
      on_failure { render_json_error(I18n.t("generic_error"), status: :unprocessable_entity) }
    end
  end

  private

  def ensure_browser_session
    raise Discourse::InvalidAccess if is_api? || is_user_api?
  end

  def trusted_session?
    # Match the credential-management trust window in UsersController.
    current_user.created_at > DiscourseAcademyRoles::PasswordSetup::TRUST_WINDOW.ago ||
      server_session["confirmed-session-#{current_user.id}"] == "true"
  end

  def rate_limit_password_setup
    RateLimiter.new(current_user, "academy-password-setup-minute", 5, 1.minute).performed!
    RateLimiter.new(current_user, "academy-password-setup-hour", 20, 1.hour).performed!
    RateLimiter.new(nil, "academy-password-setup-ip-#{request.remote_ip}", 60, 1.minute).performed!
  end
end
