# frozen_string_literal: true

module ::IsbfGuides
  class ImportDocument
    include Service::Base

    params do
      attribute :guide_id, :integer
      attribute :version, :integer
      attribute :slug, :string
      attribute :title, :string
      attribute :summary, :string, default: ""

      validates :slug, presence: true, format: { with: Guide::SLUG_FORMAT }, length: { maximum: 80 }
      validates :title, presence: true, length: { maximum: 200 }
      validates :summary, length: { maximum: 1000 }
      validates :version, presence: true, if: -> { guide_id.present? }
    end

    options { attribute :file }

    policy :can_manage
    policy :valid_upload
    try DocumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique do
      model :document, :prepare_document
      step :read_document

      transaction do
        model :guide, :find_or_create_guide
        policy :current_version
        step :stage_document
      end
    end

    private

    def can_manage(guardian:)
      guardian.can_manage_isbf_guides?
    end

    def valid_upload(options:)
      DocumentPackage.accepts?(options.file)
    end

    def prepare_document(options:)
      DocumentPackage.new(file: options.file)
    end

    def read_document(document:)
      document.read
    end

    def find_or_create_guide(params:)
      return Guide.lock.find_by(id: params.guide_id) if params.guide_id
      Guide.create(slug: params.slug)
    end

    def current_version(guide:, params:)
      params.guide_id.blank? || guide.lock_version == params.version
    end

    def stage_document(guide:, document:, guardian:, params:)
      guide.stage_document!(
        document:,
        actor: guardian.user,
        slug: params.slug,
        title: params.title,
        summary: params.summary,
      )
    end
  end
end
