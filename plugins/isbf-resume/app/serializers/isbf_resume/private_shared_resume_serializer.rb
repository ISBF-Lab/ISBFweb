# frozen_string_literal: true

module IsbfResume
  class PrivateSharedResumeSerializer < SharedResumeSerializer
    attributes :submitted_description, :lock_version, :can_review
    has_many :reviews, serializer: ShareReviewSerializer, embed: :objects

    def can_review
      scope.can_review_isbf_resumes? && object.pending?
    end

    def include_reviews?
      scope.can_review_isbf_resumes?
    end
  end
end
