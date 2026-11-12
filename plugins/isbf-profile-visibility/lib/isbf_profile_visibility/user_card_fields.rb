# frozen_string_literal: true

module IsbfProfileVisibility
  module UserCardFields
    def include_featured_topic?
      super && !scope.profile_section_hidden?(object, :bio)
    end

    def include_time_read?
      super && !scope.profile_section_hidden?(object, :summary)
    end

    def include_recent_time_read?
      super && !scope.profile_section_hidden?(object, :summary)
    end
  end
end
