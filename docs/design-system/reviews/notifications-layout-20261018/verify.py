from pathlib import Path
import json
import subprocess

review = Path("/review")
commands = [
    ["node", "/review/compile.cjs"],
    ["ruby", "/review/compile-style.rb"],
    ["node", "/review/compile-browser.cjs"],
    ["python3", "/review/attempt-qunit.py"],
    ["python3", "/review/check-browser.py"],
]
results = []
for command in commands:
    print(json.dumps({"stage": command}), flush=True)
    result = subprocess.run(command)
    results.append({"command": command, "exit_code": result.returncode})
    (review / "verification-stages.json").write_text(json.dumps(results, indent=2) + "\n")
    if result.returncode:
        if command[-1] == "/review/attempt-qunit.py":
            native = json.loads((review / "native-test-attempts.json").read_text())
            if native.get("tests_executed") == 0 and "No isolated Rails" in native.get("blocked_reason", ""):
                continue
        raise SystemExit(result.returncode)
