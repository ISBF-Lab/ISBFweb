# frozen_string_literal: true

RSpec.describe IsbfAccountSwitch::AccountsController do
  fab!(:requester) { Fabricate(:user, password: "target-password") }
  fab!(:target) { Fabricate(:user, password: "target-password") }
  fab!(:stranger, :user)
  fab!(:admin)

  before { SiteSetting.isbf_account_switch_enabled = true }

  describe "#index" do
    it "returns live links alongside a revoked link to a deleted account" do
      deleted_link = create_link
      deleted_link.update!(status: :revoked)
      target.destroy!
      live_link =
        Fabricate(
          :isbf_account_link,
          user_a: requester,
          user_b: stranger,
          requester: requester,
          status: :approved,
        )

      get "/isbf/account-switch/accounts.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["links"].map { |link| link["id"] }).to eq([live_link.id])
      expect(response.parsed_body["links"].first["account"]["username"]).to eq(stranger.username)
      expect(deleted_link.reload).to be_revoked
      expect(IsbfAccountSwitch::AuditEvent.where(account_link_id: deleted_link.id)).to exist
    end

    it "returns an empty list when the first account of an approved link was deleted" do
      link = create_link
      link.update!(status: :approved)
      requester.destroy!
      sign_in(target)

      get "/isbf/account-switch/accounts.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["links"]).to eq([])
      expect(response.parsed_body["can_link_accounts"]).to eq(true)
      expect(link.reload).to be_approved
    end

    it "returns an empty list for a user without account links" do
      sign_in(stranger)

      get "/isbf/account-switch/accounts.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["links"]).to eq([])
    end
  end

  %w[verify switch].each do |action_name|
    describe "##{action_name}" do
      it "preserves the session when the approved target account was deleted" do
        link = create_link
        link.update!(status: :approved)
        target.destroy!

        post "/isbf/account-switch/links/#{link.id}/#{action_name}.json",
             params: {
               password: "target-password",
             }

        expect(response.status).to eq(403)
        expect(response.parsed_body["errors"]).to eq(
          [I18n.t("isbf_account_switch.errors.target_unavailable")],
        )
        expect(IsbfAccountSwitch::DeviceGrant.count).to eq(0)
        get "/session/current.json"
        expect(response.parsed_body["current_user"]["username"]).to eq(requester.username)
      end
    end
  end

  it "opens the approval page directly for an administrator" do
    sign_in(admin)
    Discourse.stubs(:plugins_sorted_by_name).returns(
      [Discourse.plugins_by_name["isbf-account-switch"]],
    )

    get "/admin/plugins/isbf-account-switch/links"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("text/html")
  end

  it "does not expose the approval page to an ordinary user" do
    sign_in(requester)

    get "/admin/plugins/isbf-account-switch/links"

    expect(response.status).to eq(404)
  end

  def create_link
    sign_in(requester)
    post "/isbf/account-switch/links.json", params: { username: target.username }
    IsbfAccountSwitch::AccountLink.last
  end

  it "requires administrator approval without target confirmation" do
    link = create_link

    expect(response.status).to eq(200)
    expect(link).to be_pending_admin
    expect(response.parsed_body["link"]["status"]).to eq("pending_admin")

    sign_in(stranger)
    put "/isbf/account-switch/admin/links/#{link.id}/approve.json"
    expect(response.status).to eq(403)
    expect(link.reload).to be_pending_admin

    sign_in(admin)
    put "/isbf/account-switch/admin/links/#{link.id}/approve.json"
    expect(response.status).to eq(200)
    expect(link.reload).to be_approved
  end

  it "does not let a third user revoke a link" do
    link = create_link
    sign_in(stranger)

    delete "/isbf/account-switch/links/#{link.id}.json"
    expect(response.status).to eq(403)
  end

  it "keeps the current session when target verification fails" do
    link = create_link
    link.update!(status: :approved, approved_by: admin, approved_at: Time.zone.now)
    sign_in(requester)

    post "/isbf/account-switch/links/#{link.id}/verify.json", params: { password: "wrong-password" }

    expect(response.status).to eq(403)
    get "/session/current.json"
    expect(response.parsed_body["current_user"]["username"]).to eq(requester.username)
    expect(IsbfAccountSwitch::DeviceGrant.count).to eq(0)
  end

  it "authorizes the device only after valid target credentials" do
    link = create_link
    link.update!(status: :approved, approved_by: admin, approved_at: Time.zone.now)
    sign_in(requester)

    post "/isbf/account-switch/links/#{link.id}/verify.json",
         params: {
           password: "target-password",
         }

    expect(response.status).to eq(200)
    expect(IsbfAccountSwitch::DeviceGrant.where(account_link_id: link.id).count).to eq(2)
    expect(IsbfAccountSwitch::AuditEvent.where(action: "target_verified").count).to eq(1)
  end

  it "revokes device grants when a participant revokes the link" do
    link = create_link
    link.update!(status: :approved, approved_by: admin, approved_at: Time.zone.now)
    IsbfAccountSwitch::DeviceGrant.create!(
      account_link: link,
      user: target,
      device_digest: "digest",
      expires_at: 1.day.from_now,
    )
    sign_in(requester)

    delete "/isbf/account-switch/links/#{link.id}.json"

    expect(response.status).to eq(200)
    expect(link.reload).to be_revoked
    expect(link.device_grants.where(revoked_at: nil)).to be_empty
  end
end
