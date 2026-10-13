# frozen_string_literal: true

RSpec.describe InvitesController do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.enable_local_logins_via_code = false
  end

  describe "#show" do
    it "opens a student invitation without exposing the student number" do
      get "/invites/#{registration.invite.invite_key}"

      expect(response.status).to eq(200)
      expect(response.body).not_to include(registration.student_number)
    end

    it "rejects a legacy invitation with no student registration" do
      legacy_invite = Fabricate(:invite, invited_by: admin, email: nil)

      get "/invites/#{legacy_invite.invite_key}"

      expect(response.status).to eq(200)
      expect(response.body).to have_tag(:body, with: { class: "no-ember" })
      expect(response.body).to include(
        I18n.t("invite.not_found", base_url: Discourse.base_url)
      )
    end
  end

  describe "#perform_accept_invitation" do
    let(:parameters) do
      {
        email: "newstudent@example.com",
        username: "newstudent",
        password: "verystrongpassword"
      }
    end

    it "binds the configured student number when creating an account awaiting activation" do
      expected_student_number = registration.student_number
      put "/invites/show/#{registration.invite.invite_key}.json",
          params:
            parameters.merge(
              student_number: "forged-student-number",
              academy_student_number: "forged-student-number"
            )

      expect(response.status).to eq(200)
      user = User.find_by_email(parameters[:email])
      expect(user).to be_present
      expect(user).not_to be_active
      expect(registration.reload.user).to eq(user)
      expect(registration.registered_at).to be_present
      expect(registration.student_number).to eq(expected_student_number)
      expect(registration.invite.reload.redemption_count).to eq(1)
      expect(user.custom_fields).not_to have_key("academy_student_number")
      expect(user.groups).not_to include(official_group)
      expect(response.body).not_to include(registration.student_number)
    end

    it "rejects a second redemption without creating another account" do
      put "/invites/show/#{registration.invite.invite_key}.json",
          params: parameters
      first_user = registration.reload.user

      expect do
        put "/invites/show/#{registration.invite.invite_key}.json",
            params: parameters.merge(email: "secondstudent@example.com")
      end.not_to change(User, :count)

      expect(response.status).to eq(404)
      expect(registration.reload.user).to eq(first_user)
      expect(registration.invite.redemption_count).to eq(1)
    end

    it "rolls back account creation, invite redemption and binding when account validation fails" do
      expect do
        put "/invites/show/#{registration.invite.invite_key}.json",
            params: parameters.merge(password: "short")
      end.not_to change(User, :count)

      expect(response.status).to eq(412)
      expect(registration.reload.user_id).to be_nil
      expect(registration.registered_at).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
      expect(registration.invite.invited_users).to be_empty
      expect(registration.invite).to be_redeemable
    end

    it "rejects a legacy invitation without a student registration" do
      legacy_invite = Fabricate(:invite, invited_by: admin, email: nil)

      expect do
        put "/invites/show/#{legacy_invite.invite_key}.json", params: parameters
      end.not_to change(User, :count)

      expect(response.status).to eq(404)
      expect(legacy_invite.reload.redemption_count).to eq(0)
    end

    it "rejects expired and revoked student invitations" do
      registration.invite.update!(expires_at: 1.day.ago)

      expect do
        put "/invites/show/#{registration.invite.invite_key}.json",
            params: parameters
      end.not_to change(User, :count)
      expect(response.status).to eq(404)

      registration.invite.update!(
        expires_at: 1.day.from_now,
        invalidated_at: Time.current
      )
      expect do
        put "/invites/show/#{registration.invite.invite_key}.json",
            params: parameters
      end.not_to change(User, :count)
      expect(response.status).to eq(404)
      expect(registration.reload.user_id).to be_nil
    end

    it "accepts only the replacement code after reissuing an invitation" do
      previous_invite = registration.invite
      DiscourseAcademyRoles::ReissueStudentInvite.call(
        params: {
          student_registration_id: registration.id
        },
        guardian: admin.guardian
      )

      put "/invites/show/#{previous_invite.invite_key}.json", params: parameters
      expect(response.status).to eq(404)
      expect(registration.reload.user_id).to be_nil

      put "/invites/show/#{registration.invite.invite_key}.json",
          params: parameters
      expect(response.status).to eq(200)
      expect(registration.reload.user.email).to eq(parameters[:email])
    end

    it "rejects an existing account's email without binding that account" do
      put "/invites/show/#{registration.invite.invite_key}.json",
          params: parameters.merge(email: member.email)

      expect(response.status).to eq(412)
      expect(registration.reload.user_id).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
    end

    it "rejects an authenticated account without redeeming the invitation" do
      sign_in(member)

      put "/invites/show/#{registration.invite.invite_key}.json"

      expect(response.status).to eq(412)
      expect(registration.reload.user_id).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
    end
  end

  describe "#create" do
    it "routes administrators to student invitations instead of creating an unbound code" do
      sign_in(admin)

      expect do
        post "/invites.json", params: { max_redemptions_allowed: 1 }
      end.not_to change(Invite, :count)

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("academy_roles.student_invites.use_student_invite")
      )
    end
  end
end

RSpec.describe SessionController do
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.enable_local_logins_via_code = true
  end

  describe "#verify_login_code" do
    it "binds the student number and consumes the code for a new verified account" do
      login_code =
        EmailLoginCode.generate!(email: "verified-student@example.com")

      post "/session/login-code/verify.json",
           params: {
             invite_key: registration.invite.invite_key,
             email: login_code.email,
             code: login_code.code,
             username: "verifiedstudent"
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["account_created"]).to eq(true)
      expect(registration.reload.user).to be_active
      expect(registration.user).to be_email_confirmed
      expect(registration.user.email).to eq(login_code.email)
      expect(registration.registered_at).to be_present
      expect(registration.invite.redemption_count).to eq(1)
      expect(login_code.reload.consumed_at).to be_present
      expect(response.body).not_to include(registration.student_number)
    end

    it "keeps the invite, login code and binding untouched when account validation fails" do
      login_code =
        EmailLoginCode.generate!(email: "invalid-student@example.com")

      expect do
        post "/session/login-code/verify.json",
             params: {
               invite_key: registration.invite.invite_key,
               email: login_code.email,
               code: login_code.code,
               username: "invalid username"
             }
      end.not_to change(User, :count)

      expect(response.status).to eq(200)
      expect(registration.reload.user_id).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
      expect(registration.invite.invited_users).to be_empty
      expect(login_code.reload.consumed_at).to be_nil
    end

    it "explains that the email is registered and lets the same code log in without redeeming the invitation" do
      login_code = EmailLoginCode.generate!(email: member.email)

      post "/session/login-code/verify.json",
           params: {
             invite_key: registration.invite.invite_key,
             email: member.email,
             code: login_code.code
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["error"]).to eq(
        I18n.t("academy_roles.student_invites.new_account_required")
      )
      expect(session[:current_user_id]).to be_nil
      expect(registration.reload.user_id).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
      expect(login_code.reload.consumed_at).to be_nil

      post "/session/login-code/verify.json",
           params: {
             email: member.email,
             code: login_code.code
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["error"]).to be_nil
      expect(session[:current_user_id]).to eq(member.id)
      expect(login_code.reload.consumed_at).to be_present
      expect(registration.reload.user_id).to be_nil
      expect(registration.invite.redemption_count).to eq(0)
    end

    it "keeps the generic verification error for an incorrect code even when the email is registered" do
      login_code = EmailLoginCode.generate!(email: member.email)
      incorrect_code = login_code.code == "000000" ? "000001" : "000000"

      post "/session/login-code/verify.json",
           params: {
             invite_key: registration.invite.invite_key,
             email: member.email,
             code: incorrect_code
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body["error"]).to eq(
        I18n.t("email_login_code.invalid_code")
      )
      expect(session[:current_user_id]).to be_nil
      expect(login_code.reload.consumed_at).to be_nil
      expect(registration.reload.user_id).to be_nil
    end
  end
end
