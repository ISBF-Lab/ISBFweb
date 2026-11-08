# frozen_string_literal: true

require "fastimage"
require "stringio"

module ::IsbfGuides
  class Image < ActiveRecord::Base
    self.table_name = "isbf_guides_images"

    IMAGE_TYPES = {
      jpeg: "image/jpeg",
      png: "image/png",
      webp: "image/webp",
      gif: "image/gif",
    }.freeze
    FILENAME_FORMAT = /\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,150}\.(?:jpe?g|png|webp|gif)\z/

    belongs_to :guide, class_name: "IsbfGuides::Guide"
    belongs_to :creator, class_name: "User"

    validates :filename, format: { with: FILENAME_FORMAT }, uniqueness: { scope: :guide_id }
    validate :valid_image
    before_validation :inspect_image, on: :create

    def url
      "#{guide.url}/images/#{filename}"
    end

    private

    def inspect_image
      limit = [SiteSetting.max_image_size_kb.kilobytes, 10.megabytes].select(&:positive?).min
      return if data.blank? || data.bytesize > limit

      image = FastImage.new(StringIO.new(data))
      self.content_type = IMAGE_TYPES[image.type]
      self.width, self.height = image.size
      self.sha256 = Digest::SHA256.hexdigest(data)
    rescue StandardError
      self.content_type = nil
    end

    def valid_image
      unless content_type.in?(IMAGE_TYPES.values) && width.to_i.positive? &&
               height.to_i.positive? && width.to_i * height.to_i <= 50_000_000 && sha256.present?
        errors.add(:base, I18n.t("isbf_guides.errors.invalid_image"))
      end
    end
  end
end

# == Schema Information
#
# Table name: isbf_guides_images
#
#  id           :bigint           not null, primary key
#  content_type :string           not null
#  data         :binary           not null
#  filename     :string           not null
#  height       :integer          not null
#  sha256       :string           not null
#  width        :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  creator_id   :bigint           not null
#  guide_id     :bigint           not null
#
# Indexes
#
#  index_isbf_guides_images_on_guide_id_and_filename  (guide_id,filename) UNIQUE
#
