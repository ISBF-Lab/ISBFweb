# frozen_string_literal: true

module ::IsbfGuides
  class GuideSerializer < GuideSummarySerializer
    attributes :cooked, :toc, :preview, :revision_id, :content_format

    def content_format
      revision.content_format
    end

    def revision_id
      revision.id
    end

    def cooked
      revision.cooked
    end

    def toc
      revision.toc
    end

    def preview
      @options[:preview] == true
    end
  end
end
