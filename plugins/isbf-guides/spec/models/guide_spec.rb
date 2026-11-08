# frozen_string_literal: true

RSpec.describe IsbfGuides::Guide do
  fab!(:guide, :published_isbf_guide)

  describe "#update" do
    it "keeps a published URL fixed after the guide is unpublished" do
      original_slug = guide.slug
      guide.update!(published_revision: nil)

      expect(guide.update(slug: "different-slug")).to eq(false)
      expect(guide.reload.slug).to eq(original_slug)
    end

    it "allows a draft URL to change before its first publication" do
      draft = Fabricate(:isbf_guide)

      expect(draft.update(slug: "new-draft-url")).to eq(true)
      expect(draft.url).to eq("/guides/new-draft-url")
    end
  end

  describe ".published" do
    it "returns published guides while excluding drafts and unpublished guides" do
      draft = Fabricate(:isbf_guide)
      unpublished = Fabricate(:published_isbf_guide)
      unpublished.update!(published_revision: nil)

      expect(described_class.published).to contain_exactly(guide)
      expect(draft).not_to be_published
    end
  end

  describe "#has_changes?" do
    it "keeps an unchanged imported guide clean after anchor metadata is reloaded" do
      actor = Fabricate(:admin)
      document = Fabricate(:isbf_guide, editor: actor)
      attributes = {
        guide_id: document.id,
        slug: document.slug,
        title: "Anchored guide",
        summary: "Instructions with legacy anchors.",
        raw: "## A longer heading\n\nFirst instructions.\n\n## Short\n\nNext instructions.",
      }
      anchors = { "A longer heading" => "legacy-first", "Short" => "legacy-second" }
      initial_save =
        IsbfGuides::SaveDraft.call(
          params: attributes.merge(version: document.lock_version),
          guardian: actor.guardian,
          options: {
            anchors:,
          },
        )
      expect(initial_save).to run_successfully

      publication =
        IsbfGuides::Publish.call(
          params: {
            guide_id: document.id,
            version: document.reload.lock_version,
          },
          guardian: actor.guardian,
        )
      expect(publication).to run_successfully

      unchanged_save =
        IsbfGuides::SaveDraft.call(
          params: attributes.merge(version: document.reload.lock_version),
          guardian: actor.guardian,
        )

      expect(unchanged_save).to run_successfully
      expect(document.reload).not_to have_changes
    end
  end
end
