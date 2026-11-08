# frozen_string_literal: true

module ::IsbfGuides
  class UploadImage
    include Service::Base

    params do
      attribute :guide_id, :integer
      validates :guide_id, presence: true
    end

    options { attribute :file }

    policy :can_manage
    model :guide
    policy :valid_upload
    model :image, :create_image

    private

    def can_manage(guardian:)
      guardian.can_manage_isbf_guides?
    end

    def fetch_guide(params:)
      Guide.find_by(id: params.guide_id)
    end

    def valid_upload(options:)
      file = options.file
      file.is_a?(ActionDispatch::Http::UploadedFile) && file.size.positive? &&
        file.size <=
          [SiteSetting.max_image_size_kb.kilobytes, 10.megabytes].select(&:positive?).min &&
        File.extname(file.original_filename.to_s).downcase.in?(%w[.jpg .jpeg .png .webp .gif])
    end

    def create_image(guide:, guardian:, options:)
      file = options.file
      file.rewind
      guide.images.create(
        creator: guardian.user,
        filename: "#{SecureRandom.hex(16)}#{File.extname(file.original_filename).downcase}",
        data: file.read,
      )
    end
  end
end
