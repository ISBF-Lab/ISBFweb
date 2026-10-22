import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "codex_ci_win", Path(__file__).resolve().parents[1] / "codex_ci_win.py"
)
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


def make_job(**changes):
    job = {
        "id": "10000000-0000-4000-8000-000000000001",
        "repository": "example/forum",
        "pr": 12,
        "sha": "a" * 40,
        "thread": "20000000-0000-4000-8000-000000000001",
        "worktree": "/workspace/forum",
        "next_step": "Finish the already authorized PR task",
        "state": "ready",
        "summary": {"result": "success"},
        "created_at": 0,
    }
    job.update(changes)
    return job


class FakeGitHub:
    def __init__(self):
        self.sha = "a" * 40
        self.checks = [{"id": 1, "name": "test", "status": "completed", "conclusion": "success"}]
        self.statuses = []
        self.runs = []

    def get(self, path):
        if "/pulls/" in path:
            return {"state": "open", "head": {"sha": self.sha}}
        return {"statuses": self.statuses}

    def pages(self, _path, key):
        return self.checks if key == "check_runs" else self.runs


class FakeDesktop:
    def __init__(self):
        self.status = "completed"
        self.queue = []
        self.receipt = False
        self.sent = []
        self.deleted = []
        self.error = None

    def check(self, _thread, _cwd):
        return {"turn": {"status": self.status}}

    def queued(self, _thread):
        return self.queue

    def received(self, _thread, _marker):
        return self.receipt

    def send(self, thread, message):
        self.sent.append((thread, message))
        if self.error:
            raise self.error
        self.queue = [{"id": "submission-1"}]
        return "submission-1"

    def delete(self, _thread, submission):
        self.deleted.append(submission)


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeGitHub()
        self.job = make_job(state="waiting")

    def test_requires_stable_terminal_checks(self):
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 520))
        self.assertEqual(ci.inspect_checks(self.api, self.job, 531)["result"], "success")

    def test_empty_checks_are_not_success(self):
        self.api.checks = []
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertEqual(ci.inspect_checks(self.api, self.job, 531)["result"], "no_checks")

    def test_pending_external_status_blocks_delivery(self):
        self.api.statuses = [{"context": "external", "state": "pending"}]
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 531))

    def test_failure_cannot_be_hidden_by_a_successful_check(self):
        self.api.statuses = [{"context": "external", "state": "failure"}]
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertEqual(ci.inspect_checks(self.api, self.job, 531)["result"], "failure")

    def test_changed_head_cancels_the_wait(self):
        self.api.sha = "b" * 40
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertEqual(self.job["state"], "cancelled")


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.path = Path(self.temporary.name) / "job.json"
        self.api = FakeGitHub()
        self.desktop = FakeDesktop()
        self.job = make_job()

    def deliver(self):
        ci.deliver(self.job, self.path, self.api, self.desktop)

    def test_delivers_to_the_exact_thread_once(self):
        self.deliver()
        self.deliver()
        self.assertEqual(len(self.desktop.sent), 1)
        self.assertEqual(self.desktop.sent[0][0], self.job["thread"])
        self.assertIn(self.job["sha"], self.desktop.sent[0][1])
        self.assertEqual(json.loads(self.path.read_text())["state"], "queued")

    def test_preserves_an_active_turn_and_human_queue(self):
        for active, queued in [("inProgress", []), ("completed", [{"id": "human"}])]:
            with self.subTest(active=active, queued=queued):
                self.desktop.status = active
                self.desktop.queue = queued
                self.deliver()
                self.assertEqual(self.desktop.sent, [])
                self.assertEqual(self.job["state"], "ready")

    def test_requires_a_receipt_after_the_queue_item_disappears(self):
        self.job.update(state="queued", submission_id="submission-1")
        self.deliver()
        self.assertEqual(self.job["state"], "delivery_unknown")
        self.assertEqual(self.desktop.sent, [])

    def test_verified_receipt_completes_delivery(self):
        self.job.update(state="queued", submission_id="submission-1")
        self.desktop.receipt = True
        self.deliver()
        self.assertEqual(self.job["state"], "delivered")

    def test_changed_head_removes_the_stale_queued_callback(self):
        self.job.update(state="queued", submission_id="submission-1")
        self.desktop.queue = [{"id": "submission-1"}]
        self.api.sha = "b" * 40
        self.deliver()
        self.assertEqual(self.desktop.deleted, ["submission-1"])
        self.assertEqual(self.job["state"], "cancelled")

    def test_unknown_acknowledgement_is_never_retried_automatically(self):
        self.desktop.error = ci.HandoffError("Lost acknowledgement")
        with self.assertRaises(ci.HandoffError):
            self.deliver()
        self.assertEqual(json.loads(self.path.read_text())["state"], "delivery_unknown")
        store = ci.Store(Path(self.temporary.name) / "state")
        ci.atomic_json(store.jobs / (self.job["id"] + ".json"), self.job)
        ci.tick(store, self.api, desktop_factory=lambda _job: self.desktop, now=100)
        self.assertEqual(len(self.desktop.sent), 1)

    def test_a_process_that_never_started_remains_retryable(self):
        self.desktop.error = ci.QueueNotStarted("No process")
        with self.assertRaises(ci.QueueNotStarted):
            self.deliver()
        self.assertEqual(json.loads(self.path.read_text())["state"], "ready")


class MetadataTests(unittest.TestCase):
    def test_metadata_connections_cannot_write(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state_5.sqlite"
            with sqlite3.connect(path) as connection:
                connection.execute("CREATE TABLE metadata (id TEXT)")
            with ci.readonly_database(directory, path.name) as connection:
                with self.assertRaises(sqlite3.OperationalError):
                    connection.execute("INSERT INTO metadata VALUES ('changed')")

    def test_worker_lease_is_exclusive_and_released(self):
        with tempfile.TemporaryDirectory() as directory:
            store = ci.Store(Path(directory) / "state")
            with store.lock("worker.lock"):
                self.assertTrue(ci.Store(store.root).running())
            self.assertFalse(store.running())


if __name__ == "__main__":
    unittest.main()
