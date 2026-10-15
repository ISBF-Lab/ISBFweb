# frozen_string_literal: true

module IsbfResume
  class SharedResume::Review
    include Service::Base

    params do
      attribute :shared_resume_id
      attribute :expected_version
      attribute :decision, :string
      attribute :description, :string, default: ""
      validates :shared_resume_id, :expected_version, presence: true
      validates :shared_resume_id, numericality: { only_integer: true, greater_than: 0 }
      validates :expected_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :decision, inclusion: { in: %w[approve reject] }
      validates :description, length: { maximum: SharedResume::FIELD_LIMITS[:description] }
      validate :description_for_approval

      def description_for_approval
        errors.add(:description, :blank) if decision == "approve" && description.to_s.strip.blank?
      end

      def parsed_shared_resume_id
        Integer(shared_resume_id.to_s, 10)
      end

      def parsed_expected_version
        Integer(expected_version.to_s, 10)
      end
    end

    policy :can_review
    model :shared_resume
    try SharedResume::ReviewConflict, Discourse::InvalidAccess, Discourse::InvalidParameters do
      step :review_submission
    end

    private

    def can_review(guardian:)
      guardian.can_review_isbf_resumes?
    end

    def fetch_shared_resume(params:)
      SharedResume.find_by(id: params.parsed_shared_resume_id)
    end

    def review_submission(params:, shared_resume:, guardian:)
      result =
        shared_resume.reviewable.perform(
          guardian.user,
          params.decision == "approve" ? :approve_resume : :reject_resume,
          description: params.description,
          expected_version: params.parsed_expected_version,
        )
      raise Discourse::InvalidParameters.new(:description) unless result.success?
      shared_resume.reload
    rescue Reviewable::UpdateConflict, Reviewable::InvalidAction
      raise SharedResume::ReviewConflict
    end
  end
end
