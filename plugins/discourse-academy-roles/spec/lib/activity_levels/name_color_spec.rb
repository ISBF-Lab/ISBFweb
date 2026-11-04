# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::NameColor do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    reset_activity_appearance_caches
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    persist_activity_rules(
      activity_rules(
        levels: [
          activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
        ],
      ).merge("cosmetics" => activity_cosmetics(name_minimum: "reader")),
    )
  end

  after { reset_activity_appearance_caches }

  describe ".effective_color" do
    it "leaves an unlocked member's name unchanged until they opt in" do
      assign_activity_level(member, identifier: "reader", number: 1)

      expect(described_class.allowed?(member)).to eq(true)
      expect(described_class.effective_color(member)).to be_nil
    end

    it "suppresses a native anonymous identity's saved color independently of its owner" do
      assign_activity_level(member, identifier: "reader", number: 1)
      member.custom_fields[described_class::ENABLED_FIELD] = true
      member.save_custom_fields
      Fabricate(:activity_anonymous_identity, user: member, master_user: admin)
      reset_activity_appearance_caches

      expect(described_class.allowed?(member)).to eq(false)
      expect(described_class.effective_color(member)).to be_nil
    end

    it "suppresses a pooled anonymous identity's saved color" do
      assign_activity_level(member, identifier: "reader", number: 1)
      member.custom_fields[described_class::ENABLED_FIELD] = true
      member.save_custom_fields
      Fabricate(:activity_pool_account, user: member)
      reset_activity_appearance_caches

      expect(described_class.allowed?(member)).to eq(false)
      expect(described_class.effective_color(member)).to be_nil
    end
  end

  describe "UserLookup" do
    it "preloads effective appearances for partial user records in a constant query count" do
      actors = [member, admin, moderator]
      actors.each do |actor|
        assign_activity_level(actor, identifier: "reader", number: 1)
        actor.custom_fields[described_class::ENABLED_FIELD] = true
        actor.save_custom_fields
      end
      counts = []
      colors = nil
      [actors.first(1), actors].each do |batch|
        reset_activity_appearance_caches
        queries =
          track_sql_queries do
            lookup = UserLookup.new(batch.map(&:id))
            colors = batch.map { |actor| described_class.effective_color(lookup[actor.id]) }
          end
        counts << queries.count { |query| /\ASELECT/i.match?(query) }
      end

      expect(colors).to eq(%w[level_preset theme theme])
      expect(counts.last).to eq(counts.first)
    end
  end
end
