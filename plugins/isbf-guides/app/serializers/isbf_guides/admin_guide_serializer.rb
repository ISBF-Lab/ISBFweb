# frozen_string_literal: true

module ::IsbfGuides
  class AdminGuideSerializer < ::ApplicationSerializer
    attributes :id, :slug, :url, :version, :published, :slug_locked, :has_changes

    has_one :draft, serializer: AdminRevisionSerializer, embed: :objects
    has_one :publication, serializer: AdminRevisionSerializer, embed: :objects

    def version
      object.lock_version
    end

    def published
      object.published?
    end

    def slug_locked
      object.first_published_at.present?
    end

    def has_changes
      object.has_changes?
    end

    def draft
      object.draft_revision
    end

    def publication
      object.published_revision
    end
  end
end
