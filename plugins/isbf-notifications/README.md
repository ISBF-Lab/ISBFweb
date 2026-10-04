# ISBF Notifications

Groups existing Discourse notifications by topic and action. No tables, migrations,
notification delivery changes, or Core edits. Enable `isbf_notifications_enabled`
after installing the matching ISBF-UI theme.

Authenticated read APIs:

- `GET /isbf/notifications/groups.json?tab=all|mentions`: complete topic groups and
  standalone native notices, ordered by latest notification; signed cursor pagination.
- `GET /isbf/notifications/groups/:topic_id/actions/:action.json`: lazy action details.
  `limit` defaults to 20 and is capped at 50.

The mentions tab includes mentions, group mentions, replies, and reactions.
Likes/reactions use existing surviving actions on posts referenced by the recipient's
notifications, capped at the notification timestamp, and deduplicate each person per
topic/action. Other actions retain the available native notification records.
Historical cross-topic summaries remain standalone. Purged events are not reconstructed.

Both APIs enforce recipient, topic, and post visibility. Expanding groups never marks
notifications read. Navigation and bulk marking remain native Discourse operations.
Disabling the setting restores the native notification page in the matching theme.
