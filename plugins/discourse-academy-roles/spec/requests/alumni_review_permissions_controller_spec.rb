# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::ModeratorPermissionsController do
  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#index" do
    it "returns the alumni-review switch to developers in the existing permission interface" do
      sign_in(developer)

      get "/academy-roles/admin/moderator-permissions.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("settings")).to include(
        "review_alumni" => "academy_moderators_review_alumni",
      )
      expect(response.parsed_body.fetch("values")).to include(
        "academy_moderators_review_alumni" => false,
      )
    end

    it "keeps the switch configuration developer-only even when administrator review is allowed" do
      SiteSetting.academy_moderators_review_alumni = true
      sign_in(administrator)

      get "/academy-roles/admin/moderator-permissions.json"

      expect(response.status).to eq(403)
    end
  end
end

RSpec.describe Admin::SiteSettingsController do
  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#bulk_update" do
    it "lets developers toggle alumni review and retains a staff-history record" do
      sign_in(developer)

      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_alumni: {
                value: true,
              },
            },
          }

      expect(response.status).to eq(204)
      expect(SiteSetting.academy_moderators_review_alumni).to eq(true)
      expect(SiteSetting.academy_moderators_review_content).to eq(false)
      expect(
        UserHistory.where(
          acting_user_id: developer.id,
          subject: "academy_moderators_review_alumni",
        ).count,
      ).to eq(1)
      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_alumni: {
                value: false,
              },
            },
          }
      expect(response.status).to eq(204)
      expect(SiteSetting.academy_moderators_review_alumni).to eq(false)
    end

    it "rejects administrator attempts to toggle their own alumni-review permission" do
      SiteSetting.academy_moderators_review_alumni = true
      sign_in(administrator)

      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_alumni: {
                value: false,
              },
            },
          }

      expect(response.status).to eq(404)
      expect(SiteSetting.academy_moderators_review_alumni).to eq(true)
    end
  end
end
