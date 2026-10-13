# Workspace consolidation, 2026-10-13

The working checkout was based on `d91ef8456b91ed8301947c5e46a372642c96b01f`,
58 commits behind main at `8563fdd7776`. Authentication, account-switch permissions,
moderator permissions, campus layout, and the frontend consistency rollout had
already been merged in PRs #48, #49, #51, and #52. Their newer code is retained.
Older workspace copies do not remove those features or their tests.

The remaining source is consolidated into the main repository:

- The Apache-2.0-licensed avatar-frame plugin derives from `asa0w0/discourse-avatar-frames`
  with local adapted release `2eb878d4227dee6009f839f681b0ad06f8e6223c`: admin uploads,
  individual/CSV grants, persistent calibration, original APNG preservation, and
  corrected homepage/user-card avatar lookup. Source is stored as ordinary files,
  so a fresh clone does not depend on an unpublished nested-repository commit.
- The optional Latest-by-creation plugin preserves pins, explicit sorting, and live
  updates. It remains disabled by default.
- Remaining deployment/authoring records and design review sources are included.
  Historical prototypes and review archives do not establish new Approved UI rules.
- Existing main security rules, current theme implementations, resource limits,
  and dependency patches are preserved. The workspace lockfile that omitted the
  declared overrides and patches is superseded by main's intact lockfile.

Local deployment trees, logs, credentials, database/upload backups, generated
assets, experimental logo themes, and nested Git metadata remain local and ignored.
No production data, settings, theme, or service is changed by this consolidation.
The avatar-frame visibility fix remains pending the user's visual verification.

Earlier verification is recorded in plugin and deployment documentation.
Merge validation uses checks for the assembled branch and existing CI gates;
historical passing results are not represented as a new full-suite run.

## Validation of the assembled branch

The targeted `bin/lint --fix` invocation passed: ESLint, Prettier, RuboCop,
Stylelint, and Syntax Tree checked the changed product source. It normalized
imported plugin formatting without changing the deployed plugin's business logic.
Design reference `.txt` attachments remain byte-preserving evidence.
Candidate text files and design archives were checked for private-key/token
patterns and private deployment/dependency archive members; no findings remained.
A full forum or production browser was not started for this consolidation.
Required repository CI remains enabled for the pull request.
