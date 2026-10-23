# frozen_string_literal: true

class DiscourseAcademyRoles::DismissPasswordSetup
  include Service::Base

  policy :can_dismiss_own_password_setup

  transaction do
    model :user
    step :complete_password_setup
  end

  private

  def can_dismiss_own_password_setup(guardian:)
    guardian.can_setup_academy_password?
  end

  def fetch_user(guardian:)
    User.lock.find_by(id: guardian.user.id)
  end

  def complete_password_setup(user:)
    DiscourseAcademyRoles::PasswordSetup.complete_for(user)
  end
end
