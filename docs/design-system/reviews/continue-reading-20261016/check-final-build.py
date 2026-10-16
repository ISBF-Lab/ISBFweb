"""Run the final targeted format and compile checks serially."""

from pathlib import Path
import subprocess

for name, command in [
    ("lint-revision", ["node", "/review/run-lint.cjs", "revision-files.json", "lint-revision"]),
    ("compilation", ["node", "/review/compile.cjs"]),
    ("style-compilation", ["ruby", "/review/compile-style.rb"]),
    ("browser-compilation", ["node", "/review/compile-browser.cjs"]),
]:
    result = subprocess.run(command, cwd="/workspace", capture_output=True, text=True, timeout=110)
    output = result.stdout + result.stderr
    Path(f"/review/{name}.log").write_text(output)
    print(f"{name}: exit {result.returncode}", flush=True)
    if result.returncode:
        print(output, flush=True)
        raise SystemExit(result.returncode)
