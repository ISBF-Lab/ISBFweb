"""Run serial, offline review commands within the repository resource budget."""

import json
import os
from pathlib import Path
import subprocess
import sys
import time

ART = Path(__file__).resolve().parent
ROOT = ART.parents[3]
TOOLS = ROOT / "deploy-work/frontend-consistency-20261012/tools"
NAME = "isbf_reply_conversations_tools_20261015"
IMAGE = os.environ.get("ISBF_REPLY_TOOLS_IMAGE", "sha256:7ab5cd477cf764ef85c0e18306deea6b7b2777a4e5c991ed56ff073f6b48b18a")
SPEC_RUNNER = os.environ.get("ISBF_REPLY_SPEC_RUNNER") == "1"
TOOL_UID = 1000 if SPEC_RUNNER else os.getuid()


def available_memory():
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemAvailable:"):
            return int(line.split()[1]) * 1024
    raise RuntimeError("MemAvailable is unavailable")


if not sys.argv[1:]:
    raise SystemExit("Usage: python3 run-tool.py COMMAND [ARG ...]")
assert available_memory() >= 1024**3, "Less than 1GiB available"
env = dict(os.environ)
for name in ["DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH"]:
    env.pop(name, None)
docker = ["docker", "--host=unix:///var/run/docker.sock"]
command = docker + [
    "run", "--rm", "--pull=never", "--name", NAME,
    "--memory=512m", "--memory-swap=512m", "--cpus=0.5", "--pids-limit=192",
    "--network=none", "--read-only", f"--user={TOOL_UID}:{os.getgid()}",
    "--workdir=/workspace", f"--tmpfs=/tmp:rw,nosuid,size={'160m' if SPEC_RUNNER else '96m'},mode=1777",
]
source_names = ["node_modules", "frontend", "themes", "lib", "app", "spec", "config", "bin", "script", "stylelint-rules", ".git"]
if SPEC_RUNNER:
    source_names.append("db")
for name in source_names:
    path = ROOT / name
    if path.exists():
        readonly = SPEC_RUNNER or name in {"node_modules", ".git", "bin", "script", "stylelint-rules"}
        command += ["--mount", f"type=bind,src={path},dst=/workspace/{name}" + (",readonly" if readonly else "")]
file_names = ["package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", ".prettierrc.cjs", ".prettierignore", "eslint.config.mjs", "stylelint.config.mjs", "lefthook.yml", "Gemfile", "Gemfile.lock", ".rubocop.yml", ".rubocop_todo.yml", ".streerc", ".ruby-version"]
if SPEC_RUNNER:
    file_names += [".rspec", "Rakefile", "config.ru"]
for name in file_names:
    path = ROOT / name
    if path.exists():
        command += ["--mount", f"type=bind,src={path},dst=/workspace/{name},readonly"]
tool_mounts = [(ART, "/review")]
if not SPEC_RUNNER:
    tool_mounts += [(TOOLS / "python", "/opt/review-python"), (TOOLS / "libs", "/opt/review-libs"), (TOOLS / "chromium-1234", "/opt/review-chromium"), (TOOLS / "fonts-selected", "/usr/local/share/fonts/review"), (TOOLS, "/tools")]
for source, target in tool_mounts:
    command += ["--mount", f"type=bind,src={source},dst={target}" + ("" if source == ART else ",readonly")]
command += ["--mount", f"type=bind,src={TOOLS / 'ruby-lint'},dst=/lint-gems,readonly"]
for name, value in {
    "NODE_OPTIONS": "--max-old-space-size=256", "GOMAXPROCS": "1",
    "XDG_CACHE_HOME": "/tmp/review-cache", "XDG_CONFIG_HOME": "/tmp/review-config",
    "PYTHONPATH": "/opt/review-python", "LD_LIBRARY_PATH": "/opt/review-libs",
    "ISBF_REVIEW_CHROMIUM": "/opt/review-chromium/chrome-linux64/chrome",
    "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "safe.directory", "GIT_CONFIG_VALUE_0": "/workspace",
    "GEM_HOME": "/lint-gems", "GEM_PATH": "/lint-gems:/usr/local/lib/ruby/gems/3.4.0",
}.items():
    command += ["-e", f"{name}={value}"]
command += ["--entrypoint=timeout", IMAGE, "300", *sys.argv[1:]]
started = time.monotonic()
process = subprocess.Popen(command, env=env)
try:
    while process.poll() is None:
        if available_memory() < 512 * 1024**2 or time.monotonic() - started > 320:
            subprocess.run(docker + ["stop", "--time", "2", NAME], env=env, capture_output=True)
            raise RuntimeError("Tool stopped at memory/time budget")
        time.sleep(0.5)
    result = process.returncode
finally:
    subprocess.run(docker + ["rm", "--force", NAME], env=env, capture_output=True)
with (ART / "tool-executions.jsonl").open("a") as log:
    log.write(json.dumps({"command": sys.argv[1:], "image": IMAGE, "exit_code": result, "network": "none", "memory_limit_bytes": 536870912, "container_removed": True}) + "\n")
raise SystemExit(result)
