# ISBF MBTI

Private workbench preference tests adapted from [luhuadong/mbti-test](https://github.com/luhuadong/mbti-test/tree/daaf70bfa171fb5487b59cf9f03455dfa2dd9f22), source revision `daaf70bfa171fb5487b59cf9f03455dfa2dd9f22` (MIT). Original source bytes and license are in `data/upstream/`; the per-question semantic scoring audit is in `docs/questionnaire-audit.md`. This adaptation is not an official MBTI assessment or a validation of the questionnaire's psychometric properties.

## Privacy and API

`isbf_mbti_enabled` defaults off. `/isbf/mbti` and the workbench entry use the site capability. Metadata is public while enabled; definitions and all result endpoints require native login. APIs are mounted at `/isbf/api/mbti`: questionnaires index/show, results index/show/create/delete. Result access always scopes by the current user, including for staff.

The server validates the complete question set and scores the pinned mapping. A unique per-user attempt UUID and a canonical digest make submission retries idempotent. The result table stores scores, type, questionnaire/scoring versions, source revision and the attempt digest; it does not persist individual answers. Answer parameters are filtered from logs. Result responses use private no-store headers. Device drafts are separate from account history.

A cascade foreign key is intentional: these private records must be removed on hard user deletion even if the feature is switched off. An unconditionally registered native anonymization event also removes results while disabled.

## Migration and verification

The final migration is `db/migrate/20261029003825_create_isbf_mbti_results.rb`, produced by the native Rails generator in the current-baseline CI for source `b478424354419ead12cd274b14645f09271652b5`. The schema template remains in `db/templates/`; the helper verifies and reuses the final file. Only the MBTI schema blocks and its migration version are imported from that source-verified native dump. Model annotations were unchanged. Never deploy a candidate lacking the final native migration.

The feature is isolated from Core and other business plugins. Run its RSpec suite plus the real theme tests and native browser flow in the dedicated MBTI CI. Source question files must retain their pinned bytes.

The production CI matrix pins Core `132cc95d043db01251eedf9c93b3927cd5ffee91` and reconstructs the public frontend paths observed in the approved 2026-10-29 read-only audit. The 120-path snapshot contains 119 existing files and one absent test helper: 116 files need restoration and three retain their original Core bytes. Most restored files match merged source `9ca49588e44c18957733311239a0f355314a2980`; two float-kit files match `13d66d6f415a7a6b496741155cb55315e208f882`, and the animated OTP component matches `211f043f51681951bbb6d562ca9df66ea73366c6`. At retrieval, six other public files had not been matched to the locally available Git sources; the user approved retrieving their unchanged bytes for review and immutable, non-executable `.txt` CI fixtures. Their provenance remains runtime capture. After syncing newer main, four menu captures also match its Git bytes. See [fixture provenance](../../../.github/fixtures/isbf-mbti-runtime.md).

`.github/fixtures/isbf-mbti-production-ui.json` binds the combination to the public hash-only audit receipt. The CI-only helper validates every source HEAD, source digest, audited byte length, target base digest and retained file before writing anything, rejects drift, and records each file's origin. The original 30-file audit remains a historical fixture, not the current runtime claim. This is a scoped compatibility snapshot, not a complete production inventory. No production Core or dependency lock is changed. Both matrices retain full theme QUnit, scoring, ownership and all 16 native page examples. The absent native select helper is separately restored from fixed `9ca49588…` bytes for tests only. The candidate plugin marker is registered in the isolated checkout index so native lint uses repository-owned plugin rules without creating a separate dependency installation or changing frozen locks.

The production QUnit harness separately ports the six theme-stylesheet loading lines from fixed `9ca49588…`; Core `132cc95…` otherwise omits theme CSS from that test page. The CI-only helper verifies pinned Git HEADs and exact before/after bytes and records its test-only receipt. It does not change the observed runtime UI snapshot or product Core. Full theme assertions run with the installed theme CSS; native CI results must still be verified for the exact candidate commit.

## Release and rollback

Back up the database, plugin inventory, active theme fields, settings and asset manifest. Publish the compatible plugin and final migration, compile/publish resources, then patch only the reviewed theme fields with source-hash guards. Enable the setting after health checks. Rollback disables the entry/new submissions and restores the scoped code/theme; retain the result table and user results. Production acceptance does not create test histories.
