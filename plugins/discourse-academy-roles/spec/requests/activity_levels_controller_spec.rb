# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::ActivityLevelsController do
  include ActivityLevelsSpecHelpers

  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

  describe "#show" do
    it "returns initial rules and their catalog without writing configuration" do
      sign_in(admin)

      expect { get "/academy-roles/admin/activity-levels.json" }.not_to change(
        PluginStoreRow,
        :count,
      )

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "revision" => 0,
        "initialized" => false,
        "allow_demotion" => true,
        "minimum_continuous_check_gap_hours" => 36,
      )
      expect(response.parsed_body["levels"].map { |level| level["number"] }).to eq([0, 1, 2, 3, 4])
      expect(response.parsed_body["catalog"].map { |metric| metric["key"] }).to include(
        "posts_read",
        "penalty_count",
        "topics_viewed_percent",
      )
    end

    it "requires developer access even when moderators may manage ordinary users" do
      get "/academy-roles/admin/activity-levels.json"
      expect(response.status).to eq(403)

      SiteSetting.academy_moderators_access_user_admin = true
      [member, moderator].each do |actor|
        sign_in(actor)
        get "/academy-roles/admin/activity-levels.json"
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#update" do
    it "saves a configuration and returns a queued recalculation" do
      sign_in(admin)
      document = DiscourseAcademyRoles::ActivityLevels::Configuration.defaults

      put "/academy-roles/admin/activity-levels.json",
          params: document.merge("confirmed_deleted_ids" => []),
          as: :json

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("revision" => 1, "initialized" => true)
      expect(response.parsed_body["recalculation"]).to include(
        "status" => "queued",
        "revision" => 1,
      )
      expect(Jobs::AcademyRecalculateActivityLevels.jobs.last["args"].first["run_id"]).to eq(
        response.parsed_body["recalculation"]["id"],
      )
    end

    it "returns 409 for a stale revision and keeps the first save" do
      sign_in(admin)
      document = DiscourseAcademyRoles::ActivityLevels::Configuration.defaults
      persist_activity_rules(document)

      expect do
        put "/academy-roles/admin/activity-levels.json",
            params: document.merge("confirmed_deleted_ids" => []),
            as: :json
      end.not_to change { Jobs::AcademyRecalculateActivityLevels.jobs.size }

      expect(response.status).to eq(409)
      expect(DiscourseAcademyRoles::ActivityLevels::Configuration.current.revision).to eq(1)
    end

    it "returns 422 for invalid conditions without saving" do
      sign_in(admin)
      document =
        activity_rules(
          levels: [
            activity_tier(
              identifier: "reader",
              conditions: [activity_condition("arbitrary_expression", 1)],
            ),
          ],
        )

      expect do
        put "/academy-roles/admin/activity-levels.json", params: document, as: :json
      end.not_to change(PluginStoreRow, :count)

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "requires confirmation before deleting an assigned level and then reassigns its users" do
      sign_in(admin)
      configuration =
        persist_activity_rules(
          activity_rules(
            allow_demotion: false,
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 30)],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "reader", number: 1)
      document = configuration.document.deep_dup
      document["levels"].pop

      put "/academy-roles/admin/activity-levels.json",
          params: document.merge("confirmed_deleted_ids" => []),
          as: :json
      expect(response.status).to eq(422)

      put "/academy-roles/admin/activity-levels.json",
          params: document.merge("confirmed_deleted_ids" => ["reader"]),
          as: :json
      expect(response.status).to eq(200)
      expect(response.parsed_body["levels"].map { |level| level["number"] }).to eq([0])

      Jobs::AcademyRecalculateActivityLevels.new.execute(
        run_id: response.parsed_body["recalculation"]["id"],
      )
      expect(
        member.reload.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD],
      ).to eq("legacy-0")
    end

    it "rejects ordinary users and moderators without queueing changes" do
      document = DiscourseAcademyRoles::ActivityLevels::Configuration.defaults
      [member, moderator].each do |actor|
        sign_in(actor)

        expect do
          put "/academy-roles/admin/activity-levels.json", params: document, as: :json
        end.not_to change(PluginStoreRow, :count)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#deletion_impact" do
    it "returns an assignment count and revision without exposing account identities" do
      sign_in(admin)
      configuration =
        persist_activity_rules(
          activity_rules(
            levels: [
              activity_tier(
                identifier: "reader",
                conditions: [activity_condition("posts_read", 30)],
              ),
            ],
          ),
        )
      assign_activity_level(member, identifier: "reader", number: 1)

      get "/academy-roles/admin/activity-levels/deletion-impact.json",
          params: {
            level_id: "reader",
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq(
        "revision" => configuration.revision,
        "level_id" => "reader",
        "assigned_users" => 1,
        "references" => [],
      )
    end

    it "returns 404 for an absent level and 403 for moderators" do
      sign_in(admin)
      get "/academy-roles/admin/activity-levels/deletion-impact.json",
          params: {
            level_id: "absent",
          }
      expect(response.status).to eq(404)

      sign_in(moderator)
      get "/academy-roles/admin/activity-levels/deletion-impact.json",
          params: {
            level_id: "legacy-1",
          }
      expect(response.status).to eq(403)
    end
  end

  describe "#status" do
    it "returns only public progress counters to the developer" do
      sign_in(admin)
      persist_activity_rules(DiscourseAcademyRoles::ActivityLevels::Configuration.defaults)

      get "/academy-roles/admin/activity-levels/recalculation.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["recalculation"]).to include(
        "status" => "queued",
        "processed" => 0,
      )
      expect(response.parsed_body["recalculation"].keys).to contain_exactly(
        "id",
        "revision",
        "status",
        "processed",
        "total",
        "upgraded",
        "downgraded",
        "unchanged",
        "failed",
        "started_at",
        "completed_at",
        "error",
      )
    end

    it "rejects moderator access" do
      sign_in(moderator)
      get "/academy-roles/admin/activity-levels/recalculation.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#recalculate" do
    it "queues an initialized rule set with a 202 response" do
      sign_in(admin)
      persist_activity_rules(DiscourseAcademyRoles::ActivityLevels::Configuration.defaults)

      post "/academy-roles/admin/activity-levels/recalculate.json"

      expect(response.status).to eq(202)
      expect(response.parsed_body["recalculation"]).to include(
        "revision" => 1,
        "status" => "queued",
      )
    end

    it "requires initialized rules and developer access" do
      sign_in(admin)
      post "/academy-roles/admin/activity-levels/recalculate.json"
      expect(response.status).to eq(422)

      sign_in(moderator)
      post "/academy-roles/admin/activity-levels/recalculate.json"
      expect(response.status).to eq(403)
    end
  end
end
