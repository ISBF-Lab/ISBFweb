# frozen_string_literal: true

module IsbfMbti
  class ResultSerializer < ApplicationSerializer
    attributes :id, :variant, :version, :source_commit, :type, :scores, :dimensions, :created_at

    def version
      object.scoring_version
    end

    def type
      object.personality_type
    end
  end
end
