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
NAME = "isbf_topic_timeline_stability_review_20261022"
IMAGE = os.environ.get("ISBF_DIALOGS_TOOLS_IMAGE", "local_discourse/isbf_app:dialog-consistency-20261020-5109370e6bf4")
SPEC_RUNNER = os.environ.get("ISBF_DIALOGS_SPEC_RUNNER") == "1"
TOOL_UID = 1000 if SPEC_RUNNER else os.getuid()


RESERVE = 512 * 1024**2
memory_group = None


def memory_status():
    host = next(int(line.split()[1]) * 1024 for line in Path("/proc/meminfo").read_text().splitlines() if line.startswith("MemAvailable:"))
    remaining = []
    for line in Path("/proc/self/cgroup").read_text().splitlines():
        if not line.startswith("0::"):
            continue
        group = Path("/sys/fs/cgroup") / line.split(":", 2)[2].lstrip("/")
        while str(group).startswith("/sys/fs/cgroup"):
            maximum, current = group / "memory.max", group / "memory.current"
            if maximum.exists() and current.exists():
                limit = maximum.read_text().strip()
                if limit != "max":
                    remaining.append({"path": str(group), "limit": int(limit), "remaining": int(limit) - int(current.read_text())})
            if group == Path("/sys/fs/cgroup"):
                break
            group = group.parent
    capacity = min([host, *(item["remaining"] for item in remaining)])
    return {"host_available": host, "effective_available": capacity, "cgroups": remaining}


def container_memory(peak=False):
    global memory_group
    try:
        if memory_group is None:
            inspection = subprocess.run(docker + ["inspect", "--format={{.State.Pid}}", NAME], env=env, capture_output=True, text=True, timeout=5)
            if inspection.returncode or not inspection.stdout.strip().isdigit():
                return 0
            pid = int(inspection.stdout.strip())
            group_path = next(line.split(":", 2)[2] for line in Path(f"/proc/{pid}/cgroup").read_text().splitlines() if line.startswith("0::"))
            memory_group = Path("/sys/fs/cgroup") / group_path.lstrip("/")
        target = memory_group / ("memory.peak" if peak else "memory.current")
        return int(target.read_text()) if target.exists() else 0
    except (OSError, StopIteration, subprocess.TimeoutExpired):
        return 0


if not sys.argv[1:]:
    raise SystemExit("Usage: python3 run-tool.py COMMAND [ARG ...]")
initial = memory_status()
budget = (initial["effective_available"] - RESERVE) // (64 * 1024**2) * (64 * 1024**2)
if budget < 256 * 1024**2:
    raise SystemExit("The current sustainable budget is too small for this tool")
env = dict(os.environ)
for name in ["DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH"]:
    env.pop(name, None)
docker = ["docker", "--host=unix:///var/run/docker.sock"]
command = docker + [
    "run", "--rm", "--pull=never", "--name", NAME,
    f"--memory={budget}", f"--memory-swap={budget}", "--cpus=0.5", "--pids-limit=192",
    "--network=none", "--read-only", f"--user={TOOL_UID}:{os.getgid()}",
    "--workdir=/workspace", f"--tmpfs=/tmp:rw,nosuid,size={'160m' if SPEC_RUNNER else '96m'},mode=1777",
]
source_names = ["node_modules", "frontend", "themes", "lib", "app", "plugins", "spec", "config", "docs", "bin", "script", "stylelint-rules", ".git", ".github"]
if SPEC_RUNNER:
    source_names.append("db")
for name in source_names:
    path = ROOT / name
    if path.exists():
        readonly = not any(argument == "bin/lint" or argument.endswith("/run-lint.py") for argument in sys.argv[1:]) or name in {"node_modules", ".git", "bin", "stylelint-rules"}
        command += ["--mount", f"type=bind,src={path},dst=/workspace/{name}" + (",readonly" if readonly else "")]
file_names = ["package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", ".prettierrc.cjs", ".prettierignore", "eslint.config.mjs", "stylelint.config.mjs", "lefthook.yml", "Gemfile", "Gemfile.lock", ".rubocop.yml", ".rubocop_todo.yml", ".streerc", ".ruby-version", "AI-AGENTS.md"]
if SPEC_RUNNER:
    file_names += [".rspec", "Rakefile", "config.ru"]
for name in file_names:
    path = ROOT / name
    if path.exists():
        command += ["--mount", f"type=bind,src={path},dst=/workspace/{name},readonly"]
native_assets = ROOT / "deploy-work/reply-conversations-20261015/built/public/assets"
tool_mounts = [(ROOT / "deploy-work/reply-conversations-20261015", "/native-fixture"), (ART, "/review"), (ROOT / "docs/design-system/reviews/continue-reading-20261016/asset-cache", "/client-cache"), (ROOT / "public/images/avatar.png", "/fixture-avatar.png"), (native_assets, "/client-assets")]
if not SPEC_RUNNER:
    tool_mounts += [(TOOLS / "python", "/opt/review-python"), (TOOLS / "libs", "/opt/review-libs"), (TOOLS / "chromium-1234", "/opt/review-chromium"), (TOOLS / "fonts-selected", "/usr/local/share/fonts/review"), (TOOLS, "/tools")]
for source, target in tool_mounts:
    command += ["--mount", f"type=bind,src={source},dst={target}" + ("" if source == ART else ",readonly")]
command += ["--mount", f"type=bind,src={TOOLS / 'ruby-lint'},dst=/lint-gems,readonly"]
browser_run = any(name in argument for argument in sys.argv[1:] for name in ["check-browser.py", "check-layout.py"])
for name, value in {
    "LEFTHOOK_CONFIG": "/review/lefthook-serial.yml",
    "NODE_OPTIONS": f"--max-old-space-size={min(128 if browser_run else 256, budget // (3 * 1024**2))}", "GOMAXPROCS": "1",
    "MALLOC_ARENA_MAX": "2",
    "XDG_CACHE_HOME": "/tmp/review-cache", "XDG_CONFIG_HOME": "/tmp/review-config",
    "PYTHONPATH": "/opt/review-python", "LD_LIBRARY_PATH": "/opt/review-libs",
    "ISBF_REVIEW_CHROMIUM": "/opt/review-chromium/chrome-linux64/chrome",
    "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "safe.directory", "GIT_CONFIG_VALUE_0": "/workspace",
    "GEM_HOME": "/lint-gems", "GEM_PATH": "/lint-gems:/usr/local/lib/ruby/gems/3.4.0",
}.items():
    command += ["-e", f"{name}={value}"]
duration = 600 if browser_run else 300
command += ["--entrypoint=timeout", IMAGE, str(duration), *sys.argv[1:]]
started = time.monotonic()
peak = 0
minimum = initial["host_available"]
result = 1
reason = None
print(json.dumps({"budget_bytes": budget, "reserve_bytes": RESERVE, "initial": initial}), flush=True)
process = subprocess.Popen(command, env=env)
try:
    while process.poll() is None:
        status = memory_status()
        minimum = min(minimum, status["host_available"])
        current = container_memory()
        peak = max(peak, container_memory(peak=True))
        if status["effective_available"] < RESERVE or current > budget or time.monotonic() - started > duration + 20:
            reason = "Tool stopped at the sustainable memory/time budget"
            subprocess.run(docker + ["stop", "--time", "2", NAME], env=env, capture_output=True)
            raise RuntimeError(reason)
        time.sleep(0.5)
    result = process.returncode
finally:
    subprocess.run(docker + ["rm", "--force", NAME], env=env, capture_output=True)
    record = {"command": sys.argv[1:], "image": IMAGE, "exit_code": result, "network": "none", "memory_limit_bytes": budget, "swap_total_bytes": budget, "reserve_bytes": RESERVE, "initial": initial, "peak_bytes": peak, "minimum_host_available_bytes": minimum, "elapsed_seconds": round(time.monotonic() - started, 1), "stop_reason": reason, "container_removed": True}
    with (ART / "tool-executions.jsonl").open("a") as log:
        log.write(json.dumps(record) + "\n")
    print(json.dumps(record), flush=True)
raise SystemExit(result)
