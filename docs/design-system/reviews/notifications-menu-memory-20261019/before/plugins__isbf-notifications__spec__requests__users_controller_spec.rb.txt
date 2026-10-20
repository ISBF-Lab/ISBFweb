# frozen_string_literal: true

RSpec.describe UsersController do
  fab!(:user)
  fab!(:other_user, :user)

  before { SiteSetting.isbf_notifications_enabled = true }

  describe "#update" do
    before { sign_in(user) }

    it "persists the badge style and exposes it only in the current user's session" do
      get "/session/current.json"
      expect(response.parsed_body.dig("current_user", "isbf_notification_badge_style")).to eq(
        "number",
      )

      put "/u/#{user.username}.json",
          params: {
            custom_fields: {
              isbf_notification_badge_style: "dot",
            },
          }

      expect(response).to have_http_status(:ok)
      expect(user.reload.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD]).to eq("dot")
      get "/session/current.json"
      expect(response.parsed_body.dig("current_user", "isbf_notification_badge_style")).to eq("dot")

      get "/u/#{user.username}.json"
      expect(response.parsed_body["user"]).not_to have_key("isbf_notification_badge_style")
      expect(response.parsed_body.dig("user", "custom_fields").to_h).not_to have_key(
        IsbfNotifications::BADGE_STYLE_FIELD,
      )

      put "/u/#{user.username}.json",
          params: {
            custom_fields: {
              isbf_notification_badge_style: "number",
            },
          }
      expect(response).to have_http_status(:ok)
      expect(user.reload.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD]).to eq("number")
    end

    it "rejects unsupported styles and changes to another account" do
      user.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD] = "dot"
      user.save!

      put "/u/#{user.username}.json",
          params: {
            custom_fields: {
              isbf_notification_badge_style: "none",
            },
          }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD]).to eq("dot")

      put "/u/#{other_user.username}.json",
          params: {
            custom_fields: {
              isbf_notification_badge_style: "dot",
            },
          }
      expect(response).to have_http_status(:forbidden)
      expect(other_user.reload.custom_fields[IsbfNotifications::BADGE_STYLE_FIELD]).to be_nil
    end
  end
end
