# frozen_string_literal: true

class DiscourseAcademyRoles::SetInitialPassword
  include Service::Base

  params do
    attribute :password, :string
    attribute :password_confirmation, :string

    validates :password,
              presence: true,
              confirmation: true,
              length: {
                maximum: User.max_password_length,
              }
    validates :password_confirmation, presence: true, length: { maximum: User.max_password_length }
  end

  policy :can_set_own_password

  transaction do
    model :user
    policy :password_setup_pending
    policy :trusted_session
    step :save_password
    step :complete_password_setup
    step :invalidate_invitations
    step :log_password_change
  end

  private

  def can_set_own_password(guardian:)
    guardian.can_setup_academy_password?
  end

  def fetch_user(guardian:)
    User.lock.find_by(id: guardian.user.id)
  end

  def password_setup_pending(guardian:, user:)
    guardian.can_setup_academy_password?(user) &&
      DiscourseAcademyRoles::PasswordSetup.pending?(user)
  end

  def trusted_session(user:, trusted_session:)
    trusted_session && !user.totp_or_backup_codes_enabled? && !user.security_keys_enabled?
  end

  def save_password(params:, user:)
    user.password = params.password
    user.password_required!
    fail!(user.errors.full_messages.to_sentence) unless user.save
  end

  def complete_password_setup(user:)
    DiscourseAcademyRoles::PasswordSetup.complete_for(user)
  end

  def invalidate_invitations(user:)
    Invite.invalidate_for_email(user.email)
  end

  def log_password_change(user:)
    UserHistory.create!(
      target_user: user,
      acting_user: user,
      action: UserHistory.actions[:change_password],
    )
  end
end
