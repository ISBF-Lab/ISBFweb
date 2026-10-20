# frozen_string_literal: true

module PageObjects
  module Pages
    class FrontendConsistency < PageObjects::Pages::Base
      def visit_preferences(user, section: "account")
        visit_review(
          "/u/#{user.username}/preferences/#{section}",
          "preferences",
          ".user-preferences",
        )
      end

      def has_account_fields?
        page.has_css?(".pref-name input") && page.has_css?(".pref-email")
      end

      def has_contained_lower_navigation?
        page.evaluate_script(<<~JS)
          (() => {
            const frame = document.querySelector("#main-outlet");
            const bounds = frame.getBoundingClientRect();
            const left = bounds.left + frame.clientLeft;
            const right = left + frame.clientWidth;
            return [".new-user-content-wrapper", ".user-navigation-secondary", ".user-navigation-secondary .horizontal-overflow-nav"].every(selector => {
              const element = frame.querySelector(selector);
              if (!element) { return false; }
              const rectangle = element.getBoundingClientRect();
              return rectangle.width > 0 && rectangle.left >= left - 1 && rectangle.right <= right + 1;
            });
          })()
        JS
      end

      def has_aligned_account_labels?
        page.evaluate_script(<<~JS)
          [".pref-username", ".pref-avatar", ".pref-email", ".pref-name"]
            .map(selector => document.querySelector(`${selector} .control-label`).getBoundingClientRect().left)
            .every((left, _, positions) => Math.abs(left - positions[0]) < 1);
        JS
      end

      def has_aligned_email_metadata?
        page.evaluate_script(<<~JS)
          (() => {
            const row = document.querySelector(".pref-email .row");
            const email = row.querySelector(".email-first").getBoundingClientRect();
            const primary = row.querySelector(".primary").getBoundingClientRect();
            return Math.abs((email.top + email.bottom) / 2 - (primary.top + primary.bottom) / 2) < 2;
          })()
        JS
      end

      def rename_to(name)
        page.find(".pref-name input").set(name)
        page.find(".save-button .btn-primary").click
        self
      end

      def has_saved_preferences?
        page.has_css?(".save-button .saved")
      end

      def has_name?(name)
        page.find(".pref-name").has_field?(with: name)
      end

      def has_upper_profile?
        page.has_css?(".user-main > .about")
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

      def without_rollout_styles
        page.execute_script("document.body.classList.remove('isbf-frontend')")
        yield
      ensure
        page.execute_script("document.body.classList.add('isbf-frontend')")
      end

      def lower_surface_color
        page.evaluate_script(
          "getComputedStyle(document.querySelector('.user-content')).backgroundColor",
        )
      end

      def visit_directory
        visit_review("/u", "directory", ".directory-table__row")
      end

      def has_directory_controls?
        page.has_css?(".directory-controls")
      end

      def visit_invitations(user)
        visit_review(
          "/u/#{user.username}/invited/pending",
          "invitations",
          ".user-navigation-secondary",
        )
      end

      def open_invitation
        page.find(".invite-button, .empty-state .btn-primary", match: :first).click
        self
      end

      def has_scoped_dialog?
        page.has_css?(".d-modal[role='dialog']")
      end

      def has_invitation_fields?
        page.has_css?(".d-modal__body input")
      end

      def dismiss_dialog
        page.send_keys(:escape)
        self
      end

      def has_consistent_dialog_shape?
        page.has_css?(
          ".d-modal__container",
          style: {
            "border-top-left-radius" => "16px",
            "border-bottom-right-radius" => "16px",
          },
        ) && page.has_css?(".d-modal__footer .btn-primary", style: { "border-radius" => "999px" })
      end

      def has_dialog_inside_viewport?
        page.has_css?(".d-modal__container") do |element|
          element.evaluate_script(
            "((r) => r.left >= 15 && r.right <= innerWidth - 15 && r.top >= 15 && r.bottom <= innerHeight - 15)(this.getBoundingClientRect())",
          )
        end
      end

      def has_no_scoped_dialog?
        page.has_no_css?(".d-modal")
      end

      def visit_bookmarks(user)
        visit_review("/u/#{user.username}/activity/bookmarks", "bookmarks", ".bookmark-list-item")
      end

      def has_no_public_cards?
        page.has_no_css?(".isbf-feed-card")
      end

      def open_bookmark_removal
        page.find(".bookmark-actions-dropdown .select-kit-header", match: :first).click
        page.find('.select-kit-row[data-value="remove"]').click
        self
      end

      def has_scoped_confirmation?
        page.has_css?(".dialog-container")
      end

      def cancel_confirmation
        page.find(".dialog-footer .btn-default").click
        self
      end

      def has_no_confirmation?
        page.has_no_css?(".dialog-container")
      end

      def has_bookmark?(bookmark)
        page.has_css?(".bookmark-list-item", text: bookmark.name)
      end

      def has_accessible_bookmark_menu?
        page.evaluate_script(<<~JS)
          (() => {
            const item = document.querySelector(".bookmark-list-item");
            const row = item.getBoundingClientRect();
            const menu = item.querySelector(".bookmark-actions-dropdown .select-kit-header").getBoundingClientRect();
            const title = item.querySelector(".bookmark-status-with-link").getBoundingClientRect();
            return menu.right <= row.right && menu.top >= row.top && menu.left >= title.right;
          })()
        JS
      end

      def visit_drafts(user)
        visit_review("/u/#{user.username}/activity/drafts", "drafts", ".user-stream-item")
      end

      def has_individual_draft_actions?
        page.has_no_css?(".post-list-item__bulk-select") && page.has_css?(".resume-draft") &&
          page.has_css?(".remove-draft")
      end

      def open_draft_removal
        page.find(".remove-draft", match: :first).click
        self
      end

      def visit_pending(user)
        visit_review("/u/#{user.username}/activity/pending", "pending", ".user-content")
      end

      def visit_messages(user, filter: nil)
        path = "/u/#{user.username}/messages"
        path += "/#{filter}" if filter
        visit_review(path, "messages", ".user-content")
      end

      def has_message?(topic)
        page.has_css?(".topic-list-item", text: topic.title)
      end

      def has_balanced_message_rows?
        page.evaluate_script(<<~JS)
          [...document.querySelectorAll(".topic-list-item")].every(row => {
            const title = row.querySelector(".main-link").getBoundingClientRect();
            const avatar = [...row.querySelectorAll(".avatar")]
              .map(image => image.getBoundingClientRect()).find(bounds => bounds.width > 0);
            const table = row.closest(".topic-list").getBoundingClientRect();
            if (!avatar || avatar.width < 42 || avatar.height < 42) { return false; }
            if (window.innerWidth <= 600) { return true; }
            const centers = [...row.querySelectorAll(".num")].map(cell => {
              const walker = document.createTreeWalker(cell, NodeFilter.SHOW_TEXT);
              let text;
              while ((text = walker.nextNode())) {
                if (!text.textContent.trim()) { continue; }
                const range = document.createRange();
                range.selectNodeContents(text);
                const bounds = range.getBoundingClientRect();
                return (bounds.top + bounds.bottom) / 2;
              }
            }).filter(value => value !== undefined);
            return title.width >= table.width * 0.45 && Math.max(...centers) - Math.min(...centers) < 3;
          });
        JS
      end

      def visit_summary(user)
        visit_review("/u/#{user.username}/summary", "profile-summary", ".stats-section")
      end

      def visit_user_badges(user)
        visit_review("/u/#{user.username}/badges", "profile-badges", ".user-content")
      end

      def visit_badges
        visit_review("/badges", "badges", ".badge-grouping")
      end

      def visit_badge(badge)
        visit_review("/badges/#{badge.id}/#{badge.slug}", "badges", ".badges-granted .user-info")
      end

      def visit_groups
        visit_review("/g", "groups", ".group-box")
      end

      def visit_group(group, section: "members")
        path = %w[posts topics mentions].include?(section) ? "activity/#{section}" : section
        selector = section == "members" ? ".group-member" : ".group"
        visit_review("/g/#{group.name}/#{path}", "group", selector)
      end

      def open_group_add_members
        page.find(".group-members-add").click
        self
      end

      def visit_group_management(group, section:)
        selector = section == "members" ? ".group-member" : ".group .user-content"
        visit_review("/g/#{group.name}/manage/#{section}", "group-manage", selector)
      end

      def visit_group_messages(group, section:)
        visit_review(
          "/g/#{group.name}/messages/#{section}",
          "group-messages",
          ".group .user-content",
        )
      end

      def visit_group_creation
        visit_review("/g/custom/new", "groups", ".groups-form")
      end

      def has_no_rollout_styles?
        page.has_no_css?("body.isbf-frontend")
      end

      def visit_search(query:)
        visit_review("/search?q=#{CGI.escape(query)}", "search", ".fps-result")
      end

      def has_search_result?(topic)
        page.has_css?(".fps-result", text: topic.title)
      end

      def expand_search_filters
        page.find(".advanced-filters__toggle").click
        self
      end

      def has_search_filters?
        page.has_css?(".search-advanced-options")
      end

      def visit_tags
        visit_review("/tags", "tags", ".tag-box")
      end

      def visit_information(information)
        visit_review("/#{information}", "information", ".body-page")
      end

      def has_information_body?(post)
        page.has_css?(".body-page", text: post.raw)
      end

      def save_review_screenshot(name)
        directory = Rails.root.join("tmp/isbf-frontend-screenshots")
        FileUtils.mkdir_p(directory)
        page.driver.with_playwright_page do |pw_page|
          pw_page.screenshot(path: directory.join("#{name}.png").to_s, fullPage: true)
        end
      end

      private

      def visit_review(path, scope, selector)
        page.visit(path)
        expect(page).to have_css("body.is-frontend-#{scope}")
        expect(page).to have_css(selector)
        expect(page).to have_no_css("#main-outlet .spinner")
        expect(
          page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"),
        ).to eq(true)
        self
      end
    end
  end
end
