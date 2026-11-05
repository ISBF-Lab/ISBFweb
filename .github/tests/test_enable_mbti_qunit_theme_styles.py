import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/enable-mbti-qunit-theme-styles.py"
SPEC = importlib.util.spec_from_file_location("enable_mbti_qunit_theme_styles", SCRIPT)
harness = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(harness)
FIXTURES = Path(__file__).parent / "fixtures"
# Native git-show bytes, not runtime capture or executable templates:
# 132cc95d: blob 9bd11bb58f23258cb1ac1782f08e31e23654e5ad
# 9ca49588: blob 382900edb59d6faf7b7b0b6c16e2d15f79dffa09
BEFORE = (FIXTURES / "mbti-qunit-132.html.erb.txt").read_bytes()
AFTER = (FIXTURES / "mbti-qunit-9ca.html.erb.txt").read_bytes()


class EnableMbtiQunitThemeStylesTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.workspace = Path(directory.name)
        self.source = self.workspace / "production-ui-baseline"
        self.target = self.workspace / "discourse"
        for root, content in ((self.source, AFTER), (self.target, BEFORE)):
            view = root / harness.VIEW
            view.parent.mkdir(parents=True)
            view.write_bytes(content)
        self.target_view = self.target / harness.VIEW
        self.heads = {
            self.source: harness.SOURCE_HEAD,
            self.target: harness.TARGET_HEAD,
        }
        self.head = mock.patch.object(harness, "_head", side_effect=self.heads.__getitem__)
        self.head.start()
        self.addCleanup(self.head.stop)

    def run_harness(self):
        return harness.enable_theme_styles(self.source, self.target)

    def assert_rejected_without_write(self, pattern):
        before = self.target_view.read_bytes()
        with mock.patch.object(Path, "write_bytes") as write:
            with self.assertRaisesRegex(ValueError, pattern):
                self.run_harness()
            write.assert_not_called()
        self.assertEqual(self.target_view.read_bytes(), before)

    def test_native_fixture_provenance_and_exact_patch(self):
        self.assertEqual((len(BEFORE), harness._hash(BEFORE)), (4114, harness.BEFORE_SHA256))
        self.assertEqual((len(AFTER), harness._hash(AFTER)), (4400, harness.AFTER_SHA256))
        self.assertEqual(AFTER.replace(harness.NATIVE_BLOCK, b"", 1), BEFORE)
        unrelated = self.target / "preserved.txt"
        unrelated.write_bytes(b"untouched")
        receipt = self.run_harness()
        self.assertEqual(self.target_view.read_bytes(), AFTER)
        self.assertEqual(unrelated.read_bytes(), b"untouched")
        self.assertEqual(receipt["scope"], "test-only QUnit CSS harness")
        self.assertEqual(receipt["native_source"], harness.SOURCE_HEAD)
        self.assertEqual(receipt["before_sha256"], harness.BEFORE_SHA256)
        self.assertEqual(receipt["after_sha256"], harness.AFTER_SHA256)
        self.assertEqual((receipt["count"], receipt["wrote"]), (1, True))
        with mock.patch.object(Path, "write_bytes") as write:
            again = self.run_harness()
            write.assert_not_called()
        self.assertEqual((again["count"], again["wrote"]), (0, False))

    def test_source_drift_is_rejected(self):
        (self.source / harness.VIEW).write_bytes(AFTER + b"\n")
        self.assert_rejected_without_write("Native source bytes")

    def test_target_drift_is_rejected(self):
        for content in (BEFORE + b"\n", BEFORE.replace(b"<title>", b"<TITLE>"), AFTER + b"\n"):
            with self.subTest(content=content[:20]):
                self.target_view.write_bytes(content)
                self.assert_rejected_without_write("Target bytes")

    def test_wrong_source_and_target_heads_are_rejected(self):
        for root in (self.source, self.target):
            with self.subTest(root=root):
                original = self.heads[root]
                self.heads[root] = "0" * 40
                self.assert_rejected_without_write("checkout HEAD")
                self.heads[root] = original

    def test_tampered_block_or_anchor_is_rejected(self):
        with mock.patch.object(harness, "NATIVE_BLOCK", harness.NATIVE_BLOCK + b"\n"):
            self.assert_rejected_without_write("Native theme CSS block")
        with mock.patch.object(harness, "ANCHOR", b"missing anchor"):
            self.assert_rejected_without_write("exact anchor")

    def test_overlapping_checkouts_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "separate checkouts"):
            harness.enable_theme_styles(self.target, self.target)
        with self.assertRaisesRegex(ValueError, "separate checkouts"):
            harness.enable_theme_styles(self.workspace, self.target)
        self.assertEqual(self.target_view.read_bytes(), BEFORE)

    def test_symlinked_source_file_and_target_ancestor_are_rejected(self):
        probe = self.workspace / "link-probe"
        try:
            probe.symlink_to(self.source, target_is_directory=True)
        except OSError:
            self.skipTest("Symlink creation is unavailable on this platform")
        with self.assertRaisesRegex(ValueError, "symbolic links"):
            harness.enable_theme_styles(probe, self.target)
        source_view = self.source / harness.VIEW
        source_view.unlink()
        source_view.symlink_to(self.target_view)
        self.assert_rejected_without_write("symbolic links")
        source_view.unlink()
        source_view.write_bytes(AFTER)
        self.target_view.unlink()
        qunit = self.target_view.parent
        qunit.rmdir()
        qunit.symlink_to(source_view.parent, target_is_directory=True)
        with mock.patch.object(Path, "write_bytes") as write:
            with self.assertRaisesRegex(ValueError, "symbolic links"):
                self.run_harness()
            write.assert_not_called()
        self.assertEqual(source_view.read_bytes(), AFTER)

    def test_detected_symlink_prevents_all_writes_without_platform_privileges(self):
        linked = self.target_view.parent
        with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda path: path == linked):
            self.assert_rejected_without_write("symbolic links")

    def test_missing_source_prevents_write(self):
        (self.source / harness.VIEW).unlink()
        with mock.patch.object(Path, "write_bytes") as write:
            with self.assertRaises(OSError):
                self.run_harness()
            write.assert_not_called()
        self.assertEqual(self.target_view.read_bytes(), BEFORE)

    def test_cli_guards_reject_non_ci_missing_workspace_and_path_escape(self):
        valid = {"GITHUB_ACTIONS": "true", "GITHUB_WORKSPACE": str(self.workspace)}
        for environment, target in (
            ({}, self.target),
            ({"GITHUB_ACTIONS": "true"}, self.target),
            (valid, self.workspace),
            (valid, self.workspace / "discourse/../../outside"),
        ):
            with self.subTest(environment=environment, target=target):
                with mock.patch.dict(os.environ, environment, clear=True):
                    with contextlib.redirect_stderr(io.StringIO()):
                        with self.assertRaises(SystemExit) as error:
                            harness.main(["--source", str(self.source), "--target", str(target)])
                self.assertEqual(error.exception.code, 2)
                self.assertEqual(self.target_view.read_bytes(), BEFORE)

    def test_cli_emits_json_in_isolated_workspace(self):
        output = io.StringIO()
        with mock.patch.dict(os.environ, {
            "GITHUB_ACTIONS": "true", "GITHUB_WORKSPACE": str(self.workspace),
        }, clear=True):
            with contextlib.redirect_stdout(output):
                harness.main(["--source", str(self.source), "--target", str(self.target)])
        self.assertTrue(json.loads(output.getvalue())["wrote"])
        self.assertEqual(self.target_view.read_bytes(), AFTER)

    def test_cli_rejects_source_outside_the_isolated_checkout(self):
        with mock.patch.dict(os.environ, {
            "GITHUB_ACTIONS": "true", "GITHUB_WORKSPACE": str(self.workspace),
        }, clear=True):
            with contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as error:
                    harness.main(["--source", str(self.workspace), "--target", str(self.target)])
        self.assertEqual(error.exception.code, 2)
        self.assertEqual(self.target_view.read_bytes(), BEFORE)

    def test_head_check_rejects_nested_directory_and_git_failure(self):
        self.head.stop()
        top = subprocess.CompletedProcess([], 0, stdout=str(self.workspace) + "\n")
        with mock.patch.object(subprocess, "run", return_value=top):
            with self.assertRaisesRegex(ValueError, "checkout root"):
                harness._head(self.target)
        with mock.patch.object(subprocess, "run", side_effect=subprocess.CalledProcessError(1, "git")):
            with self.assertRaisesRegex(ValueError, "confirm harness checkout HEAD"):
                harness._head(self.target)

    def test_head_reads_real_git_checkout_under_unicode_directory(self):
        self.head.stop()
        checkout = self.workspace / "中文路径仓库"
        checkout.mkdir()

        def git(*arguments):
            return subprocess.run(
                ["git", "-C", str(checkout), *arguments],
                check=True, capture_output=True, text=True, encoding="utf-8",
            ).stdout.strip()

        git("init")
        git(
            "-c", "user.name=QUnit Harness Test",
            "-c", "user.email=qunit-harness@example.invalid",
            "-c", "commit.gpgsign=false",
            "commit", "--allow-empty", "-m", "Temporary harness HEAD check",
        )
        expected = git("rev-parse", "HEAD")
        self.assertRegex(expected, r"^[0-9a-f]{40}$")
        self.assertEqual(harness._head(checkout), expected)


if __name__ == "__main__":
    unittest.main()
