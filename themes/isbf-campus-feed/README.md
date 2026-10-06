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

Official campus/type selections are registered by the
`isbf-official-composer` pre-initializer with `addModelField`, `addModelGetter`,
and `addModelMethod`. It runs after `isbf-composer-optional-title` and before
`inject-discourse-objects` so its reset wrapper preserves the optional-title
extension. Each wrapper calls the original method and preserves its result,
including rejected promises. Create/update payloads remain JSON strings and
draft fields remain arrays. The official UI, helper, translations, and styles
were merged from theme ID 4 without replacing unrelated working-tree changes.

For the `discourse.modify-class-model` fix, remove the live
`discourse/api-initializers/isbf-official.gjs` field and add
`discourse/pre-initializers/isbf-official-composer.js` and the
`unit/composer-official-test.js` test field. Sync only those three fields; the
running theme contains newer unrelated changes. The October 6, 2026 backup,
field snapshot, sync report, and rollback script are kept in
`deploy-work/theme-model-api-20261006/` at the repository root. Rollback restores
only those fields through `Theme#set_field` and `save!`, then checks compilation
and the fresh page's JavaScript URL.

Theme regression tests live in `test/`. Test imports use the compiler's
`discourse/` module paths, which omit the source directory's `javascripts/` prefix.
Import this directory into a separate development database and run
`THEME_IDS=ID bin/qunit --rails-env development --rails-port PORT
--theme-id ID --qunit-path /theme-qunit` against that database's server. Do not
reset the running site's database to prepare tests. After validation, compare a
fresh live export with the backup before syncing changed fields, preserve theme
settings and components, check both stylesheet and JavaScript compilation, and
re-export to confirm the repository and live source match.
Keep the frontend build running during browser tests. `THEME_IDS` also supplies
the `id` query parameter needed to select the runner rather than its index page.

Official activity times and deadlines are provided by `isbf-calendar` 0.2.0.
The calendar pre-initializer runs after the campus/type extension and preserves
its reset and open behavior. Drafts keep arrays, while first-post create/update
payloads use JSON strings containing stable source IDs and revisions. Replies,
private messages and other categories omit those fields. Publish/edit uses a
FormKit collection; all official input and display uses Asia/Shanghai, including
date-only deadlines and activities without an end.
The feed card shows a summary; the cooked-post wrapper outlet adds individual
buttons on the detail page. Imported entries only expose a private-note editor.
Pending source updates load separately from the monthly range, and custom
notifications link to `/isbf/calendar?entry_id=ID` for cross-month positioning.
Accepting a source update preserves the note; dismissing acknowledges only that
revision. The UI refreshes conflicts before asking the user to decide again.
The official calendar tests include composer restoration, source time boundaries,
the FormKit editor, add/retry state, update confirmation, note-only writes,
notification routing and existing manual-calendar interactions.

The `/badges` listing and badge detail routes share the V2 shell, including
details filtered by `username`. Keep their cards and grant lists within the
central column; badge data and actions remain Core's own components.

The information pages `/guidelines`, `/faq`, `/about`, `/tos`, and `/privacy`,
including the `/rules` and `/conduct` aliases, share the V2 shell. Their route
matching ignores query strings, fragments, and a trailing slash while keeping
other paths separate. Core retains the page content, navigation, read tracking,
and external URL redirects. Information-page styles keep the content and About
sections within the central column. Sync the shell JavaScript and common SCSS
fields together after backing up and comparing the current live theme.
The theme QUnit runner loads Core's common CSS without the theme's common SCSS.
Use the acceptance tests for routing and content, and real browser checks for
header visibility, column widths, anchor offsets, and light/dark layouts.
Check the configured static-page topics before browser verification. Missing
`tos_topic_id` or `privacy_topic_id` content returns Core's 404 response, while
the acceptance tests supply fixtures for those pages. The shell does not create
or replace policy content.
API-authenticated browser checks must omit `Discourse-Logged-In` from proxied
requests. That header indicates a cookie session; without its cookie, Core sends
`Discourse-Logged-Out` and the frontend discards otherwise valid AJAX data.

The feed card uses the topic-list outlet's navigation callback for clicks on
post text and card space. Keep nested links and action controls independent.
The reply action loads the full topic and its saved draft before opening the
composer; topic-list data alone does not include the required draft key.
Feed-card footer buttons and the view count center their icons and numbers
together. They share a 2.75rem minimum size and 1.375rem icons; phone widths
remove horizontal padding and include the avatar column so localized compact
counts fit the five equal columns. Keep the footer offset tied to the card's
avatar and gap custom properties.
Omit empty count elements so zero-count icons stay centered without a gap.

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
