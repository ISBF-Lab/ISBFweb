# frozen_string_literal: true

RSpec.describe UsersController do
  fab!(:moderator) do
    Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) { Fabricate(:user, trust_level: TrustLevel[2], active: true, approved: true) }
  fab!(:developer, :admin)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.each_value do |setting|
      SiteSetting.public_send("#{setting}=", false)
    end
  end

  describe "#show" do
    it "keeps the personal profile moderator projection consistent with enabled management permissions" do
      sign_in(moderator)

      get "/u/#{moderator.username}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user")).to include(
        "moderator" => false,
        "can_edit" => true,
        "academy_can_see_staff_info" => false,
      )

      SiteSetting.academy_moderators_review_content = true
      get "/u/#{moderator.username}.json"
      expect(response.parsed_body.fetch("user")).to include(
        "moderator" => true,
        "academy_can_see_staff_info" => false,
      )

      SiteSetting.academy_moderators_review_content = false
      get "/u/#{moderator.username}.json"
      expect(response.parsed_body.fetch("user").fetch("moderator")).to eq(false)
      expect(moderator.reload[:moderator]).to eq(true)

      sign_in(developer)
      get "/u/#{moderator.username}.json"
      expect(response.parsed_body.fetch("user").fetch("moderator")).to eq(true)
    end

    it "loads management assets when the current user has a management permission" do
      sign_in(moderator)

      [false, true, false].each do |enabled|
        SiteSetting.academy_moderators_review_content = enabled
        get "/u/#{moderator.username}/summary"

        expect(response.status).to eq(200)
        document = Nokogiri.HTML5(response.body)
        expect(document.at_css("#data-discourse-setup")["data-is-staff"]).to eq(enabled.to_s)
        preloaded = JSON.parse(document.at_css("#data-preloaded").text)
        expect(JSON.parse(preloaded.fetch("currentUser"))).to include(
          "staff" => enabled,
          "moderator" => enabled,
          "academy_moderator_role" => true,
        )
        scripts = document.css("script[src]").map { |script| script["src"] }
        expect(scripts.include?(ExtraLocalesController.url("admin"))).to eq(enabled)
      end
    end

    it "keeps native management asset eligibility for members, developers and a disabled role feature" do
      [[member, false], [developer, true]].each do |actor, eligible|
        sign_in(actor)
        get "/u/#{actor.username}/summary"

        expect(response.status).to eq(200)
        document = Nokogiri.HTML5(response.body)
        expect(document.at_css("#data-discourse-setup")["data-is-staff"]).to eq(eligible.to_s)
      end

      SiteSetting.academy_roles_enabled = false
      sign_in(moderator)
      get "/u/#{moderator.username}/summary"

      expect(response.status).to eq(200)
      document = Nokogiri.HTML5(response.body)
      expect(document.at_css("#data-discourse-setup")["data-is-staff"]).to eq("true")
    end

    it "reports the staff information permission independently of another management permission" do
      sign_in(moderator)
      SiteSetting.academy_moderators_review_content = true

      get "/u/#{member.username}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user").fetch("academy_can_see_staff_info")).to eq(false)

      SiteSetting.academy_moderators_access_user_admin = true
      get "/u/#{member.username}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user").fetch("academy_can_see_staff_info")).to eq(true)

      SiteSetting.academy_moderators_access_user_admin = false
      get "/u/#{member.username}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user").fetch("academy_can_see_staff_info")).to eq(false)
    end

    it "keeps the native visibility rules for members, developers and a disabled role feature" do
      sign_in(member)
      get "/u/#{member.username}.json"
      expect(response.parsed_body.fetch("user").fetch("academy_can_see_staff_info")).to eq(false)

      sign_in(developer)
      get "/u/#{member.username}.json"
      expect(response.parsed_body.fetch("user").fetch("academy_can_see_staff_info")).to eq(true)

      SiteSetting.academy_roles_enabled = false
      sign_in(moderator)
      get "/u/#{moderator.username}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user")).not_to have_key("academy_can_see_staff_info")
      get "/u/#{moderator.username}/staff-info.json"
      expect(response.status).to eq(200)
    end

    it "keeps missing user profiles unavailable" do
      sign_in(moderator)

      get "/u/missing-personal-profile.json"

      expect(response.status).to eq(404)
    end
  end

  describe "#staff_info" do
    it "requires the dedicated permission and revokes it in the same session" do
      sign_in(moderator)
      SiteSetting.academy_moderators_review_content = true

      get "/u/#{member.username}/staff-info.json"
      expect(response.status).to eq(403)

      SiteSetting.academy_moderators_access_user_admin = true
      get "/u/#{member.username}/staff-info.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("number_of_suspensions", "number_of_deleted_posts")

      SiteSetting.academy_moderators_access_user_admin = false
      get "/u/#{member.username}/staff-info.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#bookmarks" do
    it "allows the administrator's bookmarks and protects another user's bookmarks" do
      sign_in(moderator)

      get "/u/#{moderator.username}/bookmarks.json"
      expect(response.status).to eq(200)

      get "/u/#{member.username}/bookmarks.json"
      expect(response.status).to eq(403)
    end
  end
end

RSpec.describe NotificationsController do
  fab!(:moderator) { Fabricate(:moderator, active: true, approved: true) }
  fab!(:member) { Fabricate(:user, active: true, approved: true) }
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  describe "#index" do
    it "allows the administrator's notifications and protects another user's notifications" do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
      SiteSetting.academy_moderators_access_user_admin = false
      sign_in(moderator)

      get "/notifications.json", params: { username: moderator.username }
      expect(response.status).to eq(200)

      get "/notifications.json", params: { username: member.username }
      expect(response.status).to eq(403)
    end
  end
end
