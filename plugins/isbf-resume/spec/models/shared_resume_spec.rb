# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharedResume do
  include_context "with resume review permissions"

  fab!(:reviewer, :admin)
  fab!(:shared_resume, :shared_isbf_resume)

  describe "#reviewable" do
    it "queues one native review on creation and keeps that review when metadata changes" do
      submission = nil
      expect do submission = Fabricate(:shared_isbf_resume) end.to change(
        ReviewableIsbfResume,
        :count,
      ).by(1)
      reviewable = submission.reviewable

      expect(reviewable).to have_attributes(
        status: "pending",
        created_by_id: submission.user_id,
        target_created_by_id: submission.user_id,
        force_review: true,
      )
      expect(reviewable.payload).to include(
        "shared_resume_id" => submission.id,
        "description" => submission.submitted_description,
      )
      expect do
        submission.update!(salary: "Optional salary update")
        expect(submission.reload.reviewable).to eq(reviewable)
      end.not_to change(ReviewableIsbfResume, :count)
    end
  end

  describe ".published" do
    it "contains approved submissions while pending and rejected submissions remain private" do
      approved = Fabricate(:approved_shared_isbf_resume)
      Fabricate(:rejected_shared_isbf_resume)

      expect(described_class.published).to contain_exactly(approved)
    end
  end

  describe "#review!" do
    let(:review_attributes) do
      {
        reviewer: reviewer,
        decision: "approve",
        description: "Verified summary",
        expected_version: shared_resume.lock_version,
      }
    end

    it "requires a nonblank final description even for a direct model caller" do
      expect {
        shared_resume.review!(**review_attributes.merge(description: "\n\t "))
      }.to raise_error(Discourse::InvalidParameters)
      expect(shared_resume.reload).to be_pending
      expect(shared_resume.reviews).to be_empty
    end

    it "records the reviewer and original description independently of later profile changes" do
      original_reviewer_name = reviewer.name.presence || reviewer.username
      original_reviewer_username = reviewer.username
      original_description = shared_resume.submitted_description

      shared_resume.review!(**review_attributes)
      reviewer.update!(name: "Later profile name", username: "renamed_review_user")
      shared_resume.update!(submitted_description: "Later uploader text")

      expect(shared_resume.reviews.sole).to have_attributes(
        reviewer_id: reviewer.id,
        reviewer_name: original_reviewer_name,
        reviewer_username: original_reviewer_username,
        original_description: original_description,
        description: "Verified summary",
      )
    end

    it "uses the reviewer's username when the profile name is empty" do
      reviewer.update!(name: "")

      shared_resume.review!(**review_attributes)

      expect(shared_resume.reviews.sole.reviewer_name).to eq(reviewer.username)
    end

    it "rolls back the audit record if publication cannot be saved" do
      shared_resume.update_column(:title, "a" * 201)

      expect { shared_resume.review!(**review_attributes) }.to raise_error(
        ActiveRecord::RecordInvalid,
      )

      expect(shared_resume.reload).to have_attributes(
        status: "pending",
        description: "",
        reviewed_at: nil,
        lock_version: 0,
      )
      expect(shared_resume.reviews).to be_empty
    end

    it "checks the current permission before writing a review through the model" do
      administrator = Fabricate(:moderator)
      SiteSetting.academy_moderators_review_resumes = true
      expect(administrator.guardian.can_review_isbf_resumes?).to eq(true)
      SiteSetting.academy_moderators_review_resumes = false

      expect {
        shared_resume.review!(**review_attributes.merge(reviewer: administrator))
      }.to raise_error(Discourse::InvalidAccess)

      expect(shared_resume.reload).to be_pending
      expect(shared_resume.reviews).to be_empty
    end

    it "preserves the first decision when a competing stale reviewer submits later" do
      version = shared_resume.lock_version
      shared_resume.review!(**review_attributes)
      first_review = shared_resume.reviews.sole

      expect do
        shared_resume.review!(
          **review_attributes.merge(decision: "reject", description: "", expected_version: version),
        )
      end.to raise_error(described_class::ReviewConflict)

      expect(shared_resume.reload).to have_attributes(
        status: "approved",
        description: "Verified summary",
      )
      expect(shared_resume.reviews).to contain_exactly(first_review)
    end
  end
end
