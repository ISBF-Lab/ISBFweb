# frozen_string_literal: true

require "zlib"

module DiscourseAvatarFrames
  class Png
    class Invalid < StandardError
    end

    SIGNATURE = "\x89PNG\r\n\x1a\n".b
    ANIMATION_CHUNKS = %w[acTL fcTL fdAT].freeze

    attr_reader :width, :height

    def initialize(file)
      @data = File.binread(file.path, SiteSetting.max_image_size_kb.kilobytes + 1)
      if @data.bytesize > SiteSetting.max_image_size_kb.kilobytes
        raise Invalid, I18n.t("avatar_frames.errors.image_too_large")
      end
      unless @data.start_with?(SIGNATURE)
        raise Invalid, I18n.t("avatar_frames.errors.invalid_image")
      end

      @chunks = []
      offset = SIGNATURE.bytesize
      while offset < @data.bytesize
        length = @data.byteslice(offset, 4)&.unpack1("N")
        unless length && length <= @data.bytesize - offset - 12
          raise Invalid, I18n.t("avatar_frames.errors.invalid_image")
        end
        chunk = @data.byteslice(offset, length + 12)
        kind = chunk.byteslice(4, 4)
        payload = chunk.byteslice(8, length)
        unless Zlib.crc32(kind + payload) == chunk.byteslice(-4, 4).unpack1("N")
          raise Invalid, I18n.t("avatar_frames.errors.invalid_image")
        end

        @chunks << [kind, payload, chunk]
        offset += length + 12
      end

      header = @chunks.first
      unless header&.first == "IHDR" && header[1].bytesize == 13 && @chunks.last&.first == "IEND" &&
               @chunks.any? { |entry| entry.first == "IDAT" }
        raise Invalid, I18n.t("avatar_frames.errors.invalid_image")
      end
      @width, @height = header[1].unpack("NN")
      unless width.positive? && width == height &&
               width * height <= SiteSetting.max_image_megapixels * 1_000_000
        raise Invalid, I18n.t("avatar_frames.errors.invalid_image")
      end
    end

    def animated?
      @chunks.any? { |kind, payload,| kind == "acTL" && payload.unpack1("N").to_i > 1 }
    end

    def static_data
      SIGNATURE + @chunks.reject { |kind,| ANIMATION_CHUNKS.include?(kind) }.map(&:last).join
    end
  end
end
