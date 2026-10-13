# frozen_string_literal: true

module IsbfCalendar
  class EntrySerializer < ApplicationSerializer
    attributes :id,
               :title,
               :starts_at,
               :ends_at,
               :all_day,
               :note,
               :schedule_kind,
               :source_item_id,
               :accepted_revision,
               :needs_update,
               :cancelled,
               :source_unavailable,
               :source_url,
               :latest_source

    def starts_at
      object.starts_at.iso8601
    end

    def ends_at
      object.ends_at.iso8601
    end

    def needs_update
      object.needs_update? && (source_visible? || cancelled)
    end

    def cancelled
      object.source_item&.cancelled? || false
    end

    def source_unavailable
      object.source_item_id.present? && !source_visible?
    end

    def source_url
      object.source_item.topic.relative_url if source_visible?
    end

    def latest_source
      item = object.source_item
      if source_visible?
        OfficialItemSerializer.new(item, scope:, root: false).as_json
      elsif cancelled
        { id: item.id, revision: item.revision, cancelled: true }
      end
    end

    private

    def source_visible?
      return @source_visible if defined?(@source_visible)
      @source_visible = object.source_item&.visible_to?(scope) || false
    end
  end
end
