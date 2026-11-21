# frozen_string_literal: true

RSpec.describe Admin::ThemesController, type: :request do
  fab!(:theme)
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)

  let(:defaults) { theme.settings[:workbench_entries].default }

  before do
    theme.set_field(
      target: :settings,
      name: :yaml,
      value: File.read(File.expand_path("../../settings.yml", __dir__)),
    )
    theme.save!
  end

  describe "#update_single_setting" do
    it "lets an admin save entry order, icons and tones and reload the same values" do
      sign_in(admin)
      entries = defaults.deep_dup.rotate(1)
      entries.first.merge!("icon" => "gas-pump", "tone" => "mint")

      put "/admin/themes/#{theme.id}/setting.json",
          params: {
            name: "workbench_entries",
            value: entries.to_json,
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["workbench_entries"]).to eq(entries)
      expect(theme.reload.settings[:workbench_entries].value).to eq(entries)

      get "/admin/themes/#{theme.id}.json"

      expect(response.status).to eq(200)
      setting =
        response.parsed_body["theme"]["settings"].find do |item|
          item["setting"] == "workbench_entries"
        end
      expect(setting["value"]).to eq(entries)
      expect(setting["default"]).to eq(defaults)
    end

    it "lets an admin clear an icon and restore the declared default entries" do
      sign_in(admin)
      entries = defaults.deep_dup.reverse
      entries.first.merge!("icon" => "gas-pump", "tone" => "violet")
      theme.update_setting(:workbench_entries, entries)
      theme.save!

      entries.first["icon"] = nil
      put "/admin/themes/#{theme.id}/setting.json",
          params: {
            name: "workbench_entries",
            value: entries.to_json,
          }

      expect(response.status).to eq(200)
      expect(theme.reload.settings[:workbench_entries].value).to eq(entries)

      put "/admin/themes/#{theme.id}/setting.json",
          params: {
            name: "workbench_entries",
            value: defaults.to_json,
          }

      expect(response.status).to eq(200)
      expect(theme.reload.settings[:workbench_entries].value).to eq(defaults)
    end

    it "includes a newly saved icon in the theme sprite on its first resource request" do
      sign_in(admin)
      icon = "gas-pump"
      expect(SvgSprite.all_icons(theme.id)).not_to include(icon)
      entries = defaults.deep_dup
      entries.first["icon"] = icon

      put "/admin/themes/#{theme.id}/setting.json",
          params: {
            name: "workbench_entries",
            value: entries.to_json,
          }

      expect(response.status).to eq(200)
      expect(SvgSprite.all_icons(theme.id)).to include(icon)

      get "/svg-sprite/#{Discourse.current_hostname}/svg-#{theme.id}-#{SvgSprite.version(theme.id)}.js"

      expect(response.status).to eq(200)
      expect(response.body).to include(icon)
    end

    %i[moderator user].each do |role|
      it "preserves entries when a #{role} attempts to change the setting" do
        sign_in(public_send(role))
        original = defaults.deep_dup

        put "/admin/themes/#{theme.id}/setting.json",
            params: {
              name: "workbench_entries",
              value: original.reverse.to_json,
            }

        expect(response.status).to eq(404)
        expect(theme.reload.settings[:workbench_entries].value).to eq(original)
      end
    end
  end
end
