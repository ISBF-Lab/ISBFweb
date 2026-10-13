# ISBF Account Switch

Discourse plugin for pairwise account linking with administrator approval, per-device verification, direct switching through native Discourse sessions, revocation, and audit records.

## Security model

- Links are pairwise and never expand transitively.
- Device credentials are random, encrypted HttpOnly cookies; only SHA-256 digests are stored.
- Passwords, two-factor codes, and raw Discourse session tokens are never stored.
- A direct switch requires an approved link, an active device grant, and an eligible target account.
- Native logout revokes the current device grants.

## Frontend admin routes

The account links page uses the `adminPlugins.show.isbf-account-switch-links`
route at `/admin/plugins/isbf-account-switch/links`. Its route and template live
under `admin/assets/javascripts/discourse/{routes,templates}/admin-plugins/show/`
and are named `isbf-account-switch-links.js` and `isbf-account-switch-links.gjs`.
Keep nested route segments as directories so the page resolves without the
deprecated conversion of flat, hyphen-separated module names.

Run the focused regression tests with
`bin/qunit plugins/isbf-account-switch/test/javascripts/acceptance/admin-links-test.js`.
