# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentRegistrationSerializer do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:registration, :academy_student_registration)

  describe "#as_json" do
    it "includes the student number only with an administrator scope" do
      expect(
        described_class.new(
          registration,
          scope: admin.guardian,
          root: false
        ).as_json[
          :student_number
        ]
      ).to eq(registration.student_number)

      [moderator.guardian, member.guardian, Guardian.new, nil].each do |scope|
        serialized =
          described_class.new(registration, scope:, root: false).as_json

        expect(serialized).not_to have_key(:student_number)
        expect(serialized.to_json).not_to include(registration.student_number)
      end
    end

    it "omits invitation secrets after registration" do
      registered = Fabricate(:registered_academy_student)

      serialized =
        described_class.new(
          registered,
          scope: admin.guardian,
          root: false
        ).as_json

      expect(serialized).not_to have_key(:invite_key)
      expect(serialized).not_to have_key(:link)
      expect(serialized[:status]).to eq("registered")
    end
  end
end

RSpec.describe AdminDetailedUserSerializer do
  fab!(:admin)
  fab!(:moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :registered_academy_student)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#as_json" do
    it "keeps student numbers out of the admin user list" do
      serialized =
        AdminUserSerializer.new(
          registration.user,
          scope: admin.guardian,
          root: false
        ).as_json

      expect(serialized).not_to have_key(:academy_student_number)
      expect(serialized.to_json).not_to include(registration.student_number)
    end

    it "enforces student number privacy even when serialized outside the admin controller" do
      expect(
        described_class.new(
          registration.user,
          scope: admin.guardian,
          root: false
        ).as_json[
          :academy_student_number
        ]
      ).to eq(registration.student_number)

      [moderator.guardian, registration.user.guardian].each do |scope|
        serialized =
          described_class.new(registration.user, scope:, root: false).as_json

        expect(serialized).not_to have_key(:academy_student_number)
        expect(serialized.to_json).not_to include(registration.student_number)
      end
    end
  end
end
