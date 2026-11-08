# frozen_string_literal: true

module ::IsbfGuides
  class Publish
    include Service::Base

    params do
      attribute :guide_id, :integer
      attribute :version, :integer
      validates :guide_id, :version, presence: true
    end

    policy :can_manage
    try ActiveRecord::RecordInvalid do
      transaction do
        model :guide
        policy :current_version
        policy :has_draft
        step :publish_revision
      end
    end

    private

    def can_manage(guardian:)
      guardian.can_manage_isbf_guides?
    end

    def fetch_guide(params:)
      Guide.lock.find_by(id: params.guide_id)
    end

    def current_version(guide:, params:)
      guide.lock_version == params.version
    end

    def has_draft(guide:)
      guide.draft_revision.present? && guide.draft_revision.valid?
    end

    def publish_revision(guide:, guardian:)
      published = guide.draft_revision
      published.update!(published_at: Time.current)
      draft = guide.revisions.create!(published.content_attributes.merge(editor: guardian.user))
      guide.update!(
        published_revision: published,
        draft_revision: draft,
        first_published_at: guide.first_published_at || published.published_at,
      )
    end
  end
end
