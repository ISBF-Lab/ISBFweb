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

- Before any UI change, read [UI status](docs/design-system/ui-status.md), [tokens](docs/design-system/tokens.md), [components](docs/design-system/components.md), and [reference map](docs/design-system/reference-map.md).
- Find an Approved reference for the specific region, state, route, and responsive behaviour being changed. Approval of a page shell does not approve every component inside it. Legacy UI, platform default themes, unverified prototypes, and uncommitted changes are not sources of the target visual language.
- Reuse the existing approved components and tokens within their documented scope. Read the complete styles and their later overrides; do not promote local values to global rules or invent new colours, spacing, typography, shapes, or component variants.
- Check [reference provenance](docs/design-system/references/README.md) and its manifest before using a source. The accepted theme snapshot differs from parts of the workspace; reference attachments are non-executable evidence, not installable replacements for the active theme. Authentication has its own dated accepted supplement.
- If a matching approved component or visual rule is missing, mark it as requiring human confirmation and propose a design with its references, reuse boundaries, and unresolved decisions before implementation. Wait for human confirmation of those decisions; do not fill gaps from Discourse defaults or personal preference.
- Continue to use UI kit, FormKit, float-kit, BEM, translations, and the frontend skills required above. Their APIs provide engineering behaviour; their default appearance does not establish this project's design standard.
- When a new region is explicitly approved, persist its actual source version, acceptance scope, tokens, component rules, and reference mapping in `docs/design-system/`. Do not classify a region as Approved solely because it renders or has custom CSS.

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

## Knowledge Sharing
- ALWAYS persist information for ALL developers (no conversational-only memory)
- Follow project conventions, prevent knowledge silos
- Recommend storage locations by info type
- Inform when this file changes and reloads
