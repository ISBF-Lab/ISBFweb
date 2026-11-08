# frozen_string_literal: true

module ::IsbfGuides
  class SaveDraft
    include Service::Base

    params do
      attribute :guide_id, :integer
      attribute :version, :integer
      attribute :slug, :string
      attribute :title, :string
      attribute :summary, :string, default: ""
      attribute :raw, :string

      validates :slug, presence: true, format: { with: Guide::SLUG_FORMAT }, length: { maximum: 80 }
      validates :title, presence: true, length: { maximum: 200 }
      validates :summary, length: { maximum: 1000 }
      validates :raw, length: { maximum: 200_000 }, allow_nil: true
      validates :raw, presence: true, unless: -> { guide_id.present? }
      validates :version, presence: true, if: -> { guide_id.present? }
    end

    options { attribute :anchors }

    policy :can_manage
    try ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique do
      transaction do
        model :guide, :find_or_create_guide
        policy :current_version
        step :save_revision
      end
    end

    private

    def can_manage(guardian:)
      guardian.can_manage_isbf_guides?
    end

    def find_or_create_guide(params:)
      return Guide.lock.find_by(id: params.guide_id) if params.guide_id
      Guide.create(slug: params.slug)
    end

    def current_version(guide:, params:)
      params.guide_id.blank? || guide.lock_version == params.version
    end

    def save_revision(guide:, params:, guardian:, options:)
      previous_url = guide.url
      guide.slug = params.slug
      guide.save!
      revision = guide.draft_revision || guide.revisions.build
      revision.assign_attributes(
        title: params.title,
        summary: params.summary,
        raw:
          (
            if params.raw.nil? && revision.content_format == "html"
              revision.source_at_url(previous_url:, url: guide.url)
            else
              params.raw
            end
          ),
        editor: guardian.user,
      )
      revision.anchors = options.anchors if options.anchors
      revision.save!
      guide.update!(draft_revision: revision, updated_at: Time.current)
    end
  end
end
