# frozen_string_literal: true

RSpec.describe "Browse Latest by creation date" do
  fab!(:admin)
  fab!(:older) { Fabricate(:topic_with_op, created_at: 2.days.ago, bumped_at: 1.minute.ago) }
  fab!(:newer) { Fabricate(:topic_with_op, created_at: 1.day.ago, bumped_at: 1.day.ago) }
  fab!(:pinned) do
    Fabricate(:topic_with_op, created_at: 3.days.ago, pinned_at: 1.hour.ago, pinned_globally: true)
  end
  fab!(:remaining) do
    (4..6).map do |days|
      Fabricate(:topic_with_op, created_at: days.days.ago, bumped_at: days.days.ago)
    end
  end

  let(:topic_list) { PageObjects::Components::LatestCreatedOrderList.new }
  let(:settings_page) { PageObjects::Pages::AdminSiteSettings.new }

  before do
    SiteSetting.latest_topics_order_by_created = true
    sign_in(admin)
    page.driver.with_playwright_page do |browser_page|
      browser_page.set_default_navigation_timeout(120_000)
      unless RSpec.current_example.metadata[:mobile]
        browser_page.set_viewport_size(width: 1400, height: 700)
      end
    end
  end

  around do |example|
    previous_timeout = AssetProcessor.timeout
    AssetProcessor.timeout = 120_000
    stub_const(TopicQuery, :DEFAULT_PER_PAGE_COUNT, 3) { example.run }
  ensure
    AssetProcessor.timeout = previous_timeout
  end

  [false, true].each do |mobile|
    context(mobile ? "on mobile" : "on desktop", mobile: mobile) do
      before do
        theme_directory = Rails.root.join("themes/isbf-campus-feed")
        if theme_directory.directory?
          RemoteTheme.import_theme_from_directory(theme_directory).set_default!
        end
      end

      it "keeps creation order when the user loads more, receives a reply, and refreshes" do
        visit("/latest")
        if Rails.root.join("themes/isbf-campus-feed").directory?
          expect(topic_list).to have_campus_feed
        end
        expect(topic_list).to have_topic_order([pinned, newer, older])

        topic_list.load_more_topics
        expect(topic_list).to have_topics(count: 6)
        expect(topic_list).to have_topic_order([pinned, newer, older, *remaining])

        PostCreator.create!(admin, topic_id: older.id, raw: "A live reply to the older topic.")
        TopicTrackingState.publish_latest(older.reload)
        expect(topic_list).to have_updated_topic_prompt
        topic_list.show_updated_topics
        expect(topic_list).to have_topic_order([pinned, newer, older, *remaining])
        expect(topic_list).to have_topics(count: 6)

        page.refresh
        expect(topic_list).to have_topic_order([pinned, newer, older])
      end
    end
  end

  it "lets an admin enable and disable the setting and read both translations" do
    SiteSetting.latest_topics_order_by_created = false
    settings_page.visit("latest_topics_order_by_created")
    expect(settings_page).to have_setting("latest_topics_order_by_created")
    expect(settings_page.find_setting("latest_topics_order_by_created")).to have_text(
      I18n.t("site_settings.latest_topics_order_by_created", locale: :en),
    )

    settings_page.toggle_bool_setting("latest_topics_order_by_created")
    page.refresh
    expect(settings_page.bool_setting_checkbox("latest_topics_order_by_created")).to be_checked

    visit("/latest")
    expect(topic_list).to have_topic_order([pinned, newer, older])

    admin.update!(locale: "zh_CN")
    settings_page.visit("latest_topics_order_by_created")
    page.refresh
    expect(settings_page.find_setting("latest_topics_order_by_created")).to have_text(
      I18n.t("site_settings.latest_topics_order_by_created", locale: :zh_CN),
    )

    settings_page.toggle_bool_setting("latest_topics_order_by_created")
    page.refresh
    expect(settings_page.bool_setting_checkbox("latest_topics_order_by_created")).not_to be_checked

    visit("/latest")
    expect(topic_list).to have_topic_order([pinned, older, newer])
  end
end
