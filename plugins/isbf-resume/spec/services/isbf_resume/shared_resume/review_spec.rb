# frozen_string_literal: true

require_relative "../../../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharedResume::Review do
  include_context "with resume review permissions"

  describe described_class::Contract, type: :model do
    subject(:contract) { described_class.new(decision: "approve") }

    it { is_expected.to validate_presence_of(:shared_resume_id) }
    it { is_expected.to validate_presence_of(:expected_version) }

    it do
      is_expected.to validate_numericality_of(:shared_resume_id).only_integer.is_greater_than(0)
    end

    it do
      is_expected.to validate_numericality_of(
        :expected_version,
      ).only_integer.is_greater_than_or_equal_to(0)
    end

    it { is_expected.to allow_values("approve", "reject").for(:decision) }
    it { is_expected.not_to allow_values("pending", "publish").for(:decision) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.not_to allow_values(" ", "\n\t").for(:description) }

    context "when the decision is rejection" do
      subject(:contract) { described_class.new(decision: "reject") }

      it { is_expected.to allow_values("", nil).for(:description) }
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:shared_resume, :shared_isbf_resume)

    let(:params) do
      {
        shared_resume_id: shared_resume.id,
        expected_version: shared_resume.lock_version,
        decision: "approve",
        description: "  Administrator's revised description  ",
      }
    end
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }
    let(:events) { DiscourseEvent.track_events { result } }
    let(:messages) { MessageBus.track_publish("/reviewable_action") { events } }

    context "when the approval description contract is invalid" do
      let(:params) { super().merge(description: " ") }

      it "halts before recording a decision" do
        expect { expect(result).to fail_a_contract }.not_to change(IsbfResume::ShareReview, :count)
        expect(shared_resume.reload).to be_pending
      end
    end

    context "when the actor is a visitor" do
      fab!(:acting_user) { nil }

      it { is_expected.to fail_a_policy(:can_review) }
    end

    context "when the actor is an ordinary member" do
      fab!(:acting_user, :user)

      before { SiteSetting.academy_moderators_review_resumes = true }

      it { is_expected.to fail_a_policy(:can_review) }
    end

    context "when the administrator lacks the resume review capability" do
      fab!(:acting_user, :moderator)

      before { SiteSetting.academy_moderators_review_content = true }

      it "requires the dedicated capability independently of content review" do
        expect(result).to fail_a_policy(:can_review)
        expect(shared_resume.reviews).to be_empty
      end
    end

    context "when an administrator's capability is revoked" do
      fab!(:acting_user, :moderator)

      it "checks the setting again for an existing guardian" do
        SiteSetting.academy_moderators_review_resumes = true
        expect(dependencies[:guardian].can_review_isbf_resumes?).to eq(true)
        SiteSetting.academy_moderators_review_resumes = false

        expect(result).to fail_a_policy(:can_review)
        expect(shared_resume.reload).to be_pending
      end
    end

    context "when the submission is missing" do
      let(:params) { super().merge(shared_resume_id: IsbfResume::SharedResume.maximum(:id) + 1) }

      it { is_expected.to fail_to_find_a_model(:shared_resume) }
    end

    context "when the review version is stale" do
      let(:params) { super().merge(expected_version: shared_resume.lock_version + 1) }

      it "returns a conflict without a partial audit record" do
        expect {
          expect(result).to fail_with_exception(IsbfResume::SharedResume::ReviewConflict)
        }.not_to change(IsbfResume::ShareReview, :count)
        expect(shared_resume.reload).to be_pending
      end
    end

    context "when the submission has already been decided" do
      fab!(:shared_resume, :approved_shared_isbf_resume)

      it "rejects a repeated decision" do
        expect {
          expect(result).to fail_with_exception(IsbfResume::SharedResume::ReviewConflict)
        }.not_to change(IsbfResume::ShareReview, :count)
        expect(shared_resume.reload).to be_approved
      end
    end

    context "when a developer approves the submission with the switch disabled" do
      it "publishes the revised description and records the server identity atomically" do
        freeze_time(Time.now.utc.change(usec: 0))
        expect { messages }.to change(IsbfResume::ShareReview, :count).by(1)
        expect(result).to run_successfully
        expect(shared_resume.reviewable).to be_approved
        expect(events.map { |event| event[:event_name] }).to include(:reviewable_transitioned_to)
        expect(messages.map(&:channel)).to include("/reviewable_action")
        expect(shared_resume.reload).to have_attributes(
          status: "approved",
          description: "Administrator's revised description",
          reviewed_at: Time.now.utc,
        )
        expect(shared_resume.reviews.sole).to have_attributes(
          reviewer_id: acting_user.id,
          reviewer_name: acting_user.name.presence || acting_user.username,
          reviewer_username: acting_user.username,
          decision: "approve",
          original_description: shared_resume.submitted_description,
          previous_description: "",
          description: shared_resume.description,
          created_at: Time.now.utc,
        )
        expect(IsbfResume::SharedResume.published).to contain_exactly(shared_resume)
      end
    end

    context "when an administrator has the dedicated capability" do
      fab!(:acting_user, :moderator)

      before { SiteSetting.academy_moderators_review_resumes = true }

      it "approves through the same audited workflow" do
        expect(result).to run_successfully
        expect(shared_resume.reload).to be_approved
        expect(shared_resume.reviews.sole.reviewer_id).to eq(acting_user.id)
      end
    end

    context "when the reviewer rejects without a description" do
      let(:params) { super().merge(decision: "reject", description: "") }

      it "keeps the PDF out of the published list and records the rejection" do
        expect(result).to run_successfully
        expect(shared_resume.reload.status).to eq("rejected")
        expect(shared_resume.reviews.sole).to have_attributes(decision: "reject", description: "")
        expect(IsbfResume::SharedResume.published).to be_empty
      end
    end
  end
end
