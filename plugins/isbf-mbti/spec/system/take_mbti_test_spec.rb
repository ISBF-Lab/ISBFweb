# frozen_string_literal: true

require_relative "page_objects/mbti"

RSpec.describe "Take an MBTI test" do
  fab!(:user)

  let!(:theme) do
    RemoteTheme.import_theme_from_directory(Rails.root.join("themes/isbf-campus-feed")).tap(
      &:set_default!
    )
  end
  let(:mbti) { PageObjects::Pages::Mbti.new }

  before do
    SiteSetting.isbf_mbti_enabled = true
    SiteSetting.login_required = false
    SiteSetting.default_locale = "en"
  end

  it "lets a member resume, finish and remove their private result" do
    sign_in(user)
    page.current_window.resize_to(1440, 900)
    mbti.visit_index
    expect(mbti).to have_intro
    mbti.choose_version("40").start
    expect(mbti).to have_question(1)
    expect(mbti).to have_disabled_next
    mbti.answer(2).next_question
    expect(mbti).to have_question(2)
    mbti.answer(1).previous_question
    expect(mbti).to have_question(1)
    expect(mbti).to have_selected_choice(2)
    mbti.next_question
    expect(mbti).to have_question(2)
    expect(mbti).to have_selected_choice(1)

    page.refresh
    expect(mbti).to have_intro
    mbti.resume
    expect(mbti).to have_question(2)
    expect(mbti).to have_selected_choice(1)
    mbti.finish_questions(from: 2, total: 40)
    expect(mbti).to have_result
    mbti.save_review("completed-result")
    mbti.open_history
    expect(mbti).to have_history_item

    page.refresh
    expect(mbti).to have_intro
    mbti.open_history
    expect(mbti).to have_history_item
    mbti.open_latest_result
    expect(mbti).to have_result
    mbti.delete_result
    expect(mbti).to have_empty_history
    page.refresh
    expect(mbti).to have_intro
    mbti.open_history
    expect(mbti).to have_empty_history
  end

  it "takes a guest to native login before answering questions" do
    mbti.visit_index
    expect(mbti).to have_intro
    expect(mbti).to have_versions
    expect(mbti).to have_login_prompt
    mbti.open_login
    expect(mbti).to have_native_login
  end

  [390, 430, 600, 601, 768, 1024, 1440].each do |width|
    %w[light dark].each do |mode|
      context "with #{width}px #{mode} layout", mobile: width <= 600 do
        before do
          scheme = theme.color_schemes.find_by!(name: "ISBF Community #{mode.capitalize}")
          theme.update!(color_scheme_id: scheme.id)
          user.user_option.update!(color_scheme_id: scheme.id, dark_scheme_id: scheme.id)
          page.current_window.resize_to(width, 900)
          sign_in(user)
        end

        it "lets a member read and answer without horizontal overflow" do
          mbti.visit_index
          expect(mbti).to have_intro
          expect(mbti).to have_versions
          expect(mbti).to be_contained
          mbti.save_review("#{width}-#{mode}-intro")
          mbti.choose_version("28").start
          expect(mbti).to have_question(1)
          mbti.answer(1)
          expect(mbti).to have_selected_choice(1)
          expect(mbti).to be_contained
          mbti.save_review("#{width}-#{mode}-question")
        end
      end
    end
  end
end
