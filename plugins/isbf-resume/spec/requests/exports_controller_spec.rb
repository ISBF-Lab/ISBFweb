# frozen_string_literal: true

require_relative "../support/isbf_resume_helpers"

RSpec.describe IsbfResume::ExportsController do
  include_context "with private resume storage"

  fab!(:owner, :user)
  fab!(:other_user, :user)
  fab!(:administrator, :admin)

  before { SiteSetting.isbf_resume_enabled = true }

  describe "#create" do
    context "when the owner submits a valid resume" do
      before { sign_in(owner) }

      it "creates both real documents and returns only public export metadata" do
        post "/isbf-resume/exports.json", params: { resume: }, as: :json
        expect(response.status).to eq(201)
        payload = response.parsed_body
        expect(payload.keys).to contain_exactly(
          "id",
          "pages",
          "template",
          "expires_at",
          "docx_url",
          "pdf_url",
          "preview_urls"
        )
        export = IsbfResume::Export.find(payload["id"])
        expect(export.owner_id).to eq(owner.id)
        expect(export).to be_available
        expect(File.exist?(export.input_path)).to eq(false)
        expect(payload["preview_urls"]).to eq(
          (1..export.pages).map do |page|
            "/isbf-resume/exports/#{export.id}/previews/#{page}"
          end
        )

        get payload["docx_url"]
        expect(response.status).to eq(200)
        expect(response.body.b[0, 4]).to eq("PK\x03\x04".b)
        get payload["pdf_url"]
        expect(response.status).to eq(200)
        expect(response.body.b[0, 5]).to eq("%PDF-".b)
        get payload["preview_urls"].first
        expect(response.status).to eq(200)
        expect(response.media_type).to eq("image/png")
        expect(response.body.b[0, 8]).to eq(IsbfResume::Export::PNG_SIGNATURE)
      end
    end

    context "when the caller is a visitor" do
      it "requires authentication before creating files" do
        post "/isbf-resume/exports.json", params: { resume: }, as: :json
        expect(response.status).to eq(403)
        expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
      end
    end

    context "when the plugin is disabled" do
      before do
        sign_in(owner)
        SiteSetting.isbf_resume_enabled = false
      end

      it "hides the generation route" do
        post "/isbf-resume/exports.json", params: { resume: }, as: :json
        expect(response.status).to eq(404)
        expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
      end
    end

    context "when the request has the wrong structure" do
      before { sign_in(owner) }

      it "returns a contract error without accepting an array" do
        post "/isbf-resume/exports.json", params: { resume: [] }, as: :json
        expect(response.status).to eq(400)
        expect(response.parsed_body.keys).to contain_exactly("errors")
        expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
      end
    end

    context "when content fails validation" do
      before { sign_in(owner) }

      it "returns field paths and leaves no downloadable metadata" do
        invalid =
          resume.deep_merge("basic" => { "email" => "invalid" }).merge(
            "unsupported" => "保留而不能静默丢弃的内容"
          )
        post "/isbf-resume/exports.json", params: { resume: invalid }, as: :json
        expect(response.status).to eq(422)
        expect(response.parsed_body.keys).to contain_exactly(
          "errors",
          "field_errors"
        )
        expect(response.parsed_body["field_errors"].keys).to contain_exactly(
          "basic.email",
          "document"
        )
        expect(
          Dir.glob(
            File.join(IsbfResume::Export.storage_path, "*", "input.json")
          )
        ).to be_empty
        expect(
          Dir.glob(
            File.join(IsbfResume::Export.storage_path, "*", "metadata.json")
          )
        ).to be_empty
      end
    end

    context "when the encoded request exceeds the byte limit" do
      before { sign_in(owner) }

      it "rejects the body before creating private files" do
        stub_const(IsbfResume, :MAX_REQUEST_BYTES, 128) do
          post "/isbf-resume/exports.json", params: { resume: }, as: :json
          expect(response.status).to eq(400)
          expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
        end
      end
    end

    context "when the generator is unavailable" do
      before { sign_in(owner) }

      around do |example|
        with_resume_environment(
          "ISBF_RESUME_PYTHON" =>
            File.join(IsbfResume::Export.storage_path, "missing-python")
        ) { example.run }
      end

      it "returns a safe generation error without exposing storage paths" do
        post "/isbf-resume/exports.json", params: { resume: }, as: :json
        expect(response.status).to eq(422)
        expect(response.parsed_body.keys).to contain_exactly("errors")
        expect(response.body).not_to include(IsbfResume::Export.storage_path)
        expect(
          Dir.glob(
            File.join(IsbfResume::Export.storage_path, "*", "input.json")
          )
        ).to be_empty
      end
    end
  end

  describe "#download" do
    let(:export) { create_downloadable_resume(owner:) }

    context "when the owner downloads documents" do
      before { sign_in(owner) }

      it "serves both formats privately and supports inline PDF preview" do
        get "/isbf-resume/exports/#{export.id}/docx"
        expect(response.status).to eq(200)
        expect(response.media_type).to eq(
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
        expect(response.headers["Content-Disposition"]).to include(
          "attachment",
          "resume-blue-gold.docx"
        )
        expect(response.headers["Cache-Control"]).to include(
          "private",
          "no-store"
        )
        expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")

        get "/isbf-resume/exports/#{export.id}/pdf", params: { inline: "1" }
        expect(response.status).to eq(200)
        expect(response.media_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include(
          "inline",
          "resume-blue-gold.pdf"
        )
        expect(response.headers["Cache-Control"]).to include(
          "private",
          "no-store"
        )
      end
    end

    context "when another user requests the private export" do
      it "returns the same missing-resource status for members and administrators" do
        export_id = export.id
        [other_user, administrator].each do |viewer|
          sign_in(viewer)
          get "/isbf-resume/exports/#{export_id}/pdf"
          expect(response.status).to eq(404)
          expect(response.body).not_to include(resume["basic"]["email"])
        end
      end
    end

    context "when the caller is a visitor" do
      it "requires authentication" do
        get "/isbf-resume/exports/#{export.id}/pdf.json"
        expect(response.status).to eq(403)
      end
    end

    context "when the plugin is disabled" do
      before do
        sign_in(owner)
        SiteSetting.isbf_resume_enabled = false
      end

      it "hides existing exports" do
        get "/isbf-resume/exports/#{export.id}/pdf"
        expect(response.status).to eq(404)
      end
    end

    context "when the export has expired" do
      before { sign_in(owner) }

      it "returns a missing-resource status at expiry" do
        export_id = export.id
        freeze_time(export.expires_at)
        get "/isbf-resume/exports/#{export_id}/pdf"
        expect(response.status).to eq(404)
      end
    end

    context "when the export id or format is invalid" do
      before { sign_in(owner) }

      it "returns a missing-resource status for unrecognized ids and file types" do
        get "/isbf-resume/exports/not-a-uuid/pdf"
        expect(response.status).to eq(404)
        get "/isbf-resume/exports/#{SecureRandom.uuid}/pdf"
        expect(response.status).to eq(404)
        get "/isbf-resume/exports/#{export.id}/txt"
        expect(response.status).to eq(404)
      end
    end

    context "when a document is missing" do
      before { sign_in(owner) }

      it "keeps the incomplete export private" do
        export_id = export.id
        File.unlink(export.file_path("pdf"))
        get "/isbf-resume/exports/#{export_id}/docx"
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#preview" do
    let(:export) { create_downloadable_resume(owner:) }

    context "when the owner requests an image" do
      before { sign_in(owner) }

      it "serves a PNG privately without requiring an XHR request" do
        get "/isbf-resume/exports/#{export.id}/previews/1"
        expect(response.status).to eq(200)
        expect(response.media_type).to eq("image/png")
        expect(response.body.b).to eq(IsbfResumeSpecHelpers::PNG_FIXTURE)
        expect(response.headers["Cache-Control"]).to include(
          "private",
          "no-store"
        )
        expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
        expect(response.headers["Content-Disposition"]).to include(
          "inline",
          "preview-1.png"
        )
      end
    end

    context "when another member or administrator requests an image" do
      it "hides the private preview from both actors" do
        export_id = export.id
        [other_user, administrator].each do |viewer|
          sign_in(viewer)
          get "/isbf-resume/exports/#{export_id}/previews/1"
          expect(response.status).to eq(404)
        end
      end
    end

    context "when the caller is a visitor" do
      it "requires authentication before serving image bytes" do
        get "/isbf-resume/exports/#{export.id}/previews/1"
        expect(response.status).to eq(403)
      end
    end

    context "when the feature is disabled" do
      before do
        sign_in(owner)
        SiteSetting.isbf_resume_enabled = false
      end

      it "hides the private image" do
        get "/isbf-resume/exports/#{export.id}/previews/1"
        expect(response.status).to eq(404)
      end
    end

    context "when the export has expired" do
      before { sign_in(owner) }

      it "hides the image at expiry" do
        export_id = export.id
        freeze_time(export.expires_at)
        get "/isbf-resume/exports/#{export_id}/previews/1"
        expect(response.status).to eq(404)
      end
    end

    context "when the id or page is invalid" do
      before { sign_in(owner) }

      it "rejects out-of-range, noncanonical and traversal-shaped page identifiers" do
        %w[0 2 -1 01 1.0 invalid %2e%2e].each do |page|
          get "/isbf-resume/exports/#{export.id}/previews/#{page}"
          expect(response.status).to eq(404)
        end
        get "/isbf-resume/exports/#{SecureRandom.uuid}/previews/1"
        expect(response.status).to eq(404)
      end
    end

    context "when the image is missing" do
      before { sign_in(owner) }

      it "hides the image while keeping document downloads available" do
        export_id = export.id
        File.unlink(export.preview_path(1))
        get "/isbf-resume/exports/#{export_id}/previews/1"
        expect(response.status).to eq(404)
        get "/isbf-resume/exports/#{export_id}/pdf"
        expect(response.status).to eq(200)
        expect(response.media_type).to eq("application/pdf")
      end
    end

    context "when the export metadata predates image previews" do
      before { sign_in(owner) }

      it "returns no preview URLs while serving the original documents" do
        metadata_path = File.join(export.directory, "metadata.json")
        metadata = JSON.parse(File.read(metadata_path))
        metadata.delete("preview_files")
        File.write(metadata_path, JSON.generate(metadata))
        restored = IsbfResume::Export.find(export.id)
        payload =
          IsbfResume::ExportSerializer
            .new(restored, root: false)
            .as_json
            .deep_stringify_keys
        expect(payload["preview_urls"]).to eq([])
        get "/isbf-resume/exports/#{export.id}/previews/1"
        expect(response.status).to eq(404)
        get "/isbf-resume/exports/#{export.id}/docx"
        expect(response.status).to eq(200)
      end
    end
  end
end
