# frozen_string_literal: true

module DiscourseAvatarFrames
  class UploadPairSerializer < ::ApplicationSerializer
    attributes :suggested_calibration
    has_one :image_upload, serializer: ::UploadSerializer, embed: :object
    has_one :static_upload, serializer: ::UploadSerializer, embed: :object

    def suggested_calibration
      object.suggested_calibration
    end
  end
end
