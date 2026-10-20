"""Cache only the missing locked test gems, verifying repository checksums."""

import hashlib
import json
from pathlib import Path
import re
import resource
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
available = int(next(line.split()[1] for line in Path("/proc/meminfo").read_text().splitlines() if line.startswith("MemAvailable:"))) * 1024
limit = available - 512 * 1024**2
if limit <= 0:
    raise SystemExit("Insufficient memory reserve")
resource.setrlimit(resource.RLIMIT_AS, (limit, limit))
log = (Path(__file__).parent / "latest-run.log").read_text()
missing = json.loads(next(line.removeprefix("MISSING_GEMS=") for line in log.splitlines() if line.startswith("MISSING_GEMS=")))
checksums = {}
for name, version, checksum in re.findall(r"^  ([\w.-]+) \(([^)]+)\) sha256=([a-f0-9]+)$", (ROOT / "Gemfile.lock").read_text(), re.M):
    checksums[(name, version)] = checksum
cache = ROOT / "deploy-work/ai-moderation-20261018/gem-cache"
cache.mkdir(parents=True, exist_ok=True)
for spec in missing:
    name, version = spec["name"], spec["version"]
    if spec["platform"] != "ruby":
        raise RuntimeError("Unexpected native platform archive")
    expected = checksums[(name, version)]
    target = cache / f"{name}-{version}.gem"
    if not target.exists():
        with urllib.request.urlopen(f"https://rubygems.org/downloads/{target.name}", timeout=30) as response, target.open("wb") as output:
            while chunk := response.read(65536):
                output.write(chunk)
    digest = hashlib.file_digest(target.open("rb"), "sha256").hexdigest()
    if digest != expected:
        target.unlink()
        raise RuntimeError(f"Checksum mismatch: {target.name}")
    print(f"Verified {target.name}", flush=True)
