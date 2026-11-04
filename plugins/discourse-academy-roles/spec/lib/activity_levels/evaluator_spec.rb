# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::Evaluator do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    freeze_time(Time.utc(2026, 11, 3, 12))
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

  describe "#update!" do
    it "preserves an existing qualifying clock when a badge or appearance requirement changes" do
      badge = Fabricate(:activity_level_badge)
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("days_visited", 1)],
                continuous_days: 1,
              ),
            ],
          ),
        )
      member.user_stat.update!(days_visited: 1)
      now = Time.current
      described_class.new(member, configuration: configuration, now: now).update!
      changed = configuration.document.deep_dup
      changed["levels"][1]["badge_id"] = badge.id
      changed["cosmetics"] = activity_cosmetics(name_minimum: "regular")
      updated = persist_activity_rules(changed)

      described_class.new(member, configuration: updated, now: now + 1.day).update!

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("regular")
      expect(UserBadge.where(user: member, badge: badge)).to exist
    end

    it "selects the highest independently satisfied level without changing internal trust" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 30)],
              ),
              activity_tier(
                identifier: "visitor",
                conditions: [activity_condition("days_visited", 2)],
              ),
            ],
          ),
        )
      member.user_stat.update!(posts_read_count: 0, days_visited: 2)
      before_trust = member.trust_level

      described_class.new(member, configuration: configuration).update!

      expect(member.reload.custom_fields).to include(
        DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 2,
        DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD => "visitor",
      )
      expect(member.trust_level).to eq(before_trust)
    end

    it "requires every enabled condition on a level" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [
                  activity_condition("posts_read", 30),
                  activity_condition("days_visited", 2),
                ],
              ),
            ],
          ),
        )
      member.user_stat.update!(posts_read_count: 30, days_visited: 1)

      described_class.new(member, configuration: configuration).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)

      member.user_stat.update!(days_visited: 2)
      described_class.new(member, configuration: configuration).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)
    end

    it "keeps an earned existing level when automatic demotion is disabled" do
      configuration =
        persist_activity_rules(
          activity_rules(
            allow_demotion: false,
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 30)],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "reader", number: 1)
      member.user_stat.update!(posts_read_count: 0)

      described_class.new(member, configuration: configuration).update!

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("reader")
    end

    it "reassigns a deleted level even when demotion is disabled" do
      first =
        persist_activity_rules(
          activity_rules(
            allow_demotion: false,
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 1)],
              ),
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("posts_read", 30)],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "regular", number: 2)
      document = first.document.deep_dup
      document["levels"].pop
      configuration = persist_activity_rules(document)
      member.user_stat.update!(posts_read_count: 1)

      described_class.new(member, configuration: configuration).update!

      expect(member.reload.custom_fields).to include(
        DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 1,
        DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD => "reader",
      )
    end

    it "renumbers the same stable level after deleting a lower level" do
      first =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 1)],
              ),
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("posts_read", 30)],
                name: "Regular",
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "regular", number: 2)
      document = first.document.deep_dup
      document["levels"].delete_at(1)
      configuration = persist_activity_rules(document)
      member.user_stat.update!(posts_read_count: 30)

      described_class.new(member, configuration: configuration).update!

      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)
      expect(DiscourseAcademyRoles::ActivityLevels.level_name(member)).to eq("Regular")
      expect(DiscourseAcademyRoles::ActivityLevels.level_number(member)).to eq(1)
    end

    it "demotes independently of a native trust default that disables native demotion" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 30)],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "reader", number: 1)
      member.user_stat.update!(posts_read_count: 29)
      SiteSetting.default_trust_level = 4

      described_class.new(member, configuration: configuration).update!

      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)
    end

    it "uses elapsed qualifying time rather than the number of recalculations" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("days_visited", 1)],
                continuous_days: 1,
              ),
            ],
          ),
        )
      member.user_stat.update!(days_visited: 1)
      now = Time.current

      described_class.new(member, configuration: configuration, now: now).update!
      described_class.new(member, configuration: configuration, now: now + 1.minute).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)

      described_class.new(member, configuration: configuration, now: now + 1.day).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)
    end

    it "resets continuity after the configured check gap" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("days_visited", 1)],
                continuous_days: 1,
                gap_hours: 12,
              ),
            ],
          ),
        )
      member.user_stat.update!(days_visited: 1)
      now = Time.current

      described_class.new(member, configuration: configuration, now: now).update!
      described_class.new(member, configuration: configuration, now: now + 1.day).update!

      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)
    end

    it "resets continuity when a condition stops being satisfied" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("days_visited", 1)],
                continuous_days: 1,
              ),
            ],
          ),
        )
      member.user_stat.update!(days_visited: 1)
      now = Time.current
      described_class.new(member, configuration: configuration, now: now).update!
      member.user_stat.update!(days_visited: 0)
      described_class.new(member, configuration: configuration, now: now + 1.hour).update!
      member.user_stat.update!(days_visited: 1)
      described_class.new(member, configuration: configuration, now: now + 2.hours).update!
      described_class.new(member, configuration: configuration, now: now + 25.hours).update!

      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)

      described_class.new(member, configuration: configuration, now: now + 26.hours).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)
    end

    it "preserves continuity across a rename and resets it after a rule edit" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                conditions: [activity_condition("days_visited", 1)],
                continuous_days: 1,
              ),
            ],
          ),
        )
      member.user_stat.update!(days_visited: 1)
      now = Time.current
      described_class.new(member, configuration: configuration, now: now).update!
      renamed = configuration.document.deep_dup
      renamed["levels"][1]["name"] = "Regular"
      configuration = persist_activity_rules(renamed)
      described_class.new(member, configuration: configuration, now: now + 1.day).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)

      changed = configuration.document.deep_dup
      changed["levels"][1]["conditions"][0]["value"] = 2
      configuration = persist_activity_rules(changed)
      member.user_stat.update!(days_visited: 2)
      described_class.new(member, configuration: configuration, now: now + 25.hours).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)
    end

    it "applies a configured recent-count buffer without relaxing cumulative thresholds" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "regular",
                buffer: 10,
                conditions: [activity_condition("days_visited", 10, period: "recent")],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "regular", number: 1)
      9.times do |offset|
        Fabricate(
          :user_visit,
          user: member,
          visited_at: (offset + 1).days.ago.to_date,
          posts_read: 1,
        )
      end

      described_class.new(member, configuration: configuration).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)

      cumulative = configuration.document.deep_dup
      cumulative["levels"][1]["conditions"] = [activity_condition("days_visited", 10)]
      configuration = persist_activity_rules(cumulative)
      member.user_stat.update!(days_visited: 9)
      described_class.new(member, configuration: configuration).update!
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)
    end
  end
end
