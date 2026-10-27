# frozen_string_literal: true

module Jobs
  class AcademyStudentGroupBatch < ::Jobs::Base
    def execute(args)
      DiscourseAcademyRoles::StudentGroups::Runner.call(batch_id: args[:batch_id])
    end
  end
end
