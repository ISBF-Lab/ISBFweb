"""Run the required final bin/lint --fix once, with bounded serial tools."""

import json
from pathlib import Path
import subprocess
import sys

art = Path("/review")
files = json.loads((art / "lint-files.json").read_text())
commands = [["ruby", "bin/lint", "--fix", *files]]
prefix = "lint"
if "--tools-only" in sys.argv:
    tools = ["script/check-isbf-dialogs.mjs", "script/check-isbf-dialogs.test.mjs"]
    commands = [["pnpm", "exec", "prettier", "--write", *tools], ["pnpm", "exec", "eslint", "--fix", "--no-warn-ignored", *tools]]
    prefix = "tool-lint"
results = []
output = ""
for command in commands:
    result = subprocess.run(command, cwd="/workspace", text=True, capture_output=True)
    output += result.stdout + result.stderr
    results.append({"command": command, "exit_code": result.returncode})
(art / f"{prefix}.log").write_text(output)
(art / f"{prefix}-status.json").write_text(json.dumps({"commands": results, "exit_code": max(entry["exit_code"] for entry in results), "serial": True}, indent=2) + "\n")
print(output, flush=True)
raise SystemExit(max(entry["exit_code"] for entry in results))
