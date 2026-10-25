# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::OfficialPostQuota do
  fab!(:developer, :admin)
  fab!(:member, :user)
  fab!(:other_member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    freeze_time Time.utc(2026, 1, 4, 15, 59, 59)
  end

  describe ".snapshot" do
    it "defaults to unlimited without creating a store row" do
      expect {
        expect(described_class.snapshot(member)).to include(
          limit: 0,
          used: 0,
          remaining: nil,
          timezone: "Asia/Shanghai",
          exempt: false,
          official: false,
        )
      }.not_to change {
        PluginStoreRow.where(plugin_name: DiscourseAcademyRoles::PLUGIN_NAME).count
      }
    end

    it "uses Monday in Shanghai across the calendar year" do
      expect(described_class.snapshot(member)).to include(
        week_starts_at: "2025-12-28T16:00:00Z",
        resets_at: "2026-01-04T16:00:00Z",
      )
      expect(described_class.snapshot(member, now: Time.utc(2026, 1, 4, 16))).to include(
        week_starts_at: "2026-01-04T16:00:00Z",
        resets_at: "2026-01-11T16:00:00Z",
        used: 0,
      )
    end

    it "reports independent limits and remaining capacity for each user" do
      official_group.add(member)
      described_class.update_limit!(developer, member, limit: 2)
      described_class.update_limit!(developer, other_member, limit: 5)
      member.with_lock { described_class.record_success!(member, used: 0) }

      expect(described_class.snapshot(member)).to include(
        limit: 2,
        used: 1,
        remaining: 1,
        official: true,
      )
      expect(described_class.snapshot(other_member)).to include(limit: 5, used: 0, remaining: 5)
    end
  end

  describe ".usage" do
    it "seeds from marked first posts including soft deleted posts after a category move" do
      official_post = Fabricate(:post, user: member, created_at: 1.hour.ago)
      deleted_post = Fabricate(:post, user: member, created_at: 2.hours.ago)
      [official_post, deleted_post].each do |post|
        post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
        post.save_custom_fields
      end
      deleted_post.update_columns(deleted_at: Time.current)
      official_post.topic.update_columns(category_id: Fabricate(:category).id)
      Fabricate(:post, user: member, created_at: 3.hours.ago)
      old_post = Fabricate(:post, user: member, created_at: 2.weeks.ago)
      old_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
      old_post.save_custom_fields
      reply = Fabricate(:post, topic: official_post.topic, user: member, created_at: 1.minute.ago)
      reply.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
      reply.save_custom_fields

      expect(described_class.usage(member)).to eq(2)
      expect(
        PluginStoreRow.exists?(
          plugin_name: DiscourseAcademyRoles::PLUGIN_NAME,
          key: "#{described_class::STORE_KEY_PREFIX}:#{member.id}",
        ),
      ).to eq(false)
    end

    it "excludes marked shared drafts until they are published" do
      draft_post = Fabricate(:post, user: member, created_at: 1.hour.ago)
      draft_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
      draft_post.save_custom_fields
      shared_draft = Fabricate(:shared_draft, topic: draft_post.topic, category: official_category)

      expect(described_class.usage(member)).to eq(0)

      shared_draft.destroy!

      expect(described_class.usage(member)).to eq(1)
    end

    it "starts the next week at zero while retaining the previous week's stored counter" do
      member.with_lock { described_class.record_success!(member, used: 2) }

      expect(described_class.usage(member)).to eq(3)
      expect(described_class.usage(member, now: Time.utc(2026, 1, 4, 16))).to eq(0)
      expect(described_class.usage(member)).to eq(3)
    end
  end

  describe ".record_success!" do
    it "retains seeded usage after the historical posts are permanently removed" do
      official_post = Fabricate(:post, user: member, created_at: 1.hour.ago)
      official_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
      official_post.save_custom_fields

      member.with_lock do
        used = described_class.usage(member)
        described_class.record_success!(member, used: used)
      end
      official_post.destroy!

      expect(described_class.usage(member.reload)).to eq(2)
    end

    it "survives saving custom fields from a stale ordinary profile snapshot" do
      stale_profile = User.find(member.id)
      stale_profile.custom_fields
      described_class.update_limit!(developer, User.find(member.id), limit: 2)
      member.with_lock { described_class.record_success!(member, used: 0) }

      stale_profile.custom_fields["profile_note"] = "Updated after publishing"
      stale_profile.save_custom_fields

      expect(described_class.snapshot(member)).to include(limit: 2, used: 1, remaining: 1)
      expect(User.find(member.id).custom_fields["profile_note"]).to eq("Updated after publishing")
    end

    it "counts unlimited and exempt users and rolls back with the publishing transaction" do
      [member, developer].each do |user|
        user.with_lock { described_class.record_success!(user, used: 0) }
        expect(described_class.snapshot(user)).to include(used: 1, remaining: nil)
      end

      member.with_lock do
        described_class.record_success!(member, used: 1)
        raise ActiveRecord::Rollback
      end

      expect(described_class.usage(member)).to eq(1)
    end
  end

  describe ".limited?" do
    it "enforces the configured boundary while exempting developers and unlimited users" do
      described_class.update_limit!(developer, member, limit: 2)
      described_class.update_limit!(developer, developer, limit: 1)

      expect(described_class.limited?(member, 1)).to eq(false)
      expect(described_class.limited?(member, 2)).to eq(true)
      expect(described_class.limited?(member, 3)).to eq(true)
      expect(described_class.limited?(developer, 10)).to eq(false)
      expect(described_class.limited?(other_member, 10)).to eq(false)
    end

    it "uses a changed limit immediately even if the user's custom fields were cached" do
      member.custom_fields
      described_class.update_limit!(developer, User.find(member.id), limit: 1)

      expect(described_class.limited?(member, 1)).to eq(true)
    end
  end

  describe ".update_limit!" do
    it "persists historical usage when first configuring a limit before posts are purged" do
      official_post = Fabricate(:post, user: member, created_at: 1.hour.ago)
      official_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
      official_post.save_custom_fields
      official_post.update_columns(deleted_at: Time.current)

      expect(described_class.update_limit!(developer, member, limit: 1)).to include(
        limit: 1,
        used: 1,
        remaining: 0,
      )
      official_post.destroy!

      expect(described_class.snapshot(member)).to include(limit: 1, used: 1, remaining: 0)
    end

    it "initializes usage when saving the default limit without recording a limit change" do
      expect { described_class.update_limit!(developer, member, limit: 0) }.not_to change {
        UserHistory.where(custom_type: described_class::AUDIT_ACTION).count
      }

      expect(
        PluginStore.get(
          DiscourseAcademyRoles::PLUGIN_NAME,
          "#{described_class::STORE_KEY_PREFIX}:#{member.id}",
        ),
      ).to include(
        "limit" => 0,
        "usage" => {
          "week_starts_at" => "2025-12-28T16:00:00Z",
          "used" => 0,
        },
      )
    end

    it "preserves usage when reducing or removing a limit" do
      member.with_lock { described_class.record_success!(member, used: 2) }

      expect(described_class.update_limit!(developer, member, limit: 2)).to include(
        limit: 2,
        used: 3,
        remaining: 0,
      )
      expect(described_class.update_limit!(developer, member, limit: 0)).to include(
        limit: 0,
        used: 3,
        remaining: nil,
      )
      expect(
        described_class.update_limit!(developer, member, limit: described_class::MAX_LIMIT)[:limit],
      ).to eq(described_class::MAX_LIMIT)
    end

    it "records the actor, target and old and new limits only for actual changes" do
      expect {
        described_class.update_limit!(developer, member, limit: 3)
        described_class.update_limit!(developer, member, limit: 3)
      }.to change { UserHistory.where(custom_type: described_class::AUDIT_ACTION).count }.by(1)

      history =
        UserHistory.find_by!(
          custom_type: described_class::AUDIT_ACTION,
          acting_user_id: developer.id,
          target_user_id: member.id,
        )
      expect(history).to have_attributes(
        acting_user_id: developer.id,
        target_user_id: member.id,
        previous_value: "0",
        new_value: "3",
      )
      expect(described_class.snapshot(member)[:limit]).to eq(3)
    end

    it "rejects invalid limits without changing the existing value" do
      described_class.update_limit!(developer, member, limit: 2)
      [nil, true, false, "3", 1.5, -1, described_class::MAX_LIMIT + 1].each do |invalid_limit|
        expect {
          described_class.update_limit!(developer, member, limit: invalid_limit)
        }.to raise_error(Discourse::InvalidParameters)
      end

      expect(described_class.snapshot(member)[:limit]).to eq(2)
    end

    it "rejects a nondeveloper actor" do
      expect { described_class.update_limit!(other_member, member, limit: 1) }.to raise_error(
        Discourse::InvalidAccess,
      )
    end
  end
end
