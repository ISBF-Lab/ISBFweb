# frozen_string_literal: true

module IsbfCalendar
  class Entry < ActiveRecord::Base
    self.table_name = "isbf_calendar_entries"

    belongs_to :user

    validates :title, presence: true, length: { maximum: 120 }
    validates :note, length: { maximum: 2000 }
    validates :starts_at, :ends_at, presence: true
    validate :ends_after_start

    private

    def ends_after_start
      return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

      errors.add(:ends_at, "must be after the start")
    end
  end
end
