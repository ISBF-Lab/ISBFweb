# frozen_string_literal: true

RSpec.describe IsbfGuides::GuidesController do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:guide, :published_isbf_guide)

  before { SiteSetting.isbf_guides_enabled = true }

  describe "#index" do
    it "requires authentication for the tutorial listing" do
      get "/guides.json"

      expect(response.status).to eq(403)
    end

    it "redirects direct anonymous HTML visits to login" do
      get "/guides"

      expect(response.status).to eq(302)
      expect(response.location).to include("/login")
      expect(cookies[:destination_url]).to include("/guides")
    end

    it "serves the complete application bootstrap for a signed-in member" do
      sign_in(member)

      get "/guides"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to have_tag("meta#data-discourse-setup")
      expect(response.body).to have_tag("section#main")
      expect(response.body).to have_tag("script[type='module'][src]")
    end

    it "lists published snapshots and excludes draft metadata" do
      draft = Fabricate(:isbf_guide)
      guide.draft_revision.update!(title: "Unpublished title", summary: "Unpublished summary")
      sign_in(member)

      get "/guides.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["guides"].map { |entry| entry["id"] }).to eq([guide.id])
      expect(response.parsed_body["guides"].first).to include(
        "title" => guide.published_revision.title,
        "summary" => guide.published_revision.summary,
      )
      expect(response.parsed_body["guides"].first.keys).not_to include("draft", "raw", "version")
      expect(response.body).not_to include(draft.draft_revision.title)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  describe "#show" do
    it "requires authentication for JSON and redirects direct HTML visits to login" do
      get "#{guide.url}.json"
      expect(response.status).to eq(403)

      get guide.url
      expect(response.status).to eq(302)
      expect(response.location).to include("/login")
      expect(cookies[:destination_url]).to include(guide.url)
    end

    it "serves the complete application bootstrap for a signed-in member" do
      sign_in(member)

      get guide.url

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to have_tag("meta#data-discourse-setup")
      expect(response.body).to have_tag("section#main")
      expect(response.body).to have_tag("script[type='module'][src]")
    end

    it "serves the published snapshot while keeping a newer draft private" do
      draft_text = "## Draft section\n\nThese instructions are still being reviewed."
      guide.draft_revision.update!(raw: draft_text)
      sign_in(member)

      get "#{guide.url}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]).to include(
        "title" => guide.published_revision.title,
        "cooked" => guide.published_revision.cooked,
        "preview" => false,
      )
      expect(response.parsed_body["guide"].keys).not_to include("raw", "draft", "publication")
      expect(response.body).not_to include(draft_text)
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
    end

    it "returns 404 for draft-only, unpublished and unknown guides" do
      draft = Fabricate(:isbf_guide)
      guide.update!(published_revision: nil)
      sign_in(member)

      [draft.url, guide.url, "/guides/missing-guide"].each do |url|
        get "#{url}.json"
        expect(response.status).to eq(404)
      end
    end

    it "restricts draft preview to administrators" do
      guide.draft_revision.update!(raw: "## Preview\n\nDraft instructions.")
      sign_in(member)

      get "#{guide.url}.json", params: { preview: "1" }
      expect(response.status).to eq(404)

      sign_in(admin)
      get "#{guide.url}.json", params: { preview: "1" }
      expect(response.status).to eq(200)
      expect(response.parsed_body["guide"]).to include(
        "preview" => true,
        "cooked" => guide.draft_revision.cooked,
      )
    end

    it "returns 404 when the plugin is disabled" do
      sign_in(member)
      SiteSetting.isbf_guides_enabled = false

      get "#{guide.url}.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#image" do
    fab!(:guide, :isbf_guide)
    fab!(:published_image, :isbf_guide_image) { Fabricate(:isbf_guide_image, guide:) }
    fab!(:draft_image, :isbf_guide_image) { Fabricate(:isbf_guide_image, guide:) }

    before do
      guide.draft_revision.update!(raw: "## Settings\n\n![Settings](#{published_image.url})")
      IsbfGuides::Publish.call(
        params: {
          guide_id: guide.id,
          version: guide.lock_version,
        },
        guardian: admin.guardian,
      )
      guide.reload
    end

    it "requires authentication even when the original image URL is known" do
      get published_image.url

      expect(response.status).to eq(404)
      expect(response.body).not_to eq(published_image.data)
    end

    it "serves referenced published image bytes with private caching" do
      sign_in(member)

      get published_image.url

      expect(response.status).to eq(200)
      expect(response.body.b).to eq(published_image.data.b)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    end

    it "keeps draft images private from members and available to administrators" do
      sign_in(member)

      get draft_image.url
      expect(response.status).to eq(404)

      sign_in(admin)
      get draft_image.url
      expect(response.status).to eq(200)
      expect(response.body.b).to eq(draft_image.data.b)
    end

    it "revokes member image access when a guide is unpublished" do
      guide.update!(published_revision: nil)
      sign_in(member)

      get published_image.url

      expect(response.status).to eq(404)
    end

    it "returns 404 for missing image names" do
      sign_in(member)

      get "#{guide.url}/images/missing.png"

      expect(response.status).to eq(404)
    end
  end
end
