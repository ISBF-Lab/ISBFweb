# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::ModeratorPermissionsController do
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

  describe "#index" do
    it "returns the twenty switches to developers" do
      sign_in(developer)
      get "/academy-roles/admin/moderator-permissions.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("settings").length).to eq(20)
      expect(response.parsed_body.fetch("values").values).to eq([false] * 20)
    end

    it "keeps permission configuration developer-only with every switch enabled" do
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      sign_in(moderator)
      get "/academy-roles/admin/moderator-permissions.json"
      expect(response.status).to eq(403)
      get "/academy-roles/admin/student-invites.json"
      expect(response.status).to eq(403)
      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_content: {
                value: false,
              },
            },
          }
      expect(response.status).to eq(404)
      expect(SiteSetting.academy_moderators_review_content).to eq(true)
    end

    it "keeps ordinary accounts outside the management interface" do
      sign_in(member)
      get "/academy-roles/admin/moderator-permissions.json"
      expect(response.status).to eq(403)
    end

    it "never grants unrelated staff routes through a permission to review content" do
      SiteSetting.academy_moderators_review_content = true
      sign_in(moderator)
      get "/admin/reports/signups.json"
      expect(response.status).to eq(403)
      get "/admin/users/list.json"
      expect(response.status).to eq(403)
    end
  end
end

RSpec.describe UsersController do
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    sign_in(moderator)
  end

  describe "#update" do
    it "allows ordinary profile editing without granting access to another account's credentials" do
      put "/u/#{member.username}.json", params: { name: "Updated profile" }
      expect(response.status).to eq(403)
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      put "/u/#{member.username}.json", params: { name: "Updated profile" }
      expect(response.status).to eq(200), response.body
      expect(member.reload.name).to eq("Updated profile")

      token = UserAuthToken.generate!(user_id: member.id)
      post "/u/#{member.username}/preferences/revoke-auth-token.json",
           params: {
             token_id: token.id,
           }
      expect(response.status).to eq(403)
      expect(UserAuthToken.exists?(token.id)).to eq(true)
      post "/u/#{member.username}/preferences/revoke-account.json",
           params: {
             provider_name: "oauth",
           }
      expect(response.status).to eq(403)
      put "/u/#{member.username}/remove-password.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#revoke_auth_token" do
    it "retains the moderator's own ordinary session controls with all switches disabled" do
      token = UserAuthToken.generate!(user_id: moderator.id)
      post "/u/#{moderator.username}/preferences/revoke-auth-token.json",
           params: {
             token_id: token.id,
           }
      expect(response.status).to eq(200)
      expect(UserAuthToken.exists?(token.id)).to eq(false)
    end
  end
end

RSpec.describe Admin::GroupsController do
  fab!(:moderator)
  fab!(:group)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    sign_in(moderator)
  end

  it "allows deleting a visible nonautomatic group only while group management is enabled" do
    delete "/admin/groups/#{group.id}.json"
    expect(response.status).to eq(404)
    expect(group.reload).to be_present
    SiteSetting.moderators_manage_groups = true
    delete "/admin/groups/#{Group::AUTO_GROUPS[:admins]}.json"
    expect(response.status).to eq(403)
    expect(Group.exists?(Group::AUTO_GROUPS[:admins])).to eq(true)
    delete "/admin/groups/#{group.id}.json"
    expect(response.status).to eq(200)
    expect(Group.exists?(group.id)).to eq(false)
  end
end

RSpec.describe Admin::SiteSettingsController do
  fab!(:developer, :admin)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#update" do
    before { sign_in(developer) }

    it "saves only the submitted switches and records staff history" do
      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_content: {
                value: true,
              },
              academy_moderators_suspend_users: {
                value: true,
              },
            },
          }
      expect(response.status).to eq(204)
      expect(SiteSetting.academy_moderators_review_content).to eq(true)
      expect(SiteSetting.academy_moderators_suspend_users).to eq(true)
      expect(SiteSetting.academy_moderators_silence_users).to eq(false)
      expect(
        UserHistory.where(
          acting_user_id: developer.id,
          subject: "academy_moderators_review_content",
        ).count,
      ).to eq(1)
    end

    it "rejects the entire update when a submitted setting is invalid" do
      put "/admin/site_settings/bulk_update.json",
          params: {
            settings: {
              academy_moderators_review_content: {
                value: true,
              },
              min_post_length: {
                value: -1,
              },
            },
          }
      expect(response.status).to eq(422)
      expect(SiteSetting.academy_moderators_review_content).to eq(false)
    end
  end
end

RSpec.describe Admin::UsersController do
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :registered_academy_student)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#show" do
    before { sign_in(moderator) }

    it "requires user administration access and applies immediate revocation in the same session" do
      get "/admin/users/#{registration.user_id}.json"
      expect(response.status).to eq(404)
      SiteSetting.academy_moderators_access_user_admin = true
      get "/admin/users/#{registration.user_id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body).not_to have_key("academy_student_number")
      expect(response.body).not_to include(registration.student_number)
      SiteSetting.academy_moderators_access_user_admin = false
      get "/admin/users/#{registration.user_id}.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#suspend" do
    before { sign_in(moderator) }

    it "requires suspension permission independently of access to the user page" do
      SiteSetting.academy_moderators_access_user_admin = true
      put "/admin/users/#{member.id}/suspend.json",
          params: {
            suspend_until: 1.day.from_now.iso8601,
            reason: "Repeated violations",
          }
      expect(response.status).to eq(403)
      expect(member.reload.suspended?).to eq(false)
      SiteSetting.academy_moderators_suspend_users = true
      put "/admin/users/#{member.id}/suspend.json",
          params: {
            suspend_until: 1.day.from_now.iso8601,
            reason: "Repeated violations",
          }
      expect(response.status).to eq(200)
      expect(member.reload.suspended?).to eq(true)
    end
  end
end
