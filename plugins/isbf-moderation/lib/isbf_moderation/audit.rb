# frozen_string_literal: true

module IsbfModeration
  module Audit
    KEY = "isbf_severe_report"

    def self.severe?(score)
      Array(score.reviewable.payload&.dig(Hold::SCORES)).include?(score.id)
    end

    def self.details(score)
      return unless severe?(score)
      JSON.parse(score.context.to_s)[KEY]
    rescue JSON::ParserError
      nil
    end

    def self.record!(score, reason, timestamp, original_resolution: nil)
      original_context = score.context
      details = {
        "reason" => reason,
        "submitted_at" => timestamp,
        "original_context" => original_context,
      }
      details["original_resolution"] = original_resolution if original_resolution
      score.update!(context: JSON.generate(KEY => details))
    end
  end
end
