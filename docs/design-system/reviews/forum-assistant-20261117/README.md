# Forum assistant workbench integration — 2026-11-17

The user approved implementation of a workbench AI entry and forum-only Q&A,
then confirmed the existing DeepSeek model. This record covers implementation
and independent development validation. The user subsequently accepted the dedicated
workspace and authorized a pull request and production deployment on 2026-11-17;
the later workspace record defines that accepted presentation scope.

## Appearance and reuse

- Workbench: A08 / C02 and the later workbench layout settings references.
  Add the “AI 助手” card immediately before Guides, using the existing blue tone,
  `far-discobot` icon renderer, grid geometry, traditional and glass variants.
  Visibility follows the authenticated user's configured assistant status.
- Conversation: reuse the existing AI conversations page and docked composer.
  Add translated scope, remaining allowance, reset time, unavailable, busy and
  cooldown text. Refresh and stop use existing `DButton` actions and 44px targets.
- Administration: retain the approved native admin composition, `DPageSubheader`,
  `AdminConfigAreaCard` and FormKit. The record table scrolls inside its region.
- No new global colors, type scale, radius, surface or dialog variant is introduced.
  The local status text uses `--primary-medium`, `--font-down-1` and `--space-2`.

## Engineering boundaries

The assistant opens `/discourse-ai/ai-bot/conversations`. Its backend enforces the
same policy for new conversations, existing private replies and retries. Interface
restrictions are supplementary. File uploads, participant invitations and public
sharing are unavailable for managed conversations.

The shared core docked composer gains an optional `allowUploads` argument, defaulting
to its existing behavior, and forwards its existing disabled state to the editor.
The rich editor now updates ProseMirror editability when that state changes,
preserving its document while a request is checking or cooling down. Feature-specific
decisions stay in the plugin. The forum conversation uses the existing AI docked
input without requiring the optional general AI docked-input setting.

The workbench component, its two translation entries, tests and one icon fill rule
were merged into development theme 4. The fill rule retains the existing icon's
native filled path inside the glass glyph slot. Each apply preserves unrelated
theme fields; the final stylesheet-only apply preserved 309 other fields.
The helpers in this directory refuse execution outside the independent development
database. The DeepSeek setup consumes the user-supplied key through standard input.

## Evidence

The workspace-level implementation record is
`ISBF-One/docs/forum-assistant-20261117/README.md`. Native backend tests, QUnit,
real-model policy evaluation, browser reports and screenshots are stored alongside
that record in `results/`. Source before-images and the final file manifest are
preserved in `.local/changes/forum-assistant-20261117/`.

Design scope is confirmed; final browser results and any remaining limitations
must be read from the implementation record. No production changes have been made.
