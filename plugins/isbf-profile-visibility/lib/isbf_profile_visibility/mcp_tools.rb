# frozen_string_literal: true

module IsbfProfileVisibility
  module McpUser
    def call(arguments:, request_context:)
      result = super
      user = User.find_by_username(arguments.fetch("username"))
      return result unless user && request_context.guardian.profile_section_hidden?(user, :bio)

      DiscourseMcp::ToolHelpers.text_and_structured(result[:structuredContent].merge(bio: ""))
    end
  end

  module McpSummary
    def call(arguments:, request_context:)
      user = User.find_by_username(arguments.fetch("username"))
      if user && request_context.guardian.profile_section_hidden?(user, :summary)
        raise DiscourseMcp::ToolError, I18n.t("mcp.errors.user_not_found")
      end

      super
    end
  end
end
