import json
import os
from pathlib import Path
import subprocess

review = Path("/review")
command = ["ruby", "bin/lint", "--fix", *json.loads((review / "lint-files.json").read_text())]
env = dict(os.environ, LEFTHOOK_CONFIG="/tools/lefthook-serial.yml")
result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
(review / "lint.log").write_text(result.stdout)
(review / "lint-status.json").write_text(json.dumps({"command": command, "exit_code": result.returncode, "configuration": "Existing offline serial lefthook configuration; repository CI unchanged"}, indent=2) + "\n")
print(result.stdout)
raise SystemExit(result.returncode)
