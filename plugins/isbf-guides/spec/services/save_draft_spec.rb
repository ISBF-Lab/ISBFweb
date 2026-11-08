# frozen_string_literal: true

RSpec.describe IsbfGuides::SaveDraft do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:raw) }
    it { is_expected.to validate_length_of(:slug).is_at_most(80) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:summary).is_at_most(1000) }
    it { is_expected.to validate_length_of(:raw).is_at_most(200_000) }
    it { is_expected.to allow_values("android", "getting-started-2").for(:slug) }
    it { is_expected.not_to allow_values("../android", "UPPERCASE", "has space").for(:slug) }

    it "requires a version when editing an existing guide" do
      contract = described_class.new(guide_id: 1)

      expect(contract).to validate_presence_of(:version)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:guide, :published_isbf_guide)

    let(:params) { { guide_id:, version:, slug:, title:, summary:, raw: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }
    let(:guide_id) { guide.id }
    let(:version) { guide.lock_version }
    let(:slug) { guide.slug }
    let(:title) { "Updated notification guide" }
    let(:summary) { "Updated setup instructions." }
    let(:raw) { "## Updated settings\n\nEnable the forum messages category." }

    before { SiteSetting.isbf_guides_enabled = true }

    context "when the contract is invalid" do
      let(:title) { "" }

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

    context "when guides are disabled" do
      before { SiteSetting.isbf_guides_enabled = false }

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the guide is missing" do
      let(:guide_id) { -1 }

      it { is_expected.to fail_to_find_a_model(:guide) }
    end

    context "when another editor saved a newer version" do
      let(:version) { guide.lock_version - 1 }

      it "rejects the stale write and preserves both versions" do
        original_draft = guide.draft_revision.raw
        original_published = guide.published_revision.raw

        expect(result).to fail_a_policy(:current_version)
        expect(guide.reload.draft_revision.raw).to eq(original_draft)
        expect(guide.published_revision.raw).to eq(original_published)
      end
    end

    context "when creating a guide" do
      let(:guide_id) { nil }
      let(:version) { nil }
      let(:slug) { "new-guide" }

      it "persists a draft without publishing it" do
        expect { result }.to change(IsbfGuides::Guide, :count).by(1).and change(
                IsbfGuides::Revision,
                :count,
              ).by(1)
        expect(result).to run_successfully
        created = IsbfGuides::Guide.find_by!(slug:)
        expect(created).not_to be_published
        expect(created.draft_revision).to have_attributes(
          title:,
          summary:,
          raw:,
          editor: acting_user,
        )
      end
    end

    context "when creating a duplicate slug" do
      let(:guide_id) { nil }
      let(:version) { nil }

      it { is_expected.to fail_with_an_invalid_model(:guide) }
    end

    context "when saving an existing guide" do
      it "updates the draft while retaining the published snapshot" do
        published = guide.published_revision
        original_published = published.attributes
        original_version = guide.lock_version

        expect(result).to run_successfully
        expect(guide.reload.draft_revision).to have_attributes(
          title:,
          summary:,
          raw:,
          editor: acting_user,
        )
        expect(guide.lock_version).to be > original_version
        expect(guide.published_revision.reload.attributes).to eq(original_published)
        expect(guide).to have_changes
      end
    end

    context "when changing a published slug" do
      let(:slug) { "renamed-guide" }

      it "rejects the change without modifying the draft" do
        original_draft = guide.draft_revision.raw

        expect(result).to fail_with_exception(ActiveRecord::RecordInvalid)
        expect(guide.reload.slug).not_to eq(slug)
        expect(guide.draft_revision.raw).to eq(original_draft)
      end
    end

    context "when a draft references an unavailable image" do
      let(:raw) { "![Missing image](#{guide.url}/images/missing.png)" }

      it "rolls back the draft and version counter" do
        original_draft = guide.draft_revision.attributes
        original_version = guide.lock_version

        expect(result).to fail_with_exception(ActiveRecord::RecordInvalid)
        expect(guide.reload.draft_revision.attributes).to eq(original_draft)
        expect(guide.lock_version).to eq(original_version)
      end
    end

    context "when a new guide contains an invalid image" do
      let(:guide_id) { nil }
      let(:version) { nil }
      let(:slug) { "invalid-image-guide" }
      let(:raw) { "![External image](https://example.com/public.png)" }

      it "leaves no partially created guide" do
        expect { result }.not_to change(IsbfGuides::Guide, :count)
        expect(result).to fail_with_exception(ActiveRecord::RecordInvalid)
      end
    end

    context "when saving metadata for an HTML draft" do
      fab!(:guide, :isbf_html_guide)

      let(:params) { super().except(:raw) }

      it "keeps the existing HTML source while updating its title and summary" do
        previous_raw = guide.draft_revision.raw
        previous_images = guide.draft_revision.image_ids

        expect(result).to run_successfully
        expect(guide.reload.draft_revision).to have_attributes(
          title:,
          summary:,
          raw: previous_raw,
          content_format: "html",
          image_ids: previous_images,
        )
      end
    end
  end
end
