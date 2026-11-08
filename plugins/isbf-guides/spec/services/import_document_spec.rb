# frozen_string_literal: true

RSpec.describe IsbfGuides::ImportDocument do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:slug).is_at_most(80) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:summary).is_at_most(1000) }
    it { is_expected.to allow_values("android", "getting-started-2").for(:slug) }
    it { is_expected.not_to allow_values("../android", "UPPERCASE", "has space").for(:slug) }

    it "requires an optimistic version for an existing guide" do
      contract = described_class.new(guide_id: 1)

      expect(contract).to validate_presence_of(:version)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:guide, :published_isbf_guide)

    let(:params) { { guide_id:, version:, slug:, title:, summary: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new, options: { file: } } }
    let(:guide_id) { nil }
    let(:version) { nil }
    let(:slug) { "imported-html" }
    let(:title) { "Imported notification guide" }
    let(:summary) { "Imported HTML instructions." }
    let(:filename) { "guide.html" }
    let(:type) { "text/html" }
    let(:bytes) { guide_document_html(image_source: inline_guide_image) }
    let(:file) { guide_document_upload(bytes, filename:, type:) }

    before { SiteSetting.isbf_guides_enabled = true }
    after { file.tempfile.close! }

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

    context "with an unsupported upload" do
      let(:filename) { "guide.pdf" }
      let(:type) { "application/pdf" }

      it { is_expected.to fail_a_policy(:valid_upload) }
    end

    context "when the document cannot be decoded" do
      let(:bytes) { "<main>\xFF</main>".b }

      it "returns a document error before creating any guide data" do
        expect { result }.not_to change(IsbfGuides::Guide, :count)
        expect(result).to fail_with_exception(IsbfGuides::DocumentError)
      end
    end

    context "when creating a guide" do
      it "saves a private HTML draft without publishing it" do
        expect { result }.to change(IsbfGuides::Guide, :count).by(1).and change(
                IsbfGuides::Image,
                :count,
              ).by(1)
        expect(result).to run_successfully
        created = IsbfGuides::Guide.find_by!(slug:)
        expect(created).not_to be_published
        expect(created.draft_revision).to have_attributes(title:, summary:, content_format: "html")
        expect(created.draft_revision.image_ids).to eq(created.images.pluck(:id))
        document = Nokogiri::HTML5.fragment(created.draft_revision.cooked)
        expect(document.at_css("article#step-01 h3").text).to eq("Open settings")
        expect(document.at_css("img")["src"]).to eq(created.images.first.url)
      end
    end

    context "when a new slug is already in use" do
      let(:slug) { guide.slug }

      it { is_expected.to fail_with_an_invalid_model(:guide) }
    end

    context "when updating a guide" do
      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version }
      let(:slug) { guide.slug }

      it "creates a fresh HTML draft while preserving the Markdown publication" do
        previous_draft = guide.draft_revision
        publication = guide.published_revision.attributes

        expect(result).to run_successfully
        expect(guide.reload.draft_revision_id).not_to eq(previous_draft.id)
        expect(guide.draft_revision.content_format).to eq("html")
        expect(previous_draft.reload.content_format).to eq("markdown")
        expect(guide.published_revision.reload.attributes).to eq(publication)
      end
    end

    context "when the existing guide is missing" do
      let(:guide_id) { -1 }
      let(:version) { 0 }

      it { is_expected.to fail_to_find_a_model(:guide) }
    end

    context "when the existing guide has a newer version" do
      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version - 1 }
      let(:slug) { guide.slug }

      it "rejects a stale import without changing its content or images" do
        previous_draft = guide.draft_revision.attributes

        expect { result }.not_to change(IsbfGuides::Image, :count)
        expect(result).to fail_a_policy(:current_version)
        expect(guide.reload.draft_revision.attributes).to eq(previous_draft)
      end
    end

    context "when imported assets contain duplicate image bytes" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        html =
          guide_document_html(image_source: "images/one.png").sub(
            "</article>",
            "<img src='images/two.png' alt='Repeated screenshot'></article>",
          )
        guide_zip_bytes(
          "index.html" => html,
          "images/one.png" => guide_image_bytes,
          "images/two.png" => guide_image_bytes,
        )
      end

      it "reuses one private image without dropping either figure image" do
        expect { result }.to change(IsbfGuides::Image, :count).by(1)
        expect(result).to run_successfully
        created = IsbfGuides::Guide.find_by!(slug:)
        expect(created.draft_revision.image_ids.length).to eq(1)
        expect(Nokogiri::HTML5.fragment(created.draft_revision.cooked).css("img").length).to eq(2)
      end
    end

    context "when an imported image has invalid bytes" do
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:bytes) do
        html =
          guide_document_html(image_source: "images/valid.png").sub(
            "</article>",
            "<img src='images/invalid.png' alt='Invalid screenshot'></article>",
          )
        guide_zip_bytes(
          "index.html" => html,
          "images/valid.png" => guide_image_bytes,
          "images/invalid.png" => "This is not image data.",
        )
      end

      it "rolls back the guide, fresh revision and partially staged images" do
        original_guides = IsbfGuides::Guide.count
        original_revisions = IsbfGuides::Revision.count
        original_images = IsbfGuides::Image.count

        expect(result).to fail_with_exception
        expect(IsbfGuides::Guide.count).to eq(original_guides)
        expect(IsbfGuides::Revision.count).to eq(original_revisions)
        expect(IsbfGuides::Image.count).to eq(original_images)
      end
    end

    context "when reusing an existing image from the same guide" do
      fab!(:image) { Fabricate(:isbf_guide_image, guide:) }

      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version }
      let(:slug) { guide.slug }
      let(:bytes) { guide_document_html(image_source: image.url) }

      it "retains the existing private image bytes" do
        expect { result }.not_to change(IsbfGuides::Image, :count)
        expect(result).to run_successfully
        expect(guide.reload.draft_revision.image_ids).to eq([image.id])
        expect(image.reload.data).to eq(guide_image_bytes)
      end
    end

    context "when a private image belongs to another guide" do
      fab!(:image, :isbf_guide_image)

      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version }
      let(:slug) { guide.slug }
      let(:bytes) { guide_document_html(image_source: image.url) }

      it "rejects the cross-guide image without replacing the saved draft" do
        previous_draft = guide.draft_revision_id

        expect(result).to fail_with_exception(IsbfGuides::DocumentError)
        expect(guide.reload.draft_revision_id).to eq(previous_draft)
      end
    end

    context "when reimporting an unpublished guide under a new URL" do
      fab!(:guide, :isbf_html_guide)

      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version }
      let(:slug) { "renamed-import" }
      let(:image) { guide.images.first }
      let(:bytes) { guide_document_html(image_source: image.url) }

      before do
        initial_file = guide_document_upload(guide_document_html(image_source: inline_guide_image))
        document = IsbfGuides::DocumentPackage.read(file: initial_file)
        guide.stage_document!(
          document:,
          actor: acting_user,
          slug: guide.slug,
          title: guide.draft_revision.title,
          summary: guide.draft_revision.summary,
        )
        guide.reload
      ensure
        initial_file&.tempfile&.close!
      end

      it "reuses its old private image only within the same guide" do
        existing_image_id = image.id

        expect { result }.not_to change(IsbfGuides::Image, :count)
        expect(result).to run_successfully
        expect(guide.reload.slug).to eq(slug)
        expect(guide.draft_revision.image_ids).to eq([existing_image_id])
        rendered = Nokogiri::HTML5.fragment(guide.draft_revision.cooked)
        expect(rendered.at_css("img")["src"]).to eq("#{guide.url}/images/#{image.filename}")
        expect(image.reload.data).to eq(guide_image_bytes)
      end
    end

    context "when a ZIP replaces an image used by the publication" do
      fab!(:image) { Fabricate(:isbf_guide_image, guide:) }

      let(:guide_id) { guide.id }
      let(:version) { guide.lock_version }
      let(:slug) { guide.slug }
      let(:filename) { "guide.zip" }
      let(:type) { "application/zip" }
      let(:replacement_bytes) { guide_image_bytes + "replacement" }
      let(:bytes) do
        guide_zip_bytes(
          "index.html" => guide_document_html(image_source: image.url),
          "images/#{image.filename}" => replacement_bytes,
        )
      end

      before do
        guide.draft_revision.update!(raw: "## Published image\n\n![Original](#{image.url})")
        IsbfGuides::Publish.call(
          guardian: acting_user.guardian,
          params: {
            guide_id: guide.id,
            version: guide.lock_version,
          },
        )
        guide.reload
      end

      it "stores replacement bytes under a fresh URL and preserves the live image" do
        publication = guide.published_revision.attributes

        expect { result }.to change(IsbfGuides::Image, :count).by(1)
        expect(result).to run_successfully
        expect(image.reload.data).to eq(guide_image_bytes)
        expect(guide.reload.published_revision.attributes).to eq(publication)
        replacement = guide.images.find(guide.draft_revision.image_ids.first)
        expect(replacement.id).not_to eq(image.id)
        expect(replacement.data).to eq(replacement_bytes)
        expect(replacement.url).not_to eq(image.url)
      end
    end
  end
end
