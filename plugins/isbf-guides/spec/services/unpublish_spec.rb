# frozen_string_literal: true

RSpec.describe IsbfGuides::Unpublish do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:guide_id) }
    it { is_expected.to validate_presence_of(:version) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:guide, :published_isbf_guide)

    let(:params) { { guide_id:, version: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }
    let(:guide_id) { guide.id }
    let(:version) { guide.lock_version }

    before { SiteSetting.isbf_guides_enabled = true }

    context "when the contract is invalid" do
      let(:version) { nil }

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

    context "when the guide has changed since loading" do
      let(:version) { guide.lock_version - 1 }

      it { is_expected.to fail_a_policy(:current_version) }
    end

    context "when unpublishing a guide" do
      it "removes reader visibility and preserves editable and published content" do
        draft = guide.draft_revision
        published = guide.published_revision
        first_published_at = guide.first_published_at

        expect(result).to run_successfully
        expect(guide.reload).not_to be_published
        expect(guide.draft_revision).to eq(draft)
        expect(published.reload).to be_persisted
        expect(guide.first_published_at).to eq_time(first_published_at)
      end
    end
  end
end
