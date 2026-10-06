# frozen_string_literal: true

module IsbfCalendar
  class PublishOfficialItems
    include Service::Base

    params do
      attribute :items
      validates :items, length: { maximum: MAX_OFFICIAL_ITEMS }

      validate do
        unless items.is_a?(Array) && items.all? { |item| item.is_a?(Hash) }
          errors.add(:items, :invalid)
        end
      end
    end

    policy :can_publish

    transaction do
      step :lock_topic
      try ArgumentError do
        step :prepare_items
      end
      step :save_items
    end

    private

    def can_publish(topic:, guardian:)
      IsbfCalendar.official_topic?(topic) && guardian.user &&
        (
          guardian.is_staff? ||
            DiscourseAcademyRoles.official_member?(guardian.user)
        ) && (!topic.persisted? || guardian.can_edit?(topic.first_post))
    end

    def lock_topic(topic:)
      Topic.where(id: topic.id).lock.pick(:id) if topic.persisted?
    end

    def prepare_items(topic:, params:)
      existing =
        topic.persisted? ? OfficialItem.where(topic_id: topic.id).to_a : []
      context[:before_items] = existing
        .reject(&:cancelled?)
        .map { |item| item.snapshot.as_json.merge("id" => item.id) }
      existing_by_id = existing.index_by(&:id)
      used_ids = Set.new
      context[:items] = params.items.each_with_index.map do |payload, position|
        item =
          if payload[:id].present?
            id = payload[:id]
            raise ArgumentError unless id.is_a?(Integer) && used_ids.add?(id)
            record = existing_by_id.fetch(id) { raise ArgumentError }
            if record.cancelled? || payload[:revision] != record.revision
              raise ArgumentError
            end
            record
          else
            topic.isbf_official_calendar_items.build
          end
        item.assign_attributes(
          OfficialItem.attributes_from_payload(payload).merge(position:)
        )
        fail! unless item.valid?
        item
      end
      context[:removed_items] = existing
        .reject(&:cancelled?)
        .reject { |item| used_ids.include?(item.id) }
    end

    def save_items(topic:, items:, removed_items:)
      if topic.persisted?
        items.each(&:save!)
        removed_items.each { |item| item.update!(cancelled: true) }
        topic.association(:isbf_official_calendar_items).reset
      end
      context[:after_items] = items.map do |item|
        item.snapshot.as_json.merge("id" => item.id)
      end
    end
  end
end
