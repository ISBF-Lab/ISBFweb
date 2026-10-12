# frozen_string_literal: true

RSpec.describe "Frontend consistency" do
  let!(:theme) { upload_theme }

  fab!(:user) { Fabricate(:user, trust_level: 3) }
  fab!(:admin)
  fab!(:other_user) { Fabricate(:user, name: "Synthetic directory member") }
  fab!(:group) do
    Fabricate(:group, name: "frontend_review", full_name: "Synthetic frontend review group")
  end

  before do
    SiteSetting.enable_user_directory = true
    SiteSetting.enable_names = true
    SiteSetting.tagging_enabled = true
    group.add_owner(user)
    sign_in(user)
  end

  [
    ["desktop", "light", 1440, false],
    ["mobile", "light", 390, true],
    ["desktop", "dark", 1440, false],
    ["mobile", "dark", 390, true],
  ].each do |device, mode, width, mobile|
    context "with #{device} layout in #{mode} mode", mobile: mobile do
      before do
        scheme = theme.color_schemes.find_by!(name: "ISBF Community #{mode.capitalize}")
        theme.update!(color_scheme_id: scheme.id)
        [user, admin].each do |account|
          account.user_option.update!(color_scheme_id: scheme.id, dark_scheme_id: scheme.id)
        end
        page.driver.browser.manage.window.resize_to(width, 900)
      end

      it "loads settings and directory without changing the upper profile region" do
        visit_review("/u/#{user.username}/preferences/account", "preferences", ".pref-name")
        expect(page).to have_css(".pref-email")
        expect(page).to have_css(".user-main > .about")
        upper_before = upper_region_geometry
        page.execute_script("document.body.classList.remove('isbf-frontend')")
        expect(upper_region_geometry).to eq(upper_before)
        page.execute_script("document.body.classList.add('isbf-frontend')")
        expected_surface = mode == "light" ? "rgb(255, 255, 255)" : "rgb(16, 20, 19)"
        expect(
          page.evaluate_script(
            "getComputedStyle(document.querySelector('.user-content')).backgroundColor",
          ),
        ).to eq(expected_surface)
        save_review_screenshot("#{device}-#{mode}-account")

        page.find(".pref-name input").set("Synthetic reviewed name")
        page.find(".save-button .btn-primary").click
        expect(page).to have_css(".save-button .saved")
        expect(user.reload.name).to eq("Synthetic reviewed name")
        %w[
          security
          profile
          emails
          notifications
          tracking
          users
          tags
          interface
          apps
          navigation-menu
          calendar-subscriptions
        ].each do |preference|
          visit_review(
            "/u/#{user.username}/preferences/#{preference}",
            "preferences",
            ".user-preferences",
          )
        end
        DirectoryItem.refresh!
        visit_review("/u", "directory", ".directory-table__row")
        expect(page).to have_css(".directory-controls")
        save_review_screenshot("#{device}-#{mode}-directory")
      end

      it "keeps invitation controls and native dismissal available" do
        visit_review(
          "/u/#{user.username}/invited/pending",
          "invitations",
          ".user-navigation-secondary",
        )
        page.find(".invite-button, .empty-state .btn-primary", match: :first).click
        expect(page).to have_css("body.has-frontend-dialog")
        expect(page).to have_css(".d-modal[role='dialog']")
        expect(page).to have_css(".d-modal__body input")
        save_review_screenshot("#{device}-#{mode}-invitation-dialog")
        page.send_keys(:escape)
        expect(page).to have_no_css(".d-modal")
        expect(page).to have_no_css("body.has-frontend-dialog")
      end

      it "retains private lists, reminder cancellation, and lower profile collections" do
        bookmark = Fabricate(:bookmark, user: user)
        Draft.set(
          user,
          "#{Draft::NEW_TOPIC}_1",
          0,
          { title: "Synthetic draft", reply: "Synthetic draft body" }.to_json,
        )
        message = Fabricate(:private_message_topic, user: user, recipient: other_user)
        Fabricate(:post, user: user, topic: message)
        visit_review("/u/#{user.username}/activity/bookmarks", "bookmarks", ".bookmark-list-item")
        expect(page).to have_no_css(".isbf-feed-card")
        save_review_screenshot("#{device}-#{mode}-bookmarks")
        page.find(".bookmark-actions-dropdown .select-kit-header", match: :first).click
        page.find('.select-kit-row[data-value="remove"]').click
        expect(page).to have_css("body.has-frontend-dialog")
        page.find(".dialog-footer .btn-default").click
        expect(page).to have_no_css(".dialog-container")
        expect(Bookmark.exists?(bookmark.id)).to eq(true)
        visit_review("/u/#{user.username}/activity/drafts", "drafts", ".user-stream-item")
        save_review_screenshot("#{device}-#{mode}-drafts")
        visit_review("/u/#{user.username}/activity/pending", "pending", ".user-content")
        %w[sent new unread archive].each do |filter|
          visit_review("/u/#{user.username}/messages/#{filter}", "messages", ".user-content")
        end
        visit_review("/u/#{user.username}/messages", "messages", ".topic-list-item")
        expect(page).to have_text(message.title)
        expect(page).to have_no_css(".isbf-feed-card")
        save_review_screenshot("#{device}-#{mode}-messages")
        visit_review("/u/#{user.username}/summary", "profile-summary", ".stats-section")
        upper_before = upper_region_geometry
        page.execute_script("document.body.classList.remove('isbf-frontend')")
        expect(upper_region_geometry).to eq(upper_before)
        page.execute_script("document.body.classList.add('isbf-frontend')")
        save_review_screenshot("#{device}-#{mode}-summary")
        visit_review("/u/#{user.username}/badges", "profile-badges", ".user-content")
        visit_review("/badges", "badges", ".badge-grouping")
        save_review_screenshot("#{device}-#{mode}-badges")
        badge = Badge.find(Badge::FirstLike)
        BadgeGranter.grant(badge, user)
        visit_review(badge.url, "badges", ".badges-granted .user-info")
        save_review_screenshot("#{device}-#{mode}-badge-details")
      end

      it "retains group ownership, every management section, and associated dialogs" do
        visit_review("/g", "groups", ".group-box")
        save_review_screenshot("#{device}-#{mode}-groups")
        visit_review("/g/#{group.name}/members", "group", ".group-member")
        page.find(".group-members-add").click
        expect(page).to have_css("body.has-frontend-dialog")
        expect(page).to have_css(".d-modal[role='dialog']")
        page.send_keys(:escape)
        expect(page).to have_no_css("body.has-frontend-dialog")
        %w[requests activity/posts activity/topics activity/mentions permissions].each do |section|
          visit_review("/g/#{group.name}/#{section}", "group", ".group")
        end
        %w[profile membership interaction email members categories tags logs].each do |section|
          selector = section == "members" ? ".group-member" : ".group .user-content"
          visit_review("/g/#{group.name}/manage/#{section}", "group-manage", selector)
          save_review_screenshot("#{device}-#{mode}-group-#{section}")
        end
        %w[inbox archive].each do |section|
          visit_review(
            "/g/#{group.name}/messages/#{section}",
            "group-messages",
            ".group .user-content",
          )
        end
        sign_in(admin)
        visit_review("/g/custom/new", "groups", ".groups-form")
        save_review_screenshot("#{device}-#{mode}-group-new")
        visit("/admin")
        expect(page).to have_no_css("body.isbf-frontend")
      end

      it "loads search data, tag collections, and the complete information body" do
        topic = Fabricate(:topic, title: "Frontend review topic with synthetic search content")
        post = Fabricate(:post, topic: topic, raw: "Frontend review synthetic content")
        SearchIndexer.enable
        SearchIndexer.index(topic, force: true)
        SearchIndexer.index(post, force: true)
        visit_review("/search?q=frontend", "search", ".fps-result")
        expect(page).to have_text(topic.title)
        page.find(".advanced-filters__toggle").click
        expect(page).to have_css(".search-advanced-options")
        save_review_screenshot("#{device}-#{mode}-search")
        Fabricate(:tag, name: "frontend-review-tag")
        visit_review("/tags", "tags", ".tag-box")
        save_review_screenshot("#{device}-#{mode}-tags")
        %w[about faq guidelines conduct rules tos privacy].each do |information|
          visit_review("/#{information}", "information", ".body-page")
          save_review_screenshot("#{device}-#{mode}-#{information}")
        end
      ensure
        SearchIndexer.disable
      end
    end
  end

  def visit_review(path, scope, selector)
    visit(path)
    expect(page).to have_css("body.is-frontend-#{scope}")
    expect(page).to have_css(selector)
    expect(page).to have_no_css("#main-outlet .spinner")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to eq(
      true,
    )
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
