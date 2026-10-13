# frozen_string_literal: true

module DiscourseAvatarFrames
  class ImportSerializer < ::ApplicationSerializer
    attributes :id,
               :frame_id,
               :status,
               :matched_count,
               :unmatched_count,
               :duplicate_count,
               :processed_count,
               :granted_count,
               :skipped_count,
               :failed_count,
               :unmatched_entries,
               :failures,
               :created_at
  end
end
