# frozen_string_literal: true

RSpec.describe IsbfGuides::Publish do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:guide_id) }
    it { is_expected.to validate_presence_of(:version) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:guide, :isbf_guide)

    let(:params) { { guide_id:, version: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }
    let(:guide_id) { guide.id }
    let(:version) { guide.lock_version }

    before { SiteSetting.isbf_guides_enabled = true }

    context "when the contract is invalid" do
      let(:guide_id) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the actor is a member" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "without an authenticated actor" do
      fab!(:acting_user) { nil }

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the guide is missing" do
      let(:guide_id) { -1 }

      it { is_expected.to fail_to_find_a_model(:guide) }
    end

    context "when the draft has changed since loading" do
      let(:version) { guide.lock_version - 1 }

      it { is_expected.to fail_a_policy(:current_version) }
    end

    context "without a draft" do
      before { guide.update!(draft_revision: nil) }

      it { is_expected.to fail_a_policy(:has_draft) }
    end

    context "when publishing the first draft" do
      it "publishes a complete snapshot and creates an independent editable draft" do
        draft = guide.draft_revision

        expect(result).to run_successfully
        expect(guide.reload).to be_published
        expect(guide.published_revision_id).to eq(draft.id)
        expect(guide.published_revision.published_at).to be_present
        expect(guide.draft_revision_id).not_to eq(draft.id)
        expect(guide.draft_revision.content_attributes).to eq(draft.content_attributes)
        expect(guide.draft_revision.published_at).to be_nil
        expect(guide).not_to have_changes
      end
    end

    context "when publishing an updated guide" do
      fab!(:guide, :published_isbf_guide)

      it "replaces the snapshot while preserving the original publication date" do
        previous_revision = guide.published_revision
        first_published_at = guide.first_published_at
        guide.draft_revision.update!(title: "New version", raw: "## Updated\n\nNew instructions.")

        expect(result).to run_successfully
        expect(guide.reload.published_revision.title).to eq("New version")
        expect(guide.published_revision_id).not_to eq(previous_revision.id)
        expect(guide.first_published_at).to eq_time(first_published_at)
        expect(previous_revision.reload).to be_persisted
      end
    end
  end
end
