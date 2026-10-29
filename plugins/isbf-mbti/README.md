# ISBF MBTI

Private workbench preference tests adapted from [luhuadong/mbti-test](https://github.com/luhuadong/mbti-test/tree/daaf70bfa171fb5487b59cf9f03455dfa2dd9f22), source revision `daaf70bfa171fb5487b59cf9f03455dfa2dd9f22` (MIT). Original source bytes and license are in `data/upstream/`; the per-question semantic scoring audit is in `docs/questionnaire-audit.md`. This adaptation is not an official MBTI assessment or a validation of the questionnaire's psychometric properties.

## Privacy and API

`isbf_mbti_enabled` defaults off. `/isbf/mbti` and the workbench entry use the site capability. Metadata is public while enabled; definitions and all result endpoints require native login. APIs are mounted at `/isbf/api/mbti`: questionnaires index/show, results index/show/create/delete. Result access always scopes by the current user, including for staff.

The server validates the complete question set and scores the pinned mapping. A unique per-user attempt UUID and a canonical digest make submission retries idempotent. The result table stores scores, type, questionnaire/scoring versions, source revision and the attempt digest; it does not persist individual answers. Answer parameters are filtered from logs. Result responses use private no-store headers. Device drafts are separate from account history.

A cascade foreign key is intentional: these private records must be removed on hard user deletion even if the feature is switched off. An unconditionally registered native anonymization event also removes results while disabled.

## Migration and verification

`db/templates/` contains a schema template, not an installable timestamp migration. The native CI helper generates its timestamp and Rails migration version. Commit the generated, source-SHA-verified migration and model annotation artifacts before merging or deployment. Never deploy a candidate lacking the final native migration.

The feature is isolated from Core and other business plugins. Run its RSpec suite plus the real theme tests and native browser flow in the dedicated MBTI CI. Source question files must retain their pinned bytes.

## Release and rollback

Back up the database, plugin inventory, active theme fields, settings and asset manifest. Publish the compatible plugin and final migration, compile/publish resources, then patch only the reviewed theme fields with source-hash guards. Enable the setting after health checks. Rollback disables the entry/new submissions and restores the scoped code/theme; retain the result table and user results. Production acceptance does not create test histories.
