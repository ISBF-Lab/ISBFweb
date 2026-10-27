"""Generate the final plugin migration name using the native Rails generator in CI."""
from pathlib import Path
import subprocess

plugin = Path(__file__).resolve().parents[1]
paths = list((plugin / "db/migrate").glob("*_create_academy_student_group_batches.rb"))
if len(paths) != 1:
    raise SystemExit("Expected exactly one batch migration")
source = paths[0]
marker = "# Generated with bin/rails g plugin_migration CreateAcademyStudentGroupBatches"
content = source.read_text(encoding="utf-8")
if marker not in content:
    temporary = Path("tmp/student-group-migration-body.rb")
    temporary.parent.mkdir(parents=True, exist_ok=True)
    source.rename(temporary)
    try:
        subprocess.run([
            "bin/rails", "g", "plugin_migration", "CreateAcademyStudentGroupBatches",
            "--plugin-name=discourse-academy-roles",
        ], check=True)
        generated = list((plugin / "db/migrate").glob("*_create_academy_student_group_batches.rb"))
        if len(generated) != 1:
            raise SystemExit("Native migration generation did not produce one file")
        skeleton = generated[0].read_text(encoding="utf-8")
        declaration = "class CreateAcademyStudentGroupBatches < ActiveRecord::Migration[8.0]"
        if declaration not in skeleton or declaration not in content:
            raise SystemExit("Native migration class/version differs from the proposed schema")
        generated[0].write_text(content.replace("# frozen_string_literal: true", "# frozen_string_literal: true\n\n" + marker, 1), encoding="utf-8")
    except BaseException:
        if not source.exists():
            source.write_text(content, encoding="utf-8")
        raise
