# ISBF Campus Feed

This is the source export of the local site's default `ISBF Campus Feed`
theme (ID 4). Another theme has the same name, so select ID 4 when exporting.
The theme is edited in Discourse's theme editor; sync its current export here
before committing later UI changes.
This directory and the running theme are separate copies. After editing files
here, sync the changed fields to theme ID 4 and confirm they compile; a passing
repository lint check alone does not update the site.
For a focused update, export a fresh backup and compare the live field values
before writing. Apply only the intended patch to those fields; importing an
older whole-theme export can discard unrelated fixes.
After syncing through a separate Rails process, verify that a fresh page loads
the theme JavaScript URL currently stored for ID 4. If the page still references
an older digest that returns 404, restart the development web server to clear
its stale theme cache.
The bookmarks page hides Discourse's activity subnavigation so its content
starts with the bookmark search and list. Other activity pages keep those tabs.

The October 2026 merge uses theme ID 4's current export as the baseline, including
notifications, explore preferences, reporting, topic actions, and optional titles.
Optional titles remain explicitly entered; do not derive them from post bodies.
The `isbf-composer-optional-title` pre-initializer registers the composer field,
draft serialization, and reset method before `inject-discourse-objects` using
`addModelField` and `addModelMethod`. Keep the original reset behavior and return
value when extending it; modifying `model:composer` through `modifyClass` is
deprecated. Calendar deletion uses Discourse's confirmation dialog, and the
editor retains keyboard focus and Escape behavior alongside the all-day date fixes.
The current reading modules replace the former short-topic CSS fallback.
The reporting route extends the core action with a subclass and `@action` so
repeated application initialization preserves the bound action descriptor.

Theme regression tests live in `test/`. Test imports use the compiler's
`discourse/` module paths, which omit the source directory's `javascripts/` prefix.
Import this directory into a separate development database and run
`bin/qunit --rails-env development --rails-port PORT
--theme-id ID --qunit-path /theme-qunit` against that database's server. Do not
reset the running site's database to prepare tests. After validation, compare a
fresh live export with the backup before syncing changed fields, preserve theme
settings and components, check both stylesheet and JavaScript compilation, and
re-export to confirm the repository and live source match.

The `/badges` listing and badge detail routes share the V2 shell, including
details filtered by `username`. Keep their cards and grant lists within the
central column; badge data and actions remain Core's own components.

The feed card uses the topic-list outlet's navigation callback for clicks on
post text and card space. Keep nested links and action controls independent.
The reply action loads the full topic and its saved draft before opening the
composer; topic-list data alone does not include the required draft key.

Topic posts share the 600px feed column. Keep the post inset and desktop body
width in `common/common.scss` aligned with Core's avatar column so the author
metadata remains beside the avatar. Core renders the author label and falls back
to the username when a user has no full name.

Regular topic posts use the full central column. The A timeline layout reuses
Core's single topic navigation instance and reading state; it does not move
Ember-owned nodes or copy the timeline component. At the existing 1280px right
rail breakpoint, the actual `.timeline-scrollarea-wrapper` enables a reading
card below search. A ResizeObserver reserves its measured height above the
remaining rail cards and releases that space when the topic or mode changes.
Core keeps short single-post timelines hidden and long single-post timelines
available. Remaining admin and language controls stay accessible.

The header progress button uses Core's stream index and expansion event. Above
600px, the expanded timeline is a compact card below the header, aligned to the
button's right edge. Its width is capped at 340px and constrained by the central
column; short windows scroll inside the card. At 600px and below, it remains a
reading sheet above the mobile reply/navigation area and safe inset. The
collapsed desktop rail keeps its existing 60dvh height cap.
The blue track extends through the top half of Core's 50px scroller to meet the
handle's center. Shared track and handle sizes keep their horizontal alignment
without changing drag geometry or duplicating reading state. Private messages
and nested views keep their existing navigation. The layout lives in
`stylesheets/topic-reading.scss`, imported by `common/common.scss`; sync that
extra SCSS field with the two reading JavaScript modules and locale additions.
The extra SCSS field is named `topic-reading` without its file extension.
When syncing an older live export, limit the desktop navigation hiding rule with
`:not(.isbf-topic-reading)`, and wrap the rail's existing panels with
`isbf-v2-rail__content`.

The topic footer uses the same 16px inset as posts. Share, bookmark, and reply
stay visible with labels; the theme's More menu receives the core footer button
actions through the existing `topic-footer-main-buttons-before-create` outlet
and contains flag and mark-unread on desktop. Core's mobile action menu remains
in use at phone widths; nested topic controls keep their Core layout.

The `topic-list-class` transformer marks discovery and suggested lists with
`isbf-v2-topic-list` and their respective `--discovery` or `--suggested` modifier.
Keep the block layout for the table and its body scoped to discovery lists;
suggested lists need native table layout for full-width row separators. Their
activity times align to the end with the same 16px inset as topic posts.

For local browser checks in `discourse_dev`, run `pnpm playwright-install` as
`discourse`. If Chromium cannot start because system libraries are missing, run
`pnpm exec playwright install-deps chromium` as root. The install script skips
the headless shell, so launch Playwright with `channel: "chromium"`.

If the local Pitchfork process exits repeatedly, the existing Puma server can
restore the development site. Check that port 3000 is free first and preserve
independent test instances:

```bash
RAILS_ENV=development bin/rails server -u puma -b 0.0.0.0 -p 3000
```

The explicit environment is required because `bin/rails server` otherwise
redirects to Pitchfork.

The calendar and workbench routes, and the private calendar entry API, require
the `isbf-calendar` plugin. Community events use Discourse Events and the
`calendar_category_id` and `calendar_category_path` theme settings.

Per-post anonymous publishing requires `plugins/isbf-anonymous`, Discourse's
`allow_anonymous_mode` setting, and `anonymous_posting_allowed_groups` containing
`trust_level_0` (group 10). The plugin uses the core shadow identity; its private
`/isbf-anonymous/api/posts` endpoint resolves all rotated identities for the
logged-in owner. Anonymous posts cannot be edited or deleted by non-staff after
publishing. The core full-session anonymous switch is denied by the plugin.
