# frozen_string_literal: true

RSpec.describe IsbfModeration::Admin::AiModerationModesController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)

  let(:endpoint) { "/isbf/moderation/admin/ai-moderation-modes.json" }

  def category_update(category = "fraud")
    get endpoint
    response.parsed_body.fetch("categories").fetch(category).merge("category" => category)
  end

  describe "#show" do
    it "returns all editable defaults and revisions without initializing stored settings" do
      sign_in(admin)
      original_setting = SiteSetting.isbf_ai_moderation_modes

      expect { get endpoint }.not_to change(UserHistory, :count)

      expect(response.status).to eq(200)
      expect(SiteSetting.isbf_ai_moderation_modes).to eq(original_setting)
      document = response.parsed_body
      expect(document.fetch("max_policy_length")).to eq(2000)
      expect(document.fetch("defaults")).to eq(IsbfModeration::AiModes.defaults)
      expect(document.fetch("categories").keys).to contain_exactly(
        "fraud",
        "harassment",
        "privacy",
        "sexual",
      )
      document
        .fetch("categories")
        .each do |category, configuration|
          expect(configuration.fetch("active_level")).to eq("standard")
          expect(configuration.fetch("revision")).to be_present
          expect(configuration.fetch("profiles")).to eq(
            document.fetch("defaults").fetch(category).fetch("profiles"),
          )
        end
    end

    it "requires developer access for anonymous visitors, members and moderators" do
      get endpoint
      expect(response.status).to eq(403)
      [member, moderator].each do |actor|
        sign_in(actor)
        get endpoint
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#update" do
    it "atomically saves one category, records the developer and preserves the others" do
      sign_in(admin)
      document = category_update
      previous_revision = document.fetch("revision")
      previous_categories = response.parsed_body.fetch("categories").except("fraud")
      document["active_level"] = "strict"
      document["profiles"]["strict"] = {
        "policy" => "推广规则：课程群引流交人工复核。放行样例：正常资料分享。",
        "action" => "review_only",
      }
      document["profiles"]["lenient"]["policy"] = "备用规则：只复核明确诈骗。"

      expect { put endpoint, params: document, as: :json }.to change {
        UserHistory.where(
          action: UserHistory.actions[:change_site_setting],
          acting_user_id: admin.id,
        ).count
      }.by(1)

      expect(response.status).to eq(200)
      saved = response.parsed_body.fetch("categories").fetch("fraud")
      expect(saved.fetch("revision")).not_to eq(previous_revision)
      expect(saved.except("revision")).to eq(document.except("category", "revision"))
      expect(response.parsed_body.fetch("categories").except("fraud")).to eq(previous_categories)
      history =
        UserHistory
          .where(
            action: UserHistory.actions[:change_site_setting],
            acting_user_id: admin.id,
            subject: "isbf_ai_moderation_modes",
          )
          .order(:id)
          .last
      expect(JSON.parse(history.previous_value)).to eq(
        "category" => "fraud",
        "active_level" => "standard",
        "revision" => previous_revision,
      )
      expect(JSON.parse(history.new_value)).to eq(
        "category" => "fraud",
        "active_level" => "strict",
        "revision" => saved.fetch("revision"),
      )
      get endpoint
      expect(response.parsed_body.fetch("categories").fetch("fraud")).to eq(saved)
    end

    it "keeps an unchanged category save free of audit entries" do
      sign_in(admin)
      document = category_update
      stored = SiteSetting.isbf_ai_moderation_modes

      expect { put endpoint, params: document, as: :json }.not_to change(UserHistory, :count)

      expect(response.status).to eq(200)
      expect(SiteSetting.isbf_ai_moderation_modes).to eq(stored)
      expect(response.parsed_body.fetch("categories").fetch("fraud")).to eq(
        document.except("category"),
      )
    end

    it "rejects stale same-category changes and allows an independent category save" do
      sign_in(admin)
      first = category_update("fraud")
      stale = first.deep_dup
      independent = category_update("harassment")
      first["profiles"]["standard"]["policy"] = "第一位开发者保存的诈骗规则。"
      put endpoint, params: first, as: :json
      expect(response.status).to eq(200)
      stored = SiteSetting.isbf_ai_moderation_modes
      stale["profiles"]["standard"]["policy"] = "第二位开发者尚未保存的规则。"

      expect { put endpoint, params: stale, as: :json }.not_to change(UserHistory, :count)
      expect(response.status).to eq(409)
      expect(SiteSetting.isbf_ai_moderation_modes).to eq(stored)

      independent["active_level"] = "lenient"
      put endpoint, params: independent, as: :json
      expect(response.status).to eq(200)
      expect(
        response.parsed_body.dig("categories", "fraud", "profiles", "standard", "policy"),
      ).to eq(first.dig("profiles", "standard", "policy"))
      expect(response.parsed_body.dig("categories", "harassment", "active_level")).to eq("lenient")
    end

    it "rejects invalid policy documents without partially changing configuration" do
      sign_in(admin)
      valid = category_update
      invalid_documents = [
        valid.merge("category" => "unknown"),
        valid.merge("active_level" => "extreme"),
        valid.merge("profiles" => valid.fetch("profiles").except("strict")),
        valid.merge("unrecognized" => true),
      ]
      ["", "中" * 2001].each do |policy|
        document = valid.deep_dup
        document["profiles"]["standard"]["policy"] = policy
        invalid_documents << document
      end
      document = valid.deep_dup
      document["profiles"]["standard"]["action"] = "delete_post"
      invalid_documents << document
      document = valid.deep_dup
      document["profiles"]["standard"]["extra"] = true
      invalid_documents << document
      stored = SiteSetting.isbf_ai_moderation_modes

      invalid_documents.each do |invalid|
        expect { put endpoint, params: invalid, as: :json }.not_to change(UserHistory, :count)
        expect(response.status).to eq(422)
        expect(SiteSetting.isbf_ai_moderation_modes).to eq(stored)
      end
    end

    it "accepts the maximum policy length and restores an edited profile from defaults" do
      sign_in(admin)
      document = category_update("privacy")
      document["profiles"]["strict"]["policy"] = "中" * 2000
      document["profiles"]["strict"]["action"] = "review_only"
      put endpoint, params: document, as: :json
      expect(response.status).to eq(200)
      document =
        response.parsed_body.fetch("categories").fetch("privacy").merge("category" => "privacy")
      document["profiles"]["strict"] = IsbfModeration::AiModes
        .defaults
        .fetch("privacy")
        .fetch("profiles")
        .fetch("strict")

      put endpoint, params: document, as: :json

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("categories", "privacy", "profiles", "strict")).to eq(
        IsbfModeration::AiModes.defaults.dig("privacy", "profiles", "strict"),
      )
    end

    it "requires developer access before any policy can be saved" do
      document =
        IsbfModeration::AiModes
          .defaults
          .fetch("fraud")
          .merge("category" => "fraud", "revision" => "stale")
      stored = SiteSetting.isbf_ai_moderation_modes
      put endpoint, params: document, as: :json
      expect(response.status).to eq(403)
      [member, moderator].each do |actor|
        sign_in(actor)
        put endpoint, params: document, as: :json
        expect(response.status).to eq(403)
      end
      expect(SiteSetting.isbf_ai_moderation_modes).to eq(stored)
    end
  end
end
