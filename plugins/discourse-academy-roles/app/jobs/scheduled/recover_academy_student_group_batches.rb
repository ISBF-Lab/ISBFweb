# frozen_string_literal: true

module Jobs
  class RecoverAcademyStudentGroupBatches < ::Jobs::Scheduled
    every 5.minutes

    def execute(_args)
      return unless SiteSetting.academy_roles_enabled?
      DiscourseAcademyRoles::StudentGroupBatch
        .unfinished
        .where("updated_at < ?", 10.minutes.ago)
        .limit(5)
        .pluck(:id)
        .each { |batch_id| Jobs.enqueue(:academy_student_group_batch, batch_id:) }
    end
  end
end
