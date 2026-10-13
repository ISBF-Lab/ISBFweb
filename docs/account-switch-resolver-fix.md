# Account switch admin resolver fix

Backup cleanup on 2026-10-07: the historical database backup and image below were
deleted following the user's confirmed cleanup plan. See the
[email code login deployment record](login-email-code-entry-production.md) for the
current backup and rollback version.

## Cause and implementation

Opening `/admin/plugins/isbf-account-switch/links` resolved the plugin's route
and template through deprecated normalization of flat, hyphen-separated module
names. Both emitted `discourse.deprecated-resolver-normalization`.

The route and template now live under
`plugins/isbf-account-switch/admin/assets/javascripts/discourse/{routes,templates}/admin-plugins/show/`.
Their basenames are `isbf-account-switch-links.js` and
`isbf-account-switch-links.gjs`. The public route remains
`adminPlugins.show.isbf-account-switch-links`; the URL, API requests, and account
approval logic are unchanged.

Release commit: `403bce2f3c83711a5f2891eef0b82d6941e5ae5c`.
Previous production commit: `1575e9c1de2ae36bd1a2bbf34371029fa3c751dc`.

## Validation

The acceptance tests cover opening the URL directly and navigating from the
plugin settings page. They also check the account rows, approval actions,
audit table, and absence of this resolver deprecation. Both tests passed;
the test runner reported no deprecations. ESLint and Prettier passed through
`bin/lint --fix`.

The production verification and test artifacts are stored in
`deploy-work/account-switch-resolver-20261006/`.

## Production deployment

Deployment date: 2026-10-06. Status: completed; maintenance lock released.

Production configuration changes only `params.version`. The local release
repository HEAD is `refs/heads/account-switch-resolver-20261006`.
The existing full configuration preserves the HTTPS, certificate renewal,
SMTP, and proxy setup. A persistent maintenance lock prevents normal writes
during the update. No database migration is added by this fix.

Disposable dependency and compilation caches were removed to increase free
disk space from 3.2 GB to 4.2 GB. With the existing Docker runtime, pinned
base image, and rollback image verified, the full rebuild uses
`./launcher rebuild isbf_app --skip-prereqs` to bypass the generic 5 GB
precheck. Disk space is monitored during the build. Cache paths are recorded
in `deploy-work/account-switch-resolver-20261006/cache-cleanup.json`.

The deployment record is in
`/home/codex/discourse-production/deploy/account-switch-resolver-20261006/`,
with directory mode `700`; configuration copies and build logs are private.
The previous image is retained as
`local_discourse/isbf_app:before-account-switch-resolver-20261006`.

The native database and upload backup is
`shared/standalone/account-switch-resolver-20261006/before-account-switch-resolver-20261006-v20261004090640.tar.gz`.
Its gzip integrity check passed. SHA256:
`a16ea465856c3da37875ac5cf9b7d5421b2e107ae5458262a7a45ac394d86bb1`.

The baseline includes 13 real users, 31 topics, 53 posts, 20 uploads,
4 account links, and 43 audit events. The default theme is ID 4; theme source
and settings hashes are recorded for comparison after deployment.

The full rebuild exited with code 0. Production runs the release commit;
the plugin manifest contains separate `admin` and `main` entrypoints.
HTTPS health checks return 200. All baseline counts and theme hashes match
after deployment.

The live browser opened the links URL directly and through plugin navigation.
Both displayed the two tables. The admin bundle loaded, and there were zero
resolver warnings, zero matching developer notices, and no failed script or
stylesheet responses. The verification blocked POST requests for MessageBus
polling and page view tracking; these produced three expected `Failed to fetch`
events in the report. The temporary local-only read-only API key and credential
files were deleted. The maintenance lock is off, and the development container
is stopped, matching its initial state.

## Rollback

Restore `containers/isbf_app.yml` from the private `config-before.yml`, and set
the bare release repository HEAD to `refs/heads/student-invitations-20261004`.
Both must resolve the previous production commit. Restart the retained old
container if a build fails before replacement, or recreate it using the
preserved image and complete configuration. Release the maintenance lock
after health checks pass. Preserve the current database; this code change
does not require a database restore.
