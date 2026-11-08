# frozen_string_literal: true

module ::IsbfGuides
  class Guide < ActiveRecord::Base
    self.table_name = "isbf_guides_guides"

    SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    RESERVED_SLUGS = %w[admin api new images].freeze

    belongs_to :draft_revision, class_name: "IsbfGuides::Revision", optional: true
    belongs_to :published_revision, class_name: "IsbfGuides::Revision", optional: true
    has_many :revisions, class_name: "IsbfGuides::Revision", dependent: :destroy
    has_many :images, class_name: "IsbfGuides::Image", dependent: :destroy

    validates :slug,
              presence: true,
              uniqueness: true,
              length: {
                maximum: 80,
              },
              format: {
                with: SLUG_FORMAT,
              },
              exclusion: {
                in: RESERVED_SLUGS,
              }
    validate :preserve_published_slug

    scope :published, -> { where.not(published_revision_id: nil) }

    def published?
      published_revision_id.present?
    end

    def has_changes?
      draft_revision&.content_digest != published_revision&.content_digest
    end

    def url
      "/guides/#{slug}"
    end

    def stage_document!(document:, actor:, slug:, title:, summary:)
      previous_url = url
      self.slug = slug
      save!
      mapping = {}
      available_images = images.select(:id, :guide_id, :filename, :sha256).to_a
      document.image_sources.each do |source|
        asset = document.asset_for(source)
        image =
          if asset
            available_images.find { |existing| existing.sha256 == asset.sha256 } ||
              images.create!(
                creator: actor,
                filename: "#{SecureRandom.hex(16)}#{asset.extension}",
                data: asset.data,
              )
          else
            available_images.find do |existing|
              source == "#{url}/images/#{existing.filename}" ||
                source == "#{previous_url}/images/#{existing.filename}"
            end
          end
        raise DocumentError.new(:missing_image, path: source.truncate(160)) unless image
        available_images << image if available_images.exclude?(image)
        mapping[source] = "#{url}/images/#{image.filename}"
      end
      revision =
        revisions.create!(
          editor: actor,
          title:,
          summary:,
          raw: document.html_with_images(mapping),
          content_format: "html",
        )
      update!(draft_revision: revision, updated_at: Time.current)
    end

    private

    def preserve_published_slug
      if first_published_at.present? && slug_changed?
        errors.add(:slug, I18n.t("isbf_guides.errors.fixed_slug"))
      end
    end
  end
end

# == Schema Information
#
# Table name: isbf_guides_guides
#
#  id                    :bigint           not null, primary key
#  first_published_at    :datetime
#  lock_version          :integer          default(0), not null
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  draft_revision_id     :bigint
#  published_revision_id :bigint
#
# Indexes
#
#  index_isbf_guides_guides_on_slug  (slug) UNIQUE
#
