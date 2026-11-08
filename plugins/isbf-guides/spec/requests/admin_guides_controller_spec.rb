# frozen_string_literal: true

RSpec.describe IsbfGuides::Admin::GuidesController do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:guide, :published_isbf_guide)

  let(:base_url) { "/isbf/guides/admin/guides" }

  before { SiteSetting.isbf_guides_enabled = true }

  describe "#index" do
    it "restricts the administrative listing to administrators" do
      get "#{base_url}.json"
      expect(response.status).to eq(403)

      sign_in(member)
      get "#{base_url}.json"
      expect(response.status).to eq(403)

      sign_in(admin)
      get "#{base_url}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["guides"].first).to include(
        "id" => guide.id,
        "version" => guide.lock_version,
        "published" => true,
        "slug_locked" => true,
      )
    end
  end

  describe "#show" do
    it "exposes draft source only to administrators" do
      sign_in(member)
      get "#{base_url}/#{guide.id}.json"
      expect(response.status).to eq(403)

      sign_in(admin)
      get "#{base_url}/#{guide.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]["draft"]["raw"]).to eq(guide.draft_revision.raw)
    end
  end

  describe "#create" do
    let(:attributes) do
      {
        slug: "android",
        title: "Android notification guide",
        summary: "Configure notifications.",
        raw: "## Setup\n\nSign in first.",
      }
    end

    it "creates a draft and returns its editable state" do
      sign_in(admin)

      expect { post "#{base_url}.json", params: attributes }.to change(
        IsbfGuides::Guide,
        :count,
      ).by(1)

      expect(response.status).to eq(201)
      expect(response.parsed_body["guide"]).to include("slug" => "android", "published" => false)
      expect(response.parsed_body["guide"]["draft"]).to include("raw" => attributes[:raw])
    end

    it "rejects writes from members before any guide is created" do
      sign_in(member)

      expect { post "#{base_url}.json", params: attributes }.not_to change(
        IsbfGuides::Guide,
        :count,
      )

      expect(response.status).to eq(403)
    end

    it "returns validation errors for incomplete content" do
      sign_in(admin)

      post "#{base_url}.json", params: attributes.merge(title: "")

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "#update" do
    let(:attributes) do
      {
        version: guide.lock_version,
        slug: guide.slug,
        title: "Edited title",
        summary: "Edited summary",
        raw: "## Updated draft\n\nAwaiting publication.",
      }
    end

    it "saves new draft content without changing the published content" do
      sign_in(admin)
      original_publication = guide.published_revision.attributes

      put "#{base_url}/#{guide.id}.json", params: attributes

      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]["draft"]["raw"]).to eq(attributes[:raw])
      expect(guide.reload.published_revision.attributes).to eq(original_publication)
    end

    it "returns a conflict for a stale editor" do
      sign_in(admin)
      original_draft = guide.draft_revision.raw

      put "#{base_url}/#{guide.id}.json", params: attributes.merge(version: guide.lock_version - 1)

      expect(response.status).to eq(409)
      expect(guide.reload.draft_revision.raw).to eq(original_draft)
    end

    it "rejects changing an established URL" do
      sign_in(admin)

      put "#{base_url}/#{guide.id}.json", params: attributes.merge(slug: "different-url")

      expect(response.status).to eq(422)
      expect(guide.reload.slug).to eq(attributes[:slug])
    end

    context "with an imported HTML draft" do
      fab!(:guide, :isbf_html_guide)

      it "updates metadata without requiring or replacing the HTML source" do
        sign_in(admin)
        previous_raw = guide.draft_revision.raw

        put "#{base_url}/#{guide.id}.json", params: attributes.except(:raw)

        expect(response.status).to eq(200)
        expect(response.parsed_body["guide"]["draft"]).to include(
          "title" => attributes[:title],
          "raw" => previous_raw,
          "content_format" => "html",
        )
      end

      it "keeps imported images accessible after changing an unpublished guide URL" do
        initial_file = guide_document_upload(guide_document_html(image_source: inline_guide_image))
        document = IsbfGuides::DocumentPackage.read(file: initial_file)
        guide.stage_document!(
          document:,
          actor: admin,
          slug: guide.slug,
          title: guide.draft_revision.title,
          summary: guide.draft_revision.summary,
        )
        guide.reload
        image = guide.images.first
        sign_in(admin)

        put "#{base_url}/#{guide.id}.json",
            params: attributes.except(:raw).merge(slug: "renamed-html")

        expect(response.status).to eq(200)
        expected_image_url = "/guides/renamed-html/images/#{image.filename}"
        get "/guides/renamed-html.json", params: { preview: "1" }
        expect(response.status).to eq(200)
        preview = Nokogiri::HTML5.fragment(response.parsed_body["guide"]["cooked"])
        expect(preview.at_css("img")["src"]).to eq(expected_image_url)
        get expected_image_url
        expect(response.status).to eq(200)
        expect(response.body.b).to eq(guide_image_bytes)
      ensure
        initial_file&.tempfile&.close!
      end
    end
  end

  describe "#import_document" do
    let(:upload) { rack_guide_document(guide_document_html(image_source: inline_guide_image)) }
    let(:metadata) do
      { slug: "html-tutorial", title: "HTML tutorial", summary: "Imported instructions." }
    end

    it "creates an HTML draft that becomes readable only after publishing" do
      sign_in(admin)

      post "#{base_url}/import.json", params: metadata.merge(file: upload)

      expect(response.status).to eq(201)
      saved = response.parsed_body["guide"]
      expect(saved).to include("published" => false)
      expect(saved["draft"]["content_format"]).to eq("html")
      sign_in(member)
      get "#{saved["url"]}.json"
      expect(response.status).to eq(404)

      sign_in(admin)
      post "#{base_url}/#{saved["id"]}/publish.json", params: { version: saved["version"] }
      expect(response.status).to eq(200)

      sign_in(member)
      get "#{saved["url"]}.json"
      expect(response.status).to eq(200)
      document = Nokogiri::HTML5.fragment(response.parsed_body["guide"]["cooked"])
      expect(document.at_css("article#step-01 h3").text).to eq("Open settings")
      expect(document.at_css("figure figcaption").text).to eq("Notification settings screenshot")
    end

    it "replaces an existing draft without changing its publication" do
      sign_in(admin)
      previous_publication = guide.published_revision.attributes
      previous_draft_id = guide.draft_revision_id

      post "#{base_url}/#{guide.id}/import.json",
           params: metadata.merge(slug: guide.slug, version: guide.lock_version, file: upload)

      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]["draft"]["content_format"]).to eq("html")
      expect(guide.reload.draft_revision_id).not_to eq(previous_draft_id)
      expect(guide.published_revision.attributes).to eq(previous_publication)
    end

    it "blocks anonymous and member imports before creating any data" do
      original_count = IsbfGuides::Guide.count

      post "#{base_url}/import.json", params: metadata.merge(file: upload)
      expect(response.status).to eq(403)

      sign_in(member)
      post "#{base_url}/import.json", params: metadata.merge(file: upload)
      expect(response.status).to eq(403)
      expect(IsbfGuides::Guide.count).to eq(original_count)
    end

    it "returns a conflict instead of overwriting a newer draft" do
      sign_in(admin)
      previous_draft = guide.draft_revision.attributes

      post "#{base_url}/#{guide.id}/import.json",
           params: metadata.merge(slug: guide.slug, version: guide.lock_version - 1, file: upload)

      expect(response.status).to eq(409)
      expect(guide.reload.draft_revision.attributes).to eq(previous_draft)
    end

    it "returns a translated document error for malformed source text" do
      sign_in(admin)
      invalid = rack_guide_document("<main>\xFF</main>".b)

      post "#{base_url}/import.json", params: metadata.merge(file: invalid)

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to eq([I18n.t("isbf_guides.errors.document_encoding")])
    end

    it "returns contract errors when metadata is incomplete" do
      sign_in(admin)

      post "#{base_url}/import.json", params: metadata.merge(title: "", file: upload)

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "#template" do
    it "downloads an importable private ZIP through a normal browser GET" do
      sign_in(admin)

      get "#{base_url}/template"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("application/zip")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      file =
        guide_document_upload(response.body.b, filename: "template.zip", type: "application/zip")
      document = IsbfGuides::DocumentPackage.read(file:)
      expect(document.image_sources).to be_present
    ensure
      file&.tempfile&.close!
    end

    it "restricts template downloads to administrators" do
      get "#{base_url}/template.json"
      expect(response.status).to eq(403)

      sign_in(member)
      get "#{base_url}/template.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#source" do
    it "downloads the saved draft as a private ZIP rather than exporting the publication" do
      sign_in(admin)
      guide.draft_revision.update!(raw: "## Unpublished source\n\nSaved draft instructions.")

      get "#{base_url}/#{guide.id}/source"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("application/zip")
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      file = guide_document_upload(response.body.b, filename: "source.zip", type: "application/zip")
      document = Nokogiri::HTML5.fragment(IsbfGuides::DocumentPackage.read(file:).html)
      expect(document.at_css("h2").text).to eq("Unpublished source")
      expect(document.at_css("p").text).to eq("Saved draft instructions.")
    ensure
      file&.tempfile&.close!
    end

    it "restricts saved source downloads to administrators" do
      get "#{base_url}/#{guide.id}/source.json"
      expect(response.status).to eq(403)

      sign_in(member)
      get "#{base_url}/#{guide.id}/source.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#publish" do
    it "publishes the saved draft and returns the new version" do
      sign_in(admin)
      guide.draft_revision.update!(title: "New published title")

      post "#{base_url}/#{guide.id}/publish.json", params: { version: guide.lock_version }

      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]["publication"]["title"]).to eq("New published title")
      expect(guide.reload.published_revision.title).to eq("New published title")
    end

    it "rejects publishing a version that changed after preview" do
      sign_in(admin)
      original_revision_id = guide.published_revision_id

      post "#{base_url}/#{guide.id}/publish.json", params: { version: guide.lock_version - 1 }

      expect(response.status).to eq(409)
      expect(guide.reload.published_revision_id).to eq(original_revision_id)
    end
  end

  describe "#unpublish" do
    it "removes the publication while retaining its draft" do
      sign_in(admin)
      draft = guide.draft_revision

      post "#{base_url}/#{guide.id}/unpublish.json", params: { version: guide.lock_version }

      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]).to include("published" => false, "publication" => nil)
      expect(guide.reload.draft_revision).to eq(draft)
    end
  end

  describe "#upload_image" do
    let(:file) do
      Rack::Test::UploadedFile.new(File.expand_path("../fixtures/step.png", __dir__), "image/png")
    end

    it "stores an administrator upload and returns a private image URL" do
      sign_in(admin)

      expect do post "#{base_url}/#{guide.id}/images.json", params: { file: } end.to change(
        IsbfGuides::Image,
        :count,
      ).by(1)

      expect(response.status).to eq(201)
      expect(response.parsed_body["image"]["url"]).to start_with("#{guide.url}/images/")
      expect(guide.images.last.data).to eq(File.binread(file.path))
    end

    it "rejects member uploads" do
      sign_in(member)

      post "#{base_url}/#{guide.id}/images.json", params: { file: }

      expect(response.status).to eq(403)
    end
  end
end
