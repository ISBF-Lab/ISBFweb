# frozen_string_literal: true

RSpec.describe IsbfGuides::DocumentArchive do
  describe ".template" do
    it "produces an importable HTML document with its example image" do
      file =
        guide_document_upload(
          described_class.template,
          filename: "template.zip",
          type: "application/zip",
        )
      document = IsbfGuides::DocumentPackage.read(file:)

      expect(document.html).to be_present
      expect(document.image_sources).to be_present
      expect(document.image_sources.map { |source| document.asset_for(source).data }).to all(
        be_present,
      )
    ensure
      file&.tempfile&.close!
    end
  end

  describe "#data" do
    fab!(:guide, :isbf_html_guide)
    fab!(:image) { Fabricate(:isbf_guide_image, guide:) }

    before do
      file = guide_document_upload(guide_document_html(image_source: image.url))
      document = IsbfGuides::DocumentPackage.read(file:)
      guide.draft_revision.update!(raw: document.html)
    ensure
      file&.tempfile&.close!
    end

    it "roundtrips saved HTML structure and original image bytes" do
      revision = guide.draft_revision
      file =
        guide_document_upload(
          described_class.new(revision:).data,
          filename: "source.zip",
          type: "application/zip",
        )
      document = IsbfGuides::DocumentPackage.read(file:)
      mapping = document.image_sources.to_h { |source| [source, image.url] }
      restored = Nokogiri::HTML5.fragment(document.html_with_images(mapping))
      original = Nokogiri::HTML5.fragment(revision.raw)

      expect(restored.element_children.map(&:to_html)).to eq(
        original.element_children.map(&:to_html),
      )
      expect(document.image_sources.map { |source| document.asset_for(source).data }).to eq(
        [image.data],
      )
    ensure
      file&.tempfile&.close!
    end

    it "exports only the current draft's referenced images" do
      unused = Fabricate(:isbf_guide_image, guide:)
      data = described_class.new(revision: guide.draft_revision).data
      entries = guide_zip_contents(data).keys

      expect(entries).to contain_exactly("index.html", "images/#{image.filename}")
      expect(entries).not_to include("images/#{unused.filename}")
    end

    it "escapes the current metadata title in the source document" do
      title = '<script>alert("title")</script> & guide'
      guide.draft_revision.update!(title:)
      data = described_class.new(revision: guide.draft_revision).data
      html = guide_zip_contents(data).fetch("index.html")
      document = Nokogiri.HTML5(html)

      expect(document.at_css("title").text).to eq(title)
      expect(document.at_css("h1").text).to eq(title)
      expect(document.css("script")).to be_empty
    end

    it "exports an existing Markdown draft as readable HTML" do
      markdown = Fabricate(:isbf_guide)
      screenshot = Fabricate(:isbf_guide_image, guide: markdown)
      markdown.draft_revision.update!(
        raw:
          "## Markdown setup\n\nKeep **forum messages** enabled.\n\n![Existing screenshot](#{screenshot.url})",
      )
      data = described_class.new(revision: markdown.draft_revision).data
      file = guide_document_upload(data, filename: "markdown-source.zip", type: "application/zip")
      package = IsbfGuides::DocumentPackage.read(file:)
      document = Nokogiri::HTML5.fragment(package.html)

      expect(document.at_css("h2").text).to eq("Markdown setup")
      expect(document.at_css("strong").text).to eq("forum messages")
      expect(package.image_sources.map { |source| package.asset_for(source).data }).to eq(
        [screenshot.data],
      )
    ensure
      file&.tempfile&.close!
    end
  end
end
