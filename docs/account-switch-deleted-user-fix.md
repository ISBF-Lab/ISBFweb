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
