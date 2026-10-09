# frozen_string_literal: true

RSpec.describe InvitesController do
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.academy_auth_page_enabled = true
  end

  describe "#show" do
    it "returns the valid invitation without student identity" do
      get "/invites/#{registration.invite.invite_key}", headers: { "HTTP_ACCEPT" => "application/json" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["is_invite_link"]).to eq(true)
      expect(response.body).not_to include(registration.student_number)
      expect(registration.reload).not_to be_registered
      expect(registration.invite.reload.redemption_count).to eq(0)
    end

    it "returns a structured error for an invalid invitation" do
      get "/invites/missing-student-invitation", headers: { "HTTP_ACCEPT" => "application/json" }

      expect(response.status).to eq(404)
      expect(response.parsed_body).to eq(
        "errors" => [I18n.t("academy_roles.auth.invite_invalid")],
        "invite_status" => "invalid"
      )
    end

    it "returns an expired invitation error" do
      registration.invite.update!(expires_at: 1.day.ago)

      get "/invites/#{registration.invite.invite_key}", headers: { "HTTP_ACCEPT" => "application/json" }

      expect(response.status).to eq(404)
      expect(response.parsed_body["invite_status"]).to eq("expired")
    end

    it "returns a used invitation error" do
      registration.invite.update!(redemption_count: 1)

      get "/invites/#{registration.invite.invite_key}", headers: { "HTTP_ACCEPT" => "application/json" }

      expect(response.status).to eq(404)
      expect(response.parsed_body["invite_status"]).to eq("used")
    end

    it "rejects an invitation without an associated student record" do
      invite = Fabricate(:invite, email: nil, invited_by: registration.issued_by)

      get "/invites/#{invite.invite_key}", headers: { "HTTP_ACCEPT" => "application/json" }

      expect(response.status).to eq(404)
      expect(response.parsed_body["invite_status"]).to eq("invalid")
    end

    it "retains the standard error page when the new page is disabled" do
      SiteSetting.academy_auth_page_enabled = false

      get "/invites/missing-student-invitation"

      expect(response.status).to eq(200)
      expect(response.body).to include(
        I18n.t("invite.not_found", base_url: Discourse.base_url)
      )
    end
  end
end
