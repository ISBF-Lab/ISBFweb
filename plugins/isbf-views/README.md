# ISBF Views

Counts each signed-in account once per topic when a feed card enters the viewport.
The displayed total combines feed impressions with existing Discourse topic-detail
view records, deduplicated by account. Discourse's own topic view counter remains
independent.

POST /isbf/views/impressions.json accepts topic_ids[] (up to 50) and returns
{ "counts": { "123": 4 } } for topics the current user may view.


POST /isbf/views/post-impressions.json accepts post_ids[] (1 to 50 positive
integer IDs) and returns the same counts shape for eligible replies only. Both
endpoints require login and the isbf_views_enabled setting.

Reply views use the independent isbf_post_view_impressions table: one lifetime
record per reply and signed-in account, shared across devices. A unique database
index and duplicate-skipping batch inserts prevent repeated or concurrent requests
from increasing that account's count. Counts begin when this feature is installed;
existing topic visits and topic impressions are not backfilled into reply counts.

Only visible, accessible regular-topic replies with a normal post type and
post_number greater than 1 are eligible. Original posts, deleted or hidden posts,
system posts, private messages, and inaccessible topics are omitted from both
storage and the response. Each candidate is checked with Discourse Guardian.
Reply counts do not change the existing topic endpoint or Discourse counters.
