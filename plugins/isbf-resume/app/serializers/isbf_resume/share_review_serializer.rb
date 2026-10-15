# frozen_string_literal: true

module IsbfResume
  class ShareReviewSerializer < ApplicationSerializer
    attributes :id,
               :reviewer_id,
               :reviewer_name,
               :reviewer_username,
               :decision,
               :original_description,
               :previous_description,
               :description,
               :created_at
  end
end
