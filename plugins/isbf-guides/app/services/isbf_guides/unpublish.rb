# frozen_string_literal: true

module ::IsbfGuides
  class Unpublish
    include Service::Base

    params do
      attribute :guide_id, :integer
      attribute :version, :integer
      validates :guide_id, :version, presence: true
    end

    policy :can_manage

    transaction do
      model :guide
      policy :current_version
      step :unpublish_guide
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

    def unpublish_guide(guide:)
      guide.update!(published_revision: nil)
    end
  end
end
