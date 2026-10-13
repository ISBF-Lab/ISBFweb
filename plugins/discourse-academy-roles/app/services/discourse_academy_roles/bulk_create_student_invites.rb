# frozen_string_literal: true

class DiscourseAcademyRoles::BulkCreateStudentInvites
  include Service::Base

  params base_class: DiscourseAcademyRoles::StudentInviteContract do
    attribute :file

    validates :file, presence: true
    validate :csv_upload

    private

    def csv_upload
      if !file.respond_to?(:tempfile) ||
           !file.respond_to?(:original_filename) ||
           !file.original_filename.to_s.match?(/\.csv\z/i)
        errors.add(
          :file,
          I18n.t("academy_roles.student_invites.bulk.csv_required")
        )
      elsif file.size > DiscourseAcademyRoles::StudentInviteCsv::MAX_BYTES
        errors.add(
          :file,
          I18n.t("academy_roles.student_invites.bulk.too_large")
        )
      end
    end
  end

  policy :can_manage_student_invites
  model :csv, :read_student_numbers
  step :issue_student_invitations

  private

  def can_manage_student_invites(guardian:)
    SiteSetting.academy_roles_enabled? && guardian.is_admin?
  end

  def read_student_numbers(params:)
    DiscourseAcademyRoles::StudentInviteCsv.new(params.file.tempfile)
  end

  def issue_student_invitations(params:, guardian:, csv:)
    DiscourseAcademyRoles::StudentInvites::Action::IssueBatch.call(
      csv:,
      guardian:,
      expires_at: params.expiration.iso8601
    )
  end
end
