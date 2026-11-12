# frozen_string_literal: true

RSpec.describe IsbfProfileVisibility::GuardianExtension do
  fab!(:owner) { Fabricate(:user, trust_level: 2) }
  fab!(:viewer) { Fabricate(:user, trust_level: 2) }
  fab!(:moderator)
  fab!(:admin)

  before do
    SiteSetting.isbf_profile_visibility_enabled = true
    owner.user_stat.update!(post_count: 1)
  end

  def hide(*sections)
    sections.each { |section| owner.custom_fields[IsbfProfileVisibility::FIELDS[section]] = true }
    owner.save_custom_fields
    owner.reload
  end

  describe "#can_see_profile_section?" do
    it "allows every section while nothing is hidden" do
      IsbfProfileVisibility::SECTIONS.each do |section|
        expect(Guardian.new.can_see_profile_section?(owner, section)).to eq(true)
        expect(Guardian.new(viewer).can_see_profile_section?(owner, section)).to eq(true)
      end
    end

    it "hides only the chosen section from anonymous and regular viewers" do
      hide(:summary)

      [Guardian.new, Guardian.new(viewer)].each do |guardian|
        expect(guardian.can_see_profile_section?(owner, :summary)).to eq(false)
        expect(guardian.can_see_profile_section?(owner, :bio)).to eq(true)
        expect(guardian.can_see_profile_section?(owner, :activity)).to eq(true)
        expect(guardian.can_see_profile?(owner)).to eq(true)
      end
    end

    it "reads the owner's choice when another loader preloaded only its own fields" do
      hide(:activity)
      User.preload_custom_fields([owner], [])
      expect(owner.custom_field_preloaded?(IsbfProfileVisibility::FIELDS[:activity])).to eq(true)

      owner.set_preloaded_custom_fields({ "unrelated" => nil })

      expect(Guardian.new(viewer).can_see_profile_section?(owner, :activity)).to eq(false)
      expect(Guardian.new(viewer).can_see_profile_section?(owner, :bio)).to eq(true)
      expect(owner.custom_fields["unrelated"]).to be_nil
    end

    it "keeps hidden sections visible to the owner and to staff" do
      hide(:bio, :summary, :activity)

      [owner, moderator, admin].each do |privileged|
        IsbfProfileVisibility::SECTIONS.each do |section|
          expect(Guardian.new(privileged).can_see_profile_section?(owner, section)).to eq(true)
        end
      end
    end

    it "hides every section when the whole profile is hidden" do
      owner.user_option.update!(hide_profile: true)

      IsbfProfileVisibility::SECTIONS.each do |section|
        expect(Guardian.new(viewer).can_see_profile_section?(owner, section)).to eq(false)
      end
    end

    it "ignores section choices when profile hiding is disallowed or the plugin is off" do
      hide(:activity)

      SiteSetting.allow_users_to_hide_profile = false
      expect(Guardian.new(viewer).can_see_profile_section?(owner, :activity)).to eq(true)

      SiteSetting.allow_users_to_hide_profile = true
      SiteSetting.isbf_profile_visibility_enabled = false
      expect(Guardian.new(viewer).can_see_profile_section?(owner, :activity)).to eq(true)
    end
  end

  describe "#restrict_user_fields?" do
    it "restricts a hidden bio for other users only" do
      hide(:bio)

      expect(Guardian.new(viewer).restrict_user_fields?(owner)).to eq(true)
      expect(Guardian.new(owner).restrict_user_fields?(owner)).to eq(false)
      expect(Guardian.new(moderator).restrict_user_fields?(owner)).to eq(false)
    end

    it "does not restrict fields when another section is hidden" do
      hide(:summary, :activity)

      expect(Guardian.new(viewer).restrict_user_fields?(owner)).to eq(false)
    end
  end

  describe "#can_see_user_actions?" do
    it "is false for other users when the activity section is hidden" do
      hide(:activity)

      expect(Guardian.new.can_see_user_actions?(owner, [])).to eq(false)
      expect(Guardian.new(viewer).can_see_user_actions?(owner, [])).to eq(false)
    end

    it "stays true for the owner and staff when the activity section is hidden" do
      hide(:activity)

      expect(Guardian.new(owner).can_see_user_actions?(owner, [])).to eq(true)
      expect(Guardian.new(moderator).can_see_user_actions?(owner, [])).to eq(true)
      expect(Guardian.new(admin).can_see_user_actions?(owner, [])).to eq(true)
    end

    it "is false for other users when the whole profile is hidden" do
      owner.user_option.update!(hide_profile: true)

      expect(Guardian.new(viewer).can_see_user_actions?(owner, [])).to eq(false)
    end

    it "still accepts a missing user" do
      expect(Guardian.new.can_see_user_actions?(nil)).to eq(true)
    end
  end
end
