# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ModeratorPermissions do
  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  it "scopes the native queue to alumni reviews and revokes access immediately" do
    RSpec::Mocks::ExampleMethods.instance_method(:stub_const).bind_call(
      self,
      "ReviewableIsbfAlumni",
      Class.new(Reviewable),
    )
    alumni = Fabricate(:reviewable_queued_post, topic: nil, category_id: nil)
    alumni.update_columns(type: "ReviewableIsbfAlumni", reviewable_by_moderator: true)
    ordinary = Fabricate(:reviewable_queued_post, category_id: nil)
    visible_ids = -> { Reviewable.viewable_by(administrator, preload: false).pluck(:id) }
    expect(visible_ids.call).not_to include(alumni.id)
    SiteSetting.academy_moderators_review_alumni = true
    expect(visible_ids.call).to include(alumni.id)
    expect(visible_ids.call).not_to include(ordinary.id)
    SiteSetting.academy_moderators_review_alumni = false
    expect(visible_ids.call).not_to include(alumni.id)
  end

  describe ".allowed?" do
    it "blocks suspended and silenced administrators without granting general email access" do
      SiteSetting.academy_moderators_review_alumni = true
      expect(administrator.guardian.can_see_review_queue?).to eq(true)
      expect(administrator.guardian.can_see_emails?).to eq(false)
      administrator.update!(suspended_till: 1.day.from_now)
      expect(described_class.allowed?(administrator, :review_alumni)).to eq(false)
      administrator.update!(suspended_till: nil, silenced_till: 1.day.from_now)
      expect(described_class.allowed?(administrator, :review_alumni)).to eq(false)
    end

    it "uses the alumni capability for approval and rejection without account-edit privileges" do
      reviewable =
        double(
          type: "ReviewableIsbfAlumni",
          category_id: nil,
          target_created_by: nil,
          target_type: "IsbfAlumni::Application",
        )
      expect(described_class.review_permission(reviewable)).to eq(:review_alumni)
      expect(described_class.review_edit_permission(reviewable)).to eq(:review_alumni)
      expect(described_class.review_action_allowed?(administrator, reviewable, :approve)).to eq(
        false,
      )
      SiteSetting.academy_moderators_review_alumni = true
      expect(described_class.review_action_allowed?(administrator, reviewable, :approve)).to eq(
        true,
      )
      expect(described_class.review_action_allowed?(administrator, reviewable, :reject)).to eq(true)
      expect(described_class.allowed?(administrator, :edit_users)).to eq(false)
      expect(described_class.allowed?(administrator, :view_emails)).to eq(false)
      SiteSetting.academy_moderators_review_alumni = false
      expect(administrator.guardian.can_see_review_queue?).to eq(false)
    end

    it "defines a dedicated alumni-review capability disabled by default" do
      expect(described_class::SETTINGS.fetch(:review_alumni)).to eq(
        :academy_moderators_review_alumni,
      )
      expect(SiteSetting.academy_moderators_review_alumni).to eq(false)
      expect(described_class.allowed?(developer, :review_alumni)).to eq(true)
      expect(described_class.allowed?(administrator, :review_alumni)).to eq(false)
    end

    it "keeps alumni review independent of ordinary content review and resource review" do
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resources = true
      expect(described_class.allowed?(administrator, :review_alumni)).to eq(false)
      SiteSetting.academy_moderators_review_alumni = true

      expect(described_class.allowed?(administrator, :review_alumni)).to eq(true)
      expect(described_class.allowed?(member, :review_alumni)).to eq(false)
      expect(described_class.allowed?(nil, :review_alumni)).to eq(false)
    end

    it "reflects switch revocation without requiring the administrator to sign in again" do
      SiteSetting.academy_moderators_review_alumni = true
      expect(described_class.for(administrator).fetch(:review_alumni)).to eq(true)
      SiteSetting.academy_moderators_review_alumni = false

      expect(described_class.for(administrator).fetch(:review_alumni)).to eq(false)
      expect(described_class.for(developer).fetch(:review_alumni)).to eq(true)
    end
  end
end
