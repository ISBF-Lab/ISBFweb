# AI Coding Agent Guide

Project-specific instructions for AI agents. MUST be loaded at conversation start.

## Default Mode
- Architect mode enabled by default: detailed analysis, patterns, trade-offs, architectural guidance
- Stop and ask for context if unable to write code meeting guidelines

## Development Rules
Discourse is large with long history. Understand context before changes.

### Toolset
- Use `pnpm` for JavaScript, `bundle` for Ruby
- Use helpers in bin over bundle exec (bin/rspec, bin/rake, bin/lint)

### JavaScript and UI
- No empty backing classes for template-only components unless requested
- Build UI from the ui-kit primitives (`frontend/discourse/app/ui-kit`: `d-*` components, `helpers/`, `modifiers/`) rather than hand-rolling controls, layout, or behaviour; new shared, domain-free primitives go there. See ./docs/developer-guides/docs/03-code-internals/02-ui-kit.md
- Use the skill at `.skills/discourse-frontend-conventions` when writing or reviewing JS/TS/Glimmer classes and templates (private members, member ordering, comments, invocation ordering)
- Use FormKit for forms, see ./docs/developer-guides/docs/03-code-internals/22-form-kit.md (`frontend/discourse/app/form-kit`)
- Use BEM for CSS, see ./docs/developer-guides/docs/03-code-internals/26-css-guidelines-bem.md
- Make display strings translatable (use placeholders, not split strings)
- Use "Sentence case" for strings, not "Proper Case" or "lower case"
- Plugins/themes can't import npm modules directly; add the dependency to core and expose a `frontend/discourse/app/lib/load-*.js` wrapper that does the `import()` (see `load-morphlex.js`).
- Use the skill at `.skills/discourse-warpdrive-models` when creating or changing WarpDrive-backed models (`frontend/discourse/app/data`)

### Frontend Design Consistency

- Use the project skill at [`.skills/isbf-ui-guidelines`](.skills/isbf-ui-guidelines/SKILL.md) when designing, implementing, or reviewing ISBF UI; it routes to the current design references, responsive action rules, and dialog contract.
- Before any UI change, read [UI status](docs/design-system/ui-status.md), [tokens](docs/design-system/tokens.md), [components](docs/design-system/components.md), and [reference map](docs/design-system/reference-map.md).
- Find an Approved reference for the specific region, state, route, and responsive behaviour being changed. Approval of a page shell does not approve every component inside it. Legacy UI, platform default themes, unverified prototypes, and uncommitted changes are not sources of the target visual language.
- Reuse the existing approved components and tokens within their documented scope. Read the complete styles and their later overrides; do not promote local values to global rules or invent new colours, spacing, typography, shapes, or component variants.
- Check [reference provenance](docs/design-system/references/README.md) and its manifest before using a source. The accepted theme snapshot differs from parts of the workspace; reference attachments are non-executable evidence, not installable replacements for the active theme. Authentication has its own dated accepted supplement.
- If a matching approved component or visual rule is missing, mark it as requiring human confirmation and propose a design with its references, reuse boundaries, and unresolved decisions before implementation. Wait for human confirmation of those decisions; do not fill gaps from Discourse defaults or personal preference.
- Continue to use UI kit, FormKit, float-kit, BEM, translations, and the frontend skills required above. Their APIs provide engineering behaviour; their default appearance does not establish this project's design standard.
- When a new region is explicitly approved, persist its actual source version, acceptance scope, tokens, component rules, and reference mapping in `docs/design-system/`. Do not classify a region as Approved solely because it renders or has custom CSS.
- Keep this rollout's worktree and snapshots in persistent storage and follow [its resource policy](docs/design-system/resource-policy.md): serialize work, use one browser tool, and keep the full preview forum stopped on this shared host. Do not use production as a test backend.


### Dialog Consistency

- Follow [the foreground dialog contract](docs/design-system/dialogs.md): use DModal, the dialog service, DButton, and FormKit. The theme supplies the shared frame and text-action appearance automatically.
- Keep dialog chrome in the shared theme stylesheet. Preserve task widths through documented layout variants; do not add private frame/button radii, mobile edge overrides, or inline modal styles.
- Run `pnpm lint:dialogs` when adding or changing dialog templates or styles. Reviewed exceptions require a reason, design reference, and verification entry in `docs/design-system/dialog-exceptions.json`.
- Admin, popup cards, image viewers, editor surfaces, mobile menus, and the accepted standalone recruitment page retain their own presentation. DModal usage alone does not make a mobile menu a task dialog.

### Comments & Types
- Prefer self-documenting code. Comments should only be added when future misunderstanding is likely. They should be terse, and should describe 'why', not 'what'. They should not be used to describe history.
- In the frontend, typescript is typically used for platform-level code, javascript for business-logic
- Platform-level frontend code should include accurate types & tsdoc descriptions for public APIs
- Use the skill at `.skills/discourse-writing-typescript` when authoring .ts/.gts or converting .js/.gjs to TypeScript
- Simple JSDoc/TSDoc comments can be used in other code for editor intellisense, but this is not essential
- In core, never name plugin features or specific libraries in comments/docs — describe by mechanism

## Testing
- Use the skill at `.skills/discourse-writing-rspec-tests` when writing RSpec tests

## Commands

```bash
# JavaScript tests - bin/qunit
bin/qunit --help # detailed help
bin/qunit path/to/test-file.js  # Run all tests in file
bin/qunit path/to/tests/directory # Run all tests in directory
bin/qunit --filter "Some text" # Case-insensitive substring match on "module: test name"
bin/qunit --filter "/Foo|Bar/i" # Slash-wrapped value is a regex (include the "i" flag); use for alternation

# Linting
bin/lint --fix path/to/file path/to/another/file
bin/lint --fix --recent # Lint all recently changed files
```

Run `bin/lint --fix` once after implementation is complete and before handing
off completed changes, committing, or pushing. During iterative edits, only run
lint when it helps diagnose an issue. Prefer passing the specific changed files;
use `bin/lint --fix --recent` only when appropriate.

## Pull requests and CI handoff

- Use the background handoff in [docs/codex-ci-handoff.md](docs/codex-ci-handoff.md) for this repository's PR work, including new conversations. Do not keep a model turn alive to poll CI, sleep repeatedly, or send unchanged progress updates.
- After pushing a PR or a fix, run `python3 script/codex_ci.py watch --pr NUMBER --next-step "the remaining user-authorized work"`. It binds the exact PR head and `CODEX_THREAD_ID`. Never select the most recent session with `--last`.
- Confirm registration succeeds, report that CI is pending, and end the turn. The background worker waits without model calls and resumes the same thread after the applicable checks finish. Do not describe a pending PR as merged or complete.
- If registration fails, repair or report the actual handoff problem; do not claim automatic continuation is configured. Use `doctor` and `status` to inspect it. Foreground model polling is reserved for an explicit user request.
- On a handoff message, read its saved result, verify the live PR head, current checks and review findings, and continue within the user's existing authorization. Merge only when merging was authorized. After another push or CI rerun, register a new wait and end the turn again.
- Before reusing a worktree, check `python3 script/codex_ci.py status`. Keep a handed-off worktree intact; use an isolated worktree for other work. Preserve new edits and other worktrees when a callback arrives.

## Site Settings
- Configured in `config/site_settings.yml` or `config/settings.yml` for plugins
- Functionality in `lib/site_setting_extension.rb`
- Access: `SiteSetting.setting_name` (Ruby), `siteSettings.setting_name` (JS with `@service siteSettings`)

## Services
- Extract business logic (validation, models, permissions) from controllers
- docs/developer-guides/docs/03-code-internals/20-service-objects.md
- Use the skill at .skills/discourse-service-authoring
- Examples: `app/services` (only classes with `Service::Base`)

## Database & Performance
- ActiveRecord: use `includes()`/`preload()` (N+1), `find_each()`/`in_batches()` (large sets), `update_all`/`delete_all` (bulk), `exists?` over `present?`
- Queries: use `explain`, specify columns, strategic indexing, `counter_cache` for counts

## Migrations
- Use the skill at `.skills/discourse-migration` before writing or reviewing any migration

## HTTP Response Codes
- **204 No Content**: Use `head :no_content` for successful operations that don't return data
  - DELETE operations that successfully remove a resource
  - UPDATE/PUT operations that succeed but don't need to return modified data
  - POST operations that perform an action without creating/returning resources (mark as read, clear notifications)
- **200 OK**: Use `render json: success_json` when returning confirmation data or when clients expect a response body
- **201 Created**: Use when creating resources, include location header or resource data
- **Do NOT use 204 when**:
  - Creating resources (use 201 with data)
  - Returning modified/useful data to the client
  - Clients expect confirmation data beyond success/failure

## Security
- XSS: use `{{}}` (escaped) not `{{{ }}}`, sanitize with `sanitize`/`cook`, no `innerHTML`, careful with `@html`
- Auth: Guardian classes (`lib/guardian.rb`), POST/PUT/DELETE for state changes, CSRF tokens, `protect_from_forgery`
- Input: validate client+server, strong parameters, length limits, don't trust client-only validation
- Authorization: Guardian classes, route+action permissions, scope limiting, `can_see?`/`can_edit?` patterns. Use user.guardian shorthand not Guardian.new(user)

## Production Deployments
- Before building or rolling back production, read [the external plugin deployment incident](docs/workbench-plugins-missing-20261010.md).
- Compare the candidate image with the running container's complete plugin inventory, symlink targets, shared release markers, and source hashes, including hidden files. A saved base image or the container's immutable image ID does not include later filesystem changes. Resolve missing plugins before switching production.
- Inspect the active database-backed theme before replacing it with workspace files. Preserve unrelated deployed features, settings, and data during recovery.
- Verify existing feature links and completed data loading in desktop and mobile browsers. Git HEAD, the health endpoint, and the login page alone do not establish deployment completeness. Update the known-good deployment image reference after verification.

## Knowledge Sharing
- ALWAYS persist information for ALL developers (no conversational-only memory)
- Follow project conventions, prevent knowledge silos
- Recommend storage locations by info type
- Inform when this file changes and reloads

## Shared dropdown contract

- Follow [the dropdown contract](docs/design-system/dropdowns.md) for frontend, authentication, admin, themes and plugins.
- Use FormKit/DSelect, the existing SelectKit/DMultiSelect adapters, and DMenu/DDropdownMenu. The shared menu appearance is automatic; keep task-specific trigger shapes.
- Menu surfaces are defined only by the active theme shared dropdown stylesheet. Do not add private menu radii, shadows, opening animations, or visible native selects.
- Menus float beside the trigger on mobile. Non-menu popovers use the explicit surface type and a documented policy entry.
- Run `pnpm test:menus` and `pnpm lint:menus`; the rule also runs in the normal lint and CI workflow.
