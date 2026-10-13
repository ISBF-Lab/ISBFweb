# frozen_string_literal: true

module DiscourseAvatarFrames
  class Import < ActiveRecord::Base
    self.table_name = "discourse_avatar_frames_imports"

    belongs_to :frame, class_name: "DiscourseAvatarFrames::Frame"
    belongs_to :created_by, class_name: "::User"

    validates :status, inclusion: { in: %w[queued processing completed failed] }

    def finished?
      %w[completed failed].include?(status)
    end

    def self.from_csv(frame:, actor:, file:)
      csv = CsvRecipients.new(file)
      create(
        frame:,
        created_by: actor,
        user_ids: csv.user_ids,
        matched_count: csv.user_ids.length,
        unmatched_count: csv.unmatched_entries.length,
        unmatched_entries: csv.unmatched_entries.first(100),
        duplicate_count: csv.duplicate_count,
      )
    end
  end
end
