# frozen_string_literal: true

class DiscourseAcademyRoles::RevokeStudentInvite
  include Service::Base

  params do
    attribute :student_registration_id, :integer

    validates :student_registration_id, presence: true
  end

  policy :can_manage_student_invites
  model :student_registration

  transaction do
    step :lock_registration
    policy :unredeemed
    step :revoke_invite
  end

  private

  def can_manage_student_invites(guardian:)
    SiteSetting.academy_roles_enabled? && guardian.is_admin?
  end

  def fetch_student_registration(params:)
    DiscourseAcademyRoles::StudentRegistration.find_by(
      id: params.student_registration_id
    )
  end

  def lock_registration(student_registration:)
    student_registration.lock!
  end

  def unredeemed(student_registration:)
    !student_registration.registered?
  end

  def revoke_invite(student_registration:)
    student_registration.invite&.update!(invalidated_at: Time.current)
  end
end
