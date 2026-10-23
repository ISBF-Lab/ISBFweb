# frozen_string_literal: true

module DiscourseAcademyRoles::PasswordSetup
  PENDING_FIELD = "academy_password_setup_pending"
  TRUST_WINDOW = 5.minutes

  def self.enabled?
    SiteSetting.academy_roles_enabled? && SiteSetting.enable_local_logins? &&
      !SiteSetting.enable_discourse_connect?
  end

  def self.pending?(user)
    user.custom_fields[PENDING_FIELD] == true && !user.has_password?
  end

  def self.anonymous_account?(user)
    AnonymousUser.exists?(user:) ||
      (defined?(IsbfAnonymous::PoolAccount) && IsbfAnonymous::PoolAccount.exists?(user:))
  end

  def self.mark_for(user)
    unless enabled? && user.id.positive? && !user.staged? && !user.has_password? &&
             !anonymous_account?(user)
      return
    end

    user.upsert_custom_fields(PENDING_FIELD => true)
  end

  def self.complete_for(user)
    UserCustomField.where(user:, name: PENDING_FIELD).delete_all
    user.clear_custom_fields
  end
end
