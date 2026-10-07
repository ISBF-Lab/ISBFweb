# frozen_string_literal: true

class DiscourseAcademyRoles::StudentInvites::Action::IssueBatch < Service::ActionBase
  option :csv
  option :guardian
  option :expires_at

  def call
    existing_numbers =
      DiscourseAcademyRoles::StudentRegistration
        .where(student_number: csv.rows.map { |row| row[:student_number] }.uniq)
        .pluck(:student_number)
        .to_set
    seen = Set.new

    csv.rows.each do |row|
      student_number = row[:student_number]

      if error = csv.row_error(row)
        csv.record(row, status: :failed, reason: error)
      elsif !seen.add?(student_number)
        csv.record(
          row,
          status: :skipped,
          reason: I18n.t("academy_roles.student_invites.bulk.duplicate_row")
        )
      elsif existing_numbers.include?(student_number)
        csv.record(
          row,
          status: :skipped,
          reason:
            I18n.t("academy_roles.student_invites.bulk.existing_student_number")
        )
      else
        issue_invite(row)
      end
    end
  end

  private

  def issue_invite(row)
    result = nil
    DiscourseAcademyRoles::StudentRegistration.transaction(
      requires_new: true
    ) do
      result =
        DiscourseAcademyRoles::CreateStudentInvite.call(
          params: {
            student_number: row[:student_number],
            expires_at:
          },
          guardian:
        )
      raise ActiveRecord::Rollback if result.failure?
    end

    if result.success?
      csv.record(
        row,
        status: :created,
        registration: result.student_registration
      )
    elsif DiscourseAcademyRoles::StudentRegistration.exists?(
          student_number: row[:student_number]
        )
      csv.record(
        row,
        status: :skipped,
        reason:
          I18n.t("academy_roles.student_invites.bulk.existing_student_number")
      )
    else
      csv.record(
        row,
        status: :failed,
        reason: I18n.t("academy_roles.student_invites.create_failed")
      )
    end
  end
end
