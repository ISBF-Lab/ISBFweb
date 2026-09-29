# ISBF per-post anonymous publishing

This plugin uses Discourse's `AnonymousShadowCreator` for individual public topics
and replies. A request with `isbf_anonymous=true` is accepted only from an active
registered account allowed by `anonymous_posting_allowed_groups`. The request is
rejected for private messages, read-restricted categories, the configured
academy official category, and official posts. The server replaces the author
with the core shadow user; the public post only stores the boolean
`isbf_per_post_anonymous` custom field. The original account linkage remains in
Discourse's private `anonymous_users` table.

Marked posts cannot be edited or deleted by non-staff, including their shadow
account. The core full-session `/u/toggle-anon` route allows existing anonymous
sessions to exit but does not allow new ones. The owner can view marked posts
from every rotated shadow identity at `/isbf-anonymous/posts`; the underlying
`/isbf-anonymous/api/posts` endpoint requires login and returns only posts
belonging to the caller. Reply alerts and queued-post moderation feedback are
sent to the original account.

To enable this on a site, set `allow_anonymous_mode=true` and include automatic
group `10` (`trust_level_0`) in `anonymous_posting_allowed_groups`, along with
staff groups as needed. The ISBF Campus Feed theme supplies the composer
control and private list UI.
