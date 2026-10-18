# frozen_string_literal: true

class ReviewableIsbfLearningCourse < Reviewable
  include ReviewableActionBuilder

  def serializer
    ReviewableIsbfLearningCourseSerializer
  end

  def build_combined_actions(actions, guardian, _args)
    return unless pending? && can_review_target?(guardian)
    build_action(
      actions,
      :approve_course,
      icon: "check",
      button_class: "btn-primary",
      source: "isbf_learning",
    )
    build_action(actions, :reject_course, icon: "xmark", source: "isbf_learning")
  end

  def perform(performed_by, action_id, args = nil)
    result = nil
    IsbfLearning::Courses.synchronize do
      result = super
      raise ActiveRecord::Rollback unless result.success?
    end
    result
  end

  def perform_approve_course(performed_by, _args)
    course =
      IsbfLearning::Courses.approve_locked(
        performed_by,
        name: payload.fetch("course_name"),
        grade: payload.fetch("grade"),
      )
    self.payload = payload.merge("course_id" => course.fetch("id"))
    create_result(:success, :approved)
  rescue IsbfLearning::StorageError
    create_result(:failure).tap do |result|
      result.errors = [I18n.t("isbf_learning.course_storage_error")]
    end
  end

  def perform_reject_course(_performed_by, _args)
    create_result(:success, :rejected)
  end

  private

  def can_review_target?(guardian)
    (
      IsbfLearning.can_review?(guardian) ||
        (
          guardian.is_staff? &&
            !(
              SiteSetting.respond_to?(:academy_roles_enabled?) && SiteSetting.academy_roles_enabled?
            )
        )
    ) && SiteSetting.isbf_learning_enabled && category_id == IsbfLearning.category_id && category &&
      guardian.can_see_category?(category) && !guardian.user.silenced? &&
      !guardian.user.suspended? && super
  end
end
