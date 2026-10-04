# frozen_string_literal: true

class DiscourseAcademyRoles::ReissueStudentInvite
  include Service::Base

  params base_class: DiscourseAcademyRoles::StudentInviteContract do
    attribute :student_registration_id, :integer

    validates :student_registration_id, presence: true
  end

  policy :can_manage_student_invites
  model :student_registration

  try(ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique) do
    transaction do
      step :lock_registration
      policy :unredeemed
      model :invite, :create_invite
      step :replace_invite
    end
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

  def create_invite(params:, guardian:)
    Invite.generate(
      guardian.user,
      max_redemptions_allowed: 1,
      skip_email: true,
      expires_at: params.expiration
    )
  end

  def replace_invite(student_registration:, invite:, guardian:)
    student_registration.invite&.update!(invalidated_at: Time.current)
    student_registration.update!(invite:, issued_by: guardian.user)
  end
end
