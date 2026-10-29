# MBTI runtime compatibility fixture

This fixture records an approved read-only observation of 120 public frontend paths on 2026-10-29. It is not a complete production inventory or authorization to publish Core. The running source tree was not changed.

The original 30-file snapshot is preserved as `isbf-mbti-production-ui-initial.json`. A later audit found additional companion implementations and drift in six of those original entries. The current manifest must not substitute the original bytes for the newly observed ones.

`isbf-mbti-production-source-audit.json` contains only paths, byte counts, SHA256 values, missing-file state and the observed Core HEAD. Its canonical JSON digest binds the manifest: UTF-8 JSON with sorted keys, compact separators and unescaped Unicode.

The 119 observed files comprise:

- 107 matching merged Git source `9ca49588e44c18957733311239a0f355314a2980`;
- two float-kit files matching merged `13d66d6f415a7a6b496741155cb55315e208f882`;
- one animated OTP component matching merged ancestor `211f043f51681951bbb6d562ca9df66ea73366c6`;
- six unchanged public files captured with explicit user approval, checked against the earlier size and SHA256 observations before and after retrieval;
- three files matching Core `132cc95d043db01251eedf9c93b3927cd5ffee91`, which are verified and retained without replacement.

The six captured files under `isbf-mbti-runtime/` are immutable `.txt` data. Their original paths and digests are explicit in the manifest; they have no claimed Git source commit. They contain the existing menu viewport/highlight positioning adjustments, a deleted-post branch condition and an ARIA attribute correction. Review found no added external network calls or credential content. Preserve their exact bytes: `.gitattributes` disables newline conversion, and formatter changes would invalidate the audited digest.

Syncing main `c199c2f7b47906ef0e499ab015cb89433af4dacb` subsequently made Git-equivalent versions of the four menu captures available through PR #102. The recorded origin still describes the approved capture; no captured bytes or source descriptors were replaced. The two nested-reply captures remain separately identified runtime data.

The absent `frontend/discourse/tests/helpers/d-select.js` is a separate, fixed-source test-only supplement. It is not evidence that the helper was installed in production. The current theme baseline remains fixed at `9ca49588…` with the reviewed MBTI patch; this does not claim that all current database-backed theme fields were audited.

Restoration runs only in the isolated GitHub Actions checkout. All sources, observed paths, retained files and target base digests are validated before any write. Current-candidate and production-baseline theme tests remain unfiltered; RSpec, all system examples, theme patch guards and frozen dependency-lock checks remain in place. A successful compatibility run does not establish visual acceptance or authorize merging, deployment or replacing production Core.

The theme patch guard reads the target branch's live Git ref before and after fetching a diff for the fixed base/candidate commit pair and requires the base to be an ancestor of the candidate. A PR's `base.sha` can be an older snapshot and is not used as the live target. Patch receipts record the verified live base SHA. Shared locale conflict resolution preserves all peer values and keeps the MBTI-only patch applicable to the fixed theme without importing unrelated error-page strings or styles.
