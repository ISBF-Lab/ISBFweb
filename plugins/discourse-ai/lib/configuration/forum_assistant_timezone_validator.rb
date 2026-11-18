# frozen_string_literal: true

module DiscourseAi
  module Configuration
    class ForumAssistantTimezoneValidator
      def initialize(opts = {})
      end

      def valid_value?(value)
        ActiveSupport::TimeZone[value].present?
      rescue ArgumentError, TZInfo::InvalidTimezoneIdentifier
        false
      end

      def error_message
        I18n.t("discourse_ai.forum_assistant.invalid_timezone")
      end
    end
  end
end
