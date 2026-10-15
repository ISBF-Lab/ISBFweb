# frozen_string_literal: true

require_relative "../support/isbf_resume_helpers"

RSpec.describe IsbfResume::Export do
  include_context "with private resume storage"

  fab!(:owner, :user)

  describe ".create" do
    it "stores exact content in a private uncompleted task" do
      export = described_class.create(owner_id: owner.id, resume:)
      expect(export.id).to match(described_class::EXPORT_ID)
      expect(export.owner_id).to eq(owner.id)
      expect(JSON.parse(File.read(export.input_path))).to eq(resume)
      expect(File.stat(export.directory).mode & 0o777).to eq(0o700)
      expect(File.stat(export.input_path).mode & 0o777).to eq(0o600)
      expect(export).not_to be_available
      expect(described_class.find(export.id)).to eq(nil)
    end
  end

  describe ".find" do
    it "restores completed metadata without exposing submitted content" do
      export = create_downloadable_resume(owner:)
      restored = described_class.find(export.id)
      expect(restored).to have_attributes(
        id: export.id,
        owner_id: owner.id,
        pages: 1,
        template: "blue-gold"
      )
      expect(restored.created_at.iso8601).to eq(export.created_at.iso8601)
      expect(
        File.stat(File.join(export.directory, "metadata.json")).mode & 0o777
      ).to eq(0o600)
    end

    it "rejects traversal, unknown ids and damaged metadata" do
      export = create_downloadable_resume(owner:)
      File.write(File.join(export.directory, "metadata.json"), "invalid-json")
      expect(
        ["../private", "not-a-uuid", SecureRandom.uuid, export.id].map do |id|
          described_class.find(id)
        end
      ).to eq([nil, nil, nil, nil])
    end

    it "keeps legacy document exports available without image previews" do
      export = create_downloadable_resume(owner:)
      metadata_path = File.join(export.directory, "metadata.json")
      metadata = JSON.parse(File.read(metadata_path))
      metadata.delete("preview_files")
      File.write(metadata_path, JSON.generate(metadata))
      restored = described_class.find(export.id)
      expect(restored).to be_available
      expect(restored.preview_count).to eq(0)
      expect(restored.preview_path(1)).to eq(nil)
      expect(restored.file_path("docx")).to eq(export.file_path("docx"))
      expect(restored.file_path("pdf")).to eq(export.file_path("pdf"))
    end

    it "rejects metadata with a mismatched preview list" do
      export = create_downloadable_resume(owner:)
      metadata_path = File.join(export.directory, "metadata.json")
      metadata = JSON.parse(File.read(metadata_path))
      metadata["preview_files"] = ["../preview-1.png"]
      File.write(metadata_path, JSON.generate(metadata))
      expect(described_class.find(export.id)).to eq(nil)
    end
  end

  describe "#available?" do
    it "expires at the lifetime boundary" do
      export = create_downloadable_resume(owner:)
      expect(export).to be_available
      freeze_time(export.expires_at)
      expect(export).not_to be_available
    end

    it "requires both nonempty regular documents" do
      export = create_downloadable_resume(owner:)
      pdf_path = export.file_path("pdf")
      File.truncate(pdf_path, 0)
      expect(export).not_to be_available
      expect(export.file_path("pdf")).to eq(nil)
    end
  end

  describe "#file_path" do
    it "restricts formats and rejects symbolic links" do
      export = create_downloadable_resume(owner:)
      expect(export.file_path("../../input.json")).to eq(nil)
      expect(export.file_path("txt")).to eq(nil)
      pdf_path = export.file_path("pdf")
      docx_path = export.file_path("docx")
      File.unlink(pdf_path)
      File.symlink(docx_path, pdf_path)
      expect(export.file_path("pdf")).to eq(nil)
      expect(export).not_to be_available
    end
  end

  describe "#complete!" do
    it "keeps incomplete or invalid manifests unavailable" do
      export = described_class.create(owner_id: owner.id, resume:)
      expect {
        export.complete!("template" => "blue-gold", "pages" => 1)
      }.to raise_error(IsbfResume::Generator::GenerationError)
      expect {
        export.complete!("template" => "blue-gold", "pages" => 0)
      }.to raise_error(IsbfResume::Generator::GenerationError)
      expect {
        export.complete!("template" => "unknown", "pages" => 1)
      }.to raise_error(IsbfResume::Generator::GenerationError)
      expect(described_class.find(export.id)).to eq(nil)
    end

    it "requires exact ordered preview filenames for the reported page count" do
      export = described_class.create(owner_id: owner.id, resume:)
      previews = write_resume_file_fixtures(export, pages: 2)
      manifest = {
        "template" => "blue-gold",
        "pages" => 2,
        "preview_files" => previews
      }
      invalid_manifests = [
        manifest.except("preview_files"),
        manifest.merge("preview_files" => []),
        manifest.merge("preview_files" => ["preview-1.png"]),
        manifest.merge("preview_files" => previews.reverse),
        manifest.merge("preview_files" => %w[../preview-1.png preview-2.png]),
        manifest.merge(
          "preview_files" => [
            File.join(export.directory, "preview-1.png"),
            "preview-2.png"
          ]
        ),
        manifest.merge("pages" => 1.5)
      ]
      invalid_manifests.each do |invalid|
        expect { export.complete!(invalid) }.to raise_error(
          IsbfResume::Generator::GenerationError
        )
      end
      expect(described_class.find(export.id)).to eq(nil)
    end

    it "keeps missing or linked preview pages unpublished" do
      export = described_class.create(owner_id: owner.id, resume:)
      previews = write_resume_file_fixtures(export, pages: 2)
      manifest = {
        "template" => "blue-gold",
        "pages" => 2,
        "preview_files" => previews
      }
      last_page = File.join(export.directory, "preview-2.png")
      File.unlink(last_page)
      expect { export.complete!(manifest) }.to raise_error(
        IsbfResume::Generator::GenerationError
      )
      File.symlink(File.join(export.directory, "preview-1.png"), last_page)
      expect { export.complete!(manifest) }.to raise_error(
        IsbfResume::Generator::GenerationError
      )
      expect(described_class.find(export.id)).to eq(nil)
    end
  end

  describe "#preview_path" do
    it "accepts canonical page numbers and bounds them to the export" do
      export = create_downloadable_resume(owner:, pages: 2)
      expect(export.preview_count).to eq(2)
      expect(export.preview_path(1)).to eq(
        File.join(export.directory, "preview-1.png")
      )
      expect(export.preview_path("2")).to eq(
        File.join(export.directory, "preview-2.png")
      )
      invalid_pages = [
        0,
        -1,
        3,
        10_000,
        "01",
        "0",
        "-1",
        "1.0",
        "../1",
        "1/../2",
        1.0,
        true,
        nil
      ]
      expect(invalid_pages.map { |page| export.preview_path(page) }).to all(
        eq(nil)
      )
    end

    it "rejects missing, linked and non-PNG images without disabling documents" do
      export = create_downloadable_resume(owner:)
      path = export.preview_path(1)
      target = File.join(export.directory, "other-image.png")
      File.binwrite(target, IsbfResumeSpecHelpers::PNG_FIXTURE)
      File.unlink(path)
      File.symlink(target, path)
      expect(export.preview_path(1)).to eq(nil)
      File.unlink(path)
      File.binwrite(path, "invalid image")
      expect(export.preview_path(1)).to eq(nil)
      File.unlink(path)
      expect(export.preview_path(1)).to eq(nil)
      expect(export).to be_available
    end

    it "makes images unavailable at the same expiry boundary as documents" do
      export = create_downloadable_resume(owner:)
      freeze_time(export.expires_at)
      expect(export.preview_path(1)).to eq(nil)
      expect(export).not_to be_available
    end
  end
end
