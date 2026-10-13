# frozen_string_literal: true

RSpec.describe IsbfAccountSwitch::Admin::LinksController do
  fab!(:first_user, :user)
  fab!(:second_user, :user)
  fab!(:admin)
  fab!(:link) do
    Fabricate(:isbf_account_link, user_a: first_user, user_b: second_user, requester: first_user)
  end

  before { SiteSetting.isbf_account_switch_enabled = true }

  describe "#index" do
    it "retains the deleted account ID and audit history" do
      event =
        IsbfAccountSwitch::AuditEvent.record!(
          action: "link_requested",
          link: link,
          actor: second_user,
        )
      second_user.destroy!
      sign_in(admin)

      get "/isbf/account-switch/admin/links.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["links"].map { |entry| entry["id"] }).to eq([link.id])
      payload = response.parsed_body["links"].first
      expect(payload["user_a"]["username"]).to eq(first_user.username)
      expect(payload["user_b"]).to eq("id" => second_user.id, "username" => nil, "name" => nil)
      expect(payload["status"]).to eq("pending_admin")
      expect(response.parsed_body["audit_events"].map { |entry| entry["id"] }).to eq([event.id])
      expect(response.parsed_body["audit_events"].first["actor"]).to eq(nil)
    end

    it "returns historical links when the requester and first account were deleted" do
      first_user.destroy!
      sign_in(admin)

      get "/isbf/account-switch/admin/links.json"

      expect(response.status).to eq(200)
      payload = response.parsed_body["links"].first
      expect(payload["user_a"]).to eq("id" => first_user.id, "username" => nil, "name" => nil)
      expect(payload["requester"]).to eq(nil)
      expect(payload["user_b"]["username"]).to eq(second_user.username)
    end

    it "restricts the account history to administrators" do
      sign_in(first_user)

      get "/isbf/account-switch/admin/links.json"

      expect(response.status).to eq(403)
    end
  end

  describe "#approve" do
    %i[first_user second_user].each do |user_name|
      it "rejects approval when #{user_name} was deleted" do
        public_send(user_name).destroy!
        sign_in(admin)

        put "/isbf/account-switch/admin/links/#{link.id}/approve.json"

        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to eq(
          [I18n.t("isbf_account_switch.errors.invalid_link")],
        )
        expect(link.reload).to be_pending_admin
        expect(IsbfAccountSwitch::AuditEvent.where(action: "link_approved")).not_to exist
      end
    end
  end

  describe "#reject" do
    it "rejects a pending link after its requester was deleted" do
      first_user.destroy!
      sign_in(admin)

      put "/isbf/account-switch/admin/links/#{link.id}/reject.json"

      expect(response.status).to eq(200)
      expect(link.reload).to be_rejected
      expect(response.parsed_body["link"]["requester"]).to eq(nil)
      expect(
        IsbfAccountSwitch::AuditEvent.where(action: "link_rejected", account_link_id: link.id),
      ).to exist
    end
  end

  describe "#revoke" do
    it "revokes an approved link and its device grants after an account was deleted" do
      link.update!(status: :approved)
      grant =
        IsbfAccountSwitch::DeviceGrant.create!(
          account_link: link,
          user: first_user,
          device_digest: "digest",
          expires_at: 1.day.from_now,
        )
      second_user.destroy!
      sign_in(admin)

      put "/isbf/account-switch/admin/links/#{link.id}/revoke.json"

      expect(response.status).to eq(200)
      expect(link.reload).to be_revoked
      expect(grant.reload.revoked_at).to be_present
      expect(response.parsed_body["link"]["user_b"]["id"]).to eq(second_user.id)
      expect(
        IsbfAccountSwitch::AuditEvent.where(action: "link_revoked", account_link_id: link.id),
      ).to exist
    end
  end
end
