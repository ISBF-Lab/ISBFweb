# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::NameColor do
  fab!(:developer, :admin)
  fab!(:other_developer, :admin)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    described_class::Cache.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.avatar_frames_enabled = false if SiteSetting.respond_to?(:avatar_frames_enabled)
  end

  describe ".effective_color" do
    it "defaults to normal text and follows the role feature switch" do
      expect(described_class.effective_color(developer)).to be_nil
      developer.custom_fields[described_class::ENABLED_FIELD] = true
      developer.save!
      expect(described_class.effective_color(developer)).to eq("theme")

      SiteSetting.academy_roles_enabled = false
      expect(described_class.effective_color(developer)).to be_nil
    end

    it "suppresses colors for shadow identities" do
      developer.custom_fields[described_class::ENABLED_FIELD] = true
      developer.save!
      AnonymousUser.create!(master_user: other_developer, user: developer, active: true)
      described_class::Cache.reset

      expect(described_class.effective_color(developer)).to be_nil
    end

    if defined?(IsbfAnonymous::PoolAccount)
      it "suppresses colors for pooled anonymous identities" do
        developer.custom_fields[described_class::ENABLED_FIELD] = true
        developer.save!
        IsbfAnonymous::PoolAccount.create!(user: developer, slot: 999)
        described_class::Cache.reset

        expect(described_class.effective_color(developer)).to be_nil
      end
    end
  end

  describe "UserLookup" do
    it "sideloads author appearances with a constant number of queries" do
      [developer, other_developer].each do |user|
        user.custom_fields[described_class::ENABLED_FIELD] = true
        user.save!
      end
      serialize = ->(ids) do
        lookup = UserLookup.new(ids)
        ids.map do |id|
          BasicUserSerializer.new(lookup[id], scope: Guardian.new, root: false).as_json
        end
      end
      described_class::Cache.reset
      one = track_sql_queries { serialize.call([developer.id]) }
      described_class::Cache.reset
      two = track_sql_queries { serialize.call([developer.id, other_developer.id]) }

      expect(two.size).to eq(one.size)
      expect(
        serialize
          .call([developer.id, other_developer.id])
          .map { |json| json[:academy_display_name_color] },
      ).to eq(%w[theme theme])
    end
  end
end
