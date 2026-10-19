# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharedPdf do
  include_context "with private shared resume storage"

  describe ".store" do
    it "accepts only uploaded files rather than strings or arbitrary file metadata" do
      [nil, "%PDF-1.7", { filename: "resume.pdf", path: "/tmp/resume.pdf" }].each do |upload|
        expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)
      end

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "stores a real PDF without rendering it, then renders only requested pages privately" do
      upload = sharing_pdf_upload(filename: "Example.PDF", pages: 2)
      expected_bytes = File.binread(upload.path)

      pdf = described_class.store(upload)

      expect(pdf).to have_attributes(
        pages: 2,
        filename_title: "Example",
        bytes: expected_bytes.bytesize,
        sha256: Digest::SHA256.hexdigest(expected_bytes),
      )
      expect(File.binread(pdf.available_path)).to eq(expected_bytes)
      expect(Dir.children(pdf.directory)).to eq(["resume.pdf"])
      preview = pdf.render_preview!(2)
      expect(File.binread(preview, 8)).to eq(described_class::PNG_SIGNATURE)
      expect(pdf.preview_path(1)).to eq(nil)
      expect(pdf.render_preview!(2)).to eq(preview)
      expect(File.stat(pdf.directory).mode & 0o777).to eq(0o700)
      expect(File.stat(pdf.pdf_path).mode & 0o777).to eq(0o600)
      expect(File.stat(preview).mode & 0o777).to eq(0o600)
    end

    it "rejects a renamed non-PDF and leaves no stored submission" do
      upload = sharing_raw_upload(content: "PK\x03\x04word document")

      expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "requires the PDF extension even when the file contains a valid PDF" do
      upload = sharing_pdf_upload(filename: "resume.docx")

      expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "rejects empty and oversized uploads before retaining files" do
      empty = sharing_raw_upload(content: "")
      oversized = sharing_raw_upload(content: "%PDF-" + " " * described_class::MAX_BYTES)

      [empty, oversized].each do |upload|
        expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)
      end

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "rejects a damaged PDF with a correct signature and removes partial previews" do
      upload = sharing_raw_upload(content: "%PDF-1.7\ntruncated document\n%%EOF")

      expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "rejects encrypted documents even when the uploader provides a valid PDF" do
      upload = sharing_pdf_upload(encrypted: true)

      expect { described_class.store(upload) }.to raise_error(
        described_class::InvalidPdf,
      ) do |error|
        expect(error.reason).to eq("pdf_encrypted")
      end

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "rejects documents outside the supported page-count boundary" do
      [0, 101].each do |pages|
        upload = sharing_pdf_upload(pages: pages)
        expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)
      end

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "rejects documents with invalid page dimensions" do
      upload = sharing_pdf_upload(width: 0)

      expect { described_class.store(upload) }.to raise_error(described_class::InvalidPdf)

      expect(Dir.children(described_class.storage_path)).to be_empty
    end

    it "validates document content independently of the declared MIME type" do
      upload = sharing_pdf_upload
      upload.content_type = "text/plain"

      pdf = described_class.store(upload)

      expect(pdf.pages).to eq(1)
      expect(File.binread(pdf.available_path, 5)).to eq("%PDF-")
    end
  end

  describe ".store_preview" do
    it "renders only the first three PDF pages and removes this upload's stored original" do
      upload = sharing_pdf_upload(filename: "Long resume.pdf", pages: 5)
      original_bytes = File.binread(upload.path)

      preview = described_class.store_preview(file: upload)

      expect(preview).to have_attributes(
        pages: 3,
        filename_title: "Long resume",
        bytes: original_bytes.bytesize,
        sha256: Digest::SHA256.hexdigest(original_bytes),
        available_path: nil,
      )
      expect(Dir.children(preview.directory)).to contain_exactly(
        "preview-1.png",
        "preview-2.png",
        "preview-3.png",
      )
      (1..3).each do |page|
        path = preview.preview_path(page)
        expect(File.binread(path, 8)).to eq(described_class::PNG_SIGNATURE)
        expect(File.stat(path).mode & 0o777).to eq(0o600)
      end
      expect(preview.preview_path(4)).to eq(nil)
      expect(File.stat(preview.directory).mode & 0o777).to eq(0o700)
    end

    it "converts PNG, JPEG and WebP uploads into three ordered private PNG previews" do
      images = [
        sharing_image_upload,
        sharing_image_upload(filename: "second.jpg", format: "JPEG"),
        sharing_image_upload(filename: "third.webp", format: "WEBP"),
      ]

      preview = described_class.store_preview(images: images)

      expect(preview.pages).to eq(3)
      expect(preview.available_path).to eq(nil)
      expect(preview.sha256).to match(/\A[0-9a-f]{64}\z/)
      expect(preview.bytes).to eq(images.sum(&:size))
      expect(Dir.children(preview.directory)).to contain_exactly(
        "preview-1.png",
        "preview-2.png",
        "preview-3.png",
      )
      expect((1..3).map { |page| File.binread(preview.preview_path(page), 8) }).to eq(
        [described_class::PNG_SIGNATURE] * 3,
      )
    end

    it "requires exactly one uploaded preview source and at most three images" do
      pdf = sharing_pdf_upload
      image = sharing_image_upload
      [
        {},
        { images: [] },
        { file: pdf, images: [image] },
        { images: [image] * 4 },
        { images: ["/tmp/forged.png"] },
      ].each do |sources|
        expect { described_class.store_preview(**sources) }.to raise_error(
          described_class::InvalidPdf,
        )
      end

      expect(Dir.glob(File.join(described_class.storage_path, "*"))).to be_empty
    end

    it "checks image content and rejects a mixed upload without retaining partial previews" do
      invalid = sharing_raw_upload(content: "%PDF-1.7\nnot an image", filename: "spoofed.png")
      renamed = sharing_image_upload(filename: "unsupported.gif")

      [[sharing_image_upload, invalid], [renamed]].each do |images|
        expect { described_class.store_preview(images: images) }.to raise_error(
          described_class::InvalidPdf,
        )
      end

      expect(Dir.glob(File.join(described_class.storage_path, "*"))).to be_empty
    end

    it "rejects image uploads whose combined size exceeds ten MiB before retaining files" do
      bytes = described_class::PNG_SIGNATURE + ("x" * (described_class::MAX_BYTES / 2))
      images =
        %w[first.png second.png].map do |filename|
          sharing_raw_upload(content: bytes, filename: filename, content_type: "image/png")
        end

      expect { described_class.store_preview(images: images) }.to raise_error(
        described_class::InvalidPdf,
      )

      expect(Dir.glob(File.join(described_class.storage_path, "*"))).to be_empty
    end

    it "keeps an existing historical PDF intact while a new preview upload is rejected" do
      historical = described_class.store(sharing_pdf_upload)
      original_bytes = File.binread(historical.available_path)
      invalid = sharing_raw_upload(content: "%PDF-1.7\ntruncated document")

      expect { described_class.store_preview(file: invalid) }.to raise_error(
        described_class::InvalidPdf,
      )

      expect(File.binread(historical.available_path)).to eq(original_bytes)
      expect(Dir.glob(File.join(described_class.storage_path, "*"))).to eq([historical.directory])
    end

    it "discards a new PDF when preview generation is busy" do
      upload = sharing_pdf_upload
      File.open(File.join(described_class.storage_path, ".preview.lock"), "w", 0o600) do |lock|
        lock.flock(File::LOCK_EX)

        expect { described_class.store_preview(file: upload) }.to raise_error(
          described_class::PreviewUnavailable,
        )

        expect(Dir.glob(File.join(described_class.storage_path, "*"))).to be_empty
      end
    end
  end

  describe "#available_path" do
    it "refuses a symlinked PDF even when its target is a valid file" do
      pdf = described_class.store(sharing_pdf_upload)
      moved_path = File.join(@sharing_fixture_directory, "moved.pdf")
      File.rename(pdf.pdf_path, moved_path)
      File.symlink(moved_path, pdf.pdf_path)

      expect(pdf.available_path).to eq(nil)
    end
  end

  describe "#preview_path" do
    it "accepts only existing, canonical page numbers inside the document" do
      pdf = described_class.store(sharing_pdf_upload)
      pdf.render_preview!(1)

      expect(pdf.preview_path(1)).to eq(File.join(pdf.directory, "preview-1.png"))
      expect(%w[0 2 -1 01 1.0 ../resume.pdf].map { |page| pdf.preview_path(page) }).to eq([nil] * 6)
    end

    it "refuses a forged or symlinked preview" do
      pdf = described_class.store(sharing_pdf_upload)
      pdf.render_preview!(1)
      preview = pdf.preview_path(1)
      File.binwrite(preview, "not an image")
      expect(pdf.preview_path(1)).to eq(nil)
      File.unlink(preview)
      target = File.join(@sharing_fixture_directory, "preview.png")
      File.binwrite(target, described_class::PNG_SIGNATURE)
      File.symlink(target, preview)

      expect(pdf.preview_path(1)).to eq(nil)
    end
  end

  describe "#render_preview!" do
    it "accepts a 58-page PDF and previews its last page without rendering preceding pages" do
      pdf = described_class.store(sharing_pdf_upload(pages: 58))
      original_sha256 = pdf.sha256

      expect(pdf.pages).to eq(58)
      expect(Dir.children(pdf.directory)).to eq(["resume.pdf"])
      preview = pdf.render_preview!(58)
      expect(File.binread(preview, 8)).to eq(described_class::PNG_SIGNATURE)
      expect(Dir.children(pdf.directory)).to contain_exactly("resume.pdf", "preview-58.png")
      expect(Digest::SHA256.file(pdf.available_path).hexdigest).to eq(original_sha256)
    end

    it "allows retry when the renderer is busy while retaining the original PDF" do
      pdf = described_class.store(sharing_pdf_upload)
      File.open(File.join(described_class.storage_path, ".preview.lock"), "w", 0o600) do |lock|
        lock.flock(File::LOCK_EX)
        expect { pdf.render_preview!(1) }.to raise_error(described_class::PreviewUnavailable)
        expect(pdf.preview_path(1)).to eq(nil)
        expect(File.binread(pdf.available_path, 5)).to eq("%PDF-")
      end

      expect(File.binread(pdf.render_preview!(1), 8)).to eq(described_class::PNG_SIGNATURE)
    end
  end
end
