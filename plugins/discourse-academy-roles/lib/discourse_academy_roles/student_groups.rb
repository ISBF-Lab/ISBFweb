# frozen_string_literal: true

module DiscourseAcademyRoles::StudentGroups
  MAX_ROWS = 1500
  MAX_BYTES = 1.megabyte
  PAGE_SIZE = 40
  CHUNK_BUDGET = 60
  USER_SLICE_BUDGET = 30
  CHUNK_SIZE = 50
  PREVIEW_LIFETIME = 30.minutes
  DISPLAY_FIELDS = %w[primary_group_id title flair_group_id].freeze

  class Error < StandardError
    attr_reader :code

    def initialize(code)
      @code = code.to_s
      super(I18n.t("academy_roles.student_groups.errors.#{@code}"))
    end
  end

  def self.ensure_developer!(actor)
    unless SiteSetting.academy_roles_enabled? && actor&.reload&.admin?
      raise Discourse::InvalidAccess
    end
  end
end
