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

The page-header, marketplace, learning, and alumni back links share the
`isbf-back-navigation` service. Normal clicks traverse the current tab's browser
history, retaining native scroll restoration and query parameters. The service
records successful pushes and replacements by the browser history UUID, updates
its position on `popstate`, and persists through `sessionStore`. Capture the
current UUID before leaving or reloading: topic reading can replace it without
a route event. Unknown UUIDs start a new history boundary, including new tabs
with copied session storage. Without a recorded predecessor, page headers use
`/latest`, and marketplace, learning, and alumni use `/isbf/workbench`.
Modified clicks follow the rendered return URL as ordinary links. Regression
coverage lives in `test/unit/back-navigation-history-test.js` and
`test/integration/back-navigation-test.gjs`; validation is limited to these
flows, changed-file lint, and theme JavaScript compilation.

The `discourse/initializers/isbf-back-navigation` initializer registers and starts
the service through the application owner, the second initializer argument.
The first argument is the lookup container and does not support registration.
Rendering tests invoke this entry point with the actual container and owner so
startup errors are covered alongside the back-link behavior.

The production release also patches the current shared headers in
`isbf-workbench-topic-page` (marketplace/teamup) and `isbf-resource-page`
(learning/library). The marketplace and learning sources in this export use
older layouts; the active theme delegates those headers to the shared views.
The release merges into the live fields and preserves those delegated pages,
the library, teamup, and other deployed features. Actual source versions and
rollback details are recorded in
`docs/design-system/deployments/back-navigation-20261014/`. Obtain a fresh live
export before updating these fields; do not replace them with the older layouts.

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

Official activity times and deadlines are provided by `isbf-calendar` 0.3.0.
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

The official feed places an activity summary after the post body and before the
existing action footer. Each activity has a title and a two-column grid of
activity time, registration deadline, location, and organizer on both desktop
and mobile. Missing registration deadlines display None; blank locations and
organizers display Not provided. Ordinary announcements have no schedule block,
and independent deadlines use compact name/time rows. The latest feed retains
its existing summary. Theme color variables support light and dark modes.
The standard official category list also uses this layout when the dedicated
campus/type feed is unavailable. Match the configured official category path
with a segment boundary so other categories and the latest feed remain separate.

The editor groups an activity with its optional registration deadline while
submitting the existing flat source array. Activity rows link to deadline rows
using `registration_deadline_index`; saved responses use stable IDs. The helper
retains existing IDs and revisions, and counts a linked deadline toward the
20-item limit. Historical deadlines remain independent until explicitly linked.
Location and organizer belong to the official display and publication history;
they do not alter personal calendar snapshots or time-change notifications.

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

`isbf-user-display` scopes name priority to regular feed-style topic posts without
changing global name settings. The feed and grouped notification entries share
`user-display`; received notification labels include the name and `@username`
when a name is available. Native notification menus keep their renderers, links,
counts, group names and read-state handling. Empty names fall back to usernames.
The live feed includes home-pinning changes absent from this source export; merge
only the author getter and import into its current field when deploying this fix.
The actual merged source, checks and conditional rollback are recorded in
`docs/design-system/deployments/user-display-20261013/`.

Regular topic posts use the full central column. Reading reuses Core's single
topic navigation instance and reading state without moving Ember-owned nodes.
The timeline starts collapsed at every viewport width. When progress is available,
the header button opens a content-sized frosted-glass panel at the viewport's
right edge, below the header. The right rail reserves no reading space.
Core keeps short single-post timelines hidden and long single-post timelines
available. Remaining admin and language controls stay accessible.

On feed-style topics, the hidden `.d-header-wrap` mirrors the visible 60px page
header with a fixed, non-interactive measurement box. Core's header service and
post jump lock then align the target article immediately below that header on
desktop and mobile. Do not remove the measurement box or add a second scroll
correction; other topic layouts keep their existing header measurements.

The header progress button uses Core's stream index and expansion event. Dates,
counts, and reading information appear on the left; the track and handle appear
on the right. The panel uses 12px padding, 60% theme-background opacity,
and 24px blur, as requested for this floating region. At 600px and below, it reserves the existing 130px
bottom clearance plus safe inset; short windows scroll inside the panel.
The header button, close control, outside press, and Escape dismiss reading.
Explicit dismissal restores opener focus; outside dismissal preserves target
focus. Native jump dialogs and nested menus retain their interactions.
The panel cancels the old sheet swipe while retaining native pointer dragging.
The blue track extends through the top half of Core's 50px scroller to meet the
handle's center. Shared track and handle sizes keep their horizontal alignment
without changing drag geometry or duplicating reading state. Private messages
and nested views keep their existing navigation. The layout lives in
`stylesheets/topic-reading.scss`, imported by `common/common.scss`; sync that
extra SCSS field with the two reading JavaScript modules and locale additions.
The extra SCSS field is named `topic-reading` without its file extension.
The return button sits in the footer beside jump and notification controls,
using the native return threshold and filtered stream index. Native embedded
return buttons are hidden only in this reading region. The theme's
`isbf-close-on-click-outside` modifier extends the existing UI kit modifier and
installs its listener during capture, so this release needs no Core changes.
The proposal, source hashes, and validation boundaries are recorded in
`docs/design-system/proposals/topic-timeline-floating-20261013.md` and its review
directory. Final visual acceptance is pending the user's review.
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

## Reply conversations (candidate, not deployed)

The [approved interaction plan](../../docs/design-system/proposals/reply-conversations-20261015.md)
groups ordinary topic replies by their root. Descendants render once, oldest first,
at one level of indentation derived from the avatar radius plus the existing 12px gap.
The initial preview shows three replies; expansion pages
through 50 replies and collapse restores the preview. Reply context loads on demand
through the existing permission-checked post endpoint and links to the exact original floor.

The `nested-topic-navigation` outlet mounts one native `TopicNavigation`/`TopicTimeline` pair.
The optional timeline `navigation` adapter exposes `total`, `lastReadIndex`,
`dateForIndex(index)`, `label(index)`, `loadedAllPosts`, and
`excerpt(index)`. Labels show only the current / total group index, such as `1 / 2`.
The theme adds `jumpToIndex(index)` and
`jumpToPostNumber(number)`; the core container uses the optional adapter and retains
its normal post-stream behavior otherwise. `topic:group-scrolled` carries the group
index and fraction. Group navigation resolves server metadata before using canonical
`/t/slug/id/floor` routes, so floor numbers are never treated as group ordinals.

Server navigation and root responses share the same oldest-first ordering, pinned
root priority and visible descendant relation. Targeted pages retain the first three
replies plus the target's 50-reply page, with explicit controls for missing earlier
replies and root pages. Requests and cached state are scoped to their topic.
The selected straight-branch design starts its one-pixel trunk at the root avatar's
bottom center and joins reply avatars with horizontal 12px branches. The resulting
indent is currently 33px; the trunk ends at the last reply avatar's center. The earlier
page control participates in the trunk to preserve its continuity across a target-page
gap. Colors use the existing strong border token; the collapse button uses the normal
Collapse label. See the [selected reference](../../docs/design-system/reviews/reply-conversations-20261015/guide-redesign/README.md).

The [review directory](../../docs/design-system/reviews/reply-conversations-20261015/README.md)
contains desktop/mobile light/dark previews, test sources, limitations, and prepared
activation settings. It does not change default core settings or production. Existing
and new regular topics enter this view when the site-wide nested default is enabled;
private messages, embedded views, chat and admin interfaces keep their dedicated UI.

## Continue reading footer (2026-10-16)

The `more-topics-content` wrapper outlet presents the existing suggested and related topic records
with `isbf-continue-reading` components and `stylesheets/continue-reading.scss`. It retains native
mode selection, topic order, author data, unread semantics, navigation and tracking counts.
Private messages and unknown plugin modes yield to the original components. The footer shares
`BrowseMore.topicBrowseMoreData`; preserve its message-count dependency and all effective URLs.

The stylesheet is imported locally by `common/common.scss`. Do not extend these rules to discovery
lists or change the recommendation provider. Source snapshots, checks, local fixture instructions
and acceptance boundaries are in `docs/design-system/reviews/continue-reading-20261016/README.md`.

2026-10-16：继续阅读已技术发布，仅接管普通话题底部的两种已知来源。实际合并源码、原生检查和恢复见[发布记录](../../docs/design-system/deployments/continue-reading-20261016/README.md)，最终视觉仍待用户核验。
