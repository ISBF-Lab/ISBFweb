"""Run one isolated verification command with a fresh shared-host memory budget."""

import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent
RESERVE = 512 * 1024**2
NAME = "isbf_ai_moderation_verification"


def capacity():
    values = dict(line.split(":", 1) for line in Path("/proc/meminfo").read_text().splitlines())
    available = int(values["MemAvailable"].split()[0]) * 1024
    relative = Path("/proc/self/cgroup").read_text().strip().split("::", 1)[1].lstrip("/")
    directory = Path("/sys/fs/cgroup") / relative
    root = Path("/sys/fs/cgroup")
    while directory == root or root in directory.parents:
        maximum, current = directory / "memory.max", directory / "memory.current"
        if maximum.exists() and current.exists() and maximum.read_text().strip() != "max":
            available = min(available, int(maximum.read_text()) - int(current.read_text()))
        if directory == root:
            break
        directory = directory.parent
    return available


parameters = sys.argv[1:]
lint_mode = parameters[0] == "--lint"
if lint_mode:
    parameters = parameters[1:]
image, *arguments = parameters
available = capacity()
budget = (available - RESERVE) // (64 * 1024**2) * (64 * 1024**2)
if budget <= 0:
    raise SystemExit("Insufficient capacity after service reserve")
env = dict(os.environ)
for key in ["DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH"]:
    env.pop(key, None)
docker = ["docker", "--host=unix:///var/run/docker.sock"]
command = docker + [
    "run", "--rm", "--pull=never", "--name", NAME,
    f"--memory={budget}", f"--memory-swap={budget}", "--cpus=0.5", "--pids-limit=192",
    "--network=none", "--read-only", f"--user=1000:{os.getgid()}",
    "--tmpfs=/tmp:rw,nosuid,size=512m,mode=1777", "--workdir=/workspace",
]
for name in ["app", "lib", "spec", "config", "bin", "script", "db", "frontend", "node_modules", "themes"]:
    path = ROOT / name
    if path.exists():
        command += ["--mount", f"type=bind,src={path},dst=/workspace/{name},readonly"]
for name in ["isbf-moderation", "isbf-anonymous", "discourse-academy-roles", "discourse-ai", "automation"]:
    permissions = "" if lint_mode and name == "isbf-moderation" else ",readonly"
    command += ["--mount", f"type=bind,src={ROOT / 'plugins' / name},dst=/workspace/plugins/{name}{permissions}"]
for name in ["Gemfile", "Gemfile.lock", ".ruby-version", ".rspec", "Rakefile", "config.ru", ".rubocop.yml", ".rubocop_todo.yml", ".streerc", ".git", ".gitignore", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", "lefthook.yml", ".prettierrc.cjs", ".prettierignore"]:
    if (ROOT / name).exists():
        command += ["--mount", f"type=bind,src={ROOT / name},dst=/workspace/{name},readonly"]
command += ["--mount", f"type=bind,src={ART},dst=/review,readonly"]
command += ["--mount", f"type=bind,src={ROOT / 'docs/design-system/reviews/reply-conversations-20261015'},dst=/prior-review,readonly"]
cache = ROOT / "deploy-work/ai-moderation-20261018"
cache.mkdir(parents=True, exist_ok=True)
test_gems = cache / "test-gems"
test_gems.mkdir(exist_ok=True)
test_gems.chmod(0o2770)
command += ["--mount", f"type=bind,src={test_gems},dst=/test-gems"]
if (cache / "gem-cache").exists():
    command += ["--mount", f"type=bind,src={cache / 'gem-cache'},dst=/gem-cache,readonly"]
lint_gems = ROOT / "deploy-work/frontend-consistency-20261012/tools/ruby-lint"
command += ["--mount", f"type=bind,src={lint_gems},dst=/lint-gems,readonly"]
command += ["-e", "GIT_CONFIG_COUNT=1", "-e", "GIT_CONFIG_KEY_0=safe.directory", "-e", "GIT_CONFIG_VALUE_0=/workspace"]
command += ["-e", f"NODE_OPTIONS=--max-old-space-size={budget // (4 * 1024**2)}"]
command += ["--entrypoint=timeout", image, "300", *arguments]
original_modes = {}
if lint_mode:
    for argument in arguments:
        path = ROOT / argument
        if path.is_file() and path.is_relative_to(ROOT / "plugins/isbf-moderation"):
            original_modes[path] = path.stat().st_mode & 0o777
            path.chmod(original_modes[path] | 0o020)
started = time.monotonic()
result = {"image": image, "command": arguments, "available_bytes": available,
          "reserve_bytes": RESERVE, "memory_limit_bytes": budget, "network": "none"}
with (ART / "latest-run.log").open("w") as log:
    process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        while process.poll() is None:
            if capacity() < RESERVE or time.monotonic() - started > 320:
                subprocess.run(docker + ["stop", "--time", "2", NAME], env=env, capture_output=True, timeout=15)
                raise RuntimeError("Verification stopped at resource/time limit")
            time.sleep(0.5)
        result["exit_code"] = process.returncode
    finally:
        subprocess.run(docker + ["rm", "--force", NAME], env=env, capture_output=True, timeout=15)
        for path, mode in original_modes.items():
            path.chmod(mode)
        result["elapsed_seconds"] = round(time.monotonic() - started, 2)
        with (ART / "executions.jsonl").open("a") as report:
            report.write(json.dumps(result) + "\n")
print(json.dumps(result))
raise SystemExit(process.returncode)
