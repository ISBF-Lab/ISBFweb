# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::OfficialPostQuotasController do
  fab!(:developer, :admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  let(:path) { "/academy-roles/admin/users/#{member.id}/official-post-quota.json" }

  describe "#show" do
    it "returns a read only snapshot to developers" do
      sign_in(developer)

      expect { get path }.not_to change {
        PluginStoreRow.where(plugin_name: DiscourseAcademyRoles::PLUGIN_NAME).count
      }

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("official_post_quota")).to include(
        "limit" => 0,
        "used" => 0,
        "remaining" => nil,
        "timezone" => "Asia/Shanghai",
        "official" => false,
        "exempt" => false,
      )
    end

    it "requires login" do
      get path

      expect(response.status).to eq(403)
    end

    it "rejects members and moderators even with all moderator permissions enabled" do
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      [member, moderator].each do |user|
        sign_in(user)
        get path
        expect(response.status).to eq(403)
      end
    end

    it "returns not found for an unknown target" do
      sign_in(developer)
      get "/academy-roles/admin/users/0/official-post-quota.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#update" do
    it "changes only the limit and returns the resulting snapshot" do
      sign_in(developer)
      quota = DiscourseAcademyRoles::OfficialPostQuota
      member.with_lock { quota.record_success!(member, used: 0) }

      put path, params: { limit: 2, used: 0, remaining: 99 }, as: :json

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("official_post_quota")).to include(
        "limit" => 2,
        "used" => 1,
        "remaining" => 1,
      )
      put path, params: { limit: 0 }, as: :json
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("official_post_quota")).to include(
        "limit" => 0,
        "used" => 1,
        "remaining" => nil,
      )
    end

    it "rejects malformed limits without persisting a value" do
      sign_in(developer)
      [nil, true, false, "2", 2.5, -1, 2_147_483_648].each do |invalid_limit|
        put path, params: { limit: invalid_limit }, as: :json
        expect(response.status).to eq(400)
      end
      put path, params: { used: 0 }, as: :json
      expect(response.status).to eq(400)
      expect(
        PluginStoreRow.exists?(
          plugin_name: DiscourseAcademyRoles::PLUGIN_NAME,
          key: "#{DiscourseAcademyRoles::OfficialPostQuota::STORE_KEY_PREFIX}:#{member.id}",
        ),
      ).to eq(false)
    end

    it "requires login" do
      put path, params: { limit: 1 }, as: :json

      expect(response.status).to eq(403)
    end

    it "rejects members and moderators with every management permission enabled" do
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      [member, moderator].each do |user|
        sign_in(user)
        put path, params: { limit: 1 }, as: :json
        expect(response.status).to eq(403)
      end

      expect(DiscourseAcademyRoles::OfficialPostQuota.snapshot(member)[:limit]).to eq(0)
    end

    it "keeps quota state outside ordinary profile updates and public profiles" do
      sign_in(member)
      quota = DiscourseAcademyRoles::OfficialPostQuota
      quota.update_limit!(developer, member, limit: 2)
      member.with_lock { quota.record_success!(member, used: 0) }
      limit_field = "academy_official_weekly_topic_limit"
      usage_field = "academy_official_weekly_topic_usage"
      put "/u/#{member.username}.json",
          params: {
            custom_fields: {
              limit_field => 100,
              usage_field => {
                week_starts_at: Time.current.iso8601,
                used: 0,
              },
            },
          },
          as: :json

      expect(response.status).to eq(200)
      expect(
        UserCustomField.where(user_id: member.id, name: [limit_field, usage_field]),
      ).to be_empty
      expect(quota.snapshot(member)).to include(limit: 2, used: 1, remaining: 1)

      get "/u/#{member.username}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user")).not_to have_key("official_post_quota")
      expect(response.body).not_to include(limit_field, usage_field)
    end
  end
end
