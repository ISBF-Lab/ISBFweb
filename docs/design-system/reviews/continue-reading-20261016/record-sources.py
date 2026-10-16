"""Persist the exact reviewed implementation and its verification artifacts."""

import hashlib
import json
from pathlib import Path
import subprocess

art = Path(__file__).resolve().parent
root = art.parents[3]
files = json.loads((art / "changed-files.json").read_text())
before = {item["path"]: item["sha256"] for item in json.loads((art / "before-manifest.json").read_text())}
records = []
for name in files:
    data = (root / name).read_bytes()
    snapshot = Path("source") / (name + ".txt")
    (art / snapshot).parent.mkdir(parents=True, exist_ok=True)
    (art / snapshot).write_bytes(data)
    records.append({"path": name, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data), "snapshot": str(snapshot), "before_sha256": before.get(name)})
version = hashlib.sha256("\n".join(item["path"] + ":" + item["sha256"] for item in records).encode()).hexdigest()
artifacts = ["compilation.json", "style-compilation.json", "lint-status.json", "lint-revision-status.json", "browser-report.json", "qunit-attempts.json"]
artifacts += [f"{width}-{mode}.png" for width in [320, 390, 1280] for mode in ["light", "dark"]]
artifacts += ["related-desktop-dark.png"]
report = {
    "date": "2026-10-16",
    "base_git_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
    "workspace_had_unrelated_uncommitted_changes": True,
    "implementation_sha256": version,
    "scope": "Ordinary-topic footer; suggested and related sources only",
    "design_direction_confirmed": True,
    "final_visual_acceptance_pending": True,
    "production_deployed": False,
    "source_files": records,
    "artifacts": [{"path": name, "sha256": hashlib.sha256((art / name).read_bytes()).hexdigest()} for name in artifacts],
}
(art / "source-manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"source_files": len(records), "artifacts": len(artifacts), "implementation_sha256": version}))
