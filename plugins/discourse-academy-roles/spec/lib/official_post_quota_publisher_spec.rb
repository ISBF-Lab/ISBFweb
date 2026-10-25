# frozen_string_literal: true

RSpec.describe TopicPublisher do
  fab!(:developer, :admin)
  fab!(:author, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:draft_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.shared_drafts_category = draft_category.id
    official_group.add(author)
    freeze_time Time.utc(2026, 10, 25, 4)
  end

  let(:quota) { DiscourseAcademyRoles::OfficialPostQuota }
  let(:draft_post) do
    post = Fabricate(:post, user: author, topic: Fabricate(:topic, user: author, category: draft_category))
    post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
    post.save_custom_fields
    SharedDraft.create!(topic: post.topic, category: official_category)
    post
  end

  it "charges shared drafts only when actually published and never twice" do
    topic = draft_post.topic
    quota.update_limit!(developer, author, limit: 1)
    expect(quota.usage(author)).to eq(0)
    described_class.new(topic, developer, official_category.id).publish!
    expect(quota.usage(author)).to eq(1)
    expect(topic.reload.category_id).to eq(official_category.id)
    expect(SharedDraft.where(topic: topic)).to be_empty
    described_class.new(topic.reload, developer, official_category.id).publish!
    expect(quota.usage(author)).to eq(1)
    expect(DiscourseAcademyRoles::OfficialPostQuotaPublication.topic_id).to be_nil
  end

  it "retains the draft and timestamps when its author has exhausted quota" do
    topic = draft_post.topic
    quota.update_limit!(developer, author, limit: 1)
    author.with_lock { quota.record_success!(author, used: 0) }
    topic_time = topic.created_at
    post_time = draft_post.created_at
    freeze_time 1.minute.from_now

    expect { described_class.new(topic, developer, official_category.id).publish! }.to raise_error(Discourse::InvalidAccess)
    expect(topic.reload.category_id).to eq(draft_category.id)
    expect(topic.created_at).to eq(topic_time)
    expect(draft_post.reload.created_at).to eq(post_time)
    expect(SharedDraft.exists?(topic: topic)).to eq(true)
    expect(quota.usage(author)).to eq(1)
    expect(DiscourseAcademyRoles::OfficialPostQuotaPublication.topic_id).to be_nil
  end
end
