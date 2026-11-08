# frozen_string_literal: true

RSpec.describe IsbfGuides::Revision do
  fab!(:guide, :published_isbf_guide)

  describe "#update" do
    it "rejects updates to published snapshots" do
      publication = guide.published_revision
      previous = publication.attributes

      expect(publication.update(raw: "## Changed\n\nChanged content.")).to eq(false)
      expect(publication.reload.attributes).to eq(previous)
    end

    it "rebakes draft content and updates its directory" do
      draft = guide.draft_revision
      draft.update!(raw: "## New section\n\n### New subsection\n\nInstructions.")

      expect(draft.reload.cooked).to include("New section", "New subsection")
      expect(draft.toc.map { |entry| entry["title"] }).to eq(["New section", "New subsection"])
      expect(guide.reload).to have_changes
    end

    it "rerenders content when its format changes without changing the source text" do
      draft = guide.draft_revision
      draft.update!(raw: "## Literal heading\n\nKeep **these asterisks**.")
      source = draft.raw
      markdown_digest = draft.content_digest

      draft.update!(content_format: "html")

      expect(draft.reload.raw).to eq(source)
      expect(draft.content_digest).not_to eq(markdown_digest)
      document = Nokogiri::HTML5.fragment(draft.cooked)
      expect(document.css("h2, strong")).to be_empty
      expect(document.text).to include("## Literal heading", "**these asterisks**")
    end

    it "rejects unsupported content formats without changing stored content" do
      draft = guide.draft_revision
      previous = draft.attributes

      expect(draft.update(content_format: "xml")).to eq(false)
      expect(draft.reload.attributes).to eq(previous)
    end
  end
end
