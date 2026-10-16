"""Record targeted native test attempts without starting the full preview forum."""

import json
from pathlib import Path
import subprocess

art = Path("/review")
commands = {
    "core": [
        "ruby", "bin/qunit",
        "frontend/discourse/tests/acceptance/more-topics-plugin-api-test.gjs",
        "frontend/discourse/tests/integration/components/more-topics/browse-more-test.gjs",
    ],
    "theme": [
        "ruby", "bin/qunit", "--theme-name", "ISBF Campus Feed",
        "--qunit-path", "/theme-qunit", "--filter", "ContinueReading",
    ],
}
results = {}
for name, command in commands.items():
    result = subprocess.run(command, cwd="/workspace", capture_output=True, text=True, timeout=45)
    output = result.stdout + result.stderr
    (art / f"qunit-{name}.log").write_text(output)
    results[name] = {"command": command, "exit_code": result.returncode, "log": f"qunit-{name}.log"}
    print(json.dumps({"suite": name, **results[name]}), flush=True)
    print(output, flush=True)
results["preview_forum_started"] = False
results["production_backend_used"] = False
results["tests_executed"] = 0 if all(item.get("exit_code") == 1 for item in [results["core"], results["theme"]]) else None
(art / "qunit-attempts.json").write_text(json.dumps(results, indent=2) + "\n")
