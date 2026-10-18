# frozen_string_literal: true

class ReviewableIsbfLearningCourseSerializer < ReviewableSerializer
  payload_attributes :course_name, :grade, :course_id
end
