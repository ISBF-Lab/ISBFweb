# frozen_string_literal: true

module DiscourseAvatarFrames
  class UploadCreator < ::UploadCreator
    Pair = Data.define(:image_upload, :static_upload, :suggested_calibration)

    def self.create_pair(file, actor)
      png = Png.new(file.tempfile)
      suggested_calibration = ImageAnalysis.call(png)
      image = new(file.tempfile, file.original_filename, png).create_for(actor.id)
      raise Png::Invalid, image.errors.full_messages.join(". ") if image.errors.present?

      return Pair.new(image, image, suggested_calibration) unless png.animated?

      Tempfile.create(%w[avatar-frame-static .png]) do |static_file|
        static_file.binmode
        static_file.write(png.static_data)
        static_file.flush
        still =
          new(static_file, "avatar-frame-static.png", Png.new(static_file)).create_for(actor.id)
        raise Png::Invalid, still.errors.full_messages.join(". ") if still.errors.present?
        Pair.new(image, still, suggested_calibration)
      end
    end

    def initialize(file, filename, png)
      @avatar_frame_png = png
      super(file, filename, type: "avatar_frame", origin: "avatar-frame")
    end

    private

    # APNG control chunks are removed by the generic PNG optimizer.
    def should_optimize?
      false
    end

    def should_downsize?
      false
    end

    def convert_png_to_jpeg?
      false
    end

    def animated?
      @avatar_frame_png.animated?
    end
  end
end
