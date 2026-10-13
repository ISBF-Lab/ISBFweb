# frozen_string_literal: true

module DiscourseAvatarFrames
  class UploadFrame
    include Service::Base

    policy :can_manage

    params do
      attribute :file
      validates :file, presence: true
    end

    model :images, :upload_images

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def upload_images(params:, guardian:)
      UploadCreator.create_pair(params.file, guardian.user)
    end
  end
end
