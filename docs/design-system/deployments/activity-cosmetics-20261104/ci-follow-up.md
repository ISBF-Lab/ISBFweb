# Activity release CI and review follow-up

The first PR head `f22074a399b07d481e393459acd9ffad37709650` passed the dedicated
activity/cosmetic native regression, the full frontend consistency workflow, native
formatting and the alumni identity boundary. It has not been deployed to production.

## Existing workflow failures

The official quota workflow passed its 42 backend cases, but the pinned runtime did not
contain the `discourse/tests/helpers/d-select` helper imported by the new plugin test bundle.
Even a filtered QUnit run loads those imports. It now copies that candidate test helper into
the pinned test checkout; production core code is unaffected.

The student-group workflow ran 504 backend cases with 49 failures: 46 missing frame-cache
constants, one missing frame fabricator, and two anonymous-identity name-color assertions.
Its pinned checkout lacked the frame dependency. The test overlay now also installs the
candidate frame plugin and copies the select helper. The anonymous plugin is already present
in the pinned runtime and is preserved.
The native helper already loads installed plugins' support and fabricators; the original
complete plugin-suite command remains. No failing cases, assertions or existing CI gates
are removed. The original reports remain the evidence for that first run.

The two old name-color examples change an account's anonymous identity after saving preferences
within one fabricated request. Saving now legitimately primes the shared eligibility cache;
those examples reset only the older name-color cache. Their identity transitions now reset
both request caches, retaining the exact assertions that anonymous actors have no effective
color. The correction models a new request and does not relax production eligibility.

## Review corrections

Before configurable rules are first saved, legacy numeric assignments are authoritative.
New accounts now defer stable-ID initialization until rules are persisted, with that decision
made under the configuration lock. First-save backfill also reconciles pre-existing stale IDs
against each legacy numeric assignment. Thus a member who earns LV2 during the legacy period
keeps that previous level when switching to configured rules with demotion disabled.
Existing stable IDs are preserved on subsequent saves, and legacy continuity is retained.

Daily evaluation requires an interval that permits the next scheduled check and ordinary
delay. Positive `continuous_days` now requires at least 36 hours, matching the existing
default allowance. The serializer exposes `minimum_continuous_check_gap_hours`; the native
FormKit minimum, validation and bilingual description consume it. Non-continuous rules
retain the previous integer range. The scheduled job cadence remains daily.

| Review | Outcome | Evidence |
| --- | --- | --- |
| Legacy-to-configured identity | Fixed | Initialization decision inside the lock; first-save numeric reconciliation; real creation, legacy evaluation and first-save regression |
| Persisted configuration safety | Preserved | Later saves retain established stable IDs and continuity state |
| Supported qualification intervals | Fixed | Shared backend policy, serialized minimum and FormKit validation; boundary and real form submission coverage |
| Existing workflow coverage | Preserved | Required installed-plugin/test-helper inputs added; original backend and frontend commands retained |
| Service and permission boundaries | Preserved | Save/retry services, transaction ordering, developer checks and owner-only appearance capabilities remain unchanged |

Follow-up raw results are stored separately in the migration workspace's private release
directory. The original development delivery manifests are historical records and are not
rewritten. Production source plans must incorporate this passing follow-up before any build
or installation; the old preparation hashes alone do not authorize installing earlier code.

## Follow-up validation

- The new review cases passed 60 backend examples. After correcting the two old identity
  fixtures, the old name-color suite plus the complete activity model/service/request suite
  passed 126 examples, including those sixty cases.
- The intervening full-inventory run recorded 632 examples/five failures: three documented
  pre-feature issues and the two subsequently corrected identity-fixture transitions. The
  entire broad suite was not repeated after that localized fixture correction.
- Native frontend regression passed 18 tests/67 assertions, including rejection below the
  server-supplied minimum and a successful native form submission at 36 hours.
- All ten changed implementation/frontend/workflow inputs passed scoped native checks;
  workflow YAML additionally passed explicit Prettier and parser checks. All seven changed
  Ruby specs passed native lint. Five shared-menu tests and a 5854-file scan passed.

The seven changed runtime files are staged separately, with original production preimages
retained. The release still has 54 plugin runtime files and two theme fields; its exact
review increment is [recorded here](review-runtime-preparation.json). The live inventory and
final passing PR head must still be checked before building or installing.
