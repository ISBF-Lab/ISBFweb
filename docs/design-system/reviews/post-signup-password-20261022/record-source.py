"""Persist non-executable source evidence for the approved password task."""

import hashlib
import json
from pathlib import Path
import subprocess

review = Path(__file__).resolve().parent
root = review.parents[3]
files = json.loads((review / "lint-files.json").read_text())
files += [
    "plugins/discourse-academy-roles/README.md",
    "docs/design-system/dialogs.md",
    "docs/design-system/tokens.md",
    "docs/design-system/components.md",
    "docs/design-system/reference-map.md",
    "docs/design-system/ui-status.md",
    "docs/design-system/references/README.md",
    "themes/isbf-campus-feed/stylesheets/dialog-consistency.scss",
]
entries = []
for name in sorted(set(files)):
    data = (root / name).read_bytes()
    snapshot = Path("source") / (name + ".txt")
    target = review / snapshot
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    entries.append({"source": name, "snapshot": str(snapshot), "sha256": hashlib.sha256(data).hexdigest()})
version = hashlib.sha256("\n".join(item["source"] + ":" + item["sha256"] for item in entries).encode()).hexdigest()
manifest = {
    "date": "2026-10-22",
    "base_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
    "source_version": version,
    "acceptance": "User confirmed the new-account-only dual-password task and requested implementation.",
    "scope": "C07 homepage initial password task; shared chrome and tokens retained.",
    "production_deployed": False,
    "final_visual_acceptance": "pending_user_review",
    "attachments_are_executable": False,
    "files": entries,
}
manifest_path = review / "source-manifest.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
reference_path = root / "docs/design-system/references/manifest.json"
references = json.loads(reference_path.read_text())
entry = {
    "id": "post-signup-password-20261022",
    "date": "2026-10-22",
    "status": "user_confirmed_design_implemented_not_deployed",
    "scope": manifest["scope"],
    "source_version": version,
    "source_manifest": "../reviews/post-signup-password-20261022/source-manifest.json",
    "source_manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
    "evidence": "../reviews/post-signup-password-20261022/README.md",
    "final_visual_acceptance": "pending_user_review",
    "new_global_visual_tokens": False,
}
references["supplements"] = [item for item in references["supplements"] if item.get("id") != entry["id"]] + [entry]
reference_path.write_text(json.dumps(references, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"source_version": version, "files": len(entries)}, ensure_ascii=False))
