# frozen_string_literal: true

require "enum_site_setting"

module IsbfModeration
  module AiConfiguration
    def self.model(model_id = SiteSetting.isbf_ai_moderation_model)
      LlmModel.find_by(id: model_id.to_i) if defined?(LlmModel)
    end

    def self.error(model_id:, images_enabled:)
      unless defined?(DiscourseAi::Completions::Llm) && SiteSetting.discourse_ai_enabled
        return :unavailable
      end

      selected = model(model_id)
      return :model_required unless selected
      :vision_required if images_enabled && !selected.agent_image_capable?
    end

    def self.fingerprint
      selected = model
      Digest::SHA256.hexdigest(
        [
          SiteSetting.isbf_ai_moderation_enabled,
          SiteSetting.discourse_ai_enabled,
          selected&.id,
          selected&.updated_at&.iso8601(6),
          selected&.vision_llm_model&.updated_at&.iso8601(6),
          SiteSetting.isbf_ai_moderation_images_enabled,
          SiteSetting.isbf_ai_moderation_exempt_groups,
          AiClassifier::RULES_VERSION,
        ].to_json,
      )
    end
  end

  class AiModelEnumerator < ::EnumSiteSetting
    def self.valid_value?(_value)
      true
    end

    def self.values
      return [] unless defined?(LlmModel) && LlmModel.table_exists?
      LlmModel
        .order(:display_name)
        .pluck(:id, :display_name)
        .map { |id, name| { value: id.to_s, name: name } }
    end
  end

  class AiSettingsValidator
    def initialize(options = {})
      @name = options[:name].to_s
    end

    def valid_value?(value)
      enabled = proposed("isbf_ai_moderation_enabled", value)
      return true unless enabled

      @error =
        AiConfiguration.error(
          model_id: proposed("isbf_ai_moderation_model", value),
          images_enabled: proposed("isbf_ai_moderation_images_enabled", value),
        )
      @error.nil?
    end

    def error_message
      I18n.t("isbf_moderation.ai.configuration.#{@error}")
    end

    private

    def proposed(name, value)
      proposed = @name == name ? value : SiteSetting.public_send(name)
      name.end_with?("_enabled") ? [true, "t", "true"].include?(proposed) : proposed
    end
  end
end
