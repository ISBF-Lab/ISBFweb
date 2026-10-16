# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe ReviewableIsbfResume do
  include_context "with resume review permissions"

  fab!(:reviewer, :admin)
  fab!(:shared_resume, :shared_isbf_resume)

  describe "#update_fields" do
    it "rolls back published content, native edit history and editor snapshots together" do
      reviewable = shared_resume.reviewable
      reviewable.perform(
        reviewer,
        :approve_resume,
        version: reviewable.version,
        description: "Approved text",
      )
      original_payload = reviewable.reload.payload.deep_dup
      version = reviewable.version
      histories = reviewable.reviewable_histories.count
      reviewable.shared_resume.update_column(:file_sha256, "")

      expect do
        reviewable.update_fields(
          { payload: { description: "Unsaved revision" } },
          reviewer,
          version: version,
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(reviewable.reload).to have_attributes(payload: original_payload, version: version)
      expect(reviewable.reviewable_histories.count).to eq(histories)
      expect(shared_resume.reload.description).to eq("Approved text")
      expect(shared_resume.reviews.count).to eq(1)
    end
  end

  describe "#perform" do
    it "rolls back both native review state and the audit if publication cannot be saved" do
      reviewable = shared_resume.reviewable
      shared_resume.update_column(:file_sha256, "")
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
