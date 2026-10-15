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
