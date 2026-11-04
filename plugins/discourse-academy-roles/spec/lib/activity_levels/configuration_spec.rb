# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::Configuration do
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

  describe ".current" do
    it "returns existing thresholds without initializing persisted configuration" do
      SiteSetting.tl1_requires_topics_entered = 7
      SiteSetting.tl3_requires_likes_received = 21

      expect { described_class.current }.not_to change(PluginStoreRow, :count)
      configuration = described_class.current
      expect(configuration.revision).to eq(0)
      expect(configuration.levels.map { |level| level["id"] }).to eq(
        %w[legacy-0 legacy-1 legacy-2 legacy-3 legacy-4],
      )
      expect(configuration.levels[1]["conditions"]).to include(
        activity_condition("topics_entered", 7),
      )
      expect(configuration.levels[3]["conditions"]).to include(
        activity_condition("likes_received_users", 6, period: "recent"),
        activity_condition("likes_received_days", 7, period: "recent"),
      )
      expect(configuration.levels[4]).to include(
        "continuous_days" => 90,
        "max_check_gap_hours" => 36,
      )
    end

    it "keeps persisted activity rules independent from later native settings" do
      document = described_class.defaults
      persisted = persist_activity_rules(document)

      SiteSetting.tl1_requires_topics_entered = 200
      SiteSetting.tl3_requires_likes_received = 200
      SiteSetting.tl3_time_period = 200
      SiteSetting.default_trust_level = 4

      expect(described_class.current.document).to eq(persisted.document)
    end
  end

  describe ".save!" do
    it "assigns permanent identities to new levels and keeps ordering separate" do
      level =
        activity_tier(
          identifier: nil,
          conditions: [activity_condition("topics_entered", 2)],
          name: "Reader",
        )
      persisted = persist_activity_rules(activity_rules(levels: [level]))
      identifier = persisted.levels[1]["id"]

      expect(identifier).to be_present
      expect(identifier).not_to eq("legacy-0")

      renamed = persisted.document.deep_dup
      renamed["levels"][1]["name"] = "Contributor"
      updated = persist_activity_rules(renamed)

      expect(updated.levels[1]).to include("id" => identifier, "name" => "Contributor")
      expect(updated.revision).to eq(2)
    end

    it "reconciles stale legacy identities and preserves continuity during initialization" do
      member = Fabricate(:user)
      member.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD] = "legacy-0"
      member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = 3
      member.custom_fields[DiscourseAcademyRoles::LV3_SINCE_FIELD] = 30.days.ago.iso8601
      member.custom_fields[DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD] = 1.day.ago.iso8601
      member.save_custom_fields
      previous = described_class.current

      persisted = persist_activity_rules(previous.document)

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("legacy-3")
      state =
        DiscourseAcademyRoles::ActivityLevels.read(
          "#{DiscourseAcademyRoles::ActivityLevels::STATE_PREFIX}#{member.id}",
        )
      expect(state["checks"]["legacy-4"]).to include(
        "since" => member.custom_fields[DiscourseAcademyRoles::LV3_SINCE_FIELD],
        "checked_at" => member.custom_fields[DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD],
        "fingerprint" => previous.fingerprint(previous.levels[4]),
      )
      expect(persisted.revision).to eq(1)
    end

    it "keeps a level earned before initialization when automatic demotion is disabled" do
      member = Fabricate(:user, created_at: 30.days.ago)
      SiteSetting.tl2_requires_topic_reply_count = 0
      member.user_stat.update!(
        topics_entered: SiteSetting.tl2_requires_topics_entered,
        posts_read_count: SiteSetting.tl2_requires_read_posts,
        time_read: SiteSetting.tl2_requires_time_spent_mins * 60,
        days_visited: SiteSetting.tl2_requires_days_visited,
        likes_received: SiteSetting.tl2_requires_likes_received,
        likes_given: SiteSetting.tl2_requires_likes_given,
      )

      DiscourseAcademyRoles::ActivityLevel.update(member)

      expect(member.reload.custom_fields).to include(
        DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 2,
      )
      expect(member.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD]).to be_nil
      member.user_stat.update!(posts_read_count: 0)

      persist_activity_rules(described_class.defaults.merge("allow_demotion" => false))
      DiscourseAcademyRoles::ActivityLevel.update(member.reload)

      expect(member.reload.custom_fields).to include(
        DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD => 2,
        DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD => "legacy-2",
      )
    end

    it "preserves stable identities on subsequent saves despite an outdated numeric field" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 1)],
              ),
            ],
          ),
        )
      member = Fabricate(:user)
      assign_activity_level(member, identifier: "reader", number: 0)

      persist_activity_rules(configuration.document)

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("reader")
    end

    it "rolls back both rules and pending progress when persistence fails" do
      candidate =
        described_class.new(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 2)],
              ),
            ],
          ),
        )

      expect do
        PluginStoreRow.transaction do
          described_class.save!(
            candidate,
            expected_revision: 0,
            confirmed_deleted_ids: %w[legacy-1 legacy-2 legacy-3 legacy-4],
          )
          raise ActiveRecord::Rollback
        end
      end.not_to change(PluginStoreRow, :count)

      expect(described_class).not_to be_persisted
      expect(DiscourseAcademyRoles::ActivityLevels::Recalculation.current).to be_nil
    end
  end

  describe "#fingerprint" do
    it "ignores names and stable identities while tracking eligibility changes" do
      configuration = described_class.current
      level = configuration.levels[4]

      expect(
        configuration.fingerprint(level.merge("name" => "Regular", "id" => "same-rules")),
      ).to eq(configuration.fingerprint(level))
      expect(configuration.fingerprint(level.merge("continuous_days" => 91))).not_to eq(
        configuration.fingerprint(level),
      )
      changed = level.deep_dup
      changed["conditions"][0]["value"] += 1
      expect(configuration.fingerprint(changed)).not_to eq(configuration.fingerprint(level))
    end
  end
end
