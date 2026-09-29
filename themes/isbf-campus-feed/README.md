# ISBF Campus Feed

This is the source export of the local site's default `ISBF Campus Feed`
theme (ID 4). Another theme has the same name, so select ID 4 when exporting.
The theme is edited in Discourse's theme editor; sync its current export here
before committing later UI changes.

The feed card uses the topic-list outlet's navigation callback for clicks on
post text and card space. Keep nested links and action controls independent.
The reply action loads the full topic and its saved draft before opening the
composer; topic-list data alone does not include the required draft key.

For local browser checks in `discourse_dev`, run `pnpm playwright-install` as
`discourse`. If Chromium cannot start because system libraries are missing, run
`pnpm exec playwright install-deps chromium` as root. The install script skips
the headless shell, so launch Playwright with `channel: "chromium"`.

The calendar and workbench routes, and the private calendar entry API, require
the `isbf-calendar` plugin. Community events use Discourse Events and the
`calendar_category_id` and `calendar_category_path` theme settings.

Per-post anonymous publishing requires `plugins/isbf-anonymous`, Discourse's
`allow_anonymous_mode` setting, and `anonymous_posting_allowed_groups` containing
`trust_level_0` (group 10). The plugin uses the core shadow identity; its private
`/isbf-anonymous/api/posts` endpoint resolves all rotated identities for the
logged-in owner. Anonymous posts cannot be edited or deleted by non-staff after
publishing. The core full-session anonymous switch is denied by the plugin.
