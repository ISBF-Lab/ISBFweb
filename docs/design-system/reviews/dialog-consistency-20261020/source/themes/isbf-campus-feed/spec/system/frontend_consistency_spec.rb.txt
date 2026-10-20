# frozen_string_literal: true

require_relative "page_objects/pages/frontend_consistency"

RSpec.describe "Frontend consistency" do
  let!(:theme) { upload_theme }
  let(:review) { PageObjects::Pages::FrontendConsistency.new }

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
        page.current_window.resize_to(width, 900)
      end

      it "lets users save account settings while preserving the upper profile region" do
        review.visit_preferences(user)
        expect(review).to have_contained_lower_navigation
        expect(review).to have_account_fields
        expect(review).to have_aligned_account_labels
        expect(review).to have_aligned_email_metadata
        expect(review).to have_upper_profile
        upper_before = review.upper_region_geometry
        review.without_rollout_styles { expect(review.upper_region_geometry).to eq(upper_before) }
        expected_surface = mode == "light" ? "rgb(255, 255, 255)" : "rgb(16, 20, 19)"
        expect(review.lower_surface_color).to eq(expected_surface)
        review.save_review_screenshot("#{device}-#{mode}-account")

        review.rename_to("Synthetic reviewed name")
        expect(review).to have_saved_preferences
        page.refresh
        expect(review).to have_name("Synthetic reviewed name")
      end

      it "lets users browse preference sections and the user directory" do
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
        ].each { |preference| review.visit_preferences(user, section: preference) }
        DirectoryItem.refresh!
        review.visit_directory
        expect(review).to have_directory_controls
        review.save_review_screenshot("#{device}-#{mode}-directory")
      end

      it "keeps invitation controls and native dismissal available" do
        review.visit_invitations(user)
        expect(review).to have_contained_lower_navigation
        review.open_invitation
        expect(review).to have_scoped_dialog
        expect(review).to have_consistent_dialog_shape
        expect(review).to have_dialog_inside_viewport
        expect(review).to have_invitation_fields
        review.save_review_screenshot("#{device}-#{mode}-invitation-dialog")
        review.dismiss_dialog
        expect(review).to have_no_scoped_dialog
      end

      it "lets users cancel bookmark removal and browse their drafts and pending posts" do
        bookmark = Fabricate(:bookmark, user: user, name: "Synthetic reviewed bookmark")
        Fabricate(:topic_user, user: user, topic: bookmark.bookmarkable.topic)
        Draft.set(
          user,
          "#{Draft::NEW_TOPIC}_1",
          0,
          { title: "Synthetic draft", reply: "Synthetic draft body" }.to_json,
        )
        review.visit_bookmarks(user)
        expect(review).to have_no_public_cards
        expect(review).to have_accessible_bookmark_menu
        review.save_review_screenshot("#{device}-#{mode}-bookmarks")
        review.open_bookmark_removal
        expect(review).to have_scoped_confirmation
        review.cancel_confirmation
        expect(review).to have_no_confirmation
        page.refresh
        expect(review).to have_bookmark(bookmark)
        review.visit_drafts(user)
        expect(review).to have_individual_draft_actions
        review.save_review_screenshot("#{device}-#{mode}-drafts")
        review.open_draft_removal
        expect(review).to have_scoped_confirmation
        review.cancel_confirmation
        expect(review).to have_no_confirmation
        review.visit_pending(user)
      end

      it "lets users browse their private message filters and loaded inbox" do
        message =
          Fabricate(
            :private_message_topic,
            user: other_user,
            recipient: user,
            title: "Synthetic private message with a longer title and readable metadata",
          )
        second_message = Fabricate(:private_message_topic, user: other_user, recipient: user)
        Fabricate(:post, user: other_user, topic: message)
        Fabricate(:post, user: user, topic: message)
        Fabricate(:post, user: other_user, topic: second_message)
        %w[sent new unread archive].each { |filter| review.visit_messages(user, filter: filter) }
        review.visit_messages(user)
        expect(review).to have_message(message)
        expect(review).to have_message(second_message)
        expect(review).to have_balanced_message_rows
        expect(review).to have_no_public_cards
        review.save_review_screenshot("#{device}-#{mode}-messages")
      end

      it "lets users browse their lower profile and real badge collections" do
        review.visit_summary(user)
        upper_before = review.upper_region_geometry
        review.without_rollout_styles { expect(review.upper_region_geometry).to eq(upper_before) }
        review.save_review_screenshot("#{device}-#{mode}-summary")
        review.visit_user_badges(user)
        review.visit_badges
        review.save_review_screenshot("#{device}-#{mode}-badges")
        badge = Badge.find(Badge::FirstLike)
        BadgeGranter.grant(badge, user)
        review.visit_badge(badge)
        review.save_review_screenshot("#{device}-#{mode}-badge-details")
      end

      it "lets group owners browse members and activity and dismiss the member dialog" do
        review.visit_groups
        review.save_review_screenshot("#{device}-#{mode}-groups")
        review.visit_group(group)
        review.open_group_add_members
        expect(review).to have_scoped_dialog
        review.dismiss_dialog
        expect(review).to have_no_scoped_dialog
        %w[requests posts topics mentions permissions].each do |section|
          review.visit_group(group, section: section)
        end
      end

      it "lets group owners browse profile, membership, interaction, and email settings" do
        %w[profile membership interaction email].each do |section|
          review.visit_group_management(group, section: section)
          review.save_review_screenshot("#{device}-#{mode}-group-#{section}")
        end
      end

      it "lets group owners browse member, category, tag, and log settings" do
        %w[members categories tags logs].each do |section|
          review.visit_group_management(group, section: section)
          review.save_review_screenshot("#{device}-#{mode}-group-#{section}")
        end
      end

      it "lets users browse group messages and administrators create groups with unchanged admin UI" do
        %w[inbox archive].each { |section| review.visit_group_messages(group, section: section) }
        sign_in(admin)
        review.visit_group_creation
        review.save_review_screenshot("#{device}-#{mode}-group-new")
        visit("/admin")
        expect(review).to have_no_rollout_styles
      end

      it "lets users search real content and browse populated tag collections" do
        topic = Fabricate(:topic, title: "Frontend review topic with synthetic search content")
        post = Fabricate(:post, topic: topic, raw: "Frontend review synthetic content")
        SearchIndexer.enable
        SearchIndexer.index(topic, force: true)
        SearchIndexer.index(post, force: true)
        review.visit_search(query: "frontend")
        expect(review).to have_search_result(topic)
        review.expand_search_filters
        expect(review).to have_search_filters
        review.save_review_screenshot("#{device}-#{mode}-search")
        topic.tags << Fabricate(:tag, name: "frontend-review-tag")
        review.visit_tags
        review.save_review_screenshot("#{device}-#{mode}-tags")
      ensure
        SearchIndexer.disable
      end

      it "lets users read the about page and configured information page bodies" do
        information_post =
          Fabricate(
            :post,
            raw: "Synthetic frontend review information body for policy page checks.",
          )
        SiteSetting.guidelines_topic_id = information_post.topic.id
        SiteSetting.tos_topic_id = information_post.topic.id
        SiteSetting.privacy_topic_id = information_post.topic.id
        %w[about faq guidelines conduct rules tos privacy].each do |information|
          review.visit_information(information)
          expect(review).to have_information_body(information_post) unless information == "about"
          review.save_review_screenshot("#{device}-#{mode}-#{information}")
        end
      end
    end
  end
end
