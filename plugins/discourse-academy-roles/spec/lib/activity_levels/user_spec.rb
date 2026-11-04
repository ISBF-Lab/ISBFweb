# frozen_string_literal: true

RSpec.describe User do
  include ActivityLevelsSpecHelpers

  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

  describe ".create!" do
    it "defers stable activity identities while the legacy evaluator remains active" do
      account = Fabricate(:user)

      expect(DiscourseAcademyRoles::ActivityLevels::Configuration).not_to be_persisted
      expect(account.reload.custom_fields.keys).not_to include(
        DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD,
      )
    end

    it "starts members and staff at the configured base activity level" do
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
          ],
        ),
      )
      SiteSetting.default_trust_level = 2

      accounts = [Fabricate(:user), Fabricate(:admin), Fabricate(:moderator)]

      accounts.each do |account|
        expect(account.reload.custom_fields).to include(
          DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 0,
          DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD => "legacy-0",
        )
      end
    end

    it "leaves staged accounts outside the activity-level system" do
      account = Fabricate(:user, staged: true)

      expect(account.reload.custom_fields.keys).not_to include(
        DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD,
      )
    end
  end
end
