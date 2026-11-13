# frozen_string_literal: true

module PageObjects
  module Pages
    class Mbti < Base
      def visit_index
        if ENV["ISBF_MBTI_PRODUCTION_ASSETS_SMOKE"] == "1"
          page.driver.with_playwright_page do |browser|
            browser.add_init_script(script: "performance.setResourceTimingBufferSize(5000)")
          end
        end
        visit("/isbf/mbti")
        self
      end

      def choose_version(variant, label: /\A#{variant} questions/)
        find(".isbf-mbti__versions button", text: label).click
        self
      end

      def start(label: "Start test")
        find(".isbf-mbti-intro button", text: label, exact_text: true).send_keys(:return)
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

      def next_question(label: "Next")
        find(".isbf-mbti-question button", text: label, exact_text: true).click
        self
      end

      def previous_question
        find(".isbf-mbti-question button", text: "Previous", exact_text: true).click
        self
      end

      def finish_questions(from:, total:, next_text: "Next", submit_text: "Submit and view result")
        (from..total).each do |number|
          expect(self).to have_question(number)
          answer(1)
          if number < total
            next_question(label: next_text)
          else
            find(".isbf-mbti-question button", text: submit_text, exact_text: true).click
          end
        end
        self
      end

      def open_history(label: "My history")
        find(".isbf-mbti__header button", text: label, exact_text: true).click
        self
      end

      def open_latest_result
        find(".isbf-mbti-history .isbf-mbti__history button[data-result-id]", match: :first).click
        self
      end

      def retest(label:)
        find(".isbf-mbti-result button", text: label, exact_text: true).click
        self
      end

      def delete_result(label: "Delete result")
        find(".isbf-mbti-result button", text: label, exact_text: true).click
        PageObjects::Components::Dialog.new.click_yes
        self
      end

      def scroll_to_result_dimension(number)
        dimension = find(".isbf-mbti-result__dimensions > li:nth-child(#{number})")
        page.execute_script(
          "arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' });",
          dimension,
        )
        self
      end

      def scroll_to_result_actions
        find(".isbf-mbti-result .isbf-mbti__actions")
        page.scroll_to(:bottom)
        self
      end

      def open_login
        find(".isbf-mbti-intro button", text: "Log in to start", exact_text: true).click
        self
      end

      def has_intro?(heading: nil)
        has_css?(".isbf-mbti-intro") &&
          (heading.nil? || has_css?(".isbf-mbti-intro h2", text: heading, exact_text: true))
      end

      def has_version?(label)
        has_css?(".isbf-mbti__versions button", text: label, exact_text: true)
      end

      def has_privacy_notice?(text)
        has_css?(".isbf-mbti-intro p, .isbf-mbti-history p", text: text, exact_text: true)
      end

      def has_versions?
        %w[28 40 93].all? do |variant|
          has_css?(".isbf-mbti__versions button", text: /\A#{variant} questions/)
        end
      end

      def has_question?(number)
        has_css?(".isbf-mbti-question[data-question-id='#{number}']")
      end

      def has_question_progress?(text)
        has_css?(".isbf-mbti-question p[aria-live='polite']", text: text, exact_text: true)
      end

      def has_choice_label?(choice, text)
        has_css?(
          ".isbf-mbti-question label:has(input[name='choice'][value='#{choice}'])",
          text: text,
          exact_text: true,
        )
      end

      def has_selected_choice?(choice)
        has_css?(".isbf-mbti-question input[name='choice'][value='#{choice}']:checked")
      end

      def has_disabled_next?
        has_css?(".isbf-mbti-question button[disabled]", text: "Next", exact_text: true)
      end

      def has_result?(heading: nil)
        return false unless has_css?(".isbf-mbti-result")
        return true if heading.nil?

        has_css?(".isbf-mbti-result__summary p", text: heading, exact_text: true)
      end

      def has_result_dimension_in_viewport?(number)
        has_css?(".isbf-mbti-result__dimensions > li:nth-child(#{number})") do |dimension|
          unobscured_in_viewport?(dimension)
        end
      end

      def has_result_actions_in_viewport?
        has_css?(".isbf-mbti-result .isbf-mbti__actions button", count: 2) do |button|
          unobscured_in_viewport?(button)
        end
      end

      def has_production_bundle?
        receipt = JSON.parse(Rails.root.join("tmp/mbti-production-assets/receipt.json").read)
        filename = receipt.fetch("manifest").fetch("main").fetch("fileName")
        has_css?(".isbf-mbti-intro") { page.evaluate_script(<<~JS) }
            performance.getEntriesByType("resource").some((entry) =>
              new URL(entry.name).pathname.endsWith(#{"/#{filename}".to_json})
            )
          JS
      end

      def has_docked_mobile_navigation?
        has_css?(".isbf-v2-mobile-nav") { |navigation| page.evaluate_script(<<~JS, navigation) }
            (() => {
              const rect = arguments[0].getBoundingClientRect();
              return window.scrollY > 0 && rect.top > 0 &&
                Math.abs(rect.bottom - window.innerHeight) <= 1;
            })()
          JS
      end

      def has_history_heading?(text)
        has_css?(".isbf-mbti-history h2", text: text, exact_text: true)
      end

      def has_history_item?
        has_css?(".isbf-mbti-history .isbf-mbti__history button[data-result-id]")
      end

      def has_empty_history?(text: "You have no completed tests yet.")
        has_css?(".isbf-mbti-history .isbf-mbti__history li", text: text)
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

      def save_review(name, full_page: true)
        directory = Rails.root.join("tmp/mbti-browser")
        FileUtils.mkdir_p(directory)
        name = "production-#{name}" if ENV["ISBF_MBTI_PRODUCTION_ASSETS_SMOKE"] == "1"
        page.driver.with_playwright_page do |browser|
          browser.screenshot(path: directory.join("#{name}.png").to_s, fullPage: full_page)
        end
      end

      private

      def unobscured_in_viewport?(element)
        page.evaluate_script(<<~JS, element)
          (() => {
            const element = arguments[0];
            const rect = element.getBoundingClientRect();
            if (rect.width <= 0 || rect.height <= 0 || rect.left < 0 || rect.top < 0 ||
                rect.right > window.innerWidth || rect.bottom > window.innerHeight) {
              return false;
            }

            const points = [
              [rect.left + rect.width / 2, rect.top + rect.height / 2],
              [rect.left + rect.width / 2, rect.top + 1],
              [rect.left + rect.width / 2, rect.bottom - 1],
              [rect.left + 1, rect.top + rect.height / 2],
              [rect.right - 1, rect.top + rect.height / 2],
            ];
            return points.every(([x, y]) => element.contains(document.elementFromPoint(x, y)));
          })()
        JS
      end
    end
  end
end
