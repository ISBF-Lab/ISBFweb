# frozen_string_literal: true

RSpec.describe UsersController do
  fab!(:developer, :admin)
  fab!(:moderator) { Fabricate(:moderator, approved: true, refresh_auto_groups: true) }
  fab!(:member, :user)
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
    it "exposes cosmetic capabilities independently of management access and defaults to off" do
      sign_in(moderator)

      get "/u/#{moderator.username}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user")).to include(
        "moderator" => false,
        "academy_can_wear_name_color" => true,
        "academy_can_customize_name_color" => false,
        "academy_name_color_preferences" => {
          "enabled" => false,
          "color" => nil,
        },
        "academy_display_name_color" => nil,
      )
    end

    it "keeps draft preferences private and publishes only the saved display color" do
      developer.custom_fields["academy_name_color_enabled"] = true
      developer.custom_fields["academy_name_color"] = "#123abc"
      developer.save!
      sign_in(member)

      get "/u/#{developer.username}.json"

      expect(response.status).to eq(200)
      data = response.parsed_body.fetch("user")
      expect(data.fetch("academy_display_name_color")).to eq("#123abc")
      expect(data.keys).not_to include(
        "academy_name_color_preferences",
        "academy_can_wear_name_color",
        "academy_can_customize_name_color",
      )
      expect(data.fetch("custom_fields").keys).not_to include(
        "academy_name_color_enabled",
        "academy_name_color",
      )
    end
  end

  describe "#update" do
    it "round-trips ten ordered colors and rejects an eleventh without changing saved preferences" do
      sign_in(developer)
      stops = Array.new(10) { |index| "##{(index + 1).to_s(16) * 6}" }
      gradient = "linear-gradient(180deg, #{stops.join(", ")})"
      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: gradient,
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq(gradient)
      get "/u/#{developer.username}.json"
      expect(response.parsed_body.dig("user", "academy_name_color_preferences", "color")).to eq(
        gradient,
      )

      original_name = developer.name
      put "/u/#{developer.username}.json",
          params: {
            name: "Unsaved name",
            custom_fields: {
              academy_name_color: "linear-gradient(180deg, #{(stops + ["#ffffff"]).join(", ")})",
            },
          }
      expect(response.status).to eq(422)
      expect(developer.reload.name).to eq(original_name)
      expect(developer.custom_fields["academy_name_color"]).to eq(gradient)
    end

    it "saves a gradient, retains it while disabled and clears it with the theme reset" do
      sign_in(developer)
      gradient = "linear-gradient(180deg, #aabbcc, #123456)"

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: "linear-gradient(180deg, #AbC, #123456)",
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq(gradient)
      expect(developer.reload.custom_fields["academy_name_color"]).to eq(gradient)
      get "/u/#{developer.username}.json"
      expect(response.parsed_body.dig("user", "academy_name_color_preferences", "color")).to eq(
        gradient,
      )

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: false,
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to be_nil
      expect(developer.reload.custom_fields["academy_name_color"]).to eq(gradient)

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: "",
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("theme")
    end

    it "rejects unauthorized gradients and malformed gradient updates atomically" do
      gradient = "linear-gradient(90deg, #123456, #abcdef)"
      [moderator, member].each do |user|
        sign_in(user)
        put "/u/#{user.username}.json", params: { custom_fields: { academy_name_color: gradient } }
        expect(response.status).to eq(403)
        expect(user.reload.custom_fields["academy_name_color"]).to be_nil
      end

      sign_in(developer)
      original_name = developer.name
      put "/u/#{developer.username}.json",
          params: {
            name: "Unsaved name",
            custom_fields: {
              academy_name_color: "#{gradient};display:none",
            },
          }
      expect(response.status).to eq(422)
      expect(developer.reload.name).to eq(original_name)
      expect(developer.custom_fields["academy_name_color"]).to be_nil
    end

    it "persists a normalized developer color through the existing preferences endpoint" do
      sign_in(developer)

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: "#AbC",
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("user")).to include(
        "academy_display_name_color" => "#aabbcc",
        "academy_name_color_preferences" => {
          "enabled" => true,
          "color" => "#aabbcc",
        },
      )
      expect(developer.reload.custom_fields).to include(
        "academy_name_color_enabled" => true,
        "academy_name_color" => "#aabbcc",
      )
      get "/u/#{developer.username}.json"
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("#aabbcc")
    end

    it "allows a restricted administrator to wear theme blue but forbids custom colors" do
      sign_in(moderator)
      original_name = moderator.name

      put "/u/#{moderator.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("theme")

      put "/u/#{moderator.username}.json",
          params: {
            name: "Changed name",
            custom_fields: {
              academy_name_color: "#123456",
            },
          }
      expect(response.status).to eq(403)
      expect(moderator.reload.name).to eq(original_name)
      expect(moderator.custom_fields["academy_name_color"]).to be_nil
    end

    it "rejects forged color permissions from ordinary accounts" do
      sign_in(member)

      put "/u/#{member.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }
      expect(response.status).to eq(403)

      put "/u/#{member.username}.json", params: { custom_fields: { academy_name_color: "#123456" } }
      expect(response.status).to eq(403)
      expect(
        member.reload.custom_fields.values_at("academy_name_color_enabled", "academy_name_color"),
      ).to eq([nil, nil])
    end

    it "protects another account's wear choice even from a developer" do
      other_developer = Fabricate(:admin)
      sign_in(developer)

      put "/u/#{other_developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }

      expect(response.status).to eq(403)
      expect(other_developer.reload.custom_fields["academy_name_color_enabled"]).to be_nil
    end

    it "rejects invalid colors without saving other changes" do
      sign_in(developer)
      original_name = developer.name

      put "/u/#{developer.username}.json",
          params: {
            name: "Changed name",
            custom_fields: {
              academy_name_color: "var(--danger)",
            },
          }

      expect(response.status).to eq(422)
      expect(developer.reload.name).to eq(original_name)
      expect(developer.custom_fields["academy_name_color"]).to be_nil
    end

    it "retains a custom color while off and restores theme blue without disabling wear" do
      sign_in(developer)
      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: "123456",
            },
          }
      expect(response.status).to eq(200)

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: false,
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to be_nil
      expect(developer.reload.custom_fields["academy_name_color"]).to eq("#123456")

      put "/u/#{developer.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("#123456")

      put "/u/#{developer.username}.json", params: { custom_fields: { academy_name_color: "" } }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("theme")
      expect(developer.reload.custom_fields["academy_name_color_enabled"]).to eq(true)
    end

    it "uses current roles and permits unrelated saves after developer access is revoked" do
      developer.custom_fields["academy_name_color_enabled"] = true
      developer.custom_fields["academy_name_color"] = "#123456"
      developer.save!
      developer.update_columns(admin: false, moderator: true)
      sign_in(developer)

      put "/u/#{developer.username}.json", params: { bio_raw: "Updated biography" }

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to eq("theme")
      expect(developer.reload.custom_fields["academy_name_color"]).to eq("#123456")

      developer.update_columns(moderator: false)
      get "/u/#{developer.username}.json"
      expect(response.parsed_body.dig("user", "academy_display_name_color")).to be_nil
    end

    it "accepts unchanged color preferences on repeated profile saves after all staff roles are revoked" do
      developer.custom_fields["academy_name_color_enabled"] = true
      developer.custom_fields["academy_name_color"] = "#12ab34"
      developer.save!
      developer.update_columns(admin: false, moderator: false)
      sign_in(developer)

      2.times do |index|
        put "/u/#{developer.username}.json",
            params: {
              bio_raw: "Updated biography #{index}",
              custom_fields: {
                academy_name_color_enabled: "true",
                academy_name_color: "#12AB34",
              },
            }

        expect(response.status).to eq(200)
        expect(response.parsed_body.fetch("user")).to include(
          "academy_display_name_color" => nil,
          "academy_can_wear_name_color" => false,
          "academy_can_customize_name_color" => false,
        )
      end
      expect(developer.reload.custom_fields).to include(
        "academy_name_color_enabled" => true,
        "academy_name_color" => "#12ab34",
      )
      expect(developer.user_profile.bio_raw).to eq("Updated biography 1")
    end
  end
end
