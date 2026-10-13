# frozen_string_literal: true

class DiscourseAcademyRoles::StudentInviteBatchSerializer < ApplicationSerializer
  attributes :created_count, :skipped_count, :failed_count, :csv

  delegate :created_count, :skipped_count, :failed_count, to: :object

  def csv
    object.to_csv
  end

  def include_csv?
    scope&.is_admin?
  end
end
