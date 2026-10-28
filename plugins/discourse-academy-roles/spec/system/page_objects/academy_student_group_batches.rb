# frozen_string_literal: true

module PageObjects
  module Pages
    class AcademyStudentGroupBatches < Base
      def visit_index
        visit("/admin/plugins/discourse-academy-roles/student-group-batches")
        self
      end

      def preview_accounts(group, student_number)
        form = PageObjects::Components::FormKit.new(".academy-student-group-form .form-kit")
        form.field("mode").select("groups")
        form.field("add_#{group.id}").check
        form.field("student_numbers").fill_in(student_number)
        form.submit
        self
      end

      def has_number?(student_number)
        has_css?(".academy-student-group-items", text: student_number)
      end

      def has_state?(state)
        has_css?(
          ".academy-student-group-batches__result > p[role='status']",
          text: I18n.t("js.academy_roles.student_groups.states.#{state}"),
        )
      end

      def confirm_by_keyboard
        button = find_button(I18n.t("js.academy_roles.student_groups.execute"))
        button.send_keys(:return)
        PageObjects::Components::Dialog.new.click_yes
      end

      def preview_undo
        click_button(I18n.t("js.academy_roles.student_groups.undo_preview"))
      end

      def has_active_palette?(color_scheme)
        has_css?(
          "link.light-scheme[data-scheme-id='#{color_scheme.id}'][media='all']",
          visible: false,
        )
      end

      def contained?
        page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")
      end

      def save_review(name)
        directory = Rails.root.join("tmp/student-group-browser")
        FileUtils.mkdir_p(directory)
        page.driver.with_playwright_page do |pw_page|
          pw_page.screenshot(path: directory.join("#{name}.png").to_s, fullPage: true)
        end
      end
    end
  end
end
