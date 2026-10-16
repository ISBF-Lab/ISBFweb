# frozen_string_literal: true

require_relative "../../plugin_helper"

RSpec.describe IsbfJoin::Application do
  describe "#save" do
    it "normalizes all saved fields before validation" do
      application =
        Fabricate(
          :isbf_join_application,
          name: "\uFEFF 申请人\u00a0",
          student_id: " 2026101401 ",
          phone: " +86 138-0013-8000 ",
          submission_id: "491E9A65-3270-4ACD-8BA9-DC726A6A0307",
        )

      expect(application.reload).to have_attributes(
        name: "申请人",
        student_id: "2026101401",
        phone: "+86 138-0013-8000",
        submission_id: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
      )
    end
  end
end
