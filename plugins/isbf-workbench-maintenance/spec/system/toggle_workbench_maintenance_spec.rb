# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Toggle workbench maintenance" do
  fab!(:admin)
  fab!(:theme)

  before do
    theme.set_field(
      target: :settings,
      name: :yaml,
      value: File.read(Rails.root.join("themes/isbf-campus-feed/settings.yml")),
    )
    theme.save!
    theme.set_default!
    sign_in(admin)
  end

  it "opens only on the workbench editor and persists the native checkbox across reloads" do
    visit "/admin/customize/themes/#{theme.id}"
    expect(page).to have_no_css(".isbf-workbench-maintenance")

    visit "/admin/customize/themes/#{theme.id}/schema/workbench_entries"
    toggle = find(".isbf-workbench-maintenance__toggle")
    expect(toggle["aria-expanded"]).to eq("false")
    expect(page).to have_no_css("#isbf-workbench-maintenance-settings")
    toggle.send_keys(:enter)
    expect(page).to have_css('.isbf-workbench-maintenance__toggle[aria-expanded="true"]:focus')

    expect(page).to have_css("#isbf-workbench-maintenance-settings .row.setting", count: 13)
    within('.isbf-workbench-maintenance [data-setting="isbf_workbench_pause_careers"]') do
      expect(page).to have_css('input[type="checkbox"]:not(:checked)', visible: :all)
      find('input[type="checkbox"]').send_keys(:space)
      find(".setting-controls__ok").click
      expect(page).to have_no_css(".setting-controls__ok")
    end

    page.refresh
    find(".isbf-workbench-maintenance__toggle").click
    within('.isbf-workbench-maintenance [data-setting="isbf_workbench_pause_careers"]') do
      expect(page).to have_css('input[type="checkbox"]:checked', visible: :all)
      find('input[type="checkbox"]').uncheck
      find(".setting-controls__ok").click
      expect(page).to have_no_css(".setting-controls__ok")
    end

    page.refresh
    find(".isbf-workbench-maintenance__toggle").click
    within('.isbf-workbench-maintenance [data-setting="isbf_workbench_pause_careers"]') do
      expect(page).to have_css('input[type="checkbox"]:not(:checked)', visible: :all)
    end
  end
end
