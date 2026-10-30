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


class MixedSourceTests(unittest.TestCase):
    write = RestoreMbtiProductionUiTests.write
    assert_untouched = RestoreMbtiProductionUiTests.assert_untouched

    def setUp(self):
        RestoreMbtiProductionUiTests.setUp(self)
        self.alternate = self.root / "alternate"
        self.capture = self.root / "capture"
        self.alternate.mkdir()
        self.capture.mkdir()
        self.commit = "4" * 40
        self.captured = "frontend/discourse/app/lib/captured.js"
        self.preserved = "frontend/discourse/app/lib/preserved.js"
        self.manifest["schema"] = 2
        self.manifest["files"][1]["source_commit"] = self.commit
        self.write(self.alternate, self.added, b"added")
        self.write(self.capture, self.captured + ".txt", b"captured")
        self.write(self.target, self.preserved, b"preserved")
        self.manifest["files"].append({
            "path": self.captured, "sha256": digest(b"captured"),
            "base_sha256": None, "capture": True,
        })
        self.manifest["preserved_files"] = [{"path": self.preserved, "sha256": digest(b"preserved")}]
        self.audit = {
            "core_head": self.manifest["core_head"],
            "observed_at": "2026-10-29T15:25:48+00:00",
            "scope": "Public UI source audit",
            "files": [
                {"path": path, "status": "hashed", "bytes": len(content), "sha256": digest(content)}
                for path, content in [
                    (self.existing, b"new"), (self.added, b"added"),
                    (self.captured, b"captured"), (self.preserved, b"preserved"),
                ]
            ],
        }
        self.pin_audit()

    def pin_audit(self):
        self.manifest["audit_sha256"] = digest(json.dumps(
            self.audit, sort_keys=True, separators=(",", ":"), ensure_ascii=False
        ).encode("utf-8"))

    def run_restore(self, **changes):
        options = {"extra_sources": {self.commit: self.alternate}, "audit": self.audit, "capture": self.capture}
        options.update(changes)
        return restore.restore_files(self.manifest, self.source, self.target, **options)

    def test_mixed_sources_capture_and_preservation_are_idempotent(self):
        result = self.run_restore()
        self.assertEqual([entry["status"] for entry in result["files"]], ["restored"] * 3)
        self.assertEqual((self.target / self.captured).read_bytes(), b"captured")
        self.assertEqual((self.target / self.preserved).read_bytes(), b"preserved")
        self.assertEqual(result["preserved_files"], self.manifest["preserved_files"])
        self.assertEqual(result["observed_at"], self.audit["observed_at"])
        self.assertEqual([entry["origin"] for entry in result["files"]], ["git", "git", "runtime_capture"])
        self.assertEqual(result["files"][0]["source_commit"], self.manifest["source_commit"])
        self.assertEqual(result["files"][1]["source_commit"], self.commit)
        self.assertNotIn("source_commit", result["files"][2])
        self.assertEqual([entry["status"] for entry in self.run_restore()["files"]], ["unchanged"] * 3)

    def test_later_alternate_or_capture_tampering_prevents_all_writes(self):
        for root, path, original in [(self.alternate, self.added, b"added"), (self.capture, self.captured + ".txt", b"captured")]:
            with self.subTest(path=path):
                self.write(root, path, b"tampered")
                with self.assertRaisesRegex(ValueError, "Source hash"):
                    self.run_restore()
                self.assert_untouched()
                self.assertFalse((self.target / self.captured).exists())
                self.write(root, path, original)

    def test_missing_or_wrong_audit_prevents_all_writes(self):
        for audit in [None, {}, dict(self.audit, scope="different")]:
            with self.subTest(audit=audit):
                with self.assertRaisesRegex(ValueError, "audit|Audit"):
                    self.run_restore(audit=audit)
                self.assert_untouched()

    def test_audit_hash_alone_does_not_accept_wrong_metadata_or_files(self):
        for key, value in [("core_head", "f" * 40), ("observed_at", "2026-10-28"), ("scope", ""), ("files", [])]:
            with self.subTest(key=key):
                original = self.audit[key]
                self.audit[key] = value
                self.pin_audit()
                with self.assertRaises(ValueError):
                    self.run_restore()
                self.assert_untouched()
                self.audit[key] = original
        self.pin_audit()
        self.audit["files"][2]["bytes"] += 1
        self.pin_audit()
        with self.assertRaisesRegex(ValueError, "byte length"):
            self.run_restore()
        self.assert_untouched()

    def test_missing_duplicate_and_mismatching_audit_file_records_are_rejected(self):
        original = json.loads(json.dumps(self.audit["files"]))
        for records in [
            original[:-1],
            original + [original[0]],
            [dict(entry, sha256="f" * 64) if entry["path"] == self.captured else entry for entry in original],
            [{"path": self.captured, "status": "missing"}] + original[:2] + original[3:],
        ]:
            with self.subTest(records=records):
                self.audit["files"] = records
                self.pin_audit()
                with self.assertRaises(ValueError):
                    self.run_restore()
                self.assert_untouched()

    def test_omitted_hashed_audit_path_prevents_all_writes(self):
        self.audit["files"].append({
            "path": "frontend/discourse/app/lib/omitted.js", "status": "hashed",
            "sha256": digest(b"omitted"), "bytes": len(b"omitted"),
        })
        self.pin_audit()
        with self.assertRaisesRegex(ValueError, "exactly match"):
            self.run_restore()
        self.assert_untouched()
        self.assertFalse((self.target / self.captured).exists())

    def test_audited_missing_targets_must_remain_absent_before_any_write(self):
        missing = "frontend/discourse/app/lib/missing.js"
        self.audit["files"].append({"path": missing, "status": "missing"})
        self.pin_audit()
        self.write(self.target, missing, b"unexpected")
        with self.assertRaisesRegex(ValueError, "must remain absent"):
            self.run_restore()
        self.assert_untouched()
        self.assertEqual((self.target / missing).read_bytes(), b"unexpected")
        (self.target / missing).unlink()
        with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda path: path == self.target / missing):
            with self.assertRaisesRegex(ValueError, "symbolic links"):
                self.run_restore()
        self.assert_untouched()
        self.assertFalse((self.target / self.captured).exists())
        self.assertEqual([entry["status"] for entry in self.run_restore()["files"]], ["restored"] * 3)

    def test_missing_capture_or_preserved_files_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "Capture source"):
            self.run_restore(capture=None)
        self.assert_untouched()
        (self.target / self.preserved).unlink()
        with self.assertRaisesRegex(ValueError, "Preserved target is missing"):
            self.run_restore()
        self.assert_untouched()

    def test_preserved_target_drift_prevents_all_writes(self):
        self.write(self.target, self.preserved, b"drift")
        with self.assertRaisesRegex(ValueError, "Preserved target"):
            self.run_restore()
        self.assert_untouched()
        self.assertFalse((self.target / self.captured).exists())

    def test_ambiguous_unknown_and_unsafe_descriptors_are_rejected(self):
        original = dict(self.manifest["files"][2])
        for descriptor in [
            {"capture": False}, {"capture": "true"}, {"capture": True, "source_commit": self.commit},
            {"origin": "runtime"}, {"source_commit": "unknown"},
            {"path": "frontend/discourse/.private/example.js"},
            {"path": "frontend/discourse/private/example.js"},
        ]:
            with self.subTest(descriptor=descriptor):
                self.manifest["files"][2] = dict(original, **descriptor)
                with self.assertRaises(ValueError):
                    self.run_restore()
                self.assert_untouched()
        self.manifest["files"][2] = original
        self.manifest["preserved_files"].append({"path": self.existing, "sha256": digest(b"new")})
        with self.assertRaisesRegex(ValueError, "unique"):
            self.run_restore()
        self.assert_untouched()

    def test_missing_unknown_or_primary_extra_mappings_are_rejected(self):
        for mapping in [{}, {"5" * 40: self.alternate}, {self.commit: self.alternate, "2" * 40: self.source}]:
            with self.subTest(mapping=mapping):
                with self.assertRaisesRegex(ValueError, "Extra sources"):
                    self.run_restore(extra_sources=mapping)
                self.assert_untouched()

    def test_capture_and_extra_sources_cannot_overlap_target(self):
        for changes in [{"capture": self.target}, {"capture": self.target / "frontend"}, {"extra_sources": {self.commit: self.target}}]:
            with self.subTest(changes=changes):
                with self.assertRaisesRegex(ValueError, "separate"):
                    self.run_restore(**changes)
                self.assert_untouched()

    def test_capture_links_are_rejected(self):
        with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda path: path == self.capture / (self.captured + ".txt")):
            with self.assertRaisesRegex(ValueError, "symbolic links"):
                self.run_restore()
        self.assert_untouched()

    def test_cli_mixed_heads_duplicate_mappings_and_success(self):
        manifest_file = self.root / "manifest.json"
        audit_file = self.root / "audit.json"
        manifest_file.write_text(json.dumps(self.manifest), encoding="utf-8")
        audit_file.write_text(json.dumps(self.audit), encoding="utf-8")
        args = ["--manifest", str(manifest_file), "--source", str(self.source), "--target", str(self.target),
                "--audit", str(audit_file), "--capture", str(self.capture), "--extra-source", f"{self.commit}={self.alternate}"]
        for suffix, heads in [([], ["2" * 40, "1" * 40, "f" * 40]), (["--extra-source", f"{self.commit}={self.alternate}"], ["2" * 40, "1" * 40])]:
            with self.subTest(suffix=suffix), mock.patch.dict(os.environ, {"GITHUB_ACTIONS": "true"}), mock.patch.object(restore, "_head", side_effect=heads), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    restore.main(args + suffix)
                self.assert_untouched()
        with mock.patch.dict(os.environ, {"GITHUB_ACTIONS": "true"}), mock.patch.object(restore, "_head", side_effect=["2" * 40, "1" * 40, self.commit]), contextlib.redirect_stdout(io.StringIO()) as output:
            restore.main(args)
        self.assertEqual(len(json.loads(output.getvalue())["files"]), 3)


if __name__ == "__main__":
    unittest.main()
