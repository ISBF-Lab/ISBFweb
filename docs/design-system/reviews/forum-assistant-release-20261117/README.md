# Forum assistant release integration — 2026-11-17

The user accepted the preceding work and explicitly requested a PR and production
publication. This release combines the server-side forum-only assistant, workbench
entry and dedicated conversation workspace; development HTTPS forwarding is
recorded separately in `docs/development-network-access.md`.

The isolated branch starts from main commit
`b967f46a340f79b9941ca1a3407459ba4e3d1bea`. Only changes relative to the two
captured feature before-images were applied. Existing dirty workspace changes,
development credentials and synthetic data are excluded. Main's MBTI workbench
entry and permission gate, current migration versions and other theme imports
remain intact. A resource privacy test seeds its persisted custom-field name so
it also runs against main's older optional metadata API.

The exact integrated backend passed **82 examples, zero failures** in an offline
container with disposable synthetic PostgreSQL and Redis. Native scoped lint
passed, including the integration correction; workflow YAML and new documents
passed formatting checks. Recorded development evidence also covers 44 QUnit
tests, 124 assertions, 21 browser checks, 12 real classifier cases and two real
DeepSeek turns with source links. See `docs/forum-assistant.md` for limitations.

`source-manifest.json` binds the integrated runtime and regression files to
SHA-256 hashes and retains their captured before-image hashes. Documentation and
CI changes are reviewed in the PR diff. Full private integration evidence remains
in `.local/releases/forum-assistant-20261117/` in the shared workspace.

CI adds the policy/request suite and targeted native composer/workspace tests to
the existing checks. Production remains pending until the exact PR head passes
checks and review, is merged, and completes guarded incremental publication.
The live plugin inventory, database-backed theme and configured existing model
must be reread before building or applying any source. Production authorization
is already supplied by the user; no development secret, test account or bot may
be installed in production.
