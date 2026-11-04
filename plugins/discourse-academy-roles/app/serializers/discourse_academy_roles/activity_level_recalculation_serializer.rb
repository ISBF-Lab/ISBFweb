# frozen_string_literal: true

class DiscourseAcademyRoles::ActivityLevelRecalculationSerializer < ApplicationSerializer
  FIELDS = %i[
    id
    revision
    status
    processed
    total
    upgraded
    downgraded
    unchanged
    failed
    started_at
    completed_at
    error
  ].freeze
  attributes(*FIELDS)

  FIELDS.each { |name| define_method(name) { object[name.to_s] } }
end
