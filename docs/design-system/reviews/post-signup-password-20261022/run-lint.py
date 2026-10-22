"""Run the required final fixes once and the shared dialog contract check."""

import json
from pathlib import Path
import subprocess

art = Path("/review")
files = json.loads((art / "lint-files.json").read_text())
commands = [["ruby", "bin/lint", "--fix", *files], ["pnpm", "lint:dialogs"]]
results = []
for index, command in enumerate(commands):
    result = subprocess.run(command, cwd="/workspace", text=True, capture_output=True)
    output = result.stdout + result.stderr
    (art / ("lint.log" if index == 0 else "dialog-policy.log")).write_text(output)
    results.append({"command": command, "exit_code": result.returncode})
    print(output, flush=True)
status = {"commands": results, "exit_code": max(item["exit_code"] for item in results), "serial": True}
(art / "lint-status.json").write_text(json.dumps(status, indent=2) + "\n")
raise SystemExit(status["exit_code"])
