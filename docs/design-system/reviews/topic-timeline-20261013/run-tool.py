import json
import os
from pathlib import Path
import subprocess
import sys
import time

ART = Path(__file__).resolve().parent
ROOT = ART.parents[3]
NAME = "isbf_topic_timeline_tools_20261013"
IMAGE = os.environ.get("ISBF_TIMELINE_TOOLS_IMAGE", "sha256:7ab5cd477cf764ef85c0e18306deea6b7b2777a4e5c991ed56ff073f6b48b18a")
TOOLS = ROOT / "deploy-work/frontend-consistency-20261012/tools"


def available_memory():
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemAvailable:"):
            return int(line.split()[1]) * 1024
    raise RuntimeError("MemAvailable is unavailable")


assert available_memory() >= 1024**3, "Less than 1GiB host memory available"
env = dict(os.environ)
for name in ["DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH"]:
    env.pop(name, None)
docker = ["docker", "--host=unix:///var/run/docker.sock"]
command = docker + [
    "run", "--rm", "--pull=never", "--name", NAME,
    "--memory=512m", "--memory-swap=512m", "--cpus=0.5", "--pids-limit=192",
    "--network=none", "--read-only", f"--user={os.getuid()}:{os.getgid()}",
    "--workdir=/workspace", "--tmpfs=/tmp:rw,nosuid,size=96m,mode=1777",
]
mounts = [
    (ROOT / "node_modules", "/workspace/node_modules", True),
    (ROOT / "frontend", "/workspace/frontend", False),
    (ROOT / "themes", "/workspace/themes", False),
    (ROOT / "app/assets/stylesheets", "/workspace/app/assets/stylesheets", True),
    (ROOT / "bin", "/workspace/bin", True),
    (ROOT / "script", "/workspace/script", True),
    (ROOT / ".git", "/workspace/.git", True),
    (ART, "/review", False),
    (TOOLS / "python", "/opt/review-python", True),
    (TOOLS / "libs", "/opt/review-libs", True),
    (TOOLS / "chromium-1234", "/opt/review-chromium", True),
    (TOOLS / "fonts-selected", "/usr/local/share/fonts/review", True),
]
mounts.append((ROOT / "stylelint-rules", "/workspace/stylelint-rules", True))
for name in ["package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", ".prettierrc.cjs", ".prettierignore", "eslint.config.mjs", "stylelint.config.mjs", "lefthook.yml"]:
    if (ROOT / name).exists():
        mounts.append((ROOT / name, f"/workspace/{name}", True))
for source, destination, readonly in mounts:
    command.extend(["--mount", f"type=bind,src={source},dst={destination}" + (",readonly" if readonly else "")])
for name, value in {
    "NODE_OPTIONS": "--max-old-space-size=256",
    "GOMAXPROCS": "1",
    "XDG_CACHE_HOME": "/tmp/review-cache",
    "XDG_CONFIG_HOME": "/tmp/review-config",
    "PYTHONPATH": "/opt/review-python",
    "LD_LIBRARY_PATH": "/opt/review-libs",
    "ISBF_REVIEW_CHROMIUM": "/opt/review-chromium/chrome-linux64/chrome",
    "GIT_CONFIG_COUNT": "1",
    "GIT_CONFIG_KEY_0": "safe.directory",
    "GIT_CONFIG_VALUE_0": "/workspace",
}.items():
    command.extend(["-e", f"{name}={value}"])
command.extend(["--entrypoint=timeout", IMAGE, "300", *sys.argv[1:]])
started = time.monotonic()
process = subprocess.Popen(command, env=env)
try:
    while process.poll() is None:
        if available_memory() < 512 * 1024**2 or time.monotonic() - started > 320:
            subprocess.run(docker + ["stop", "--time", "2", NAME], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            raise RuntimeError("Tool stopped at memory/time budget")
        time.sleep(0.5)
    result = process.returncode
finally:
    subprocess.run(docker + ["rm", "--force", NAME], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
with (ART / "tool-executions.jsonl").open("a") as log:
    log.write(json.dumps({"command": sys.argv[1:], "exit_code": result, "memory_limit_bytes": 536870912, "network": "none", "container_removed": True}) + "\n")
raise SystemExit(result)
