import json
from pathlib import Path
import subprocess

review = Path("/review")
command = ["ruby", "bin/qunit", "--theme-name", "ISBF Campus Feed", "--qunit-path", "/theme-qunit", "--filter", "/ISBFNotificationEntry|ISBFNotifications/i"]
result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
(review / "qunit-attempt.log").write_text(result.stdout)
record = {"command": command, "exit_code": result.returncode, "log": "qunit-attempt.log", "preview_forum_started": False, "production_backend_used": False}
if "Rails server not responding" in result.stdout:
    record.update({"tests_executed": 0, "blocked_reason": "No isolated Rails test server; full preview remains stopped"})
(review / "native-test-attempts.json").write_text(json.dumps(record, indent=2) + "\n")
print(result.stdout)
raise SystemExit(result.returncode)
