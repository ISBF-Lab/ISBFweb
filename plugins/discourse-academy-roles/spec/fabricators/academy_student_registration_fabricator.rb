# frozen_string_literal: true

Fabricator(
  :academy_student_registration,
  from: "DiscourseAcademyRoles::StudentRegistration"
) do
  student_number do
    sequence(:academy_student_number) { |number| "0002026-ACADEMY-#{number}" }
  end
  issued_by(fabricator: :admin)
  invite do |attributes|
    Fabricate(
      :invite,
      invited_by: attributes[:issued_by],
      email: nil,
      max_redemptions_allowed: 1
    )
  end
end

Fabricator(:registered_academy_student, from: :academy_student_registration) do
  user
  registered_at { Time.current }
end
