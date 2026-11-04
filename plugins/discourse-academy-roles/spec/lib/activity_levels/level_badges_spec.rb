# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::LevelBadges do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:admin)
  fab!(:reader_badge, :activity_level_badge)
  fab!(:regular_badge, :activity_level_badge)
  fab!(:manual_badge, :activity_level_badge)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  let(:document) do
    activity_rules(
      levels: [
        activity_tier(
          identifier: "reader",
          conditions: [activity_condition("posts_read", 1)],
        ).merge("badge_id" => reader_badge.id),
        activity_tier(
          identifier: "regular",
          conditions: [activity_condition("posts_read", 10)],
        ).merge("badge_id" => regular_badge.id),
      ],
    )
  end
  let(:configuration) { persist_activity_rules(document) }

  before do
    reset_activity_appearance_caches
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.enable_badges = true
    configuration
    assign_activity_level(member, identifier: "reader", number: 1)
  end

  after { reset_activity_appearance_caches }

  describe ".synchronize!" do
    it "awards the current level once and avoids duplicate notifications" do
      awards = UserBadge.where(user: member, badge: reader_badge)
      notices =
        Notification.where(user: member, notification_type: Notification.types[:granted_badge])

      expect do
        described_class.synchronize!(member, configuration)
        described_class.synchronize!(member, configuration)
      end.to change(awards, :count).by(1).and change(notices, :count).by(1)
      expect(awards.first.granted_by).to eq(Discourse.system_user)
    end

    it "replaces only the system-owned previous level badge" do
      BadgeGranter.grant(manual_badge, member, granted_by: admin)
      described_class.synchronize!(member, configuration)
      assign_activity_level(member, identifier: "regular", number: 2)

      described_class.synchronize!(member, configuration)

      expect(
        member
          .user_badges
          .where(badge: [reader_badge, regular_badge, manual_badge])
          .pluck(:badge_id),
      ).to contain_exactly(regular_badge.id, manual_badge.id)
    end

    it "revokes the automatic reward after demotion to an unbound base level" do
      described_class.synchronize!(member, configuration)
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      described_class.synchronize!(member, configuration)

      expect(UserBadge.where(user: member, badge: [reader_badge, regular_badge])).not_to exist
    end

    it "never adopts an identical badge that was already granted manually" do
      manual_award = BadgeGranter.grant(reader_badge, member, granted_by: admin)
      described_class.synchronize!(member, configuration)
      assign_activity_level(member, identifier: "regular", number: 2)

      described_class.synchronize!(member, configuration)

      expect(UserBadge.find_by(id: manual_award.id)).to eq(manual_award)
      expect(
        member.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id),
      ).to contain_exactly(reader_badge.id, regular_badge.id)
    end

    it "preserves a later manual grant of the same automatically awarded badge" do
      described_class.synchronize!(member, configuration)
      automatic_award = UserBadge.find_by!(user: member, badge: reader_badge)
      retained_award = BadgeGranter.grant(reader_badge, member, granted_by: admin)
      expect(retained_award.id).to eq(automatic_award.id)
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      described_class.synchronize!(member, configuration)

      expect(UserBadge.find_by(id: automatic_award.id)).to eq(automatic_award)
    end

    it "does not relinquish ownership when an unauthorized actor attempts a manual grant" do
      described_class.synchronize!(member, configuration)
      outsider = Fabricate(:user)
      expect(BadgeGranter.grant(reader_badge, member, granted_by: outsider)).to be_nil
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      described_class.synchronize!(member, configuration)

      expect(UserBadge.where(user: member, badge: reader_badge)).not_to exist
    end

    it "keeps the same native award when adjacent levels share a badge" do
      described_class.synchronize!(member, configuration)
      original = UserBadge.find_by!(user: member, badge: reader_badge)
      changed = configuration.document.deep_dup
      changed["levels"][2]["badge_id"] = reader_badge.id
      updated = persist_activity_rules(changed)
      assign_activity_level(member, identifier: "regular", number: 2)

      expect { described_class.synchronize!(member, updated) }.not_to change(UserBadge, :count)
      expect(UserBadge.find_by(user: member, badge: reader_badge).id).to eq(original.id)
    end

    it "updates a changed binding without requiring a level change" do
      member.user_stat.update!(posts_read_count: 1)
      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(
        DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"],
      )
      changed = configuration.document.deep_dup
      changed["levels"][1]["badge_id"] = regular_badge.id
      persist_activity_rules(changed)

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(
        DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"],
      )

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("reader")
      expect(member.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id)).to eq(
        [regular_badge.id],
      )
    end

    it "never grants a stale run's badge after a newer binding is saved" do
      member.user_stat.update!(posts_read_count: 1)
      old_run_id = DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"]
      changed = configuration.document.deep_dup
      changed["levels"][1]["badge_id"] = regular_badge.id
      persist_activity_rules(changed)
      new_run_id = DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"]

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(old_run_id)
      expect(UserBadge.where(user: member, badge: [reader_badge, regular_badge])).not_to exist

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(new_run_id)
      expect(member.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id)).to eq(
        [regular_badge.id],
      )
    end

    it "removes an owned badge when its badge is disabled" do
      described_class.synchronize!(member, configuration)
      reader_badge.update!(enabled: false)

      described_class.synchronize!(member, configuration)

      expect(UserBadge.where(user: member, badge: reader_badge)).not_to exist
    end

    it "clears an owned reward when its binding is explicitly removed without a level change" do
      described_class.synchronize!(member, configuration)
      changed = configuration.document.deep_dup
      changed["levels"][1]["badge_id"] = nil
      updated = persist_activity_rules(changed)

      described_class.synchronize!(member, updated)

      expect(UserBadge.where(user: member, badge: reader_badge)).not_to exist
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("reader")
    end

    it "removes an automatic reward after its level is deleted and recalculated" do
      described_class.synchronize!(member, configuration)
      member.user_stat.update!(posts_read_count: 1)
      changed = configuration.document.deep_dup
      changed["levels"].delete_at(1)
      persist_activity_rules(changed)

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(
        DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"],
      )

      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("legacy-0")
      expect(UserBadge.where(user: member, badge: [reader_badge, regular_badge])).not_to exist
    end

    it "does not alter grants while native badges are disabled" do
      described_class.synchronize!(member, configuration)
      SiteSetting.enable_badges = false
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      expect { described_class.synchronize!(member, configuration) }.not_to change(
        UserBadge,
        :count,
      )
    end

    it "uses the staff account's actual level for rewards" do
      assign_activity_level(admin, identifier: "reader", number: 1)

      described_class.synchronize!(admin, configuration)

      expect(admin.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id)).to eq(
        [reader_badge.id],
      )
    end

    it "rolls back a failed replacement and repairs it through the job retry" do
      described_class.synchronize!(member, configuration)
      member.user_stat.update!(posts_read_count: 10)
      UserBadge.any_instance.stubs(:save!).raises(ActiveRecord::RecordNotSaved)

      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(
        DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"],
      )

      expect(DiscourseAcademyRoles::ActivityLevels::Recalculation.current).to include(
        "status" => "completed_with_errors",
        "failed" => 1,
      )
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("reader")
      expect(member.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id)).to eq(
        [reader_badge.id],
      )

      UserBadge.any_instance.unstub(:save!)
      retry_run = DiscourseAcademyRoles::ActivityLevels::Recalculation.retry!
      DiscourseAcademyRoles::ActivityLevels::Recalculation.perform!(retry_run["id"])

      expect(DiscourseAcademyRoles::ActivityLevels::Recalculation.current).to include(
        "status" => "completed",
        "failed" => 0,
      )
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("regular")
      expect(member.user_badges.where(badge: [reader_badge, regular_badge]).pluck(:badge_id)).to eq(
        [regular_badge.id],
      )
    end
  end
end
