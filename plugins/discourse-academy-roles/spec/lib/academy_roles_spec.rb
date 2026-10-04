# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles do
  fab!(:admin)
  fab!(:moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  it "reserves invitation issuance and official certification for site admins" do
    expect(Guardian.new(admin).can_invite_to_forum?).to eq(true)
    expect(Guardian.new(moderator).can_invite_to_forum?).to eq(false)
    expect(Guardian.new(admin).can_edit_group?(official_group)).to eq(true)
    expect(Guardian.new(moderator).can_edit_group?(official_group)).to eq(false)
  end

  it "locks a new member's internal trust independently of activity" do
    member = Fabricate(:user, refresh_auto_groups: true)

    expect(member.reload.trust_level).to eq(0)
    expect(member.manual_locked_trust_level).to eq(0)
    expect(member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(0)
  end

  it "retains an existing member's activity while fixing internal trust" do
    member = Fabricate(:user, refresh_auto_groups: true)
    member.update_columns(trust_level: 3, manual_locked_trust_level: nil)
    member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = 4
    member.save_custom_fields

    DiscourseAcademyRoles.lock_member_trust_level(member)

    expect(member.reload.trust_level).to eq(0)
    expect(member.manual_locked_trust_level).to eq(0)
    expect(member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(4)
  end

  it "requires single-use invitation codes without an email binding" do
    reusable = Fabricate.build(:invite, invited_by: admin, email: nil, max_redemptions_allowed: 2)
    bound_to_email = Fabricate.build(:invite, invited_by: admin, max_redemptions_allowed: 1)
    bound_to_domain = Fabricate.build(:invite, invited_by: admin, email: nil, domain: "example.edu")

    expect(reusable).not_to be_valid
    expect(bound_to_email).not_to be_valid
    expect(bound_to_domain).not_to be_valid
  end

  it "requires an official category and group before activation" do
    validator = AcademyRolesEnabledValidator.new
    expect(validator.valid_value?(true)).to eq(true)

    SiteSetting.academy_official_category = ""
    expect(validator.valid_value?(true)).to eq(false)
  end

  it "keeps an official post marked after its author loses certification" do
    member = Fabricate(:user, refresh_auto_groups: true)
    official_group.add(member)
    topic = Fabricate(:topic, user: member, category: official_category)
    post = Fabricate(:post, user: member, topic: topic)
    post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
    post.save_custom_fields
    official_group.remove(member)

    expect(Guardian.new(member).can_edit_post?(post)).to eq(false)
    expect(post.reload.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD]).to eq(true)
  end

  it "prevents moving an official topic into an ordinary category" do
    member = Fabricate(:user, refresh_auto_groups: true)
    official_group.add(member)
    topic = Fabricate(:topic, user: member, category: official_category)
    post = Fabricate(:post, user: member, topic: topic)
    post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD] = true
    post.save_custom_fields
    ordinary_category = Fabricate(:category)

    expect(topic.change_category_to_id(ordinary_category.id)).to eq(false)
    expect(topic.reload.category_id).to eq(official_category.id)
  end

  it "does not let activity or ordinary membership grant editing another member's post" do
    member = Fabricate(:user, refresh_auto_groups: true)
    other_member = Fabricate(:user, refresh_auto_groups: true)
    post = Fabricate(:post, user: other_member)
    SiteSetting.edit_all_topic_groups = "1|2"
    SiteSetting.edit_all_post_groups = "1|2"
    member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = 4
    member.save_custom_fields

    expect(Guardian.new(member).can_edit_post?(post)).to eq(false)
    expect(Guardian.new(member).can_edit_topic?(post.topic)).to eq(false)
  end

  it "awards activity LV4 after 90 qualifying days without changing trust" do
    %i[
      tl3_requires_days_visited
      tl3_requires_topics_replied_to
      tl3_requires_topics_viewed
      tl3_requires_topics_viewed_cap
      tl3_requires_posts_read
      tl3_requires_posts_read_cap
      tl3_requires_topics_viewed_all_time
      tl3_requires_posts_read_all_time
      tl3_requires_likes_given
      tl3_requires_likes_received
    ].each { |setting| SiteSetting.public_send("#{setting}=", 0) }

    member = Fabricate(:user, refresh_auto_groups: true)
    member.custom_fields[DiscourseAcademyRoles::LV3_SINCE_FIELD] = 89.days.ago.iso8601
    member.custom_fields[DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD] = 1.day.ago.iso8601
    member.save_custom_fields

    DiscourseAcademyRoles::ActivityLevel.update(member)
    expect(member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(3)

    DiscourseAcademyRoles::ActivityLevel.update(member, now: 1.day.from_now)
    expect(member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(4)
    expect(member.reload.trust_level).to eq(0)

    DiscourseAcademyRoles::ActivityLevel.update(member, now: 3.days.from_now)
    expect(member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD]).to eq(3)
  end
end
