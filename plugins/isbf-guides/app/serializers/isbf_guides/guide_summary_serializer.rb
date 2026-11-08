# frozen_string_literal: true

module ::IsbfGuides
  class GuideSummarySerializer < ::ApplicationSerializer
    attributes :id, :slug, :url, :title, :summary, :updated_at

    def title
      revision.title
    end

    def summary
      revision.summary
    end

    def updated_at
      revision.published_at || revision.updated_at
    end

    private

    def revision
      @options[:preview] ? object.draft_revision : object.published_revision
    end
  end
end
