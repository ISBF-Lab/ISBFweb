# frozen_string_literal: true

RSpec.describe IsbfResume::PagesController do
  fab!(:user)

  before { SiteSetting.isbf_resume_enabled = true }

  describe "#index" do
    context "when a member opens the workbench resume page" do
      before { sign_in(user) }

      it "resolves the direct page route and engine route" do
        get "/isbf/workbench/resume"
        expect(response.status).to eq(200)
        get "/isbf-resume/page"
        expect(response.status).to eq(200)
      end
    end

    context "when the caller is a visitor" do
      it "requires authentication" do
        get "/isbf/workbench/resume.json"
        expect(response.status).to eq(403)
      end
    end

    context "when the plugin is disabled" do
      before do
        sign_in(user)
        SiteSetting.isbf_resume_enabled = false
      end

      it "hides the page" do
        get "/isbf/workbench/resume"
        expect(response.status).to eq(404)
      end
    end
  end
end
