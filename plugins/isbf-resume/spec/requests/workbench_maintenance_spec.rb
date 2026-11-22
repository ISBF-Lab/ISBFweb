# frozen_string_literal: true

RSpec.describe IsbfResume::PagesController do
  fab!(:user)

  let(:maintenance) do
    Module.new do
      mattr_accessor :paused, default: false

      def self.ensure_available!(key)
        raise Discourse::NotFound if key == "resume" && paused
      end
    end
  end

  around { |example| stub_const(Object, :IsbfWorkbenchMaintenance, maintenance) { example.run } }

  before do
    SiteSetting.isbf_resume_enabled = true
    sign_in(user)
  end

  describe "#index" do
    it "closes resume pages and APIs during maintenance and restores existing access" do
      get "/isbf/workbench/resume"
      expect(response.status).to eq(200)

      maintenance.paused = true
      %w[/isbf/workbench/resume /isbf-resume/page /isbf-resume/shares.json].each do |url|
        get url
        expect(response.status).to eq(404)
      end
      post "/isbf-resume/exports.json", params: { resume: {} }
      expect(response.status).to eq(404)

      maintenance.paused = false
      get "/isbf/workbench/resume"
      expect(response.status).to eq(200)
      expect(SiteSetting.isbf_resume_enabled).to eq(true)
    end
  end
end
