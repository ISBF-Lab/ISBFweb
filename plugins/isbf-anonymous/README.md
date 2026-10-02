# ISBF per-post anonymous publishing

The existing composer submits `isbf_anonymous=true` for public topics and
replies. The server checks the real account's activity, approval, suspension,
groups, permissions, trust restrictions, review requirements, and rate limits.
Private messages, restricted categories, unlisted topics, official posts, and
the configured academy official category cannot use anonymous publishing.
Non-staff cannot edit or delete marked posts. New full-session anonymous
sessions remain disabled; existing sessions can exit.

## Shared account pool

Enable `allow_anonymous_mode` and `isbf_anonymous_pool_enabled`, and configure
`anonymous_posting_allowed_groups` (automatic group `10` includes all members).
The pool has **256 slots by default**, configurable from 2 to 4096. Accounts are
created only when a slot is first used. Once pool accounts exist, the pool can
only grow. With the pool enabled, publishing and rotation cannot continually
create new shadow accounts.

`PoolAssignment` locks the real user while reading or updating their current
assignment. HMAC-SHA256 uses the site secret, user ID, and current time to
select a slot. Each assignment lasts `anonymous_account_duration_minutes`
(default seven days) from its first use. Posting during that period does not
extend it. The first post after expiry selects a different slot. Different
users can share a slot. A mutex and unique slot/user indexes prevent duplicate
account creation. Preserve the site secret across application instances.

The two tables store pool membership and each user's current assignment.
Published posts and topics use the pool account as their actual `user_id`.
Each post stores its real owner in the private integer custom field
`isbf_anonymous_owner_id`; only the boolean `isbf_per_post_anonymous` is exposed
to topic serializers. The private owner is server supplied and is never
accepted from request parameters or included in the queued-post serializer
allowlist. Queued posts temporarily retain the owner in their private payload.

Publishing reuses `NewPostManager`, `PostCreator`, `TopicCreator`, and their
existing `acting_user` mechanism. Permissions, validation, approval thresholds,
duplicate detection, drafts, slow mode, and rate limits use the real account.
Public author statistics remain attached to the pool account. The real user's
public post association is unchanged; a separate relation includes their
anonymous posts only for posting limits. Pool profiles, cards, activity,
messages, sessions, and account penalties are closed. Pool accounts are
excluded from the ordinary admin list, directory, user search, and `User.real`.

Owners use `/isbf-anonymous/posts` and the login-required
`/isbf-anonymous/api/posts` to see only their own published anonymous posts,
including legacy identities. Reply alerts, draft advancement, and approval or
rejection feedback go to the real owner, even when accounts are shared.

Only administrators can look up an author:

- On a published anonymous post, open the wrench menu at the bottom of the
  post and select **View real author**.
- On the review page, anonymous queued posts have a **View real author** button
  below their content. Other reviewable types use their existing interfaces.
- Both buttons open the same dialog, showing the real username, name when
  available, avatar, and user ID. **Manage this user** opens that real account's
  existing admin page.

The lookup is made only when an administrator opens the dialog. Results stay
in the dialog and are discarded when it closes; they are not added to post
models or browser storage. Lookup always uses the post or queued-post ID:
different people can share the same anonymous account. The review serializer
exposes only the `isbf_per_post_anonymous` boolean to administrators to control
the button's visibility. Ownership remains private.

The buttons reuse the existing administrator-only APIs:

- `GET /isbf-anonymous/api/posts/:id/author.json`
- `GET /isbf-anonymous/api/queued-posts/:id/author.json`

Moderators receive 403 responses from both routes. They can review the public
author and moderate individual posts, but cannot punish a shared pool account.
Automatic silencing of a real account does not put an anonymous reviewable ID
in moderator-visible staff logs.
Real-account pending-post lists and counts also hide anonymous entries from
moderators; the author and administrators retain access.

## Rollout and legacy migration

`isbf_anonymous_pool_enabled` defaults to false for existing installations.
With it disabled, new posts still use `AnonymousShadowCreator`; private owner
tracking and the real-account checks still apply. Enable the pool to enforce
the account bound. Existing shadows are retained until migrated and cleaned.

1. Apply the schema migration with `bin/rake db:migrate`.
2. Preview existing content using `bin/rake isbf_anonymous:migrate_legacy`.
3. Enable the pool and run `DRY_RUN=0 bin/rake isbf_anonymous:migrate_legacy`.
4. Inspect the report, then clean eligible old shadows with
   `DRY_RUN=0 CLEANUP=1 bin/rake isbf_anonymous:migrate_legacy`.

The task defaults to a **read-only preview**. It is idempotent and requires the
pool to be enabled before writes, so new per-post publishing uses the pool
during migration. A secret-derived slot preserves each legacy shadow's posts
as a group. `PostOwnerChanger` updates authors, topic ownership, reply links,
and statistics without creating public author-change revisions. Rendered HTML
may be rebaked using current site settings; post source remains unchanged.
Owner metadata is saved in the same transaction before the author changes.
Deleted public topics and their posts are included and remain deleted.
Anonymous queued posts and related post reviewables also move to the pool.

The report lists migrated counts, cleanup candidates, removed accounts,
skipped posts, and retained accounts. Unmarked, restricted, private, or unlisted
content, missing owners, remaining reviewables, and login data retain the old
account for manual inspection. Cleanup uses `UserDestroyer` and rechecks that
no posts (including deleted posts), topics, reviewables, or sessions remain.
The task does not delete content to make an account eligible for cleanup.

For authorized removal of historical anonymous content, record the legacy
user, topic, and post IDs before migration. Use the existing post/topic deletion
services and `UserDestroyer` for those IDs. Pool accounts can contain new posts
from other users, so content removal must use the recorded historical IDs.
Normal topic and post deletion leaves recoverable content records; deleting
the old shadow accounts removes their user records.

## Verification

Run `LOAD_PLUGINS=1 bin/rspec plugins/isbf-anonymous/spec`. The tests exercise
rotation boundaries and the account bound, shared-author ownership and
notifications, real-user limits and review, public payload privacy,
administrator lookup, API retries, and migration/cleanup with repeated runs.

Run the frontend tests against a Rails server with plugins loaded:

```bash
bin/qunit --qunit-path /tests --target isbf-anonymous plugins/isbf-anonymous/test/javascripts
```

These cover the administrator menu, review connector, on-demand lookup,
errors, retry, and dialog lifecycle. Use `--rails-port` and `--rails-env` to
target an isolated server when sharing the development site.
