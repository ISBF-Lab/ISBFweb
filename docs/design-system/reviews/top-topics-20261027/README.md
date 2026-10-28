# Standalone popular-topic ranking

The user approved a standalone `/top` page with a compact ranking list, then authorized production publication. The active theme maps to `themes/isbf-campus-feed` for this PR; the captured production workspace remains pinned and is not replaced with main.

The page reuses the existing shell/back navigation, native discovery controller, TopicList pagination and read tracking, topic links, untitled previews and shared DSelect. Rankings follow server order. Views, replies and likes retain native cumulative counts. Other discovery routes yield their existing content, including bulk-selection mode. No backend endpoint, schema or site setting is introduced.

The accepted visual combination uses A01/C04, A02/C09, C12 and C06 references: a dedicated heading, period selector, continuous ranked rows, two-line titles, one-line excerpts and compact metadata/statistics. Native table rows preserve J/K and Enter navigation. Scoped CSS removes inherited mobile width restrictions, retains visible focus, and follows existing semantic tokens and dark-mode mapping.

Seven focused component/route tests passed 48 assertions; the isolated development browser passed 56 checks across 320–1440px, light/dark modes, six periods, navigation, shared-menu focus and long-content cases. Native file lint and five menu-policy tests passed with zero menu findings. The evidence and source digests are recorded in `source-manifest.json` and `evidence/`; screenshots and production backups remain in the migration workspace rather than this PR.

Production publication waits for this exact PR head to pass required CI and review, then applies only the merged, guarded theme fields. Live theme changes are merged independently and unrelated fields/settings/plugins are preserved. Final user visual acceptance and the actual production release are recorded separately.
