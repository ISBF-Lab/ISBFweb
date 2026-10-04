# frozen_string_literal: true

RSpec.describe Admin::UsersController do
  fab!(:admin)
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
    it "returns the student number for an administrator" do
      sign_in(admin)

      get "/admin/users/#{registration.user_id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["academy_student_number"]).to eq(
        registration.student_number
      )
      expect(response.parsed_body["can_be_merged"]).to eq(false)
    end

    it "keeps the student number private from a moderator" do
      sign_in(moderator)

      get "/admin/users/#{registration.user_id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).not_to have_key("academy_student_number")
      expect(response.body).not_to include(registration.student_number)
    end
  end

  describe "public account responses" do
    it "keeps student numbers out of public JSON and HTML for visitors and signed-in users" do
      SiteSetting.invite_only = false

      [nil, member, moderator, admin, registration.user].each do |actor|
        sign_in(actor) if actor

        get "/u/#{registration.user.username}.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["user"]).not_to have_key(
          "academy_student_number"
        )
        expect(response.body).not_to include(registration.student_number)

        get "/u/#{registration.user.username}"
        expect(response.status).to eq(200)
        expect(response.body).not_to include(registration.student_number)
      end
    end

    it "keeps the student number out of the account holder's current-user response" do
      sign_in(registration.user)

      get "/session/current.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["current_user"]).not_to have_key(
        "academy_student_number"
      )
      expect(response.body).not_to include(registration.student_number)
    end

    it "keeps the student number out of anonymous identities" do
      SiteSetting.allow_anonymous_mode = true
      SiteSetting.anonymous_posting_allowed_groups =
        Group::AUTO_GROUPS[:trust_level_0].to_s
      Group.refresh_automatic_groups_for_user!(registration.user)
      anonymous_user = AnonymousShadowCreator.get(registration.user)

      get "/u/#{anonymous_user.username}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]).not_to have_key(
        "academy_student_number"
      )
      expect(response.body).not_to include(registration.student_number)
      expect(
        DiscourseAcademyRoles::StudentRegistration.find_by(user: anonymous_user)
      ).to be_nil
    end
  end

  describe "#merge" do
    it "rejects merging a bound account before enqueuing a job" do
      sign_in(admin)

      expect do
        post "/admin/users/#{registration.user_id}/merge.json",
             params: {
               target_username: member.username
             }
      end.not_to change { Jobs::MergeUser.jobs.size }

      expect(response.status).to eq(403)
      expect(registration.reload.user).to be_present
    end
  end
end
