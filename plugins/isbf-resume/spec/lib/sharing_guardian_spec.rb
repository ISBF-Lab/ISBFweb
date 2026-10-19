# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe Guardian do
  include_context "with resume review permissions"

  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:member, :user)
  fab!(:owner, :user)
  fab!(:pending) { Fabricate(:shared_isbf_resume, user: owner) }
  fab!(:approved, :approved_shared_isbf_resume)
  fab!(:rejected) { Fabricate(:rejected_shared_isbf_resume, user: owner) }

  describe "#can_submit_isbf_resume?" do
    it "requires active staff independently of the resume review switch" do
      suspended = Fabricate(:admin, suspended_at: 1.hour.ago, suspended_till: 1.day.from_now)
      silenced = Fabricate(:moderator, silenced_till: 1.day.from_now)

      expect(
        [
          developer.guardian,
          administrator.guardian,
          member.guardian,
          Guardian.new,
          suspended.guardian,
          silenced.guardian,
        ].map(&:can_submit_isbf_resume?),
      ).to eq([true, true, false, false, false, false])
      SiteSetting.isbf_resume_enabled = false
      expect(developer.guardian.can_submit_isbf_resume?).to eq(false)
    end
  end

  describe "#can_review_isbf_resumes?" do
    it "maps developers and administrators to the existing account roles and dedicated switch" do
      expect(
        [developer.guardian, administrator.guardian, member.guardian, Guardian.new].map(
          &:can_review_isbf_resumes?
        ),
      ).to eq([true, false, false, false])
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resources = true
      expect(administrator.guardian.can_review_isbf_resumes?).to eq(false)
      SiteSetting.academy_moderators_review_resumes = true
      expect(administrator.guardian.can_review_isbf_resumes?).to eq(true)
      expect(member.guardian.can_review_isbf_resumes?).to eq(false)
    end

    it "revokes an existing guardian immediately without disabling developer review" do
      guardian = administrator.guardian
      SiteSetting.academy_moderators_review_resumes = true
      expect(guardian.can_review_isbf_resumes?).to eq(true)
      SiteSetting.academy_moderators_review_resumes = false

      expect(guardian.can_review_isbf_resumes?).to eq(false)
      expect(developer.guardian.can_review_isbf_resumes?).to eq(true)
    end

    it "keeps active-account restrictions even for privileged reviewers" do
      developer.update!(silenced_till: 1.day.from_now)
      SiteSetting.academy_moderators_review_resumes = true
      administrator.update!(suspended_at: 1.hour.ago, suspended_till: 1.day.from_now)

      expect(developer.guardian.can_review_isbf_resumes?).to eq(false)
      expect(administrator.guardian.can_review_isbf_resumes?).to eq(false)
    end
  end

  describe "#can_view_shared_isbf_resume?" do
    it "shares only approved resumes with ordinary members while preserving owner and reviewer access" do
      expect(
        [approved, pending, rejected].map do |share|
          member.guardian.can_view_shared_isbf_resume?(share)
        end,
      ).to eq([true, false, false])
      expect(
        [pending, rejected].map { |share| owner.guardian.can_view_shared_isbf_resume?(share) },
      ).to eq([true, true])
      expect(
        [pending, rejected].map { |share| developer.guardian.can_view_shared_isbf_resume?(share) },
      ).to eq([true, true])
    end

    it "requires the resume capability for administrator access to private submissions" do
      expect(administrator.guardian.can_view_shared_isbf_resume?(pending)).to eq(false)
      SiteSetting.academy_moderators_review_resumes = true
      expect(administrator.guardian.can_view_shared_isbf_resume?(pending)).to eq(true)
      SiteSetting.academy_moderators_review_resumes = false

      expect(administrator.guardian.can_view_shared_isbf_resume?(pending)).to eq(false)
      expect(administrator.guardian.can_view_shared_isbf_resume?(approved)).to eq(true)
    end

    it "requires authentication and denies missing submissions" do
      expect(Guardian.new.can_view_shared_isbf_resume?(approved)).to eq(false)
      expect(member.guardian.can_view_shared_isbf_resume?(nil)).to be_falsey
    end

    it "allows an associated contributor to inspect their own private submission" do
      pending.update!(contributor_user_id: member.id)

      expect(member.guardian.can_view_shared_isbf_resume?(pending)).to eq(true)
      expect(member.guardian.can_view_shared_isbf_resume?(rejected)).to eq(false)
    end
  end
end
