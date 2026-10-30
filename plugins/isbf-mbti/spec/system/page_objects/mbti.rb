# frozen_string_literal: true

module PageObjects
  module Pages
    class Mbti < Base
      def visit_index
        visit("/isbf/mbti")
        self
      end

      def choose_version(variant)
        find(".isbf-mbti__versions button", text: /\A#{variant} questions/).click
        self
      end

      def start
        find(".isbf-mbti-intro button", text: "Start test", exact_text: true).send_keys(:return)
        self
      end

      def resume
        find(".isbf-mbti-intro button", text: "Resume", exact_text: true).click
        self
      end

      def answer(choice)
        find(".isbf-mbti-question input[name='choice'][value='#{choice}']").set(true)
        self
      end

      def next_question
        find(".isbf-mbti-question button", text: "Next", exact_text: true).click
        self
      end

      def previous_question
        find(".isbf-mbti-question button", text: "Previous", exact_text: true).click
        self
      end

      def finish_questions(from:, total:)
        (from..total).each do |number|
          expect(self).to have_question(number)
          answer(1)
          if number < total
            next_question
          else
            find(
              ".isbf-mbti-question button",
              text: "Submit and view result",
              exact_text: true,
            ).click
          end
        end
        self
      end

      def open_history
        find(".isbf-mbti__header button", text: "My history", exact_text: true).click
        self
      end

      def open_latest_result
        find(".isbf-mbti-history .isbf-mbti__history button[data-result-id]", match: :first).click
        self
      end

      def delete_result
        find(".isbf-mbti-result button", text: "Delete result", exact_text: true).click
        PageObjects::Components::Dialog.new.click_yes
        self
      end

      def open_login
        find(".isbf-mbti-intro button", text: "Log in to start", exact_text: true).click
        self
      end

      def has_intro?
        has_css?(".isbf-mbti-intro")
      end

      def has_versions?
        %w[28 40 93].all? do |variant|
          has_css?(".isbf-mbti__versions button", text: /\A#{variant} questions/)
        end
      end

      def has_question?(number)
        has_css?(".isbf-mbti-question[data-question-id='#{number}']")
      end

      def has_selected_choice?(choice)
        has_css?(".isbf-mbti-question input[name='choice'][value='#{choice}']:checked")
      end

      def has_disabled_next?
        has_css?(".isbf-mbti-question button[disabled]", text: "Next", exact_text: true)
      end

      def has_result?
        has_css?(".isbf-mbti-result")
      end

      def has_history_item?
        has_css?(".isbf-mbti-history .isbf-mbti__history button[data-result-id]")
      end

      def has_empty_history?
        has_css?(
          ".isbf-mbti-history .isbf-mbti__history li",
          text: "You have no completed tests yet.",
        )
      end

      def has_login_prompt?
        has_css?(".isbf-mbti-intro button", text: "Log in to start", exact_text: true) &&
          has_no_css?(".isbf-mbti-intro button", text: "Start test", exact_text: true)
      end

      def has_native_login?
        has_css?(".login-modal, .login-fullpage")
      end

      def contained?
        page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")
      end

      def save_review(name)
        directory = Rails.root.join("tmp/mbti-browser")
        FileUtils.mkdir_p(directory)
        page.driver.with_playwright_page do |browser|
          browser.screenshot(path: directory.join("#{name}.png").to_s, fullPage: true)
        end
      end
    end
  end
end
