# frozen_string_literal: true

module Jobs
  class IsbfCalendarNotifyChange < ::Jobs::Base
    def execute(args)
      item =
        IsbfCalendar::OfficialItem.includes(topic: :first_post).find_by(
          id: args[:item_id]
        )
      return unless item && item.revision == args[:revision]

      item
        .entries
        .includes(:user)
        .find_each do |entry|
          entry.with_lock do
            if [
                 entry.accepted_revision,
                 entry.dismissed_revision,
                 entry.notified_revision
               ].max >= item.revision
              next
            end
            next unless item.cancelled? || item.visible_to?(entry.user.guardian)
            Notification.create!(
              user_id: entry.user_id,
              notification_type: Notification.types[:custom],
              data: {
                message: "isbf_calendar.changed",
                entry_id: entry.id,
                source_item_id: item.id,
                revision: item.revision,
                topic_title: entry.title
              }.to_json,
              skip_send_email: true
            )
            entry.update!(notified_revision: item.revision)
          end
        end
    end
  end
end
