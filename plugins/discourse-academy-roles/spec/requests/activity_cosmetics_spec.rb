# frozen_string_literal: true

RSpec.describe "Activity level appearances", type: :request do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:other_member, :user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:level_badge, :activity_level_badge)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  let(:document) do
    activity_rules(
      levels: [
        activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
        activity_tier(identifier: "regular", conditions: [activity_condition("posts_read", 10)]),
      ],
    ).merge("cosmetics" => activity_cosmetics(avatar_minimum: "reader", name_minimum: "reader"))
  end

  before do
    reset_activity_appearance_caches
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.avatar_frames_enabled = true
    SiteSetting.enable_badges = true
    persist_activity_rules(document)
  end

  after { reset_activity_appearance_caches }

  describe "GET /academy-roles/admin/activity-levels" do
    it "returns developer-owned cosmetic settings and eligible badge options" do
      sign_in(admin)

      get "/academy-roles/admin/activity-levels.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["cosmetics"]).to eq(document["cosmetics"])
      expect(response.parsed_body["badge_options"]).to include(
        "id" => level_badge.id,
        "name" => level_badge.name,
      )
    end
  end

  describe "GET /academy-roles/admin/activity-levels/deletion-impact" do
    it "names global and per-frame references before a level may be removed" do
      frame = Fabricate(:avatar_frame, minimum_activity_level_id: "reader")
      sign_in(admin)

      get "/academy-roles/admin/activity-levels/deletion-impact.json",
          params: {
            level_id: "reader",
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["references"]).to contain_exactly(
        I18n.t("academy_roles.activity_cosmetics.references.avatar_minimum_level_id"),
        I18n.t("academy_roles.activity_cosmetics.references.name_color_minimum_level_id"),
        frame.name,
      )
    end

    it "rejects confirmed deletion while a frame still references the level" do
      frame = Fabricate(:avatar_frame, minimum_activity_level_id: "regular")
      configuration = DiscourseAcademyRoles::ActivityLevels::Configuration.current
      changed = configuration.document.deep_dup
      changed["levels"].pop
      sign_in(admin)

      expect do
        put "/academy-roles/admin/activity-levels.json",
            params: changed.merge("confirmed_deleted_ids" => ["regular"]),
            as: :json
      end.not_to change { Jobs::AcademyRecalculateActivityLevels.jobs.size }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"].join).to include(frame.name)
      expect(DiscourseAcademyRoles::ActivityLevels::Configuration.current.revision).to eq(
        configuration.revision,
      )
    end
  end

  describe "PUT /u/:username" do
    it "unlocks the fixed preset at its threshold without granting custom color access" do
      assign_activity_level(member, identifier: "reader", number: 1)
      sign_in(member)

      put "/u/#{member.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]).to include(
        "academy_display_name_color" => "level_preset",
        "academy_can_wear_name_color" => true,
        "academy_can_customize_name_color" => false,
      )
      expect(member.reload.custom_fields[DiscourseAcademyRoles::NameColor::ENABLED_FIELD]).to eq(
        true,
      )

      put "/u/#{member.username}.json", params: { custom_fields: { academy_name_color: "#111111" } }

      expect(response.status).to eq(403)
      expect(member.reload.custom_fields[DiscourseAcademyRoles::NameColor::COLOR_FIELD]).to be_blank
    end

    it "rejects enabling the color below the threshold even with forged capability fields" do
      sign_in(member)

      put "/u/#{member.username}.json",
          params: {
            academy_can_wear_name_color: true,
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }

      expect(response.status).to eq(403)
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::NameColor::ENABLED_FIELD],
      ).not_to eq(true)
    end

    it "preserves a paused color choice during unrelated profile saves and restores it after recovery" do
      assign_activity_level(member, identifier: "reader", number: 1)
      sign_in(member)
      put "/u/#{member.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }
      expect(response.status).to eq(200)
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      put "/u/#{member.username}.json",
          params: {
            bio_raw: "Updated profile",
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["academy_display_name_color"]).to be_nil
      expect(member.reload.custom_fields[DiscourseAcademyRoles::NameColor::ENABLED_FIELD]).to eq(
        true,
      )
      expect(member.user_profile.bio_raw).to eq("Updated profile")

      assign_activity_level(member, identifier: "reader", number: 1)
      get "/u/#{member.username}.json"

      expect(response.parsed_body["user"]["academy_display_name_color"]).to eq("level_preset")
    end

    it "keeps developer custom colors and moderator theme colors below the LV gate" do
      sign_in(admin)
      put "/u/#{admin.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
              academy_name_color: "#abc",
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["academy_display_name_color"]).to eq("#aabbcc")

      sign_in(moderator)
      put "/u/#{moderator.username}.json",
          params: {
            custom_fields: {
              academy_name_color_enabled: true,
            },
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["academy_display_name_color"]).to eq("theme")
    end

    it "requires both a frame grant and level access before changing the selection" do
      frame = Fabricate(:avatar_frame, minimum_activity_level_id: "regular")
      Fabricate(:avatar_frame_grant, frame: frame, user: member)
      assign_activity_level(member, identifier: "reader", number: 1)
      sign_in(member)

      put "/u/#{member.username}.json", params: { custom_fields: { avatar_frame: frame.key } }
      expect(response.status).to eq(422)

      assign_activity_level(member, identifier: "regular", number: 2)
      put "/u/#{member.username}.json", params: { custom_fields: { avatar_frame: frame.key } }

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["avatar_frame"]).to eq(frame.key)
    end

    it "preserves a locked frame while allowing unrelated saves and displays it after recovery" do
      frame = Fabricate(:avatar_frame, access_mode: "public")
      assign_activity_level(member, identifier: "reader", number: 1)
      sign_in(member)
      put "/u/#{member.username}.json", params: { custom_fields: { avatar_frame: frame.key } }
      expect(response.status).to eq(200)
      assign_activity_level(member, identifier: "legacy-0", number: 0)

      put "/u/#{member.username}.json",
          params: {
            bio_raw: "Retained frame",
            custom_fields: {
              avatar_frame: frame.key,
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["avatar_frame"]).to be_nil
      expect(member.reload.custom_fields[DiscourseAvatarFrames::FIELD]).to eq(frame.key)

      assign_activity_level(member, identifier: "reader", number: 1)
      get "/u/#{member.username}.json"
      expect(response.parsed_body["user"]["avatar_frame"]).to eq(frame.key)
    end
  end

  describe "GET /u/:username" do
    it "keeps private capabilities and ownership catalogs restricted to their owner" do
      sign_in(member)
      get "/u/#{other_member.username}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["user"].keys).not_to include(
        "academy_activity_cosmetics",
        "academy_name_color_preferences",
        "owned_avatar_frames",
      )

      get "/u/#{member.username}.json"
      expect(response.parsed_body["user"]["academy_activity_cosmetics"]["name_color"]).to include(
        "configured" => true,
        "unlocked" => false,
      )
    end

    it "publishes only configured preset colors and level labels at the site boundary" do
      get "/site.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["academy_activity_name_colors"]).to eq(
        "light" => "#a51b81",
        "dark" => "#f67cda",
      )
      expect(response.parsed_body["academy_activity_levels"].last).to eq(
        "id" => "regular",
        "number" => 2,
        "name" => "",
      )
    end
  end
end
