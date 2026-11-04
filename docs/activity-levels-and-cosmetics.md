# Configurable activity levels and cosmetic permissions

Developers manage activity levels at `/admin/plugins/discourse-academy-roles/activity-levels`.
The page edits versioned rules, optional names, demotion behavior, qualification continuity,
cosmetic requirements and one optional automatic badge per level. Saving schedules batched
recalculation and displays aggregate progress, failures and retry controls.

Until the first explicit save, the legacy activity calculation continues using the existing
activity requirement settings. Activity levels and native trust levels remain separate.
Deployment does not copy development configuration, reassign accounts or change default trust
levels. Only normal member accounts participate;
system, staged and automatic anonymous accounts are excluded. Staff keep their existing
appearance privileges and receive badges according to their actual activity level.

## Appearance rules

- Avatar frames require their existing public/individual ownership plus both the global
  minimum activity level and the optional per-frame minimum. The frame editor preserves
  uploaded assets, calibration and awards.
- Ordinary members can toggle a fixed name preset after meeting its minimum level.
  Developers configure separate six-digit light/dark colors; the preset remains disabled
  until explicitly configured. It applies to the existing feed author name. Staff retain
  their existing colors and gradients.
- Demotion or a higher threshold pauses the effective appearance while retaining the saved
  choice. Meeting the requirement again restores it without another preference save.
- Each level can bind one enabled, non-system, single-grant badge without another automatic
  rule. Only the current level's automatic award remains. Existing manual awards are never
  adopted; granting an automatic award manually releases it from automatic revocation.

Requirements reference stable level IDs. Renaming or renumbering keeps bindings. Deletion
requires clearing/rebinding all global and per-frame references first. Appearance and badge
changes do not reset continuity: metadata is excluded from qualification fingerprints and
the form preserves the original order of grouped conditions when submitting them.

Daily evaluation uses a minimum 36-hour check interval for consecutive qualification, including
the existing scheduling-delay allowance. The developer API supplies this minimum to the form;
shorter values are rejected when consecutive qualification is enabled. Before the first save,
stable-ID initialization is deferred, and the initial backfill reconciles legacy numeric levels
so that an earned level remains the previous assignment when demotion is disabled.

## Persistence and permissions

The developer-only `/academy-roles/admin/activity-levels` endpoints provide configuration,
deletion impact and recalculation status/retry. Existing clients that omit new cosmetic
settings or a badge binding retain saved values. Revision conflicts return 409; invalid
rules and outstanding references return 422. Save services enforce authorization independently.

Configuration, audit and run preparation share the existing advisory transaction lock;
cache invalidation and job enqueue follow commit. Individual evaluation and native badge
synchronization share a per-account savepoint. Frame saves recheck authoritative configuration
under the same lock to protect against concurrent level deletion.

`discourse-avatar-frames` adds only the nullable `minimum_activity_level_id` column
(`varchar(64)`) through migration `20261104043140`. Existing selections and grants are retained.
New capability/ownership fields are owner-only; existing public avatar-field compatibility
is preserved. Public site data exposes only level identifiers/names and validated preset colors.

## Validation and production delivery

Isolated development validation passed 40 real browser flow checks. The review follow-up
passed 18 native QUnit tests/67 assertions and 126 related backend examples, including the
60 new review-boundary cases, plus scoped source/spec lint and the shared menu checks.
The initial broad backend run recorded 538 examples/four failures:
three were reproduced before this feature; the fourth was an old account-switch expectation,
which was corrected and passed in the affected follow-up. The full suite was not rerun after
those localized changes and is not described as entirely green.

The feature CI runs native configuration/evaluation/permission/badge and avatar-frame cases,
plus both plugins' frontend tests, against a synthetic database. Existing project checks remain.
The first CI run's dependency failures and review fixes are documented in the dated deployment
record's `ci-follow-up.md`; its successful new-feature and frontend workflows do not erase the
recorded failures in the other workflows.
Design approval covers the existing FormKit/admin composition and the existing feed/preference
surfaces; it does not extend to unrelated pages. See the dated C22 design review records.

The authorized production release is prepared separately from the development workspace.
Preflight observes 67 plugins, 27,052 source entries, 72 generated manifests, 308 active-theme
fields and 17 saved theme settings. It preserves actual runtime bytes, hidden markers,
shared links and the existing feed alumni label. Only the two affected plugin bundles and
two theme fields are intended to change. The additive migration and Web/job-process reload
require a verified recovery snapshot; database and Redis services remain running.

Before installation, recheck the live source/theme preimages and all unaffected inventory.
Afterward, verify exact sources/assets, both responsive page modes, actual feature links and
completed data loading. Record the merged PR, build/source hashes, migration, production
checks, recovery reference and guarded retention in a dated deployment record. Do not import
development data or settings, and do not run production test writes.
