# ISBF MBTI

Private workbench preference tests adapted from [luhuadong/mbti-test](https://github.com/luhuadong/mbti-test/tree/daaf70bfa171fb5487b59cf9f03455dfa2dd9f22), source revision `daaf70bfa171fb5487b59cf9f03455dfa2dd9f22` (MIT). Original source bytes and license are in `data/upstream/`; the per-question semantic scoring audit is in `docs/questionnaire-audit.md`. This adaptation is not an official MBTI assessment or a validation of the questionnaire's psychometric properties.

## Privacy and API

`isbf_mbti_enabled` defaults off. `/isbf/mbti` and the workbench entry use the site capability. Metadata is public while enabled; definitions and all result endpoints require native login. APIs are mounted at `/isbf/api/mbti`: questionnaires index/show, results index/show/create/delete. Result access always scopes by the current user, including for staff.

The server validates the complete question set and scores the pinned mapping. A unique per-user attempt UUID and a canonical digest make submission retries idempotent. The result table stores scores, type, questionnaire/scoring versions, source revision and the attempt digest; it does not persist individual answers. Answer parameters are filtered from logs. Result responses use private no-store headers. Device drafts are separate from account history.

A cascade foreign key is intentional: these private records must be removed on hard user deletion even if the feature is switched off. An unconditionally registered native anonymization event also removes results while disabled.

## Migration and verification

The final migration is `db/migrate/20261029003825_create_isbf_mbti_results.rb`, produced by the native Rails generator in the current-baseline CI for source `b478424354419ead12cd274b14645f09271652b5`. The schema template remains in `db/templates/`; the helper verifies and reuses the final file. Only the MBTI schema blocks and its migration version are imported from that source-verified native dump. Model annotations were unchanged. Never deploy a candidate lacking the final native migration.

The feature is isolated from Core and other business plugins. Run its RSpec suite plus the real theme tests and native browser flow in the dedicated MBTI CI. Source question files must retain their pinned bytes.

The production CI matrix reproduces the deployed frontend, not a bare Git checkout: Core `132cc95d043db01251eedf9c93b3927cd5ffee91` already has 30 public UI dependency files from merged source `9ca49588e44c18957733311239a0f355314a2980`. A read-only audit on 2026-10-29 verified each file. `.github/fixtures/isbf-mbti-production-ui.json` pins their current/base hashes and audit digest; the CI-only restore helper checks both Git heads, verifies all sources and destinations before writing, and rejects drift. It neither installs Core into production nor changes dependency snapshots. Both matrices retain scoring, ownership, QUnit and all 16 native page examples.

## Release and rollback

Back up the database, plugin inventory, active theme fields, settings and asset manifest. Publish the compatible plugin and final migration, compile/publish resources, then patch only the reviewed theme fields with source-hash guards. Enable the setting after health checks. Rollback disables the entry/new submissions and restores the scoped code/theme; retain the result table and user results. Production acceptance does not create test histories.
