# ui-layout

来源：`themes/isbf-campus-feed/README.md`；原文件 SHA-256：`abaac4063f51f75f5cf7f814079acc7300222c2e4d680a034ead2f4e6549e2ee`。

以下为原文摘录。仅证明摘录中说明的检查范围。

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

