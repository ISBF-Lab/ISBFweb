# topic-reading

来源：`themes/isbf-campus-feed/README.md`；原文件 SHA-256：`abaac4063f51f75f5cf7f814079acc7300222c2e4d680a034ead2f4e6549e2ee`。

以下为原文摘录。只记录既有话题阅读、时间轴和菜单的复用边界，不新增视觉验收范围。

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

