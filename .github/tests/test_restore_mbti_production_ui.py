import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/restore-mbti-production-ui.py"
SPEC = importlib.util.spec_from_file_location("restore_mbti_production_ui", SCRIPT)
restore = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(restore)


def digest(value):
    return hashlib.sha256(value).hexdigest()


class RestoreMbtiProductionUiTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = self.root / "source"
        self.target = self.root / "target"
        self.source.mkdir()
        self.target.mkdir()
        self.existing = "frontend/discourse/app/ui-kit/d-example.gjs"
        self.added = "app/assets/stylesheets/common/components/example.scss"
        self.manifest = {
            "core_head": "1" * 40,
            "source_commit": "2" * 40,
            "observed_date": "2026-10-29",
            "audit_sha256": "3" * 64,
            "files": [
                {"path": self.existing, "sha256": digest(b"new"), "base_sha256": digest(b"old")},
                {"path": self.added, "sha256": digest(b"added"), "base_sha256": None},
            ],
        }
        self.write(self.source, self.existing, b"new")
        self.write(self.source, self.added, b"added")
        self.write(self.target, self.existing, b"old")

    def write(self, root, path, value):
        destination = root / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(value)

    def assert_untouched(self):
        self.assertEqual((self.target / self.existing).read_bytes(), b"old")
        self.assertFalse((self.target / self.added).exists())

    def test_restores_existing_and_missing_files_and_is_idempotent(self):
        self.write(self.target, "unrelated.txt", b"preserved")
        receipt = restore.restore_files(self.manifest, self.source, self.target)
        self.assertEqual((self.target / self.existing).read_bytes(), b"new")
        self.assertEqual((self.target / self.added).read_bytes(), b"added")
        self.assertEqual((self.target / "unrelated.txt").read_bytes(), b"preserved")
        self.assertEqual([entry["status"] for entry in receipt["files"]], ["restored", "restored"])
        again = restore.restore_files(self.manifest, self.source, self.target)
        self.assertEqual([entry["status"] for entry in again["files"]], ["unchanged", "unchanged"])

    def test_tampered_later_source_prevents_all_writes(self):
        self.write(self.source, self.added, b"tampered")
        with self.assertRaisesRegex(ValueError, "Source hash"):
            restore.restore_files(self.manifest, self.source, self.target)
        self.assert_untouched()

    def test_dirty_later_target_prevents_all_writes(self):
        self.write(self.target, self.added, b"someone else's change")
        with self.assertRaisesRegex(ValueError, "Target differs"):
            restore.restore_files(self.manifest, self.source, self.target)
        self.assertEqual((self.target / self.existing).read_bytes(), b"old")
        self.assertEqual((self.target / self.added).read_bytes(), b"someone else's change")

    def test_missing_base_file_is_rejected(self):
        (self.target / self.existing).unlink()
        with self.assertRaisesRegex(ValueError, "Target differs"):
            restore.restore_files(self.manifest, self.source, self.target)
        self.assertFalse((self.target / self.existing).exists())
        self.assertFalse((self.target / self.added).exists())

    def test_unsafe_or_non_public_paths_are_rejected_before_writes(self):
        for path in [
            "/frontend/discourse/example.js",
            "frontend/discourse/../example.js",
            "frontend/discourse/./example.js",
            "frontend/discourse//example.js",
            "C:/frontend/discourse/example.js",
            "frontend\\discourse\\example.js",
            "frontend/discourse/example.json",
            "plugins/example/main.js",
        ]:
            with self.subTest(path=path):
                manifest = json.loads(json.dumps(self.manifest))
                manifest["files"][1]["path"] = path
                with self.assertRaises(ValueError):
                    restore.restore_files(manifest, self.source, self.target)
                self.assert_untouched()

    def test_duplicate_paths_are_rejected(self):
        self.manifest["files"].append(dict(self.manifest["files"][0]))
        with self.assertRaisesRegex(ValueError, "unique"):
            restore.restore_files(self.manifest, self.source, self.target)
        self.assert_untouched()

    def test_symbolic_links_in_roots_ancestors_and_files_are_rejected(self):
        for role, location in [
            ("source", "root"),
            ("target", "root"),
            ("source", "ancestor"),
            ("target", "ancestor"),
            ("source", "file"),
            ("target", "file"),
        ]:
            with self.subTest(role=role, location=location):
                origin = self.source if role == "source" else self.target
                source, target = self.source, self.target
                if location == "file":
                    link = origin / self.existing
                    value = link.read_bytes()
                    outside = self.root / f"outside-{role}.gjs"
                    outside.write_bytes(value)
                    link.unlink()
                    linked = outside
                else:
                    link = self.root / f"link-{role}-{location}"
                    if location == "ancestor":
                        link.mkdir()
                        link = link / "child"
                    linked = origin
                    if role == "source":
                        source = link
                    else:
                        target = link
                try:
                    link.symlink_to(linked, target_is_directory=location != "file")
                except OSError as error:
                    if location == "file":
                        link.write_bytes(value)
                    self.skipTest(f"Creating symbolic links is unavailable: {error}")
                try:
                    with self.assertRaisesRegex(ValueError, "symbolic links"):
                        restore.restore_files(self.manifest, source, target)
                finally:
                    link.unlink()
                    if location == "file":
                        link.write_bytes(value)
                self.assert_untouched()

    def test_non_directory_target_ancestor_prevents_all_writes(self):
        (self.target / "app").write_bytes(b"not a directory")
        with self.assertRaisesRegex(ValueError, "ancestors"):
            restore.restore_files(self.manifest, self.source, self.target)
        self.assert_untouched()

    def test_cli_requires_actions_and_exact_local_heads(self):
        manifest_file = self.root / "manifest.json"
        manifest_file.write_text(json.dumps(self.manifest), encoding="utf-8")
        args = ["--manifest", str(manifest_file), "--source", str(self.source), "--target", str(self.target)]
        with mock.patch.dict(os.environ, {"GITHUB_ACTIONS": "false"}), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                restore.main(args)
        for heads in [["f" * 40], [self.manifest["source_commit"], "f" * 40]]:
            with self.subTest(heads=heads):
                with mock.patch.dict(os.environ, {"GITHUB_ACTIONS": "true"}), mock.patch.object(
                    restore, "_head", side_effect=heads
                ), contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit):
                        restore.main(args)
                self.assert_untouched()


if __name__ == "__main__":
    unittest.main()
