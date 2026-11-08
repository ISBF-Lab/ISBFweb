# frozen_string_literal: true

module ::IsbfGuides
  class AdminRevisionSerializer < ::ApplicationSerializer
    attributes :id, :title, :summary, :raw, :published_at, :updated_at, :content_format
  end
end
