# frozen_string_literal: true

require_relative "../../../../plugins/discourse-ai/spec/forum_assistant/support"

RSpec.describe "Navigation from workbench feature pages" do
  let(:theme) do
    RemoteTheme.import_theme_from_directory(Rails.root.join("themes/isbf-campus-feed"))
  end

  before { theme.set_default! }

  def resize_to(width)
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.set_viewport_size(width:, height: 900)
    end
    expect(page.evaluate_script("window.innerWidth")).to eq(width)
  end

  def expect_left_back_link(selector)
    expect(page).to have_css(%(#{selector}[href="/isbf/workbench"][aria-label] > svg))
    left, width, height, title_offset = page.evaluate_script(<<~JS)
      (() => {
        const link = document.querySelector(#{selector.to_json});
        const header = link.closest("header");
        const back = link.getBoundingClientRect();
        const title = header.querySelector("h1").getBoundingClientRect();
        return [
          back.left - header.getBoundingClientRect().left,
          back.width,
          back.height,
          title.left - back.right
        ];
      })()
    JS
    expect(left).to be_between(0, 16)
    expect(width).to be >= 44
    expect(height).to be >= 44
    expect(title_offset).to be >= 0
  end

  def use_scheme(member, mode)
    scheme = theme.color_schemes.find_by!(name: "ISBF Community #{mode}")
    theme.update!(color_scheme_id: scheme.id)
    member.user_option.update!(color_scheme_id: scheme.id, dark_scheme_id: scheme.id)
  end

  context "with published guides" do
    fab!(:member, :user)
    fab!(:guide, :published_isbf_guide)

    before do
      SiteSetting.isbf_guides_enabled = true
      use_scheme(member, "Light")
      sign_in(member)
    end

    it "returns from an article to the guide list and from the list to the workbench" do
      resize_to(390)
      visit "/isbf/workbench"
      find('[data-workbench-key="guides"]').click
      expect(page).to have_current_path("/guides")
      expect(page).to have_css(".isbf-guides h1", count: 1)

      back = ".isbf-guides__workbench-back"
      [390, 430, 600, 601, 768, 1024, 1440].each do |width|
        resize_to(width)
        expect_left_back_link(back)
      end

      resize_to(390)
      find(".isbf-guides__entry", text: guide.published_revision.title).click
      expect(page).to have_current_path(guide.url)
      find(".isbf-guides__back").click
      expect(page).to have_current_path("/guides")
      find(back).send_keys(:enter)
      expect(page).to have_current_path("/isbf/workbench")

      use_scheme(member, "Dark")
      resize_to(1440)
      visit "/guides"
      expect_left_back_link(back)
      find(back).click
      expect(page).to have_current_path("/isbf/workbench")
    end
  end

  context "with a forum assistant" do
    include_context "with a configured forum assistant"

    before do
      use_scheme(member, "Dark")
      sign_in(member)
    end

    it "returns to the workbench and closes the compact history with keyboard focus" do
      resize_to(390)
      visit "/isbf/workbench"
      find('[data-workbench-key="ai_assistant"]').click
      expect(page).to have_current_path("/discourse-ai/ai-bot/conversations")
      expect(page).to have_css(".forum-assistant-workspace h1", count: 1)

      back = ".forum-assistant-workspace__back"
      history_button = ".forum-assistant-workspace__open-history"

      [390, 430, 600, 601, 768, 1023].each do |width|
        resize_to(width)
        expect_left_back_link(back)
        expect(page).to have_css(history_button)
        expect(page).to have_no_css(".forum-assistant-workspace__history")
      end

      resize_to(390)
      find(history_button).click
      expect(page).to have_css(%(#{history_button}[aria-expanded="true"]))
      expect(page).to have_css(".forum-assistant-workspace__new:focus")
      find(".forum-assistant-workspace__new").send_keys(:escape)
      expect(page).to have_css(%(#{history_button}[aria-expanded="false"]:focus))
      expect(page).to have_css(".forum-assistant-composer textarea")
      find(back).send_keys(:enter)
      expect(page).to have_current_path("/isbf/workbench")

      use_scheme(member, "Light")
      visit "/discourse-ai/ai-bot/conversations"
      [1024, 1440].each do |width|
        resize_to(width)
        expect_left_back_link(back)
        expect(page).to have_no_css(history_button)
        expect(page).to have_css(".forum-assistant-workspace__history")
      end
      find(back).click
      expect(page).to have_current_path("/isbf/workbench")
    end
  end
end
