# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::Recalculation do
  include ActivityLevelsSpecHelpers

  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

  describe ".perform!" do
    it "processes every batch in its saved cohort and leaves later accounts for the next run" do
      member.user_stat.update!(days_visited: 1)
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(
              identifier: "visitor",
              conditions: [activity_condition("days_visited", 1)],
            ),
          ],
        ),
      )
      run = described_class.current
      later_account = Fabricate(:user)
      later_account.user_stat.update!(days_visited: 1)

      stub_const(DiscourseAcademyRoles::ActivityLevels, :BATCH_SIZE, 2) do
        described_class.perform!(run["id"])
      end

      completed = described_class.current
      expect(completed).to include(
        "status" => "completed",
        "processed" => run["total"],
        "failed" => 0,
      )
      expect(completed.values_at("upgraded", "downgraded", "unchanged").sum).to eq(run["total"])
      expect(completed.values_at("started_at", "completed_at")).to all(be_present)
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("visitor")
      expect(
        later_account.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("legacy-0")
    end

    it "updates staff and ordinary accounts while excluding inactive, staged, system and anonymous accounts" do
      inactive = Fabricate(:inactive_user)
      staged = Fabricate(:user, staged: true)
      shadow = Fabricate(:user)
      Fabricate(:activity_anonymous_identity, master_user: member, user: shadow)
      pooled_anonymous = Fabricate(:user)
      Fabricate(:activity_pool_account, user: pooled_anonymous)
      actors = [admin, moderator, member, inactive, staged, shadow, pooled_anonymous]
      actors.each { |actor| actor.user_stat.update!(days_visited: 1) }
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(
              identifier: "visitor",
              conditions: [activity_condition("days_visited", 1)],
            ),
          ],
        ),
      )
      run = described_class.current

      Jobs::AcademyRecalculateActivityLevels.new.execute(run_id: run["id"])

      [admin, moderator, member].each do |actor|
        expect(
          actor.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
        ).to eq("visitor")
      end
      [inactive, staged, shadow, pooled_anonymous].each do |actor|
        expect(actor.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i).to eq(
          0,
        )
      end
      expect(DiscourseAcademyRoles::ActivityLevels.eligible_accounts).not_to include(
        Discourse.system_user,
      )
      expect(described_class.current).to include(
        "status" => "completed",
        "processed" => run["total"],
        "upgraded" => 3,
        "failed" => 0,
      )
    end

    it "leaves a completed run unchanged when delivered again" do
      member.user_stat.update!(days_visited: 1)
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(
              identifier: "visitor",
              conditions: [activity_condition("days_visited", 1)],
            ),
          ],
        ),
      )
      run_id = described_class.current["id"]
      described_class.perform!(run_id)
      completed = described_class.current.deep_dup
      member_state =
        DiscourseAcademyRoles::ActivityLevels.read(
          "#{DiscourseAcademyRoles::ActivityLevels::STATE_PREFIX}#{member.id}",
        ).deep_dup

      freeze_time(1.minute.from_now)
      described_class.perform!(run_id)

      expect(described_class.current).to eq(completed)
      expect(
        DiscourseAcademyRoles::ActivityLevels.read(
          "#{DiscourseAcademyRoles::ActivityLevels::STATE_PREFIX}#{member.id}",
        ),
      ).to eq(member_state)
    end

    it "prevents a stale run from applying rules after a newer save" do
      member.user_stat.update!(days_visited: 1)
      first =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "visitor",
                conditions: [activity_condition("days_visited", 1)],
              ),
            ],
          ),
        )
      old_run_id = described_class.current["id"]
      changed = first.document.deep_dup
      changed["levels"][1]["conditions"][0]["value"] = 2
      persist_activity_rules(changed)
      new_run = described_class.current.deep_dup

      described_class.perform!(old_run_id)

      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i).to eq(0)
      expect(described_class.current).to eq(new_run)
      described_class.perform!(new_run["id"])
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i).to eq(0)
    end

    it "finishes other accounts after one account fails and can retry after repair" do
      healthy = Fabricate(:user)
      healthy.user_stat.update!(days_visited: 1)
      member.user_stat.destroy!
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(
              identifier: "visitor",
              conditions: [activity_condition("days_visited", 1)],
            ),
          ],
        ),
      )

      described_class.perform!(described_class.current["id"])

      expect(described_class.current).to include("status" => "completed_with_errors", "failed" => 1)
      expect(healthy.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)

      Fabricate(:user_stat, user: member, days_visited: 1, new_since: 1.year.ago)
      retried = described_class.retry!
      described_class.perform!(retried["id"])

      expect(described_class.current).to include("status" => "completed", "failed" => 0)
      expect(member.reload.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(1)
    end
  end

  describe ".enqueue!" do
    it "records a queue outage and retries the same persisted revision after recovery" do
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "visitor",
                conditions: [activity_condition("days_visited", 1)],
              ),
            ],
          ),
        )
      Jobs.stubs(:enqueue).raises(Redis::CannotConnectError)

      described_class.enqueue!

      failed_run = described_class.current
      expect(failed_run).to include(
        "status" => "failed",
        "error" => "enqueue_failed",
        "revision" => configuration.revision,
      )
      expect(DiscourseAcademyRoles::ActivityLevels::Configuration.current.document).to eq(
        configuration.document,
      )

      Jobs.unstub(:enqueue)
      retried = described_class.retry!

      expect(retried).to include(
        "status" => "queued",
        "error" => nil,
        "revision" => configuration.revision,
      )
      expect(retried["id"]).not_to eq(failed_run["id"])
      expect(Jobs::AcademyRecalculateActivityLevels.jobs.last["args"].first["run_id"]).to eq(
        retried["id"],
      )
    end
  end

  describe ".schedule!" do
    it "starts the next daily run using persisted activity rules" do
      persist_activity_rules(
        activity_rules(
          levels: [
            activity_tier(
              identifier: "visitor",
              conditions: [activity_condition("days_visited", 1)],
            ),
          ],
        ),
      )
      finished_id = described_class.current["id"]
      described_class.perform!(finished_id)

      Jobs::AcademyActivityLevels.new.execute({})

      expect(described_class.current).to include("status" => "queued", "revision" => 1)
      expect(described_class.current["id"]).not_to eq(finished_id)
      expect(Jobs::AcademyRecalculateActivityLevels.jobs.last["args"].first["run_id"]).to eq(
        described_class.current["id"],
      )
    end
  end
end
