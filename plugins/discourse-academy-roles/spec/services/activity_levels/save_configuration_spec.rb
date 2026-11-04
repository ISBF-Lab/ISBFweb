# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::SaveConfiguration do
  include ActivityLevelsSpecHelpers

  describe described_class::Contract, type: :model do
    subject(:contract) { described_class.new(params) }

    let(:document) { DiscourseAcademyRoles::ActivityLevels::Configuration.defaults }
    let(:params) { document.merge("confirmed_deleted_ids" => []) }

    it do
      is_expected.to validate_numericality_of(:revision).only_integer.is_greater_than_or_equal_to(0)
    end

    it "accepts boolean and form-encoded demotion policies" do
      { true => true, "true" => true, false => false, "false" => false }.each do |value, expected|
        candidate = described_class.new(params.merge("allow_demotion" => value))

        expect(candidate).to be_valid
        expect(candidate.configuration.allow_demotion?).to eq(expected)
      end
    end

    it "rejects unknown demotion switch values" do
      [nil, "enabled", "0", 0, 1, [], {}].each do |value|
        candidate = described_class.new(params.merge("allow_demotion" => value))

        expect(candidate).to be_invalid
      end
    end

    it "accepts compatible defaults and a fully specified cosmetic preset" do
      expect(contract).to be_valid
      expect(contract.configuration.cosmetics).to eq(
        DiscourseAcademyRoles::ActivityLevels::Cosmetics.defaults,
      )
      preset = activity_cosmetics(avatar_minimum: "legacy-1", name_minimum: "legacy-2")
      expect(described_class.new(params.merge("cosmetics" => preset))).to be_valid
    end

    it "rejects malformed cosmetic structures, unknown level IDs, non-booleans and unsafe colors" do
      variants = [nil, [], "settings", true, {}, activity_cosmetics.merge("unknown" => true)]
      %w[avatar_minimum_level_id name_color_minimum_level_id].each do |key|
        [nil, [], 1, "deleted"].each { |value| variants << activity_cosmetics.merge(key => value) }
      end
      [nil, "true", "false", 0, 1, [], {}].each do |value|
        variants << activity_cosmetics.merge("name_color_enabled" => value)
      end
      %w[name_color_light name_color_dark].each do |key|
        [
          nil,
          123,
          [],
          {},
          "",
          "abc",
          "#abc",
          "#12345g",
          "#123456; color:red",
          "linear-gradient(90deg, #123456, #abcdef)",
        ].each { |value| variants << activity_cosmetics.merge(key => value) }
      end

      variants.each do |cosmetics|
        aggregate_failures(cosmetics.inspect) do
          expect(described_class.new(params.merge("cosmetics" => cosmetics))).to be_invalid
        end
      end
    end

    it "accepts only enabled single-grant custom badges without competing automated rules" do
      valid_badge = Fabricate(:activity_level_badge)
      disabled = Fabricate(:activity_level_badge, enabled: false)
      repeated = Fabricate(:activity_level_badge, multiple_grant: true)
      automated = Fabricate(:activity_level_badge, query: "SELECT id FROM users")
      triggered = Fabricate(:activity_level_badge, trigger: Badge::Trigger::UserChange)
      system_badge = Fabricate(:activity_level_badge)
      system_badge.update!(system: true)
      accepted = params.deep_dup
      accepted["levels"][1]["badge_id"] = valid_badge.id
      expect(described_class.new(accepted)).to be_valid

      [
        disabled.id,
        repeated.id,
        automated.id,
        triggered.id,
        system_badge.id,
        -1,
        0,
        2_147_483_648,
        valid_badge.id.to_s,
        true,
        [],
        {},
      ].each do |value|
        rejected = params.deep_dup
        rejected["levels"][1]["badge_id"] = value
        expect(described_class.new(rejected)).to be_invalid
      end
    end

    it "rejects invalid level structure, duplicate identities and a modified base level" do
      variants = [
        document.merge("allow_demotion" => nil),
        document.merge("levels" => nil),
        document.merge("levels" => {}),
        document.merge("levels" => ["reader"]),
        document.merge("levels" => []),
        document.merge(
          "levels" => [document["levels"].first, document["levels"][1].merge("id" => "legacy-0")],
        ),
        document.merge(
          "levels" => [
            document["levels"].first.merge("conditions" => [activity_condition("posts_read", 1)]),
          ],
        ),
        document.merge("levels" => [document["levels"].first.merge("id" => "changed-base")]),
      ]

      variants.each do |parameters|
        invalid = described_class.new(parameters)
        expect(invalid).to be_invalid
        expect(invalid.errors.full_messages).to be_present
      end
    end

    it "rejects invalid level identities, names and numeric boundaries" do
      attributes = {
        "id" => ["", "x" * 65, 1],
        "name" => [nil, "x" * 81],
        "period_days" => [-1, 0, 36_501, "7"],
        "continuous_days" => [-1, 36_501, 1.5],
        "max_check_gap_hours" => [0, 876_001, "36"],
        "demotion_buffer_percent" => [-1, 101, 1.5],
        "conditions" => [nil, "posts_read", []],
        "arbitrary_setting" => [true],
      }

      attributes.each do |attribute, values|
        values.each do |value|
          parameters = document.deep_dup
          parameters["levels"][1][attribute] = value
          aggregate_failures("#{attribute}=#{value.inspect}") do
            expect(described_class.new(parameters)).to be_invalid
          end
        end
      end
    end

    it "rejects malformed numeric thresholds, periods and arbitrary expressions" do
      invalid_conditions = [
        nil,
        "posts_read",
        activity_condition("posts_read", -1),
        activity_condition("posts_read", 2_147_483_648),
        activity_condition("posts_read", 1.5),
        activity_condition("posts_read", "5"),
        activity_condition("posts_read", 1, period: "future"),
        activity_condition("topics_viewed_percent", 101, period: "recent", cap: 250),
        activity_condition("topics_viewed_percent", 25, period: "recent"),
        activity_condition("topics_viewed_percent", 25, period: "recent", cap: -1),
        activity_condition("penalty_count", 0, period: "recent", months: 0),
        activity_condition("penalty_count", 0, period: "recent", months: 1201),
        activity_condition("penalty_count", 0, period: "all_time", months: 6),
        activity_condition("posts_read_all_time", 1, period: "recent"),
        activity_condition("posts_read", 1, cap: 10),
        activity_condition("posts_read", 1, months: 6),
        activity_condition("posts_read", 1, sql: "SELECT * FROM users"),
        activity_condition("custom_expression", 1),
      ]

      invalid_conditions.each do |condition|
        parameters =
          activity_rules(levels: [activity_tier(identifier: "reader", conditions: [condition])])
        expect(described_class.new(parameters)).to be_invalid
      end
    end

    it "accepts supported boundary values and continuity-only levels" do
      bounded =
        activity_tier(
          identifier: nil,
          conditions: [
            activity_condition("posts_read", 2_147_483_647),
            activity_condition("topics_viewed_percent", 100, period: "recent", cap: 0),
            activity_condition("penalty_count", 0, period: "recent", months: 1200),
          ],
          continuous_days: 36_500,
          gap_hours: 876_000,
          buffer: 100,
          period_days: 36_500,
        )
      continuity_only = activity_tier(identifier: nil, conditions: [], continuous_days: 1)

      expect(described_class.new(activity_rules(levels: [bounded, continuity_only]))).to be_valid
    end

    it "rejects qualifying streak gaps shorter than the daily evaluation supports" do
      [1, 12, 24, 35].each do |gap|
        parameters = document.deep_dup
        parameters["levels"][1].merge!("continuous_days" => 1, "max_check_gap_hours" => gap)

        aggregate_failures("check gap #{gap} hours") do
          expect(described_class.new(parameters)).to be_invalid
        end
      end
    end

    it "accepts supported streak gaps and short gaps for immediate qualification" do
      [36, 48, 876_000].each do |gap|
        parameters = document.deep_dup
        parameters["levels"][1].merge!("continuous_days" => 1, "max_check_gap_hours" => gap)

        expect(described_class.new(parameters)).to be_valid
      end
      immediate = document.deep_dup
      immediate["levels"][1].merge!("continuous_days" => 0, "max_check_gap_hours" => 1)

      expect(described_class.new(immediate)).to be_valid
    end

    it "rejects non-scalar revisions without raising an exception" do
      [nil, [], {}, true, 1.5].each do |revision|
        expect(described_class.new(params.merge("revision" => revision))).to be_invalid
      end
    end

    it "rejects invalid continuity, buffers and deletion confirmations" do
      variants = [
        document.merge("confirmed_deleted_ids" => nil),
        document.merge("confirmed_deleted_ids" => "legacy-2"),
        document.merge("confirmed_deleted_ids" => [2]),
      ]
      %w[period_days max_check_gap_hours].each do |key|
        parameters = document.deep_dup
        parameters["levels"][1][key] = 0
        variants << parameters
      end
      parameters = document.deep_dup
      parameters["levels"][1]["demotion_buffer_percent"] = 101
      variants << parameters

      variants.each { |variant| expect(described_class.new(variant)).to be_invalid }
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    let(:document) { DiscourseAcademyRoles::ActivityLevels::Configuration.defaults }
    let(:params) { document.merge("confirmed_deleted_ids" => []) }
    let(:dependencies) { { guardian: acting_user.guardian } }

    before do
      DiscourseAcademyRoles::ActivityLevels::Current.reset
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

    context "with an invalid contract" do
      let(:params) { document.merge("levels" => []) }

      it { is_expected.to fail_a_contract }
    end

    context "when the actor is a moderator" do
      fab!(:acting_user, :moderator)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the actor is an ordinary member" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the feature is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when a newer revision has already been saved" do
      before { persist_activity_rules(document) }

      it "rejects the stale save without changing the persisted rules" do
        expect(result).to fail_with_exception(DiscourseAcademyRoles::ActivityLevels::Conflict)
        expect(DiscourseAcademyRoles::ActivityLevels::Configuration.current.revision).to eq(1)
      end
    end

    context "when deleted levels have not been confirmed" do
      let(:params) do
        document.merge("levels" => document["levels"].first(2), "confirmed_deleted_ids" => [])
      end

      it "rejects deletion without writing a configuration" do
        expect(result).to fail_with_exception(
          DiscourseAcademyRoles::ActivityLevels::UnconfirmedDeletion,
        )
        expect(DiscourseAcademyRoles::ActivityLevels::Configuration).not_to be_persisted
      end
    end

    context "when a frame refers to a level being deleted" do
      fab!(:frame) { Fabricate(:avatar_frame, minimum_activity_level_id: "legacy-4") }
      let(:params) do
        document.merge(
          "levels" => document["levels"].first(4),
          "confirmed_deleted_ids" => ["legacy-4"],
        )
      end

      it "rejects the deletion without changing configuration or its job queue" do
        expect { result }.not_to change { Jobs::AcademyRecalculateActivityLevels.jobs.size }
        expect(result).to fail_with_exception(
          DiscourseAcademyRoles::ActivityLevels::ReferencedLevel,
        )
        expect(frame.reload.minimum_activity_level_id).to eq("legacy-4")
      end
    end

    context "when an old client omits new appearance fields" do
      fab!(:badge, :activity_level_badge)
      let(:params) do
        current = DiscourseAcademyRoles::ActivityLevels::Configuration.current.document.deep_dup
        current.delete("cosmetics")
        current["levels"].each { |level| level.delete("badge_id") }
        current
      end

      before do
        saved = document.deep_dup
        saved["cosmetics"] = activity_cosmetics(name_minimum: "legacy-1")
        saved["levels"][1]["badge_id"] = badge.id
        persist_activity_rules(saved)
      end

      it "preserves configured capabilities and badge bindings" do
        expect(result).to run_successfully
        current = DiscourseAcademyRoles::ActivityLevels::Configuration.current
        expect(current.cosmetics).to eq(activity_cosmetics(name_minimum: "legacy-1"))
        expect(current.levels[1]["badge_id"]).to eq(badge.id)
      end
    end

    context "with valid rules" do
      it "persists one revision, audits it and queues its recalculation" do
        expect { result }.to change { Jobs::AcademyRecalculateActivityLevels.jobs.size }.by(1)
        expect(result).to run_successfully

        configuration = DiscourseAcademyRoles::ActivityLevels::Configuration.current
        run = DiscourseAcademyRoles::ActivityLevels::Recalculation.current
        expected = document.deep_dup
        expected["revision"] = 1
        expected["cosmetics"] = DiscourseAcademyRoles::ActivityLevels::Cosmetics.defaults
        expected["levels"].each { |level| level["badge_id"] = nil }
        expect(configuration.document).to eq(expected)
        expect(run).to include("revision" => 1, "status" => "queued")
        expect(Jobs::AcademyRecalculateActivityLevels.jobs.last["args"].first["run_id"]).to eq(
          run["id"],
        )
        expect(
          UserHistory.where(
            custom_type: "academy_activity_levels_changed",
            acting_user_id: acting_user.id,
            new_value: "1",
            previous_value: "0",
          ),
        ).to exist
      end
    end
  end
end
