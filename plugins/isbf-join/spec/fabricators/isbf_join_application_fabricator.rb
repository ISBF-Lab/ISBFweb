# frozen_string_literal: true

Fabricator(:isbf_join_application, from: "IsbfJoin::Application") do
  name "申请人"
  student_id { sequence(:student_id) { |number| "2026#{number.to_s.rjust(6, "0")}" } }
  phone "+86 138-0013-8000"
  submission_id { SecureRandom.uuid }
end
