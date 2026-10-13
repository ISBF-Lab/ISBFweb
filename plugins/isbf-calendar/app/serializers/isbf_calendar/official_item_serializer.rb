# frozen_string_literal: true

module IsbfCalendar
  class OfficialItemSerializer < ApplicationSerializer
    attributes :id,
               :title,
               :schedule_kind,
               :starts_at,
               :ends_at,
               :all_day,
               :location,
               :organizer,
               :registration_deadline_id,
               :revision,
               :cancelled,
               :timezone

    def starts_at
      object.starts_at.iso8601
    end

    def ends_at
      object.ends_at.iso8601
    end

    def timezone
      TIMEZONE
    end
  end
end
