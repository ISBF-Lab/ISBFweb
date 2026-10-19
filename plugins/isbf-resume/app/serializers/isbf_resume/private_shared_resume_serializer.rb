# frozen_string_literal: true

module IsbfResume
  class PrivateSharedResumeSerializer < SharedResumeSerializer
    attributes :submitted_description,
               :lock_version,
               :can_review,
               :student_number,
               :contributor_user_id
    has_many :reviews, serializer: ShareReviewSerializer, embed: :objects

    def can_review
      scope.can_review_isbf_resumes? && object.pending?
    end

    def include_reviews?
      scope.can_review_isbf_resumes?
    end

    def include_student_number?
      scope.can_submit_isbf_resume?
    end

    def include_contributor_user_id?
      scope.can_submit_isbf_resume?
    end
  end
end
