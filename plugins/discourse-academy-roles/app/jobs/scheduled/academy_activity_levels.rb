# frozen_string_literal: true

module Jobs
  class AcademyActivityLevels < ::Jobs::Scheduled
    every 1.day

    def execute(_args)
      return unless SiteSetting.academy_roles_enabled?

      User
        .where(active: true, staged: false, admin: false, moderator: false)
        .find_each { |user| DiscourseAcademyRoles::ActivityLevel.update(user) }
    end
  end
end
