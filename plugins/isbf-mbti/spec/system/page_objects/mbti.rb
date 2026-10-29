# frozen_string_literal: true

module PageObjects
  module Pages
    class Mbti < Base
      def visit_index
        visit("/isbf/mbti")
        self
      end

      def choose_version(variant)
        find("[data-test-mbti-version='#{variant}']").click
        self
      end

      def start
        find("[data-test-mbti-start]").send_keys(:return)
        self
      end

      def resume
        find("[data-test-mbti-resume]").click
        self
      end

      def answer(choice)
        find("[data-test-mbti-choice='#{choice}']").set(true)
        self
      end

      def next_question
        find("[data-test-mbti-next]").click
        self
      end

      def previous_question
        find("[data-test-mbti-previous]").click
        self
      end

      def finish_questions(from:, total:)
        (from..total).each do |number|
          expect(self).to have_question(number)
          answer(1)
          if number < total
            next_question
          else
            find("[data-test-mbti-submit]").click
          end
        end
        self
      end

      def open_history
        find("[data-test-mbti-history]").click
        self
      end

      def open_latest_result
        find("[data-test-mbti-history-item]", match: :first).click
        self
      end

      def delete_result
        find("[data-test-mbti-result-delete]").click
        PageObjects::Components::Dialog.new.click_yes
        self
      end

      def open_login
        find("[data-test-mbti-login]").click
        self
      end

      def has_intro?
        has_css?("[data-test-mbti-intro]")
      end

      def has_versions?
        %w[28 40 93].all? { |variant| has_css?("[data-test-mbti-version='#{variant}']") }
      end

      def has_question?(number)
        has_css?("[data-test-mbti-question][data-question-id='#{number}']")
      end

      def has_selected_choice?(choice)
        has_css?("[data-test-mbti-choice='#{choice}']:checked")
      end

      def has_disabled_next?
        has_css?("[data-test-mbti-next][disabled]")
      end

      def has_result?
        has_css?("[data-test-mbti-result]")
      end

      def has_history_item?
        has_css?("[data-test-mbti-history-list] [data-test-mbti-history-item]")
      end

      def has_empty_history?
        has_css?("[data-test-mbti-history-empty]")
      end

      def has_login_prompt?
        has_css?("[data-test-mbti-login]") && has_no_css?("[data-test-mbti-start]")
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
