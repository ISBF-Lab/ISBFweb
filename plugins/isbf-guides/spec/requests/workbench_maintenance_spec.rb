# frozen_string_literal: true

RSpec.describe IsbfGuides::GuidesController do
  fab!(:member, :user)
  fab!(:admin)
  fab!(:guide, :isbf_guide)
  fab!(:image, :isbf_guide_image) { Fabricate(:isbf_guide_image, guide:) }

  let(:maintenance) do
    Module.new do
      mattr_accessor :paused, default: false

      def self.ensure_available!(key)
        raise Discourse::NotFound if key == "guides" && paused
      end
    end
  end

  around { |example| stub_const(Object, :IsbfWorkbenchMaintenance, maintenance) { example.run } }

  before do
    SiteSetting.isbf_guides_enabled = true
    guide.draft_revision.update!(raw: "## Settings\n\n![Settings](#{image.url})")
    IsbfGuides::Publish.call(
      params: {
        guide_id: guide.id,
        version: guide.lock_version,
      },
      guardian: admin.guardian,
    )
    guide.reload
    sign_in(member)
  end

  describe "#show" do
    it "closes listing, saved links and private images and restores the published revision" do
      get "#{guide.url}.json"
      expect(response.status).to eq(200)
      get image.url
      expect(response.status).to eq(200)

      maintenance.paused = true
      ["/guides", "/guides.json", guide.url, "#{guide.url}.json", image.url].each do |url|
        get url
        expect(response.status).to eq(404)
      end

      maintenance.paused = false
      get "#{guide.url}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("guide").fetch("id")).to eq(guide.id)
      get image.url
      expect(response.status).to eq(200)
      expect(response.body.b).to eq(image.data.b)
    end
  end
end
