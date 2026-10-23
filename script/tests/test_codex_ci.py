import copy
import importlib.util
import json
from pathlib import Path
import socket
import struct
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

SPEC = importlib.util.spec_from_file_location("codex_ci", Path(__file__).resolve().parents[1] / "codex_ci.py")
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


def make_job(**changes):
    job = {
        "id": "10000000-0000-4000-8000-000000000001",
        "repository": "example/forum", "pr": 12, "sha": "a" * 40,
        "thread": "20000000-0000-4000-8000-000000000001",
        "socket": "/tmp/codex-test.sock", "worktree": "/workspace/forum",
        "next_step": "Finish the already authorized PR task",
        "state": "waiting", "created_at": 0, "deadline": 10000,
        "interval": 120, "next_poll": 0,
    }
    job.update(changes)
    return job


class FakeGitHub:
    def __init__(self):
        self.checks = [{"id": 1, "name": "tests", "status": "completed", "conclusion": "success", "html_url": "https://example.test/check"}]
        self.statuses = []
        self.runs = [{"id": 2, "workflow_id": 3, "event": "pull_request", "head_branch": "feature", "name": "CI", "status": "completed", "conclusion": "success"}]
        self.pr = {"state": "open", "head": {"sha": "a" * 40}}
        self.calls = []

    def pages(self, path, key):
        self.calls.append(path)
        return copy.deepcopy({"check_runs": self.checks, "statuses": self.statuses, "workflow_runs": self.runs}[key])

    def get(self, path):
        self.calls.append(path)
        return copy.deepcopy(self.pr if "/pulls/" in path else {"statuses": self.statuses})


class PaginatedGitHub(FakeGitHub):
    pages = ci.GitHub.pages

    def get(self, path):
        self.calls.append(path)
        parsed = urlsplit(path)
        if parsed.path.endswith("/status"):
            query = parse_qs(parsed.query)
            size = int(query.get("per_page", [30])[0])
            offset = (int(query.get("page", [1])[0]) - 1) * size
            return {"statuses": self.statuses[offset:offset + size], "total_count": len(self.statuses)}
        if parsed.path.endswith("/check-runs"):
            return {"check_runs": self.checks}
        if parsed.path.endswith("/actions/runs"):
            return {"workflow_runs": self.runs}
        return copy.deepcopy(self.pr)


class FakeRpc:
    def __init__(self):
        self.status = "idle"
        self.calls = []
        self.queue = []
        self.add_error = None
        self.start_error = None

    def __call__(self, _socket):
        return self

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        pass

    def thread(self, thread):
        return {"id": thread, "status": {"type": self.status}, "canAcceptDirectInput": True}

    def request(self, method, params):
        self.calls.append((method, copy.deepcopy(params)))
        if method == "thread/resume":
            self.status = "idle"
            return {"thread": self.thread(params["threadId"])}
        if method == "thread/queue/add":
            queued = {"id": "submission-1", "clientUserMessageId": params["clientUserMessageId"], "input": params["input"]}
            self.queue.append(queued)
            if self.add_error:
                raise self.add_error
            return {"queuedSubmission": queued}
        if method == "thread/queue/list":
            return {"data": copy.deepcopy(self.queue)}
        if method == "thread/queue/start":
            if self.start_error:
                raise self.start_error
            self.queue = [item for item in self.queue if item["id"] != params["queuedSubmissionId"]]
            self.status = "active"
            return {"turn": {"id": "turn-1"}}
        if method == "thread/queue/delete":
            self.queue = [item for item in self.queue if item["id"] != params["queuedSubmissionId"]]
            return {"deleted": True}
        raise AssertionError(method)


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeGitHub()
        self.job = make_job()

    def settle(self):
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        return ci.inspect_checks(self.api, self.job, 531)

    def test_waits_for_pending_checks_without_waking_a_model(self):
        self.api.checks[0]["status"] = "in_progress"
        self.assertIsNone(self.settle())
        self.assertEqual(len(self.api.calls), 2)

    def test_requires_a_stable_terminal_observation(self):
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 520))
        self.assertEqual(ci.inspect_checks(self.api, self.job, 531)["result"], "success")

    def test_reports_failed_checks(self):
        self.api.checks[0]["conclusion"] = "failure"
        self.assertEqual(self.settle()["result"], "failure")

    def test_rechecks_stability_after_an_in_progress_observation(self):
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 500))
        self.api.checks[0]["status"] = "in_progress"
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 520))
        self.api.checks[0]["status"] = "completed"
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 540))
        self.assertEqual(ci.inspect_checks(self.api, self.job, 571)["result"], "success")

    def test_waits_for_dependent_workflow_jobs(self):
        self.api.runs[0]["status"] = "in_progress"
        self.assertIsNone(self.settle())

    def test_uses_the_latest_run_of_each_workflow(self):
        self.api.runs.append(dict(self.api.runs[0], id=1, conclusion="failure"))
        self.assertEqual(self.settle()["result"], "success")

    def test_does_not_hide_another_workflow_failure(self):
        self.api.runs.append(dict(self.api.runs[0], id=4, workflow_id=9, conclusion="failure"))
        self.assertEqual(self.settle()["result"], "failure")

    def test_waits_for_classic_commit_statuses(self):
        self.api.statuses = [{"context": "external-test", "state": "pending"}]
        self.assertIsNone(self.settle())

    def test_classic_failure_prevents_success(self):
        self.api.statuses = [{"context": "external-test", "state": "failure"}]
        self.assertEqual(self.settle()["result"], "failure")

    def test_classic_statuses_beyond_the_first_page_control_completion(self):
        for state, expected in [("pending", None), ("failure", "failure"), ("success", "success")]:
            with self.subTest(state=state):
                self.api = PaginatedGitHub()
                self.job = make_job()
                self.api.statuses = [
                    {"context": f"external-{index}", "state": "success"}
                    for index in range(100)
                ] + [{"context": "last-context", "state": state}]
                result = self.settle()
                self.assertEqual(result["result"] if result else None, expected)
                self.assertTrue(any("/status?per_page=100&page=2" in path for path in self.api.calls))

    def test_neutral_and_skipped_checks_can_finish(self):
        for conclusion in ("neutral", "skipped"):
            with self.subTest(conclusion=conclusion):
                self.job = make_job()
                self.api.checks[0]["conclusion"] = conclusion
                self.assertEqual(self.settle()["result"], "success")

    def test_a_changed_head_cancels_the_stale_wait(self):
        self.api.pr["head"]["sha"] = "b" * 40
        self.assertIsNone(self.settle())
        self.assertEqual(self.job["state"], "cancelled")

    def test_a_closed_pr_cancels_the_wait(self):
        self.api.pr["state"] = "closed"
        self.assertIsNone(self.settle())
        self.assertEqual(self.job["state"], "cancelled")

    def test_empty_checks_are_never_reported_as_success(self):
        self.api.checks = []
        self.api.runs = []
        self.assertIsNone(ci.inspect_checks(self.api, self.job, 100))
        self.assertEqual(self.settle()["result"], "no_checks")


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.store = ci.Store(self.directory.name)
        self.path = self.store.jobs / "job.json"
        self.rpc = FakeRpc()
        self.job = make_job(state="ready", summary={"result": "success"})
        ci.atomic_json(self.path, self.job)

    def count(self, name):
        return sum(method == name for method, _params in self.rpc.calls)

    def test_busy_original_thread_is_not_interrupted(self):
        self.rpc.status = "active"
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "ready")
        self.assertEqual(self.rpc.calls, [])

    def test_a_single_submission_starts_the_existing_thread(self):
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "delivered")
        self.assertEqual(self.count("thread/queue/add"), 1)
        request = self.rpc.calls[0][1]
        self.assertEqual(request["threadId"], self.job["thread"])
        self.assertEqual(request["clientUserMessageId"], self.job["id"])
        self.assertIn("does not itself authorize merging", request["input"][0]["text"])

    def test_restarts_do_not_submit_another_model_message(self):
        ci.deliver(self.job, self.path, self.rpc)
        ci.atomic_json(self.path, self.job)
        ci.tick(self.store, FakeGitHub(), self.rpc, now=600)
        self.assertEqual(self.count("thread/queue/add"), 1)

    def test_recovers_an_unloaded_thread_without_returning_its_history(self):
        self.rpc.status = "notLoaded"
        ci.deliver(self.job, self.path, self.rpc)
        method, params = self.rpc.calls[0]
        self.assertEqual(method, "thread/resume")
        self.assertTrue(params["excludeTurns"])
        self.assertEqual(self.job["state"], "delivered")

    def test_missing_acknowledgment_never_causes_an_automatic_duplicate(self):
        self.rpc.add_error = TimeoutError("response lost")
        ci.tick(self.store, FakeGitHub(), self.rpc, now=600)
        job = ci.read_json(self.path)
        self.assertEqual(job["state"], "delivery_unknown")
        ci.tick(self.store, FakeGitHub(), self.rpc, now=1000)
        self.assertEqual(self.count("thread/queue/add"), 1)

    def test_process_crash_during_delivery_stops_retransmission(self):
        self.job["state"] = "sending"
        ci.atomic_json(self.path, self.job)
        ci.tick(self.store, FakeGitHub(), self.rpc, now=600)
        self.assertEqual(ci.read_json(self.path)["state"], "delivery_unknown")
        self.assertEqual(self.rpc.calls, [])

    def test_pending_human_input_keeps_its_place_in_the_queue(self):
        self.rpc.queue = [{"id": "human-submission"}]
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "queued")
        self.assertEqual(self.count("thread/queue/start"), 0)
        self.rpc.queue.pop(0)
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "delivered")
        self.assertEqual(self.count("thread/queue/add"), 1)

    def test_an_idle_race_retries_starting_the_same_submission(self):
        self.rpc.start_error = ci.RpcError("thread already has an active or pending turn")
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "queued")
        self.rpc.start_error = None
        ci.deliver(self.job, self.path, self.rpc)
        self.assertEqual(self.job["state"], "delivered")
        self.assertEqual(self.count("thread/queue/add"), 1)

    def test_delivery_timeout_does_not_turn_into_a_success(self):
        job = make_job(deadline=500)
        ci.atomic_json(self.path, job)
        ci.tick(self.store, FakeGitHub(), self.rpc, now=600)
        self.assertIn("result=timeout", self.rpc.calls[0][1]["input"][0]["text"])

    def test_unavailable_queued_delivery_remains_owned_until_inspected(self):
        self.rpc.queue = [{"id": "human-submission"}]
        ci.deliver(self.job, self.path, self.rpc)
        self.job["deadline"] = 500
        self.job["next_poll"] = 0
        ci.atomic_json(self.path, self.job)
        ci.tick(self.store, FakeGitHub(), self.rpc, now=5000)
        job = ci.read_json(self.path)
        self.assertEqual(job["state"], "delivery_unknown")
        self.assertIn(job["state"], ci.ACTIVE)
        self.assertEqual(self.count("thread/queue/add"), 1)

    def test_rechecks_the_pr_after_waiting_for_a_busy_thread(self):
        self.rpc.status = "active"
        api = FakeGitHub()
        ci.deliver(self.job, self.path, self.rpc, api)
        api.pr["head"]["sha"] = "b" * 40
        self.rpc.status = "idle"
        ci.deliver(self.job, self.path, self.rpc, api)
        self.assertEqual(self.job["state"], "cancelled")
        self.assertEqual(self.count("thread/queue/add"), 0)

    def test_removes_a_stale_notification_behind_human_input(self):
        self.rpc.queue = [{"id": "human-submission"}]
        api = FakeGitHub()
        ci.deliver(self.job, self.path, self.rpc, api)
        api.pr["head"]["sha"] = "b" * 40
        self.rpc.queue.pop(0)
        ci.deliver(self.job, self.path, self.rpc, api)
        self.assertEqual(self.job["state"], "cancelled")
        self.assertEqual(self.count("thread/queue/start"), 0)
        self.assertEqual(self.rpc.queue, [])

    def test_cancel_can_remove_a_submission_whose_acknowledgment_was_lost(self):
        self.rpc.add_error = TimeoutError("response lost")
        ci.tick(self.store, FakeGitHub(), self.rpc, now=600)
        self.path.rename(self.store.jobs / f"{self.job['id']}.json")
        with patch.object(ci, "CodexRpc", self.rpc):
            ci.cancel(self.store, self.job["id"])
        self.assertEqual(self.rpc.queue, [])

    def test_cancel_removes_only_the_watchers_queued_submission(self):
        self.rpc.queue = [{"id": "human-submission"}]
        ci.deliver(self.job, self.path, self.rpc)
        ci.atomic_json(self.path, self.job)
        renamed = self.store.jobs / f"{self.job['id']}.json"
        self.path.rename(renamed)
        with patch.object(ci, "CodexRpc", self.rpc):
            result = ci.cancel(self.store, self.job["id"])
        self.assertEqual(result["state"], "cancelled")
        self.assertEqual(self.rpc.queue, [{"id": "human-submission"}])


class RegistrationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.store = ci.Store(self.directory.name)
        self.args = ci.argparse.Namespace(
            pr=12, thread=make_job()["thread"], repository="example/forum",
            socket=Path("/tmp/codex-test.sock"), next_step="Finish authorized work",
            interval=120, timeout=86400,
        )
        self.api = FakeGitHub()
        for name, options in (
            ("verify_thread", {"return_value": {}}),
            ("GitHub", {"return_value": self.api}),
            ("ensure_worker", {}),
            ("git", {"side_effect": lambda _cwd, *args: "a" * 40 if args[-1] == "HEAD" else "/workspace/forum"}),
        ):
            patcher = patch.object(ci, name, **options)
            setattr(self, name, patcher.start())
            self.addCleanup(patcher.stop)

    def test_first_registration_after_an_inactive_runtime_upgrade_succeeds(self):
        runtime = self.store.root / "runner.py"
        runtime.write_text("old watcher")
        job = ci.register(self.store, self.args)
        self.assertEqual(job["state"], "waiting")
        self.assertEqual(runtime.read_bytes(), Path(ci.__file__).read_bytes())
        self.assertEqual(len(self.store.records()), 1)
        self.ensure_worker.assert_called_once()

    def test_an_active_older_runtime_is_not_replaced_or_given_another_job(self):
        runtime = self.store.root / "runner.py"
        runtime.write_text("old watcher")
        ci.atomic_json(self.store.jobs / "existing.json", make_job())
        with self.assertRaisesRegex(ci.HandoffError, "older watcher"):
            ci.register(self.store, self.args)
        self.assertEqual(runtime.read_text(), "old watcher")
        self.assertEqual(len(self.store.records()), 1)
        self.ensure_worker.assert_not_called()

    def test_repeated_registration_preserves_a_single_wait(self):
        first = ci.register(self.store, self.args)
        second = ci.register(self.store, self.args)
        self.assertEqual(first["id"], second["id"])
        self.assertEqual(len(self.store.records()), 1)

    def test_an_unknown_delivery_cannot_be_registered_again(self):
        ci.prepare_runtime(self.store)
        ci.atomic_json(self.store.jobs / "existing.json", make_job(state="delivery_unknown"))
        with self.assertRaisesRegex(ci.HandoffError, "uncertain delivery"):
            ci.register(self.store, self.args)
        self.assertEqual(len(self.store.records()), 1)
        self.ensure_worker.assert_not_called()


class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.client, self.server = socket.socketpair()
        self.addCleanup(self.client.close)
        self.addCleanup(self.server.close)
        self.client.settimeout(1)
        self.rpc = object.__new__(ci.CodexRpc)
        self.rpc.socket = self.client
        self.rpc.buffer = b""
        self.rpc.sequence = 0

    def frame(self, value, first=0x81):
        payload = value if isinstance(value, bytes) else json.dumps(value).encode()
        prefix = bytes([first, len(payload)]) if len(payload) < 126 else bytes([first, 126]) + struct.pack("!H", len(payload))
        return prefix + payload

    def test_handles_an_event_before_the_matching_response(self):
        self.server.sendall(self.frame({"method": "thread/changed"}) + self.frame({"id": 1, "result": {"ok": True}}))
        self.assertEqual(self.rpc.request("thread/read", {}), {"ok": True})

    def test_handles_fragmented_json_and_websocket_ping(self):
        payload = json.dumps({"id": 1, "result": {"ok": True}}).encode()
        self.server.sendall(self.frame(payload[:10], 0x01) + self.frame(b"ping", 0x89) + self.frame(payload[10:], 0x80))
        self.assertEqual(self.rpc.request("thread/read", {}), {"ok": True})

    def test_rejects_oversized_frames_before_reading_the_body(self):
        self.server.sendall(bytes([0x81, 127]) + struct.pack("!Q", ci.MAX_RESPONSE + 1))
        with self.assertRaisesRegex(ci.RpcError, "size limit"):
            self.rpc.request("thread/read", {})

    def test_outgoing_client_messages_are_masked(self):
        self.rpc.send({"method": "initialized"})
        data = self.server.recv(4096)
        self.assertTrue(data[1] & 128)
        mask, payload = data[2:6], data[6:]
        decoded = bytes(byte ^ mask[index % 4] for index, byte in enumerate(payload))
        self.assertEqual(json.loads(decoded), {"method": "initialized"})


class StateTests(unittest.TestCase):
    def test_worker_lease_is_shared_across_store_instances_and_released(self):
        with tempfile.TemporaryDirectory() as directory:
            first, second = ci.Store(directory), ci.Store(directory)
            with first.lock("worker.lock"):
                self.assertTrue(second.running())
                with self.assertRaises(BlockingIOError):
                    with second.lock("worker.lock", blocking=False):
                        self.fail("Two workers acquired the same lease")
            self.assertFalse(second.running())

    def test_state_files_are_private_and_replacements_remain_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.json"
            ci.atomic_json(path, {"state": "waiting"})
            ci.atomic_json(path, {"state": "delivered"})
            self.assertEqual(ci.read_json(path)["state"], "delivered")
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_preserves_a_service_reserve_before_starting_a_worker(self):
        with patch.object(ci, "capacity", return_value={"host_available": ci.RESERVE + 64 * 1024**2, "effective_available": ci.RESERVE + 64 * 1024**2}):
            with self.assertRaisesRegex(ci.HandoffError, "Insufficient"):
                ci.ResourceGuard("unused.json")

    def test_resolves_only_github_remotes(self):
        self.assertEqual(ci.repository_name("git@github.com:example/forum.git"), "example/forum")
        self.assertEqual(ci.repository_name("https://github.com/example/forum"), "example/forum")
        with self.assertRaises(ci.HandoffError):
            ci.repository_name("https://other.example/example/forum")


if __name__ == "__main__":
    unittest.main()
