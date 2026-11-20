# frozen_string_literal: true

module PageObjects
  module Pages
    class ISBFWorkbenchEntriesEditor < AdminObjectsSettingEditor
      def has_entry_at?(key, position)
        has_css?(
          ".schema-setting-editor__tree > .--parent:nth-child(#{position}) .schema-setting-editor__tree-node-text",
          exact_text: key,
        )
      end

      def has_disabled_move_up?
        has_css?(".schema-setting-editor__move-up-btn[disabled]")
      end

      def has_disabled_move_down?
        has_css?(".schema-setting-editor__move-down-btn[disabled]")
      end

      def move_down_with_keyboard
        find(".schema-setting-editor__move-down-btn").send_keys(:enter)
        self
      end

      def has_focused_move_down?
        has_css?(".schema-setting-editor__move-down-btn:focus")
      end

      def icon_picker
        PageObjects::Components::DIconGridPicker.new(".schema-field[data-name='icon']")
      end
    end
  end
end

RSpec.describe "Workbench entries in the native theme editor", type: :system do
  fab!(:admin)
  fab!(:theme)

  let(:themes_page) { PageObjects::Pages::AdminCustomizeThemes.new }
  let(:entries_editor) { PageObjects::Pages::ISBFWorkbenchEntriesEditor.new }

  before do
    SiteSetting.svg_icon_subset = "gamepad"
    theme.set_field(
      target: :settings,
      name: :yaml,
      value: File.read(File.expand_path("../../settings.yml", __dir__)),
    )
    theme.save!
    sign_in(admin)
  end

  it "lets an admin reorder with the keyboard, save an available icon, clear it and restore defaults" do
    entries_editor.visit_theme(theme, "workbench_entries")

    expect(entries_editor).to have_entry_at("learning_resources", 1)
    expect(entries_editor).to have_disabled_move_up
    entries_editor.click_link("guides")
    expect(entries_editor).to have_disabled_move_down
    entries_editor.click_link("learning_resources")
    entries_editor.move_down_with_keyboard
    expect(entries_editor).to have_entry_at("library", 1)
    expect(entries_editor).to have_entry_at("learning_resources", 2)
    expect(entries_editor).to have_focused_move_down

    entries_editor.icon_picker.expand.select_icon("gamepad")
    entries_editor.save
    expect(page).to have_current_path("/admin/customize/themes/#{theme.id}")

    page.refresh
    themes_page.click_edit_objects_setting_button("workbench_entries")
    expect(entries_editor).to have_entry_at("library", 1)
    entries_editor.click_link("learning_resources")
    expect(entries_editor.icon_picker).to have_selected_icon("gamepad")

    entries_editor.icon_picker.clear
    entries_editor.save
    expect(page).to have_current_path("/admin/customize/themes/#{theme.id}")

    page.refresh
    themes_page.click_edit_objects_setting_button("workbench_entries")
    entries_editor.click_link("learning_resources")
    expect(entries_editor.icon_picker).to have_no_selected_icon
    entries_editor.back
    themes_page.reset_overridden_setting("workbench_entries")

    page.refresh
    themes_page.click_edit_objects_setting_button("workbench_entries")
    expect(entries_editor).to have_entry_at("learning_resources", 1)
    expect(entries_editor).to have_entry_at("library", 2)
    expect(entries_editor).to have_entry_at("guides", 13)
    expect(entries_editor.icon_picker).to have_no_selected_icon
  end
end
