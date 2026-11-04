# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels do
  include ActivityLevelsSpecHelpers

  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    described_class::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { described_class::Current.reset }

  describe ".initialize_user" do
    it "retains an earned stable identity when initialized again" do
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
          ],
        ),
      )
      member = Fabricate(:user)
      assign_activity_level(member, identifier: "reader", number: 1)

      described_class.initialize_user(member)

      expect(member.reload.custom_fields).to include(
        DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 1,
        described_class::LEVEL_ID_FIELD => "reader",
      )
    end
  end
end
