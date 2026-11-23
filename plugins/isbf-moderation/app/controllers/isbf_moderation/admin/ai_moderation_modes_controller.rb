# frozen_string_literal: true

module IsbfModeration
  module Admin
    class AiModerationModesController < ::Admin::AdminController
      requires_plugin "isbf-moderation"
      wrap_parameters false

      def show
        render json: AiModes.response
      rescue AiModes::InvalidConfiguration
        render_invalid_configuration
      end

      def update
        input = params.except(:controller, :action, :format).to_unsafe_h
        render json: AiModes.save!(input, guardian: guardian)
      rescue AiModes::Conflict
        render_json_error(I18n.t("isbf_moderation.ai.modes.conflict"), status: 409)
      rescue AiModes::InvalidConfiguration
        render_invalid_configuration
      end

      private

      def render_invalid_configuration
        render_json_error(
          I18n.t("isbf_moderation.ai.modes.invalid", maximum: AiModes::MAX_POLICY_LENGTH),
          status: 422,
        )
      end
    end
  end
end
