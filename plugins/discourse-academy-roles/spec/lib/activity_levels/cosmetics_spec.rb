# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::Cosmetics do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  let(:document) do
    activity_rules(
      levels: [
        activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
        activity_tier(identifier: "regular", conditions: [activity_condition("posts_read", 10)]),
      ],
    ).merge("cosmetics" => activity_cosmetics(avatar_minimum: "reader", name_minimum: "regular"))
  end

  before do
    reset_activity_appearance_caches
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    persist_activity_rules(document)
  end

  after { reset_activity_appearance_caches }

  describe ".avatar_allowed?" do
    it "requires both the global and individual frame thresholds" do
      assign_activity_level(member, identifier: "legacy-0", number: 0)
      expect(described_class.avatar_allowed?(member)).to eq(false)

      assign_activity_level(member, identifier: "reader", number: 1)
      expect(described_class.avatar_allowed?(member)).to eq(true)
      expect(described_class.avatar_allowed?(member, "regular")).to eq(false)

      assign_activity_level(member, identifier: "regular", number: 2)
      expect(described_class.avatar_allowed?(member, "reader")).to eq(true)
      expect(described_class.avatar_allowed?(member, "regular")).to eq(true)
      expect(described_class.avatar_allowed?(member, "removed")).to be_nil
    end

    it "retains existing staff capabilities without changing their level" do
      [admin, moderator].each do |actor|
        assign_activity_level(actor, identifier: "legacy-0", number: 0)
        expect(described_class.avatar_allowed?(actor, "regular")).to eq(true)
        expect(DiscourseAcademyRoles::ActivityLevels.level_number(actor)).to eq(0)
      end
    end

    it "excludes native and pooled anonymous identities even when they hold a staff role" do
      shadow = Fabricate(:admin)
      pooled = Fabricate(:moderator)
      Fabricate(:activity_anonymous_identity, user: shadow, master_user: admin)
      Fabricate(:activity_pool_account, user: pooled)

      [shadow, pooled].each do |actor|
        assign_activity_level(actor, identifier: "regular", number: 2)
        expect(described_class.avatar_allowed?(actor)).to eq(false)
      end
      expect(described_class.avatar_allowed?(Discourse.system_user)).to eq(false)
      expect(described_class.avatar_allowed?(nil)).to eq(false)
    end

    it "follows stable identities when deleting an unreferenced lower level" do
      assign_activity_level(member, identifier: "regular", number: 2)
      updated = DiscourseAcademyRoles::ActivityLevels::Configuration.current.document.deep_dup
      updated["cosmetics"]["avatar_minimum_level_id"] = "regular"
      updated["levels"].delete_at(1)
      persist_activity_rules(updated)

      expect(described_class.level_info("regular")).to include(id: "regular", number: 1)
      expect(described_class.avatar_allowed?(member)).to eq(true)
    end
  end

  describe ".name_color_allowed?" do
    it "uses the current activity level rather than internal trust" do
      member.update_columns(trust_level: 4)
      assign_activity_level(member, identifier: "reader", number: 1)
      expect(described_class.name_color_allowed?(member)).to eq(false)

      assign_activity_level(member, identifier: "regular", number: 2)
      expect(described_class.name_color_allowed?(member)).to eq(true)
      expect(member.reload.trust_level).to eq(4)
    end

    it "pauses and restores the capability after demotion and recovery" do
      assign_activity_level(member, identifier: "regular", number: 2)
      expect(described_class.name_color_allowed?(member)).to eq(true)

      assign_activity_level(member, identifier: "legacy-0", number: 0)
      expect(described_class.name_color_allowed?(member)).to eq(false)

      assign_activity_level(member, identifier: "regular", number: 2)
      expect(described_class.name_color_allowed?(member)).to eq(true)
    end

    it "requires the feature and preset to be enabled" do
      assign_activity_level(member, identifier: "regular", number: 2)
      SiteSetting.academy_roles_enabled = false
      expect(described_class.name_color_allowed?(member)).to eq(false)
      expect(described_class.name_colors).to be_nil
    end

    it "pauses the configured preset when its own switch is disabled" do
      assign_activity_level(member, identifier: "regular", number: 2)
      changed = DiscourseAcademyRoles::ActivityLevels::Configuration.current.document.deep_dup
      changed["cosmetics"]["name_color_enabled"] = false
      persist_activity_rules(changed)

      expect(described_class.name_color_allowed?(member)).to eq(false)
      expect(described_class.name_colors).to be_nil
    end
  end

  describe ".name_colors" do
    it "returns only the two configured display colors" do
      expect(described_class.name_colors).to eq(light: "#a51b81", dark: "#f67cda")
    end
  end
end
