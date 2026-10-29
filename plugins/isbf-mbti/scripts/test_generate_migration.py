"""Exercise the migration helper at its external generator boundary."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "mbti_generate_migration", Path(__file__).with_name("generate-migration.py")
)
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class MigrationGenerationTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.plugin = Path(self.directory.name)
        template = self.plugin / "db/templates/create_isbf_mbti_results.rb"
        template.parent.mkdir(parents=True)
        template.write_text(
            generator.MARKER
            + "\nclass CreateIsbfMbtiResults < ActiveRecord::Migration[NATIVE_MIGRATION_VERSION]\n"
            + "  def change\n    create_table :isbf_mbti_results\n  end\nend\n",
            encoding="utf-8",
        )
        self.output = self.plugin / "db/migrate/20261029091234_create_isbf_mbti_results.rb"

    def native_generator(self, command, check):
        self.assertEqual(
            command,
            ["bin/rails", "g", "plugin_migration", "CreateIsbfMbtiResults", "--plugin-name=isbf-mbti"],
        )
        self.assertTrue(check)
        self.output.parent.mkdir(parents=True, exist_ok=True)
        self.output.write_text(
            "class CreateIsbfMbtiResults < ActiveRecord::Migration[8.1]\nend\n",
            encoding="utf-8",
        )

    def test_preserves_native_filename_and_reuses_final_migration(self):
        with patch.object(generator.subprocess, "run", side_effect=self.native_generator) as native:
            self.assertEqual(generator.finalize(self.plugin), self.output)
            self.assertIn("ActiveRecord::Migration[8.1]", self.output.read_text(encoding="utf-8"))
            self.assertEqual(generator.finalize(self.plugin), self.output)
            native.assert_called_once()

    def test_rejects_a_schema_changed_after_finalization(self):
        with patch.object(generator.subprocess, "run", side_effect=self.native_generator):
            generator.finalize(self.plugin)
        self.output.write_text(self.output.read_text(encoding="utf-8") + "# unreviewed edit\n", encoding="utf-8")
        with self.assertRaisesRegex(RuntimeError, "differs from its schema template"):
            generator.finalize(self.plugin)

    def test_rejects_an_unrecognized_generator_declaration(self):
        def unexpected_generator(*arguments, **options):
            self.output.parent.mkdir(parents=True, exist_ok=True)
            self.output.write_text("class UnexpectedMigration\nend\n", encoding="utf-8")

        with patch.object(generator.subprocess, "run", side_effect=unexpected_generator):
            with self.assertRaisesRegex(RuntimeError, "Unexpected native migration"):
                generator.finalize(self.plugin)


if __name__ == "__main__":
    unittest.main()
