# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe ReviewableIsbfResume do
  include_context "with resume review permissions"

  fab!(:reviewer, :admin)
  fab!(:shared_resume, :shared_isbf_resume)

  describe "#perform" do
    it "rolls back both native review state and the audit if publication cannot be saved" do
      reviewable = shared_resume.reviewable
      shared_resume.update_column(:title, "a" * 201)
      version = reviewable.version

      expect do
        reviewable.perform(
          reviewer,
          :approve_resume,
          version: version,
          description: "Reviewed summary",
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(shared_resume.reload).to have_attributes(
        status: "pending",
        description: "",
        reviewed_at: nil,
        lock_version: 0,
      )
      expect(shared_resume.reviews).to be_empty
      expect(reviewable.reload).to have_attributes(status: "pending", version: version)
    end
  end
end
