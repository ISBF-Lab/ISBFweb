# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroupBatchItem < ActiveRecord::Base
  self.table_name = "academy_student_group_batch_items"

  belongs_to :batch, class_name: "DiscourseAcademyRoles::StudentGroupBatch"
  belongs_to :registration, class_name: "DiscourseAcademyRoles::StudentRegistration", optional: true
  belongs_to :user, class_name: "::User", optional: true
  belongs_to :source_item, class_name: "DiscourseAcademyRoles::StudentGroupBatchItem", optional: true

  def completed_steps
    steps.select { |step| step["state"] == "done" }
  end

  def retryable?
    %w[failed partial].include?(status) && (steps.any? { |step| step["state"] == "pending" } || (batch.undo? && !display_restored))
  end

  def selectable?
    status == "ready"
  end

  def binding_matches?
    binding = DiscourseAcademyRoles::StudentRegistration.find_by(id: registration_id)
    binding && binding.student_number == student_number && binding.user_id == user_id &&
      binding.registered? && user_id && User.exists?(user_id)
  end

  def expected_snapshot
    after_snapshot.presence || before_snapshot
  end
end
