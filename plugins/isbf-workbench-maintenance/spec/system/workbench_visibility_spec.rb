# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workbench maintenance in the campus theme" do
  fab!(:user)

  let(:theme) do
    RemoteTheme.import_theme_from_directory(Rails.root.join("themes/isbf-campus-feed"))
  end
  let(:hidden_card) { '[data-workbench-key="courses"]' }
  let(:resume_card) { '[data-workbench-key="resume"]' }

  before do
    theme.set_default!
    sign_in(user)
    SiteSetting.isbf_resume_enabled = true
    SiteSetting.isbf_workbench_pause_courses = true
    SiteSetting.isbf_workbench_pause_resume = true
  end

  %w[light dark].each do |mode|
    it "preserves both layouts, hides paused cards and restores the existing design in #{mode} mode" do
      scheme = theme.color_schemes.find_by!(name: "ISBF Community #{mode.capitalize}")
      theme.update!(color_scheme_id: scheme.id)
      user.user_option.update!(color_scheme_id: scheme.id, dark_scheme_id: scheme.id)
      theme.update_setting(
        :workbench_entries,
        [{ key: "resume", icon: "heart", tone: "mint" }].to_json,
      )
      theme.save!

      [%w[traditional glass], %w[glass traditional]].each do |mobile, desktop|
        theme.update_setting(:workbench_layout_mobile, mobile)
        theme.update_setting(:workbench_layout_desktop, desktop)
        theme.save!
        page.current_window.resize_to(1440, 900)
        visit "/isbf/workbench"

        [390, 430, 600, 601, 768, 1024, 1440].each do |width|
          page.current_window.resize_to(width, 900)
          layout = width <= 600 ? mobile : desktop
          expect(page).to have_css(%(.isbf-v2-workbench[data-workbench-layout="#{layout}"]))
          expect(page).to have_no_css(hidden_card)
          expect(page).to have_no_css(resume_card)
          expect(page).to have_css('[data-workbench-key="learning_resources"]')
        end
      end

      SiteSetting.isbf_workbench_pause_resume = false
      page.refresh
      expect(page).to have_css(".isbf-workbench-grid__item:first-of-type#{resume_card}")
      expect(page).to have_css(
        %(#{resume_card}[href="/isbf/workbench/resume"][data-workbench-palette="mint"]),
      )
      expect(page).to have_no_css(hidden_card)
    end
  end

  it "keeps the workbench usable when all entries are paused" do
    IsbfWorkbenchMaintenance::ENTRY_KEYS.each do |key|
      SiteSetting.public_send("isbf_workbench_pause_#{key}=", true)
    end
    visit "/isbf/workbench"

    expect(page).to have_css(".isbf-v2-workbench__panel p", text: "No workbench entries available.")
    expect(page).to have_no_css("[data-workbench-key]")
  end
end
