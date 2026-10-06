# frozen_string_literal: true

module IsbfCalendar
  class RespondToOfficialUpdate
    include Service::Base

    params do
      attribute :id, :integer
      attribute :revision, :integer
      attribute :accept, :boolean, default: false
      validates :id,
                :revision,
                numericality: {
                  only_integer: true,
                  greater_than: 0
                }
    end

    transaction do
      model :entry
      model :item
      policy :can_respond
      policy :current_revision
      step :respond
    end

    private

    def fetch_entry(params:, guardian:)
      return unless guardian.user
      Entry.find_by(id: params.id, user_id: guardian.user.id)
    end

    def fetch_item(entry:)
      OfficialItem
        .includes(topic: :first_post)
        .lock
        .find_by(id: entry.source_item_id)
    end

    def can_respond(item:, guardian:, params:)
      if params.accept
        !item.cancelled? && item.visible_to?(guardian)
      else
        item.cancelled? || item.visible_to?(guardian)
      end
    end

    def current_revision(item:, params:)
      item.revision == params.revision
    end

    def respond(entry:, item:, params:)
      entry.lock!
      if params.accept
        entry.update!(item.snapshot.merge(accepted_revision: item.revision))
      else
        entry.update!(dismissed_revision: item.revision)
      end
      entry.source_item = item
    end
  end
end
