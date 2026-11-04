# frozen_string_literal: true

module Jobs
  class AcademyRecalculateActivityLevels < ::Jobs::Base
    def execute(args)
      return unless SiteSetting.academy_roles_enabled?

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(args.fetch(:run_id))
    end
  end
end
