# Campus feed UI verification history

These notes preserve the workspace verification record from October 8, 2026.
They describe that release, rather than the latest main behavior or approval scope.
The current theme README and design-system records take precedence for new work.

Public profile activity uses compact post previews with the original category,
time, avatar link, and expansion control. Untitled markers stay internal; previews
extract text and up to three images from cooked posts without image filenames.
Recent discussions reuse the same preview with two text lines and one thumbnail
for untitled topics. Category badges in activity use the native square style.
Cooked content loads near the viewport through the shared four-request queue,
deduplicates requests, and uses a 50-post LRU cache. Activity previews retain only
the extracted summary, while drafts, bookmarks, and messages keep their native UI.
Topic-card like toggles precede their native count so both likes and views place
the icon before the number.


Profile-cover spacing belongs to `.about.no-background`, where the theme supplies
its placeholder banner. Uploaded covers start directly below the page header;
applying that spacing to `.has-background` leaves a blank strip above the image.
At the `sm` viewport breakpoint, post metadata wraps: the author/name area uses
the first row, followed by the account and time. Names and accounts wrap instead
of using percentage caps and ellipses, including when a title or staff badge is
present. Keep the More control's reserved space independent of those rows.

Grouped notifications always show their topic's action groups. Each action row
has one detail toggle; there is no additional topic-level collapse control.
The notification menu suppresses native markers and generated `summary::before`
indicators within its own scope, preserving folded details in post content.

Action detail requests keep the latest notification and toggle in place while
loading. The loading announcement is screen-reader-only, and an empty detail
container does not enter the layout. Returned entries, errors, and pagination
controls render within the expanded details. The feed-style topic footer hides
the extra left-side reactions summary, retaining the right-side native like
control, count, and liked-users menu.

The October 8, 2026 UI verification uses the local main theme ID 4 and the default
calendar preview copy ID 6. Their common SCSS differs, so apply the focused
patches to each current field rather than replacing one with the other's source.
Backups, field comparisons, synchronization/rollback scripts, browser reports,
and before/after screenshots are kept in `deploy-work/ui-layout-fix-20261008/`.
Theme settings, components, and the selected default theme stay intact.
Chromium and WebKit checks pass at 320px, 375px, and 430px phone widths and a
1440px desktop width in light and dark modes. Uploaded-cover spacing, complete
phone author/account text, independent notification folding, lazy loading,
retry, pagination, and keyboard controls are covered by the saved reports.
