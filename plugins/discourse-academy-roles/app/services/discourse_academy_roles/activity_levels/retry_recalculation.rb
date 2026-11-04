# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  class RetryRecalculation
    include Service::Base

    policy :can_manage
    policy :rules_initialized
    model :recalculation, :restart_recalculation

    private

    def can_manage(guardian:)
      guardian.user&.admin? && SiteSetting.academy_roles_enabled?
    end

    def rules_initialized
      Configuration.persisted?
    end

    def restart_recalculation
      Recalculation.retry!
    end
  end
end
