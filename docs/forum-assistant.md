# Forum assistant

The workbench AI assistant answers questions about accessible forum posts, forum
usage, published guides, and workbench resource metadata and links. It uses the
configured existing DeepSeek model and agent. Questions, streamed answers and
follow-ups remain in `/discourse-ai/ai-bot/conversations`; the page has its own
history and composer. Its native header chat and avatar entries are removed.

## Policy and limits

Every question is classified before retrieval. Concrete site questions can use a
subject or event name without adding “on the forum”. Search tries the original
subject and a bounded number of aliases. Replies cite useful matches when the
sources cover the topic but omit a detail the user asked for. General chat,
homework, code generation, translation, external actions and anonymous-author
identification are outside the supported scope.

Course resources and the resource library use their existing catalogue and
published-topic permissions. The assistant searches course or group names,
categories, titles, descriptions and stored filenames. Resource citations point to
site entries. Catalogue overviews list a sample and link to the full collections.
Attachment contents and external pages are not fetched. The server owns model and
agent selection, and conversation APIs expose only the owner's conversations.
Replies follow the current question's language. If a Chinese answer starts in
another language, the assistant displays the authorized sources in Chinese.

Defaults are 20 questions per account per day, three attempts per minute, one
active request per account and 1,000 accepted requests per site per day. Five clear
violations in ten minutes pause this assistant for thirty minutes. Linked accounts
have separate quotas. Questions allow 4,000 characters, answers 2,000 tokens, with a
90-second total deadline. Daily limits reset in Asia/Shanghai. Technical failures
restore the personal daily allowance. Metadata expires after thirty days; native
conversation and AI API audit retention remain independent.

Administrators manage configuration and request metadata at the AI plugin's Forum
assistant page. First activation also enables the persistent ordinary-member
restriction. Disabling the assistant retains this restriction so another bot,
public mention, chat or AI helper cannot become an unrestricted fallback. Existing
administrative AI capabilities retain their separate permissions.

## Activation and publication

New installations leave the feature disabled. For this site's authorized rollout,
reread live configuration and select its existing `deepseek-flash` model and
ChatGPTeek agent by current identifiers. Keep the existing native AI secret; do not
copy a development secret, bot, test account or synthetic conversation.

The additive migration `20261117052611` creates request and quota tables. Apply
only reviewed pending migrations. Compile the core and AI plugin assets against
the actual production runtime, retain old immutable assets, and verify all plugin
directories, hidden files, symlinks, shared release markers and source hashes.
An image ID alone is not a runtime inventory.

Merge only the reviewed workbench component, translations, icon rule, new
assistant stylesheet and brand connector into the database-backed active theme.
Add its single common stylesheet import without replacing other imports. Preserve
all unrelated fields and settings, including newer MBTI and workbench changes.
Follow [the deployment incident record](workbench-plugins-missing-20261010.md)
and [backup retention](production-backup-retention.md). Recheck desktop/mobile
assistant access and existing workbench, marketplace and alumni data loading.

Rollback restores only this release's guarded source/assets/theme changes and
configuration. The additive tables can remain in place; retain recorded questions
and counters. Refuse rollback if a targeted file or field has changed since
publication. Keep the newest verified backup of each type and protect active
runtime/build dependencies.

## Validation and design

Development validation passed 82 distinct backend examples, 44 QUnit tests with
124 assertions, 21 browser checks and two real DeepSeek turns in one conversation.
An additional source-link pass confirmed both answers link to the original forum
post. Native scoped lint and type checks passed. Physical iOS/Safari was not tested.
The full unrelated AI suite was not green: its baseline comparison and limitations
are preserved in the workspace verification record.

The isolated PR worktree is checked again before publication. CI runs the backend
policy suite and targeted composer/workspace QUnit tests, alongside the existing
theme and frontend checks. No real provider credentials are needed for CI.

The user accepted this implementation and requested PR creation and production
publication on 2026-11-17. The accepted appearance is limited to the workbench entry
and dedicated forum conversation workspace; see the
[design record](design-system/reviews/forum-assistant-ui-20261117/README.md).
This document records authorization and deployment requirements; it does not claim
that production publication has already completed.
