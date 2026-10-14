# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ModeratorPermissions do
  fab!(:developer, :admin)
  fab!(:moderator) do
    Fabricate(:moderator, trust_level: 0, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) { Fabricate(:user, trust_level: 0, refresh_auto_groups: true) }
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:activity_category, :category)
  fab!(:internal_category, :category)
  fab!(:resource_category, :category)
  fab!(:discussion, :topic_with_op)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_activity_category = activity_category.id
    SiteSetting.isbf_learning_category_id = resource_category.id
    SiteSetting.academy_roles_enabled = true
    official_category.set_permissions(everyone: :create_post, staff: :full)
    activity_category.set_permissions(everyone: :create_post, staff: :full)
    internal_category.set_permissions(staff: :full)
    resource_category.set_permissions(trust_level_0: :readonly, staff: :full, moderators: :readonly)
    [official_category, activity_category, internal_category, resource_category].each(&:save!)
  end

  describe ".for" do
    it "starts with all 21 capabilities disabled and retains the persisted role" do
      expect(described_class.for(moderator).values).to eq([false] * 21)
      expect(moderator.reload[:moderator]).to eq(true)
      expect(moderator.groups.pluck(:id)).to include(
        Group::AUTO_GROUPS[:moderators],
        Group::AUTO_GROUPS[:staff],
      )
      expect(moderator.staff?).to eq(false)
      expect(moderator.has_trust_level?(TrustLevel[4])).to eq(false)
      expect(moderator.has_trust_level_or_staff?("staff")).to eq(false)
      expect(moderator.has_trust_level_or_staff?("admin")).to eq(false)
    end

    it "grants each setting only its own capability and revokes it immediately" do
      described_class::SETTINGS.each do |permission, setting|
        SiteSetting.public_send("#{setting}=", true)
        expect(described_class.for(moderator).select { |_, allowed| allowed }.keys).to eq(
          [permission],
        )
        SiteSetting.public_send("#{setting}=", false)
        expect(described_class.allowed?(moderator, permission)).to eq(false)
      end
    end

    it "retains the stored role memberships when automatic groups are refreshed" do
      before_ids = moderator.groups.pluck(:id)
      Group.refresh_automatic_groups_for_user!(moderator)
      expect(moderator.groups.pluck(:id)).to match_array(before_ids)
      expect(moderator.reload[:moderator]).to eq(true)
      expect(moderator.staff?).to eq(false)
    end

    it "keeps developers unrestricted and never grants capabilities to ordinary or anonymous users" do
      developer.update!(moderator: true)
      expect(described_class.for(developer).values).to eq([true] * 21)
      described_class::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      expect(described_class.for(member).values).to eq([false] * 21)
      expect(described_class.for(nil).values).to eq([false] * 21)
      expect(moderator.guardian.can_invite_to_forum?).to eq(false)
      expect(moderator.guardian.can_administer_user?(member)).to eq(false)
    end
  end

  describe "category access" do
    it "removes automatic staff access and publishing grants without changing ordinary browsing" do
      guardian = moderator.guardian
      expect(guardian.can_see_category?(internal_category)).to eq(false)
      expect(guardian.can_see_category?(resource_category)).to eq(true)
      expect(guardian.can_create_topic_on_category?(activity_category)).to eq(false)
      expect(guardian.can_create_topic_on_category?(official_category)).to eq(false)
      expect(guardian.can_create_topic_on_category?(resource_category)).to eq(false)
      expect(Category.secured(guardian).where(id: internal_category.id).exists?).to eq(false)
    end

    it "grants internal access without granting activity, official or resource publishing" do
      guardian = moderator.guardian
      expect(guardian.can_see_category?(internal_category)).to eq(false)
      SiteSetting.academy_moderators_access_internal_boards = true
      expect(guardian.can_see_category?(internal_category)).to eq(true)
      expect(
        Category
          .topic_create_allowed(guardian)
          .where(id: [activity_category.id, official_category.id, resource_category.id])
          .pluck(:id),
      ).to be_empty
      SiteSetting.academy_moderators_access_internal_boards = false
      expect(guardian.can_see_category?(internal_category)).to eq(false)
    end

    it "grants only the selected business category for publishing" do
      guardian = moderator.guardian
      {
        publish_activities: activity_category,
        publish_official: official_category,
        manage_resources: resource_category,
      }.each do |permission, category|
        setting = described_class::SETTINGS.fetch(permission)
        SiteSetting.public_send("#{setting}=", true)
        expect(
          Category
            .topic_create_allowed(guardian)
            .where(id: [activity_category.id, official_category.id, resource_category.id])
            .pluck(:id),
        ).to eq([category.id])
        expect(guardian.can_create_topic_on_category?(category)).to eq(true)
        SiteSetting.public_send("#{setting}=", false)
        expect(guardian.can_create_topic_on_category?(category)).to eq(false)
      end
    end

    it "does not expose management group messages until internal access is enabled" do
      topic = Fabricate(:private_message_topic, user: developer)
      topic.allowed_groups << Group.find(Group::AUTO_GROUPS[:moderators])
      guardian = moderator.guardian
      expect(guardian.can_see_topic?(topic)).to eq(false)
      expect(Topic.private_messages_for_user(moderator)).not_to include(topic)
      SiteSetting.academy_moderators_access_internal_boards = true
      expect(guardian.can_see_topic?(topic)).to eq(true)
      expect(Topic.private_messages_for_user(moderator)).to include(topic)
      SiteSetting.academy_moderators_access_internal_boards = false
      expect(guardian.visible_topic_scope(Topic.where(id: topic.id))).to be_empty
      expect(Topic.private_messages_for_user(moderator)).not_to include(topic)
    end

    it "revokes post visibility on an existing Guardian without retaining its cached category grant" do
      post = Fabricate(:post, topic: Fabricate(:topic, category: internal_category))
      guardian = moderator.guardian
      SiteSetting.academy_moderators_access_internal_boards = true
      expect(guardian.can_see_post?(post)).to eq(true)
      SiteSetting.academy_moderators_access_internal_boards = false
      expect(guardian.can_see_post?(post)).to eq(false)
      expect(guardian.visible_topic_scope(Topic.where(id: post.topic_id))).to be_empty
    end
  end

  describe "content actions" do
    it "preserves ordinary own-post editing while independently gating other content" do
      own_post = Fabricate(:post, user: moderator)
      guardian = moderator.guardian
      expect(guardian.can_edit_post?(own_post)).to eq(true)
      expect(guardian.can_edit_post?(discussion.first_post)).to eq(false)
      expect(guardian.can_delete_topic?(discussion)).to eq(false)
      expect(guardian.can_moderate_topic?(discussion)).to eq(false)
      SiteSetting.academy_moderators_edit_others_content = true
      expect(guardian.can_edit_post?(discussion.first_post)).to eq(true)
      expect(guardian.can_moderate_topic?(discussion)).to eq(false)
      SiteSetting.academy_moderators_edit_others_content = false
      SiteSetting.academy_moderators_manage_topics = true
      expect(guardian.can_moderate_topic?(discussion)).to eq(true)
      deleted_reply = Fabricate(:post, topic: discussion, deleted_at: Time.current)
      expect(guardian.can_recover_post?(deleted_reply)).to eq(false)
      %i[
        can_close_topic?
        can_open_topic?
        can_archive_topic?
        can_pin_unpin_topic?
        can_split_merge_topic?
      ].each { |action| expect(guardian.public_send(action, discussion)).to eq(true) }
      expect(guardian.can_edit_post?(discussion.first_post)).to eq(false)
      SiteSetting.academy_moderators_manage_topics = false
      expect(guardian.can_close_topic?(discussion)).to eq(false)
      SiteSetting.academy_moderators_delete_others_content = true
      expect(guardian.can_delete_topic?(discussion)).to eq(true)
      expect(guardian.can_recover_post?(deleted_reply)).to eq(true)
      SiteSetting.academy_moderators_delete_others_content = false
      expect(guardian.can_delete_topic?(discussion)).to eq(false)
    end

    it "requires hidden access even when content editing or deletion is enabled" do
      discussion.first_post.update!(hidden: true)
      guardian = moderator.guardian
      SiteSetting.academy_moderators_edit_others_content = true
      SiteSetting.academy_moderators_delete_others_content = true
      expect(guardian.can_see_post?(discussion.first_post)).to eq(false)
      expect(guardian.can_edit_post?(discussion.first_post)).to eq(false)
      SiteSetting.academy_moderators_view_hidden_content = true
      expect(guardian.can_see_post?(discussion.first_post)).to eq(true)
      expect(guardian.can_edit_post?(discussion.first_post)).to eq(true)
    end

    it "requires resource management independently of ordinary content permissions" do
      resource = Fabricate(:topic_with_op, category: resource_category)
      SiteSetting.academy_moderators_edit_others_content = true
      SiteSetting.academy_moderators_delete_others_content = true
      SiteSetting.academy_moderators_manage_topics = true
      guardian = moderator.guardian
      expect(guardian.can_edit_post?(resource.first_post)).to eq(false)
      expect(guardian.can_delete_topic?(resource)).to eq(false)
      SiteSetting.academy_moderators_manage_resources = true
      expect(guardian.can_edit_post?(resource.first_post)).to eq(true)
      expect(guardian.can_delete_topic?(resource)).to eq(true)
    end
  end

  describe "account actions" do
    it "retains management account protections and permits developers to revoke the stored role" do
      member.update!(trust_level: 4)
      SiteSetting.allow_flagging_staff = false
      SiteSetting.ignore_allowed_groups = "14"
      post = Fabricate(:post, user: moderator)
      expect(member.guardian.can_mute_user?(moderator)).to eq(false)
      expect(member.guardian.can_ignore_user?(moderator)).to eq(false)
      expect(member.guardian.post_can_act?(post, :spam)).to eq(false)
      expect(developer.guardian.can_anonymize_user?(moderator)).to eq(false)
      expect(developer.guardian.can_merge_user?(moderator)).to eq(false)
      expect(developer.guardian.can_revoke_moderation?(moderator)).to eq(true)
      expect(developer.guardian.can_grant_moderation?(moderator)).to eq(false)
    end

    it "independently gates account actions and protects management accounts" do
      actions = {
        edit_users: :can_edit_user?,
        suspend_users: :can_suspend?,
        silence_users: :can_silence_user?,
        delete_users: :can_delete_user?,
        anonymize_users: :can_anonymize_user?,
      }
      guardian = moderator.guardian
      actions.each do |permission, action|
        expect(guardian.public_send(action, member)).to eq(false)
        SiteSetting.public_send("#{described_class::SETTINGS.fetch(permission)}=", true)
        expect(guardian.public_send(action, member)).to eq(true)
        expect(guardian.public_send(action, developer)).to eq(false)
        SiteSetting.public_send("#{described_class::SETTINGS.fetch(permission)}=", false)
        expect(guardian.public_send(action, member)).to eq(false)
      end
    end

    it "independently gates categories, certification memberships and email access" do
      guardian = moderator.guardian
      expect(guardian.can_edit_category?(activity_category)).to eq(false)
      expect(guardian.can_edit_group?(official_group)).to eq(false)
      expect(guardian.can_see_emails?).to eq(false)
      SiteSetting.moderators_manage_categories = true
      expect(guardian.can_edit_category?(activity_category)).to eq(true)
      expect(guardian.can_edit_group?(official_group)).to eq(false)
      SiteSetting.moderators_manage_groups = true
      expect(guardian.can_edit_group?(official_group)).to eq(true)
      private_group =
        Fabricate(
          :group,
          visibility_level: Group.visibility_levels[:staff],
          members_visibility_level: Group.visibility_levels[:staff],
        )
      expect(guardian.can_admin_group?(private_group)).to eq(true)
      expect(guardian.can_see_group_members?(private_group)).to eq(true)
      expect(Group.visible_groups(moderator)).to include(private_group)
      expect(guardian.can_edit_group?(Group.find(Group::AUTO_GROUPS[:admins]))).to eq(false)
      SiteSetting.moderators_view_emails = true
      expect(guardian.can_see_emails?).to eq(true)
      expect(guardian.can_see_ip?).to eq(false)
    end
  end

  describe "review actions" do
    it "reviews published posts in the native review-every-post queue" do
      reviewable =
        ReviewablePost.needs_review!(
          target: discussion.first_post,
          created_by: member,
          reviewable_by_moderator: true,
        )
      SiteSetting.academy_moderators_review_content = true

      expect(Reviewable.viewable_by(moderator)).to include(reviewable)
      expect(reviewable.perform(moderator, :approve).success?).to eq(true)
    end

    it "keeps protected accounts outside the account approval queue" do
      developer.update!(approved: false)
      reviewable = Fabricate(:suspect_user_reviewable, target: developer)
      described_class::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end

      expect(Reviewable.viewable_by(moderator)).not_to include(reviewable)
      expect { reviewable.perform(moderator, :approve_user) }.to raise_error(
        Discourse::InvalidAccess,
      )
      expect(developer.reload.approved?).to eq(false)
    end

    it "reveals emails in ordinary account reviews only with the email switch" do
      reviewable = Fabricate(:suspect_user_reviewable, target: member)
      SiteSetting.academy_moderators_review_content = true
      body =
        ReviewableUserSerializer.new(reviewable, scope: moderator.guardian, root: false).to_json
      expect(body).not_to include(member.email)

      SiteSetting.moderators_view_emails = true
      body =
        ReviewableUserSerializer.new(reviewable, scope: moderator.guardian, root: false).to_json
      expect(body).to include(member.email)
    end

    it "offers a silence action without requiring suspension permission" do
      reviewable =
        ReviewableFlaggedPost.needs_review!(
          target: discussion.first_post,
          created_by: member,
          target_created_by: discussion.user,
          reviewable_by_moderator: true,
        )
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_silence_users = true

      actions = reviewable.actions_for(moderator.guardian)
      expect(actions.has?(:agree_and_silence)).to eq(true)
      expect(actions.has?(:agree_and_suspend)).to eq(false)
    end

    it "does not let a stored moderator use category moderation to bypass the silence switch" do
      group = Fabricate(:group)
      group.add(moderator)
      SiteSetting.enable_category_group_moderation = true
      Fabricate(:category_moderation_group, category: discussion.category, group: group)
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_view_hidden_content = true
      expect(moderator.guardian.is_category_group_moderator?(discussion.category)).to eq(false)
      reviewable =
        ReviewableFlaggedPost.needs_review!(
          target: discussion.first_post,
          created_by: member,
          target_created_by: discussion.user,
          reviewable_by_moderator: true,
        )
      reviewable.post.update!(hidden: true, hidden_at: Time.current)
      UserSilencer.silence(discussion.user, developer, post_id: discussion.first_post.id)
      expect(reviewable.perform(moderator, :disagree_and_restore).success?).to eq(true)
      expect(discussion.first_post.reload.hidden?).to eq(false)
      expect(discussion.user.reload.silenced?).to eq(true)
    end

    it "approves a queued post without automatically lifting a penalty unless silence permission is enabled" do
      member.update!(silenced_till: 1.day.from_now)
      SiteSetting.academy_moderators_review_content = true
      topic = Fabricate(:topic)
      queued = Fabricate(:reviewable_queued_post, topic: topic, target_created_by: member)
      expect(queued.perform(moderator, :approve_post).success?).to eq(true)
      expect(member.reload.silenced?).to eq(true)
      SiteSetting.academy_moderators_silence_users = true
      another = Fabricate(:reviewable_queued_post, topic: topic, target_created_by: member)
      expect(another.perform(moderator, :approve_post).success?).to eq(true)
      expect(member.reload.silenced?).to eq(false)
    end

    it "requires all permissions for a composite penalty action and prevents alias bypass" do
      reviewable =
        ReviewableFlaggedPost.needs_review!(
          target: discussion.first_post,
          created_by: member,
          target_created_by: discussion.user,
          reviewable_by_moderator: true,
        )
      SiteSetting.academy_moderators_review_content = true
      expect(Reviewable.viewable_by(moderator)).to include(reviewable)
      expect(reviewable.actions_for(moderator.guardian).has?(:agree_and_suspend)).to eq(false)
      expect { reviewable.perform(moderator, :agree_and_suspend) }.to raise_error(
        Discourse::InvalidAccess,
      )
      expect(discussion.user.reload.suspended?).to eq(false)
      SiteSetting.academy_moderators_suspend_users = true
      expect(reviewable.actions_for(moderator.guardian).has?(:agree_and_suspend)).to eq(true)
      SiteSetting.academy_moderators_review_content = false
      expect(Reviewable.viewable_by(moderator)).to be_empty
    end

    it "keeps the learning queue separate from the ordinary review switch" do
      queued =
        Fabricate(
          :reviewable_queued_post,
          topic: nil,
          target_created_by: member,
          category_id: resource_category.id,
          payload: {
            "raw" => "Course notes",
            "title" => "Learning resource",
            "isbf_learning_course_id" => "pending-course",
          },
          reviewable_by_moderator: false,
        )
      SiteSetting.academy_moderators_review_content = true
      expect(Reviewable.viewable_by(moderator)).not_to include(queued)
      SiteSetting.academy_moderators_review_content = false
      SiteSetting.academy_moderators_review_resources = true
      expect(Reviewable.viewable_by(moderator)).to include(queued)
      expect(queued.actions_for(moderator.guardian).has?(:approve_post)).to eq(true)
      expect(queued.editable_for(moderator.guardian).to_a).to be_empty
    end
  end
end
