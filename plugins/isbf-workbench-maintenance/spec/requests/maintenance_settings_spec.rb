# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe Admin::SiteSettingsController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)
  fab!(:theme)

  let(:setting_name) { "isbf_workbench_pause_careers" }

  it "lets a developer save, reload and restore an audited maintenance setting" do
    sign_in(admin)

    put "/admin/site_settings/#{setting_name}.json", params: { setting_name => "true" }

    expect(response.status).to eq(204)
    expect(IsbfWorkbenchMaintenance.paused?(:careers)).to eq(true)
    log = UserHistory.where(action: UserHistory.actions[:change_site_setting]).last
    expect(log.subject).to eq(setting_name)
    expect(log.acting_user_id).to eq(admin.id)

    get "/admin/site_settings.json", params: { names: [setting_name] }

    expect(response.status).to eq(200)
    expect(response.parsed_body.fetch("site_settings").sole.fetch("value")).to eq("true")

    put "/admin/site_settings/#{setting_name}.json", params: { setting_name => "false" }

    expect(response.status).to eq(204)
    expect(IsbfWorkbenchMaintenance.paused?(:careers)).to eq(false)
  end

  it "preserves maintenance while the developer restores the theme entries to their defaults" do
    theme.set_field(
      target: :settings,
      name: :yaml,
      value: File.read(Rails.root.join("themes/isbf-campus-feed/settings.yml")),
    )
    theme.save!
    SiteSetting.isbf_workbench_pause_careers = true
    sign_in(admin)

    put "/admin/themes/#{theme.id}/setting.json",
        params: {
          name: "workbench_entries",
          value: [{ key: "library" }].to_json,
        }

    expect(response.status).to eq(200)
    expect(IsbfWorkbenchMaintenance.paused?(:careers)).to eq(true)

    put "/admin/themes/#{theme.id}/setting.json",
        params: {
          name: "workbench_entries",
          value: theme.settings[:workbench_entries].default.to_json,
        }

    expect(response.status).to eq(200)
    expect(IsbfWorkbenchMaintenance.paused?(:careers)).to eq(true)
  end

  it "applies a saved native setting to the old resume link until the developer clears it" do
    key = "isbf_workbench_pause_resume"
    SiteSetting.isbf_resume_enabled = true
    sign_in(admin)
    put "/admin/site_settings/#{key}.json", params: { key => "true" }
    expect(response.status).to eq(204)

    sign_in(user)
    get "/isbf/workbench/resume"
    expect(response.status).to eq(404)

    sign_in(admin)
    put "/admin/site_settings/#{key}.json", params: { key => "false" }
    expect(response.status).to eq(204)

    sign_in(user)
    get "/isbf/workbench/resume"
    expect(response.status).to eq(200)
  end

  %i[moderator user].each do |role|
    it "preserves maintenance when a #{role} attempts to read or change it" do
      sign_in(public_send(role))

      get "/admin/site_settings.json", params: { names: [setting_name] }

      expect(response.status).to eq(404)

      put "/admin/site_settings/#{setting_name}.json", params: { setting_name => "true" }

      expect(response.status).to eq(404)
      expect(IsbfWorkbenchMaintenance.paused?(:careers)).to eq(false)
    end
  end
end
