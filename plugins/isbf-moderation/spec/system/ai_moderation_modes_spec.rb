# frozen_string_literal: true

module PageObjects
  module Pages
    class IsbfAiModerationModes < Base
      ROOT = "[data-test-ai-moderation-modes]"
      PATH = "/admin/plugins/isbf-moderation/ai-moderation-modes"

      def visit_editor
        visit(PATH)
        self
      end

      def has_editor?
        has_css?(ROOT)
      end

      def has_no_editor?
        has_no_css?(ROOT)
      end

      def choose_category(category)
        choose("category", "categories", category)
      end

      def edit_level(level, keyboard: false)
        choose("edit-level", "levels", level, keyboard:)
      end

      def activate_level(level)
        choose("active-level", "levels", level)
      end

      def choose_action(action)
        choose("action", "actions", action)
      end

      def policy
        find("[data-test-ai-mode-policy]").value
      end

      def write_policy(text)
        find("[data-test-ai-mode-policy]").fill_in(with: text)
        self
      end

      def has_policy?(text)
        within(ROOT) { has_selector?(:fillable_field, with: text) }
      end

      def has_active_level?(level)
        has_css?("[data-test-ai-mode-active-level]", exact_text: label("levels", level))
      end

      def has_action?(action)
        has_css?("[data-test-ai-mode-action]", exact_text: label("actions", action))
      end

      def save
        find("[data-test-ai-mode-save]").send_keys(:enter)
        self
      end

      def has_saved?
        has_css?("[data-test-ai-mode-saved]")
      end

      def restore_level
        find("[data-test-ai-mode-restore]").click
        self
      end

      def has_conflict?
        has_css?("[data-test-ai-mode-error]") && has_css?("[data-test-ai-mode-refresh-conflict]")
      end

      def refresh_saved_version
        find("[data-test-ai-mode-refresh-conflict]").click
        find("[data-test-ai-mode-saved-version] summary").click
        self
      end

      def has_saved_policy?(text)
        has_css?("[data-test-ai-mode-saved-version] pre", exact_text: text)
      end

      def configuration_status
        page.evaluate_script(<<~JS)
          fetch("/isbf/moderation/admin/ai-moderation-modes.json", {
            credentials: "same-origin"
          }).then(response => response.status)
        JS
      end

      def contained?
        page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")
      end

      def save_review(name)
        directory = Rails.root.join("tmp/ai-moderation-browser")
        FileUtils.mkdir_p(directory)
        page.driver.with_playwright_page do |browser|
          browser.screenshot(path: directory.join("#{name}.png").to_s, fullPage: true)
        end
      end

      private

      def choose(control, group, value, keyboard: false)
        trigger = find("[data-test-ai-mode-#{control}]")
        keyboard ? trigger.send_keys(:arrow_down) : trigger.click
        option = find("[role='option']", exact_text: label(group, value))
        keyboard ? option.send_keys(:enter) : option.click
        self
      end

      def label(group, value)
        I18n.t(
          "js.isbf_moderation.admin.modes.#{group}.#{value}",
          locale: SiteSetting.default_locale,
        )
      end
    end
  end
end

RSpec.describe "Edit AI moderation modes" do
  fab!(:admin)
  fab!(:moderator)
  fab!(:theme)

  let(:editor) { PageObjects::Pages::IsbfAiModerationModes.new }

  before do
    SiteSetting.default_locale = "en"
    theme.set_default!
    sign_in(admin)
  end

  it "lets a developer save a spare profile while choosing another active level" do
    editor.visit_editor
    expect(editor).to have_editor
    expect(editor).to have_active_level("standard")
    standard_policy = editor.policy

    editor.edit_level("strict", keyboard: true)
    editor.write_policy("Review promotional replies whose only purpose is recruiting buyers.")
    editor.choose_action("review_only")
    expect(editor).to have_active_level("standard")
    editor.choose_category("harassment").edit_level("lenient")
    harassment_default = editor.policy
    editor.write_policy("Review direct threats. Allow criticism of a proposal.")
    editor.choose_category("fraud").edit_level("strict")
    expect(editor).to have_policy(
      "Review promotional replies whose only purpose is recruiting buyers.",
    )
    expect(editor).to have_action("review_only")
    editor.activate_level("lenient").save
    expect(editor).to have_saved
    editor.choose_category("harassment").edit_level("lenient")
    expect(editor).to have_policy("Review direct threats. Allow criticism of a proposal.")

    page.refresh
    expect(editor).to have_active_level("lenient")
    expect(editor).to have_policy(standard_policy)
    editor.edit_level("strict")
    expect(editor).to have_policy(
      "Review promotional replies whose only purpose is recruiting buyers.",
    )
    expect(editor).to have_action("review_only")
    editor.choose_category("harassment").edit_level("lenient")
    expect(editor).to have_policy(harassment_default)
  end

  it "lets a developer restore one profile while retaining the other edited profiles" do
    editor.visit_editor
    editor.write_policy("Standard fraud rules customized by the developer.")
    editor.edit_level("strict")
    strict_default = editor.policy
    editor.write_policy("Strict fraud rules customized by the developer.")
    editor.choose_action("review_only").save
    expect(editor).to have_saved

    editor.restore_level
    expect(editor).to have_policy(strict_default)
    expect(editor).to have_action("hide_and_review")
    editor.edit_level("standard")
    expect(editor).to have_policy("Standard fraud rules customized by the developer.")
    editor.save
    expect(editor).to have_saved

    page.refresh
    expect(editor).to have_policy("Standard fraud rules customized by the developer.")
    editor.edit_level("strict")
    expect(editor).to have_policy(strict_default)
    expect(editor).to have_action("hide_and_review")
  end

  it "lets a developer compare a concurrent save and retain their draft before retrying" do
    editor.visit_editor
    editor.write_policy("The first developer's unsaved policy.")

    using_session(:other_developer) do
      sign_in(admin)
      editor.visit_editor
      editor.write_policy("The second developer's saved policy.").save
      expect(editor).to have_saved
    end

    editor.save
    expect(editor).to have_conflict
    expect(editor).to have_policy("The first developer's unsaved policy.")
    editor.refresh_saved_version
    expect(editor).to have_saved_policy("The second developer's saved policy.")
    expect(editor).to have_policy("The first developer's unsaved policy.")
    editor.save
    expect(editor).to have_saved

    page.refresh
    expect(editor).to have_policy("The first developer's unsaved policy.")
  end

  it "requires developer access before a moderator can read the editor's configuration" do
    sign_in(moderator)
    visit("/")
    expect(editor.configuration_status).to eq(403)
    editor.visit_editor
    expect(editor).to have_no_editor
  end

  it "lets a developer read and operate Chinese rules across narrow and wide color modes" do
    SiteSetting.default_locale = "zh_CN"
    admin.update!(locale: "zh_CN")
    dark_scheme = ColorScheme.create_from_base(name: "Moderation dark", base_scheme_id: -2)
    theme.update!(dark_color_scheme_id: dark_scheme.id)
    admin.user_option.update!(dark_scheme_id: dark_scheme.id)

    %w[light dark].each do |mode|
      page.driver.with_playwright_page { |browser| browser.emulate_media(colorScheme: mode) }
      [390, 430, 600, 601, 768, 1024, 1440].each do |width|
        page.current_window.resize_to(width, 900)
        editor.visit_editor
        expect(editor).to have_editor
        expect(editor).to have_active_level("standard")
        editor.edit_level("strict", keyboard: true)
        expect(editor).to have_action("hide_and_review")
        expect(editor).to be_contained
        editor.save_review("zh-CN-#{width}-#{mode}")
      end
    end
  end
end
