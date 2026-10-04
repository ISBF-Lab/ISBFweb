# frozen_string_literal: true

class DiscourseAcademyRoles::CreateStudentInvite
  include Service::Base

  params base_class: DiscourseAcademyRoles::StudentInviteContract do
    attribute :student_number, :string

    before_validation { self.student_number = student_number.to_s.strip }

    validates :student_number,
              presence: true,
              length: {
                maximum:
                  DiscourseAcademyRoles::StudentRegistration::MAX_STUDENT_NUMBER_LENGTH
              }
  end

  policy :can_manage_student_invites

  try(ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique) do
    transaction do
      model :invite, :create_invite
      model :student_registration, :register_student
    end
  end

  private

  def can_manage_student_invites(guardian:)
    SiteSetting.academy_roles_enabled? && guardian.is_admin?
  end

  def create_invite(params:, guardian:)
    Invite.generate(
      guardian.user,
      max_redemptions_allowed: 1,
      skip_email: true,
      expires_at: params.expiration
    )
  end

  def register_student(params:, guardian:, invite:)
    DiscourseAcademyRoles::StudentRegistration.create(
      student_number: params.student_number,
      invite:,
      issued_by: guardian.user
    )
  end
end
