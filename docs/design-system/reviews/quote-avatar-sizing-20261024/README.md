# Quote avatar sizing · 2026-10-24

The user reported that a quoted author's avatar fills the mobile feed card and approved restoring its existing size. At widths up to 600px, the feed applies `width: 100%` to every image, overriding the quote renderer's 24×24 HTML attributes. Shared content styles also apply ordinary media width, margin and corner rules to avatars.

The change excludes `img.avatar` from five existing media selectors in `themes/isbf-campus-feed/common/common.scss`: the shared content mixin, feed image height, native topic image overrides, mobile feed media and custom topic body overrides. Quotes retain their native 24×24 circular avatar, while ordinary photos, videos, main author avatars and quote markup keep their existing behavior. No new component, token, public API, setting or migration is introduced.

The accepted scope is A02/C03/C09 for the feed, A04/C03/C09 for ordinary topic content and A12/C03/C12 for expanded public activity content. The four design references record this scoped repair without promoting whole pages to Approved.

## Validation

- Targeted `bin/lint --fix`: Prettier and Stylelint passed without unrelated formatting changes.
- Native theme/core CSS compilation and isolated development theme synchronization passed. Only the common stylesheet changed; 250 other fields and seven saved settings were preserved.
- [Geometry report](geometry-verification.json): 40 passing combinations of 375/390/600/601/1280px, light/dark palettes and feed/custom-topic/native-topic/activity fixtures. A 256px image with native 24px attributes reproduces the original enlargement. Both ordinary and nested quote avatars render at 24×24 after the repair, including after feed expansion.
- The same comparisons preserve photo/video dimensions and appearance, the main author's avatar and quote source `href` values. Long quoted author names are included.
- [Before](before-dark-390.png) and [after](after-dark-390.png) show the synthetic 390px dark-mode fixture. The user's original screenshot remains in the private migration workspace.

These browser checks use native compiled CSS and representative markup in one offline browser. They verify layout rather than the complete publishing lifecycle, quote expansion/navigation handlers or physical iPhone/Safari behavior. Production publication and read-only verification will be recorded separately after merge.

## Source and release boundary

[Source manifest](source-manifest.json) binds the five-selector patch on repository base `bb07007bb950b86f259a2709b1d36f77ef230e0e` and identifies the separately validated active development theme. The migration runtime remains pinned; it is not replaced with this repository's main branch.

Production publication must patch only these five selectors into the current database-backed theme field, preserve other deployed changes, verify native compilation and served CSS, and retain a digest-guarded field backup for rollback. This PR does not authorize importing a complete repository theme over the running database theme.
