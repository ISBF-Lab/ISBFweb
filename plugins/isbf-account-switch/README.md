# ISBF Account Switch

Discourse plugin for pairwise account linking with administrator approval, per-device verification, direct switching through native Discourse sessions, revocation, and audit records.

## Security model

- Links are pairwise and never expand transitively.
- Device credentials are random, encrypted HttpOnly cookies; only SHA-256 digests are stored.
- Passwords, two-factor codes, and raw Discourse session tokens are never stored.
- A direct switch requires an approved link, an active device grant, and an eligible target account.
- Native logout revokes the current device grants.
