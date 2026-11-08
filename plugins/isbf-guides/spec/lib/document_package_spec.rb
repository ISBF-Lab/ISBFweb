# frozen_string_literal: true

RSpec.describe IsbfGuides::DocumentPackage do
  describe ".read" do
    subject(:document) { described_class.read(file:) }

    let(:file) { guide_document_upload(bytes, filename:, type:) }
    let(:filename) { "guide.html" }
    let(:type) { "text/html" }
    let(:bytes) { guide_document_html(image_source: inline_guide_image) }

    after { file.tempfile.close! }

    it "reads structural HTML and removes the document title and global shell" do
      html = Nokogiri::HTML5.fragment(document.html)

      expect(html.at_css("section#prep p").text).to eq("Read this introduction first.")
      expect(html.at_css("article#step-01 h3").text).to eq("Open settings")
      expect(html.at_css("figure figcaption").text).to eq("Notification settings screenshot")
      expect(html.css("h1, header, nav, footer, head")).to be_empty
    end

    it "extracts embedded image bytes without losing the original source reference" do
      expect(document.image_sources).to eq([inline_guide_image])
      expect(document.asset_for(inline_guide_image)).to have_attributes(
        data: guide_image_bytes,
        sha256: Digest::SHA256.hexdigest(guide_image_bytes),
      )
    end

    it "deduplicates repeated source references while retaining both image elements" do
      upload =
        guide_document_upload(
          "<main><img src='#{inline_guide_image}'><img src='#{inline_guide_image}'></main>",
        )
      parsed = described_class.read(file: upload)

      expect(parsed.image_sources).to eq([inline_guide_image])
      expect(Nokogiri::HTML5.fragment(parsed.html).css("img").length).to eq(2)
    ensure
      upload&.tempfile&.close!
    end

    it "rewrites images to the supplied private URLs" do
      private_url = "/guides/android/images/imported.png"
      html = Nokogiri::HTML5.fragment(document.html_with_images(inline_guide_image => private_url))

      expect(html.at_css("img")["src"]).to eq(private_url)
      expect(html.at_css("img")["alt"]).to eq("Notification settings")
      expect(html.at_css("figure figcaption").text).to eq("Notification settings screenshot")
    end

    context "with a standalone htm document" do
      let(:filename) { "guide.htm" }

      it "accepts the alternate HTML extension" do
        expect(document.html).to include("Allow notifications")
      end
    end

    context "with a ZIP containing relative image assets" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        guide_zip_bytes(
          "index.html" => guide_document_html(image_source: "images/setup.png"),
          "images/setup.png" => guide_image_bytes,
        )
      end

      it "resolves image bytes inside the package" do
        expect(document.image_sources).to eq(["images/setup.png"])
        expect(document.asset_for("images/setup.png").data).to eq(guide_image_bytes)
      end
    end

    context "with an existing private guide image URL" do
      let(:source) { "/guides/android/images/existing.png" }
      let(:bytes) { guide_document_html(image_source: source) }

      it "defers only the image bytes for the guide-scoped lookup" do
        expect(document.image_sources).to eq([source])
        expect(document.asset_for(source)).to be_nil
      end
    end

    context "with replacement bytes for a private URL inside the ZIP" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:source) { "/guides/android/images/existing.png" }
      let(:bytes) do
        guide_zip_bytes(
          "index.html" => guide_document_html(image_source: source),
          "images/existing.png" => guide_image_bytes,
        )
      end

      it "uses the packaged image instead of deferring to the existing image" do
        expect(document.asset_for(source).data).to eq(guide_image_bytes)
      end
    end

    context "with a missing relative image" do
      let(:bytes) { guide_document_html(image_source: "images/missing.png") }

      it "rejects a package that would produce broken image links" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with an external image URL" do
      let(:bytes) { guide_document_html(image_source: "https://example.com/setup.png") }

      it "rejects the image without fetching the external address" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with invalid UTF-8" do
      let(:bytes) { "<main>\xFF</main>".b }

      it "rejects text that cannot be safely decoded" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with a traversal image source" do
      let(:bytes) { guide_document_html(image_source: "../outside.png") }

      it "rejects access outside the document package" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with unsafe ZIP entry names" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        guide_zip_bytes("index.html" => guide_document_html, "../outside.png" => guide_image_bytes)
      end

      it "rejects traversal entries even when the document does not reference them" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with an oversized input file" do
      let(:bytes) { " " * (10.megabytes + 1) }

      it "enforces the upload byte limit" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with too many ZIP entries" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        entries = { "index.html" => guide_document_html }
        500.times { |number| entries["extra-#{number}.txt"] = "unused" }
        guide_zip_bytes(entries)
      end

      it "enforces the package entry limit" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with excessive expanded ZIP content" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        guide_zip_bytes(
          "index.html" => guide_document_html,
          "padding.txt" => "x" * (50.megabytes + 1),
        )
      end

      it "enforces the expanded package byte limit" do
        expect { document }.to raise_error(IsbfGuides::DocumentError)
      end
    end

    context "with a malformed ZIP" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) { "This is not a ZIP archive." }

      it "returns a safe document error" do
        expect { document }.to raise_error(IsbfGuides::DocumentError) do |error|
          expect(error.key).to be_present
          expect(error.message).to be_present
          expect(error.message).not_to include(Rails.root.to_s)
        end
      end
    end
  end
end
