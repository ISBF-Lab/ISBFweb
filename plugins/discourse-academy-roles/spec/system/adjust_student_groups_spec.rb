# frozen_string_literal: true

require_relative "page_objects/academy_student_group_batches"

RSpec.describe "Adjust student groups" do
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:developer, :admin)
  fab!(:target, :group)
  fab!(:registration, :registered_academy_student)

  let(:batches_page) { PageObjects::Pages::AcademyStudentGroupBatches.new }

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.default_locale = "en"
    sign_in(developer)
  end

  [
    [1440, "light", false],
    [1024, "dark", false],
    [768, "light", false],
    [430, "dark", true],
    [390, "light", true],
  ].each do |width, mode, mobile|
    context "with #{width}px #{mode} layout", mobile: do
      before do
        if mode == "dark"
          scheme =
            ColorScheme.create_from_base(
              name: "Batch review dark",
              base_scheme_id: ColorScheme::NAMES_TO_ID_MAP.fetch("Dark"),
            )
          developer.user_option.update!(color_scheme_id: scheme.id, dark_scheme_id: scheme.id)
        end
        page.current_window.resize_to(width, 900)
      end

      it "lets a developer preview a literal student number in the native backend" do
        batches_page.visit_index.preview_accounts(target, registration.student_number)

        expect(batches_page).to have_number(registration.student_number)
        expect(batches_page).to have_state("preview")
        expect(batches_page).to be_contained
        batches_page.save_review("#{width}-#{mode}")
      end
    end
  end

  it "lets a developer confirm, revisit and undo a selected batch" do
    Jobs.run_immediately!
    batches_page.visit_index.preview_accounts(target, registration.student_number)
    expect(batches_page).to have_state("preview")
    batches_page.confirm_by_keyboard
    expect(batches_page).to have_state("completed")
    page.refresh
    expect(batches_page).to have_state("completed")
    batches_page.preview_undo
    expect(batches_page).to have_state("preview")
    batches_page.confirm_by_keyboard
    expect(batches_page).to have_state("completed")
    page.refresh
    expect(batches_page).to have_state("completed")
  end
end
