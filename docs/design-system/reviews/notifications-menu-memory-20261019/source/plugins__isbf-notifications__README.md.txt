# ISBF Notifications

Groups existing Discourse notifications by topic and action. No tables, migrations,
notification delivery changes, or Core edits. Enable `isbf_notifications_enabled`
after installing the matching ISBF-UI theme.

Authenticated read APIs:

- `GET /isbf/notifications/groups.json?tab=all|mentions&filter=all|unread`: complete topic groups and
  standalone native notices, ordered by latest notification; signed cursor pagination.
- `GET /isbf/notifications/groups/:topic_id/actions/:action.json`: lazy action details.
  `limit` defaults to 20 and is capped at 50.

Both APIs default to `filter=all`. Unread filtering runs before topic/action
grouping and applies to lazy details as well. Detail URLs carry the selected tab
and filter; signed cursors are bound to both. Existing cursors without a filter
remain valid for `all`.

The mentions tab includes mentions, group mentions, replies, and reactions.
Likes/reactions use existing surviving actions on posts referenced by the recipient's
notifications, capped at the notification timestamp, and deduplicate each person per
topic/action. Other actions retain the available native notification records.
Historical cross-topic summaries remain standalone. Purged events are not reconstructed.

Both APIs enforce recipient, topic, and post visibility. Expanding groups never marks
notifications read. Navigation and bulk marking remain native Discourse operations.
Disabling the setting restores the native notification page in the matching theme.

The private user custom field `isbf_notification_badge_style` accepts `number` or
`dot` through the native user update API. The current-user serializer supplies
`number` when no preference exists. The field is not published on public profiles.
The matching theme uses native grouped unread counters, rather than counters that
exclude already-seen notices, and retains native marking/navigation behavior.

The private user custom field `isbf_notification_filter` accepts `all` or `unread`
through the same user update API. It is serialized only for the current user and
defaults to `all`. The theme reads it before its first grouped request and applies
a new selection after a successful save. Both tabs share the preference; returning,
refreshing, or signing in on another device restores the saved selection. A failed
save preserves the previous selection and offers a retry in the notification menu.
