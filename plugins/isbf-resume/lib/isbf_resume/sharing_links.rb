# frozen_string_literal: true

require "uri"

module IsbfResume
  module SharingLinks
    MAX_LENGTH = 2048

    def self.valid?(value)
      return false unless value.is_a?(String) && value.length.between?(1, MAX_LENGTH)
      return false if value.match?(/[\\\s\x00-\x20<>]/)
      uri = URI.parse(value)
      !!(
        uri.scheme == "https" && uri.port == 443 && !uri.userinfo &&
          uri.host&.match?(/\A(?:[a-z0-9-]+\.)*(?:wps|kdocs)\.cn\z/i)
      )
    rescue URI::InvalidURIError
      false
    end

    def self.validate!(value)
      raise Discourse::InvalidParameters.new(:download_url) unless valid?(value)
      value
    end

    def self.valid_collection?(value)
      valid?(value) && URI.parse(value).host == "f.wps.cn" &&
        URI.parse(value).path.match?(%r{\A/g/[A-Za-z0-9_-]+/?\z})
    end
  end
end
