"""Finalize the plugin migration with the runtime's native Rails generator."""
from pathlib import Path
import re
import subprocess


MIGRATION_NAME = "CreateIsbfMbtiResults"
MIGRATION_SUFFIX = "_create_isbf_mbti_results.rb"
MARKER = "# Generated with bin/rails g plugin_migration CreateIsbfMbtiResults --plugin-name=isbf-mbti"
DECLARATION = re.compile(r"class CreateIsbfMbtiResults < ActiveRecord::Migration\[(\d+\.\d+)\]")


def finalize(plugin: Path) -> Path:
    template = (plugin / "db/templates/create_isbf_mbti_results.rb").read_text(encoding="utf-8")
    if template.count("NATIVE_MIGRATION_VERSION") != 1 or MARKER not in template:
        raise RuntimeError("Expected one native-version placeholder and generator marker")
    migrations = plugin / "db/migrate"
    existing = list(migrations.glob(f"*{MIGRATION_SUFFIX}"))
    if len(existing) > 1:
        raise RuntimeError("Multiple MBTI result migrations exist")
    if not existing:
        subprocess.run(
            ["bin/rails", "g", "plugin_migration", MIGRATION_NAME, "--plugin-name=isbf-mbti"],
            check=True,
        )
        generated = list(migrations.glob(f"*{MIGRATION_SUFFIX}"))
        if len(generated) != 1:
            raise RuntimeError("Native generator did not produce exactly one MBTI migration")
        migration = generated[0]
        declaration = DECLARATION.search(migration.read_text(encoding="utf-8"))
        if not declaration:
            raise RuntimeError("Unexpected native migration class or Rails version")
        content = template.replace("NATIVE_MIGRATION_VERSION", declaration.group(1))
        migration.write_text(content, encoding="utf-8", newline="\n")
    else:
        migration = existing[0]
        content = migration.read_text(encoding="utf-8")
        declaration = DECLARATION.search(content)
        if not declaration or MARKER not in content:
            raise RuntimeError("The existing migration was not finalized by the native generator")
        expected = template.replace("NATIVE_MIGRATION_VERSION", declaration.group(1))
        if content.strip() != expected.strip():
            raise RuntimeError("Migration differs from its schema template; review before continuing")
    return migration


if __name__ == "__main__":
    plugin = Path(__file__).resolve().parents[1]
    migration = finalize(plugin)
    print(migration.relative_to(Path.cwd()))
