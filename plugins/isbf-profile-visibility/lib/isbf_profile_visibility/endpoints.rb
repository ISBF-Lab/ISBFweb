# frozen_string_literal: true

module IsbfProfileVisibility
  module SummaryEndpoint
    private

    # The page itself still loads, so the client can move to a section that is public.
    def isbf_ensure_summary_visible
      return unless request.format.json?

      user = fetch_user_from_params(include_inactive: true)
      raise Discourse::NotFound if guardian.profile_section_hidden?(user, :summary)
    end

    # Summaries are cached per viewer; whether activity links show is part of the result.
    def summary_cache_key(user)
      "#{super}:#{guardian.can_see_user_actions?(user, [])}"
    end
  end

  module ActivityEndpoint
    private

    def isbf_ensure_activity_visible
      user = fetch_user_from_params(include_inactive: true)
      raise Discourse::NotFound if guardian.profile_section_hidden?(user, :activity)
    end
  end
end
