# Deleted accounts in linked account lists

## Cause and behavior

Deleting a user leaves historical `isbf_account_links` rows in place. Both the
user account menu and the administrator approval list previously read the deleted
user's attributes without checking whether the association still existed.

The user list now skips links whose other account no longer exists. The admin
list retains the historical row and stored user ID, with nullable usernames,
names, and requester names. The admin UI renders a translated "Deleted account"
label. Approval is disabled in the UI and rejected by the server when either
participant is missing. Rejection and revocation remain available for historical
links. Verification and switching to a deleted target return the existing
target-unavailable error and preserve the caller's session.

No database migration or historical record cleanup is needed. Audit events remain
available, including events whose actor has been deleted.

## Regression checks

```sh
bin/rspec plugins/isbf-account-switch/spec
bin/qunit plugins/isbf-account-switch/test/javascripts/acceptance/admin-links-test.js
```

Coverage includes live and missing account links together, either participant
being deleted, deleted requesters and audit actors, empty user lists, refusal to
approve or switch invalid links, and rejection/revocation of historical links.

Validated on 2026-10-08: 21 RSpec examples and 3 QUnit tests passed. The QUnit
run recorded no deprecations. `bin/lint --fix` passed for the changed source
files; locale YAML, deployment script syntax, and patch whitespace checks also
passed. Browser tests use a single-threaded test server to fit the shared
1280 MiB container limit.

An additional `CI=1` run exposed an existing schema limitation: CI raises bigint
sequences above 10 billion, while the audit and device-grant `account_link_id`
columns are 32-bit integers. This causes range errors independently of deleted
accounts. The focused release uses the normal RSpec command above and leaves
schema changes for a separate fix. Current production link IDs are below this
limit.

## Production incident and release

On 2026-10-07, link ID 2 connected Alan_Tan (user ID 2) to deleted user ID 8.
It was already revoked, but serializing it still caused both list endpoints to
return 500. Gin's linked account still existed.

The separate 502 window at 15:35-15:36 UTC was an application restart during a
learning-plugin release. Nginx could not connect to port 3000 while the workers
were restarting. The workers became ready at 15:36:42 UTC; subsequent HTTPS
home and health checks returned 200. The container restart count and OOM counts
were zero.

This fix is based on production commit
`52eebcedf40f7f623278f71921574a095b1864e0`. Isolated checks and builds use a
1280 MiB memory limit, no additional swap, and 0.75 CPU. Production activation
preserves the current independent learning-plugin release, runtime
configuration, theme data, and data mounts. Keep a prepared previous container
and image for rollback and serialize production releases.

Release verification artifacts are stored in
`deploy-work/account-switch-deleted-user-20261007/`.

## Completed production release

Published on 2026-10-08 at 07:29 UTC with source commit
`10004ccf5090d85f80da529aeb4ecb4f3b7b1205` and image
`sha256:32e7ac0ba2e4708458571ac46087924ca512fae646a621eaa64cd170b6485404`.
The production version, release Git reference, and latest image tag now point
to this release. The current independent learning release
`621f938a6676533fce0f7e725b77c485cef965d1` was preserved.

Production acceptance passed for Alan_Tan's and Gin's account menus and their
account-list endpoints. The administrator page loaded all four historical links
and displayed the deleted-account label for link ID 2. The home and health
endpoints returned 200. Data, settings, themes, link records, and audit events
were preserved. Temporary verification keys were removed and readonly mode was
released. After publication, validation is limited to these necessary checks;
the passing source test suites are not rerun without a relevant change.

Read-only browser verification uses temporary user-bound API keys restricted to
local private addresses. Do not send the `Discourse-Logged-In` cookie-session
marker with API authentication: without a login cookie it causes a logged-out
response header. Send API credentials only to dynamic same-origin GET requests,
excluding static assets to avoid spending the API rate limit on page resources.
Telemetry writes and message-bus polling are suppressed in the verification
browser; account and approval requests reach the real production endpoints.

At the user's request, three older database-and-upload archives were removed,
reclaiming 142,886,815 bytes. The retained complete backup is
`before-account-switch-deleted-user-20261008-071312-v20261008000000.tar.gz`,
with verified SHA-256
`bd4004b9973908e40d251263c25c61ca59826b8f2dbcd56d26a33810507853a0`.
It remains under `/shared/account-switch-deleted-user-20261007/` with restricted
permissions. Backup cleanup verifies the latest archive before deleting only
older archives and does not modify live database or upload files.

The previous application container is retained for rollback. The guarded
`deploy-work/account-switch-deleted-user-20261007/rollback-production.py` restores
that container, its version configuration, and its release reference without
restoring the database. A later learning release requires updating the rollback
plan before using this script. Public release and cleanup results are recorded in
`production-report.json`, `verification/production-verification.json`, and
`backup-cleanup-report.json` within the artifact directory above.
