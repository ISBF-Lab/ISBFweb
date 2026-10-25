# Public name field instructions

The profile editing name field now explains that the name is displayed publicly.
The optional Chinese instruction is `用于对外展示的姓名（可选）`; the required
instruction omits the optional marker. English uses `Your publicly displayed name`
with the same optional distinction.

Only `js.user.name.instructions` and `js.user.name.instructions_required` change
in the English and Simplified Chinese client locales. Account preferences and the
existing signup name hint share these translations. Labels, validation, required
settings, saving, and the existing presentation remain unchanged.

This is a development change after the captured production migration. Migration
manifests remain evidence of the original capture. Publish these four values
through native translation overrides, preserving unrelated overrides, source,
plugins, theme fields, and settings. This refreshes locale caches without an
application rebuild or restart; the source defaults are also kept in the PR.

Validation: targeted `bin/lint --fix`, YAML syntax checks for both locales, and
the English i18n linter passed in the isolated development container. The change
introduces no layout, style, or form behavior changes.
