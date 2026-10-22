# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::PasswordSetupController do
  fab!(:user, :academy_password_setup_user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  let(:password) { "an initial secure password 2026" }
  let(:params) { { password:, password_confirmation: password } }

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#update" do
    it "requires authentication" do
      put "/academy-roles/password-setup.json", params: params

      expect(response.status).to eq(403)
      expect(user.reload).not_to have_password
    end

    context "when signed in" do
      before do
        user.update_column(:created_at, 1.minute.ago)
        sign_in(user)
      end

      it "sets the password and maintains a usable browser session" do
        previous_token_ids = user.user_auth_tokens.pluck(:id)

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(200)
        expect(response.parsed_body).to include(
          "success" => true,
          "no_password" => false,
          "academy_password_setup_pending" => false,
        )
        expect(user.reload.confirm_password?(password)).to eq(true)
        expect(UserAuthToken.where(id: previous_token_ids)).to be_empty

        get "/session/current.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body.fetch("current_user")).to include(
          "id" => user.id,
          "academy_password_setup_pending" => false,
        )
        expect(response.parsed_body.fetch("current_user")).not_to have_key("no_password")
      end

      it "only sets the current account's password when another user is supplied" do
        other_user = Fabricate(:academy_password_setup_user)

        put "/academy-roles/password-setup.json", params: params.merge(user_id: other_user.id)

        expect(response.status).to eq(200)
        expect(user.reload.confirm_password?(password)).to eq(true)
        expect(other_user.reload).not_to have_password
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(other_user)).to eq(true)
      end

      it "returns validation errors for mismatched confirmation without consuming eligibility" do
        put "/academy-roles/password-setup.json",
            params: params.merge(password_confirmation: "a different password")

        expect(response.status).to eq(422)
        expect(response.parsed_body.fetch("errors")).to be_present
        expect(user.reload).not_to have_password
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user)).to eq(true)
      end

      it "keeps the session and reminder available after a rejected password" do
        put "/academy-roles/password-setup.json",
            params: {
              password: "abc",
              password_confirmation: "abc",
            }

        expect(response.status).to eq(422)
        expect(response.parsed_body.fetch("errors")).to be_present

        get "/session/current.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body.fetch("current_user")).to include(
          "id" => user.id,
          "no_password" => true,
          "academy_password_setup_pending" => true,
        )
      end

      it "requires verification after the signup trust window" do
        user.update_column(:created_at, 6.minutes.ago)

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(403)
        expect(response.parsed_body["error_type"]).to eq("password_setup_verification_required")
        expect(user.reload).not_to have_password
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user)).to eq(true)
      end

      it "accepts a confirmed session after the signup trust window" do
        user.update_column(:created_at, 6.minutes.ago)
        server_session["confirmed-session-#{user.id}"] = "true"

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(200)
        expect(user.reload.confirm_password?(password)).to eq(true)
      end

      it "rejects a forged trusted-session parameter" do
        user.update_column(:created_at, 6.minutes.ago)

        put "/academy-roles/password-setup.json", params: params.merge(trusted_session: true)

        expect(response.status).to eq(403)
        expect(response.parsed_body["error_type"]).to eq("password_setup_verification_required")
        expect(user.reload).not_to have_password
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user)).to eq(true)
      end

      it "rejects repeated password setup without overwriting the first password" do
        put "/academy-roles/password-setup.json", params: params
        expect(response.status).to eq(200)

        put "/academy-roles/password-setup.json",
            params: {
              password: "a replacement password 2026",
              password_confirmation: "a replacement password 2026",
            }

        expect(response.status).to eq(409)
        expect(response.parsed_body["error_type"]).to eq("password_setup_unavailable")
        expect(user.reload.confirm_password?(password)).to eq(true)
      end

      it "rejects setting a password after skipping" do
        delete "/academy-roles/password-setup.json"
        expect(response.status).to eq(204)

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(409)
        expect(user.reload).not_to have_password
      end

      it "rejects API keys even with an eligible current account" do
        api_key = Fabricate(:api_key, user:)

        put "/academy-roles/password-setup.json",
            params:,
            headers: {
              "Api-Key" => api_key.key,
              "Api-Username" => user.username,
            }

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end

      it "rejects user API keys" do
        api_key = Fabricate(:user_api_key, user:)

        put "/academy-roles/password-setup.json",
            params:,
            headers: {
              "User-Api-Key" => api_key.key,
            }

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end

      it "rejects impersonated sessions" do
        admin = Fabricate(:admin)
        sign_in(admin)
        admin
          .user_auth_tokens
          .order(:id)
          .last
          .update!(impersonated_user_id: user.id, impersonation_expires_at: 1.hour.from_now)

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end

      it "rejects requests when local logins are disabled" do
        SiteSetting.enable_local_logins = false

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end

      it "rejects requests when DiscourseConnect is enabled" do
        SiteSetting.discourse_connect_url = "https://example.com/sso"
        SiteSetting.discourse_connect_secret = "a secure shared secret"
        SiteSetting.enable_discourse_connect = true

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end

      it "rate limits repeated setup attempts without consuming eligibility" do
        RateLimiter.enable

        5.times do
          put "/academy-roles/password-setup.json",
              params: params.merge(password_confirmation: "a different password")
          expect(response.status).to eq(422)
        end

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(429)
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user.reload)).to eq(true)
      end

      it "rejects requests when the plugin is disabled" do
        SiteSetting.academy_roles_enabled = false

        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(404)
        expect(user.reload).not_to have_password
      end
    end

    context "with CSRF protection enabled" do
      before do
        user.update_column(:created_at, 1.minute.ago)
        sign_in(user)
      end

      around do |example|
        previous = ApplicationController.allow_forgery_protection
        ApplicationController.allow_forgery_protection = true
        example.run
      ensure
        ApplicationController.allow_forgery_protection = previous
      end

      it "rejects a browser request without a valid CSRF token" do
        put "/academy-roles/password-setup.json", params: params

        expect(response.status).to eq(403)
        expect(user.reload).not_to have_password
      end
    end
  end

  describe "#destroy" do
    it "requires authentication" do
      delete "/academy-roles/password-setup.json"

      expect(response.status).to eq(403)
      expect(DiscourseAcademyRoles::PasswordSetup.pending?(user.reload)).to eq(true)
    end

    context "when signed in" do
      before { sign_in(user) }

      it "persists skipping across reloads and repeated requests" do
        2.times do
          delete "/academy-roles/password-setup.json"

          expect(response.status).to eq(204)
          expect(response.body).to be_empty

          get "/session/current.json"

          expect(response.status).to eq(200)
          expect(response.parsed_body.fetch("current_user")).to include(
            "id" => user.id,
            "no_password" => true,
            "academy_password_setup_pending" => false,
          )
        end
      end

      it "only dismisses the current account's reminder" do
        other_user = Fabricate(:academy_password_setup_user)

        delete "/academy-roles/password-setup.json", params: { user_id: other_user.id }

        expect(response.status).to eq(204)
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user.reload)).to eq(false)
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(other_user.reload)).to eq(true)
      end
    end
  end
end
