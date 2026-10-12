# frozen_string_literal: true

RSpec.describe "Frontend consistency" do
  let!(:theme) { upload_theme }

  fab!(:user) { Fabricate(:user, trust_level: 3) }

  before do
    SiteSetting.enable_user_directory = true
    SiteSetting.enable_names = true
    sign_in(user)
  end

  [["desktop", 1440, false], ["mobile", 390, true]].each do |device, width, mobile|
    context device, mobile: mobile do
      before { page.driver.browser.manage.window.resize_to(width, 900) }

      it "loads settings and directory without changing the upper profile region" do
        visit("/u/#{user.username}/preferences/account")
        expect(page).to have_css("body.is-frontend-preferences")
        expect(page).to have_css(".pref-email")
        expect(page).to have_css(".pref-name")
        expect(page).to have_css(".user-main > .about")

        upper_before = upper_region_geometry
        page.execute_script("document.body.classList.remove('isbf-frontend')")
        expect(upper_region_geometry).to eq(upper_before)
        page.execute_script("document.body.classList.add('isbf-frontend')")
        expect(
          page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"),
        ).to eq(true)
        save_review_screenshot("#{device}-account")

        visit("/u")
        expect(page).to have_css("body.is-frontend-directory")
        expect(page).to have_css(".directory-controls")
        expect(page).to have_no_css(".loading-container")
        expect(
          page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"),
        ).to eq(true)
        save_review_screenshot("#{device}-directory")
      end

      it "keeps invitation controls and native dismissal available" do
        visit("/u/#{user.username}/invited/pending")
        expect(page).to have_css("body.is-frontend-invitations")
        expect(page).to have_css(".user-nav__invites-pending, .user-navigation-secondary")
        button = page.find(".invite-button, .empty-state .btn-primary", match: :first)
        button.click
        expect(page).to have_css("body.has-frontend-dialog")
        expect(page).to have_css(".d-modal[role='dialog']")
        expect(page).to have_css(".d-modal__body input")
        save_review_screenshot("#{device}-invitation-dialog")
        page.send_keys(:escape)
        expect(page).to have_no_css(".d-modal")
        expect(page).to have_no_css("body.has-frontend-dialog")
      end
    end
  end

  def upper_region_geometry
    page.evaluate_script(<<~JS)
      [".user-main > .about", ".user-profile-avatar", ".user-profile-names", ".user-navigation-primary"].map(selector => {
        const element = document.querySelector(selector);
        const rectangle = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        return { selector, width: rectangle.width, height: rectangle.height, font: style.font, background: style.backgroundColor };
      })
    JS
  end

  def save_review_screenshot(name)
    directory = Rails.root.join("tmp/isbf-frontend-screenshots")
    FileUtils.mkdir_p(directory)
    page.save_screenshot(directory.join("#{name}.png")) # rubocop:disable Lint/Debugger -- Required theme review artifact.
  end
end
