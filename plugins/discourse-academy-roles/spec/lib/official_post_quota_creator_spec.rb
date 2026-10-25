# frozen_string_literal: true

RSpec.describe PostCreator do
  fab!(:developer, :admin)
  fab!(:member) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_member) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:ordinary_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.auto_silence_fast_typers_on_first_post = false
    official_group.add(member)
    official_group.add(other_member)
    official_category.set_permissions({ everyone: :create_post }.merge(official_group => :full))
    ordinary_category.set_permissions(everyone: :full)
    freeze_time Time.utc(2026, 10, 25, 4)
  end

  let(:quota) { DiscourseAcademyRoles::OfficialPostQuota }
  let(:payload) do
    {
      title: "An official academy announcement",
      raw: "Important information for the academy community.",
      category: official_category.id,
      academy_official: true,
      isbf_official_campuses: '["zhuhai"]',
      isbf_official_types: '["academic"]',
      skip_rate_limits: true,
      skip_jobs: true,
    }
  end

  it "enforces separate limits and preserves usage through deletion and quota changes" do
    quota.update_limit!(developer, member, limit: 1)
    quota.update_limit!(developer, other_member, limit: 2)
    created = described_class.new(member, payload).create
    expect(created).to be_persisted
    expect(quota.snapshot(member)).to include(used: 1, remaining: 0)

    created.update_columns(deleted_at: Time.current)
    denied = described_class.new(member, payload.merge(title: "Another official announcement"))
    expect { denied.create }.not_to change { Topic.with_deleted.count }
    expect(denied.errors.full_messages).to include(quota.error_message(member))
    expect(
      described_class.new(
        other_member,
        payload.merge(title: "Another member's announcement"),
      ).create,
    ).to be_persisted

    quota.update_limit!(developer, member, limit: 0)
    expect(
      described_class.new(
        member,
        payload.merge(title: "An unlimited official announcement"),
      ).create,
    ).to be_persisted
    quota.update_limit!(developer, member, limit: 1)
    expect(quota.snapshot(member)).to include(used: 2, remaining: 0)
  end

  it "leaves invalid submissions, ordinary topics and replies outside the official quota" do
    quota.update_limit!(developer, member, limit: 1)
    failed = described_class.new(member, payload.merge(raw: ""))
    expect(failed.create).not_to be_persisted
    expect(quota.usage(member)).to eq(0)
    ordinary =
      described_class.new(
        member,
        payload.merge(
          category: ordinary_category.id,
          academy_official: false,
          isbf_official_campuses: nil,
          isbf_official_types: nil,
        ),
      ).create
    expect(ordinary).to be_persisted
    expect(
      described_class.new(
        member,
        {
          topic_id: ordinary.topic_id,
          raw: "A reply to ordinary discussion",
          skip_rate_limits: true,
          skip_jobs: true,
        },
      ).create,
    ).to be_persisted
    expect(quota.usage(member)).to eq(0)
  end

  it "enforces quota when native approval skips validation and events" do
    quota.update_limit!(developer, member, limit: 1)
    options = payload.merge(skip_validations: true, skip_events: true, reviewed_queued_post: true)
    expect(described_class.new(member, options).create).to be_persisted
    denied = described_class.new(member, options.merge(title: "A second reviewed official post"))
    expect { denied.create }.not_to change { Post.with_deleted.count }
    expect(denied.errors.full_messages).to include(quota.error_message(member))
  end

  it "keeps an over-quota application pending until real approval can publish it" do
    quota.update_limit!(developer, member, limit: 1)
    expect(described_class.new(member, payload).create).to be_persisted
    reviewable =
      Fabricate(
        :reviewable_queued_post_topic,
        category: official_category,
        target_created_by: member,
        created_by: developer,
        payload:
          payload.except(:category, :skip_jobs).merge(title: "A reviewed official announcement"),
      )

    expect {
      expect(reviewable.perform(developer, :approve_post)).not_to be_success
    }.not_to change { Post.with_deleted.count }
    expect(reviewable.reload).to be_pending
    expect(reviewable.target_id).to be_nil
    expect(quota.usage(member)).to eq(1)

    quota.update_limit!(developer, member, limit: 2)
    result = reviewable.reload.perform(developer, :approve_post)
    expect(result).to be_success
    expect(result.created_post).to be_persisted
    expect(quota.usage(member)).to eq(2)
  end

  it "keeps developer accounts exempt while tracking their successful publications" do
    quota.update_limit!(developer, developer, limit: 1)
    2.times do |index|
      expect(
        described_class.new(
          developer,
          payload.merge(title: "Developer announcement #{index}"),
        ).create,
      ).to be_persisted
    end
    expect(quota.snapshot(developer)).to include(used: 2, remaining: nil, exempt: true)
  end

  it "rolls native partial writes back without leaving an orphan topic or using quota" do
    quota.update_limit!(developer, member, limit: 1)
    creator = described_class.new(member, payload)
    allow(creator).to receive(:save_post) do
      creator.post.errors.add(:base, "A native late failure")
      creator.send(:rollback_from_errors!, creator.post)
    end

    expect { creator.create }.not_to change { Topic.with_deleted.count }
    expect(Post.with_deleted.where(user: member)).to be_empty
    expect(quota.usage(member)).to eq(0)
  end

  it "rolls publication back if durable usage cannot be saved" do
    quota.update_limit!(developer, member, limit: 1)
    allow(PluginStore).to receive(:set).and_return(false)

    expect { described_class.new(member, payload).create }.to raise_error(
      ActiveRecord::RecordNotSaved,
    )
    expect(Post.with_deleted.where(user: member)).to be_empty
    expect(Topic.with_deleted.where(user: member)).to be_empty
    expect(quota.usage(member)).to eq(0)
  end

  it "starts a fresh Shanghai Monday quota" do
    quota.update_limit!(developer, member, limit: 1)
    expect(described_class.new(member, payload).create).to be_persisted
    freeze_time Time.utc(2026, 10, 25, 16)

    expect(
      described_class.new(member, payload.merge(title: "A fresh week announcement")).create,
    ).to be_persisted
    expect(quota.snapshot(member)).to include(used: 1, remaining: 0)
  end
end
