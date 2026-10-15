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

  describe ".allowed?" do
    it "defines a dedicated resume-review capability disabled by default" do
      expect(described_class::SETTINGS.fetch(:review_resumes)).to eq(
        :academy_moderators_review_resumes,
      )
      expect(SiteSetting.academy_moderators_review_resumes).to eq(false)
      expect(described_class.allowed?(developer, :review_resumes)).to eq(true)
      expect(described_class.allowed?(administrator, :review_resumes)).to eq(false)
    end

    it "keeps resume review independent of ordinary content review and resource review" do
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resources = true
      expect(described_class.allowed?(administrator, :review_resumes)).to eq(false)
      SiteSetting.academy_moderators_review_resumes = true

      expect(described_class.allowed?(administrator, :review_resumes)).to eq(true)
      expect(described_class.allowed?(member, :review_resumes)).to eq(false)
      expect(described_class.allowed?(nil, :review_resumes)).to eq(false)
    end

    it "reflects switch revocation without requiring the administrator to sign in again" do
      SiteSetting.academy_moderators_review_resumes = true
      expect(described_class.for(administrator).fetch(:review_resumes)).to eq(true)
      SiteSetting.academy_moderators_review_resumes = false

      expect(described_class.for(administrator).fetch(:review_resumes)).to eq(false)
      expect(described_class.for(developer).fetch(:review_resumes)).to eq(true)
    end
  end
end
