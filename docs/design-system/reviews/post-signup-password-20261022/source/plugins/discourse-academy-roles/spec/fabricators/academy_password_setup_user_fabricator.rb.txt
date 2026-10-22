# frozen_string_literal: true

Fabricator(:academy_password_setup_user, from: :user) do
  password nil
  custom_fields { { DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD => true } }
end
