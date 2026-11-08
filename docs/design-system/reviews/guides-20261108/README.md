# Guides center and file-authored tutorials

The approved Guides delivery adds member-only reading and administrator draft,
preview, publish and unpublish flows. HTML and ZIP imports retain the original
Android tutorial's semantic layout, chapters, step anchors and screenshot bytes.
Existing Markdown guides remain editable; their stored digests are preserved.

## Approved appearance and authoring

- Reuse the A01/C04 shell and A04/C09 reading language with existing site tokens.
- List hover highlights only the title and arrow. The directory is collapsed above
  the body on desktop and phone; steps use side-by-side text/images where space permits.
- Preserve information cards, badges, callouts, figures, captions and the native viewer.
- Maintain content through UTF-8 HTML or ZIP, with a standard template and portable
  draft-source download. Scripts, global CSS and external image fetches are excluded.
- Keep saved drafts and image references private until explicit publication, with
  stale-version protection and unchanged live content while importing a replacement.
- Guides is the last workbench business entry, including when MBTI is available.
  It uses an independent solid-color compass, enlarged by 15% inside the existing
  icon container. The user requested no additional icon acceptance before release.

Source lives in `plugins/isbf-guides/` and the scoped theme integration. No new
whole-site visual tokens or acceptance scope are implied.

## Verification

Development completed 162 backend examples without failures, full import/download/
preview/publication/privacy browser flows, original text/ID/image-byte comparisons,
responsive and light/dark checks, and native scoped lint. The final icon revision
passed scoped native lint; existing page receipts cover its size, fill and position.
Repository CI additionally checks the plugin suite, editor async lifecycle and the
existing frontend/theme gates, including MBTI coexistence.

The CI follow-up isolates the Guides feature flag in the existing Join menu test
and covers enabled Guides navigation after menu dismissal. Both document renderers
supply the native viewer's known image dimensions, preserving lazy loading and
avoiding screenshot downloads before chapter navigation.

The MBTI production-core job keeps its fixed, audited UI fixture and projects the
reviewed PR patch onto the current target branch's theme. Its explicit theme scope
includes the Guides integration; the complete projected theme must equal the
candidate. Offline checks verified all 259 theme files and rejected stale commits,
branch movement and unreviewed theme paths. All 37 existing fixture-helper tests
passed. The focused Markdown and HTML renderer regression passed all 10 examples
using the release plugin. The full MBTI and frontend gates remain enabled.

The menu regression supplies the router stub's navigation callback explicitly;
both affected native QUnit tests passed all nine assertions in a temporary
development theme, which was then removed. An additive audited fixture restores
the two existing error-page modules required by the current theme into the pinned
CI core. Both public-source hashes match the recorded runtime observations. Five
fixture checks cover restoration, preservation, idempotence, the transitive module
dependency and rejection of modified source before writing any target file.

Account enclosure tests wait for the account request and complete frame positioning
before measuring the original card. Their original one-pixel tolerance and all
geometry assertions remain in place, with explicit edge deltas for diagnostics.
All six native account regressions passed 43 assertions; the temporary development
test field, view and theme settings were restored.

## Release boundary

The user authorized PR, merge and production rollout. Deployment must preserve
unrelated source, plugins, theme fields, settings and data; install only the guarded
Guides changes and required resources. Database migrations and authenticated routing
are prerequisites to switching the former public static Guides location. The Android
source is migrated as real existing content. The iPhone ZIP is delivered separately
for the user to upload and is not automatically published.

Deployment verification and final production state are recorded separately from
code approval. Production validation uses read-only requests and real guide content.
