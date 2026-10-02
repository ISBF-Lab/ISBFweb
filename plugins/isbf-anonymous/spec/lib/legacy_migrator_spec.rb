# frozen_string_literal: true

require_relative "../../lib/isbf_anonymous/legacy_migrator"

RSpec.describe IsbfAnonymous::LegacyMigrator do
  fab!(:user)
  fab!(:category)

  before do
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.anonymous_posting_allowed_groups = "1|2|10"
    SiteSetting.isbf_anonymous_pool_enabled = true
  end

  def legacy_post(shadow, **options)
    published =
      Fabricate(
        :post,
        user: shadow,
        topic: Fabricate(:topic, user: shadow, category: category),
        **options,
      )
    published.custom_fields[IsbfAnonymous::POST_FIELD] = true
    published.save_custom_fields
    published
  end

  describe "#run" do
    it "previews eligible content and cleanup without writing data" do
      shadow = AnonymousShadowCreator.get(user)
      published = legacy_post(shadow)

      expect do
        report = described_class.new(cleanup: true).run
        expect(report[:posts]).to eq(1)
        expect(report[:cleanable_accounts]).to eq([shadow.id])
      end.not_to change { [User.count, IsbfAnonymous::PoolAccount.count, PostCustomField.count] }

      expect(published.reload.user_id).to eq(shadow.id)
    end

    it "migrates visible and deleted posts and queued posts, then cleans old accounts idempotently" do
      shadow = AnonymousShadowCreator.get(user)
      published = legacy_post(shadow)
      deleted = legacy_post(shadow, deleted_at: 1.day.ago)
      reviewable =
        Fabricate(
          :reviewable_queued_post,
          target_created_by: shadow,
          category: category,
          payload: {
            raw: "An anonymous post pending review.",
            isbf_anonymous: "true",
          },
        )
      previous_revision_count = PostRevision.count

      report = described_class.new(dry_run: false, cleanup: true).run

      expect(report[:posts]).to eq(2)
      expect(report[:queued_posts]).to eq(1)
      expect(report[:deleted_accounts]).to eq([shadow.id])
      expect(User.exists?(shadow.id)).to eq(false)
      [published, deleted].each do |post|
        post.reload
        expect(post.custom_fields[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
        expect(IsbfAnonymous::PoolAccount.exists?(user_id: post.user_id)).to eq(true)
        expect(post.topic.reload.user_id).to eq(post.user_id)
      end
      expect(deleted.deleted_at).to be_present
      expect(PostRevision.count).to eq(previous_revision_count)
      expect(reviewable.reload.payload[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
      expect(IsbfAnonymous::PoolAccount.exists?(user_id: reviewable.target_created_by_id)).to eq(
        true,
      )
      expect(UserAction.where(user_id: shadow.id)).not_to exist

      expect(described_class.new(dry_run: false, cleanup: true).run[:posts]).to eq(0)
    end

    it "retains accounts with unmarked content or active sessions" do
      shadow = AnonymousShadowCreator.get(user)
      published = legacy_post(shadow)
      unmarked = Fabricate(:post, user: shadow)
      UserAuthToken.generate!(user_id: shadow.id)

      report = described_class.new(dry_run: false, cleanup: true).run

      expect(published.reload.user_id).not_to eq(shadow.id)
      expect(unmarked.reload.user_id).to eq(shadow.id)
      expect(report[:skipped_posts].map { |row| row[:id] }).to eq([unmarked.id])
      expect(report[:retained_accounts].map { |row| row[:user_id] }).to eq([shadow.id])
      expect(User.exists?(shadow.id)).to eq(true)
    end

    it "migrates deleted public topics and preserves their deleted state during cleanup" do
      shadow = AnonymousShadowCreator.get(user)
      published = legacy_post(shadow, deleted_at: 1.day.ago)
      topic = published.topic
      topic.trash!(user)
      post_deleted_at = published.deleted_at
      topic_deleted_at = topic.deleted_at
      previous_revision_count = PostRevision.count

      preview = described_class.new(cleanup: true).run
      expect(preview[:posts]).to eq(1)
      expect(preview[:cleanable_accounts]).to eq([shadow.id])

      report = described_class.new(dry_run: false, cleanup: true).run

      expect(report[:deleted_accounts]).to eq([shadow.id])
      expect(IsbfAnonymous::PoolAccount.exists?(user_id: published.reload.user_id)).to eq(true)
      expect(published.custom_fields[IsbfAnonymous::OWNER_FIELD]).to eq(user.id)
      expect(topic.reload.user_id).to eq(published.user_id)
      expect(published.deleted_at).to eq_time(post_deleted_at)
      expect(topic.deleted_at).to eq_time(topic_deleted_at)
      expect(PostRevision.count).to eq(previous_revision_count)
      expect(described_class.new(dry_run: false, cleanup: true).run[:posts]).to eq(0)
    end

    it "retains accounts with anonymous posts in deleted unlisted topics" do
      shadow = AnonymousShadowCreator.get(user)
      published = legacy_post(shadow)
      topic = published.topic
      topic.update!(visible: false)
      topic.trash!(user)

      report = described_class.new(dry_run: false, cleanup: true).run

      expect(report[:posts]).to eq(0)
      expect(report[:retained_accounts].map { |row| row[:user_id] }).to eq([shadow.id])
      expect(report[:skipped_posts].map { |row| row[:id] }).to eq([published.id])
      expect(published.reload.user_id).to eq(shadow.id)
      expect(User.exists?(shadow.id)).to eq(true)
      expect(IsbfAnonymous::PoolAccount.count).to eq(0)
    end
  end
end
