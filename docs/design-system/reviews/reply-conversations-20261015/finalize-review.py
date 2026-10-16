"""Persist the exact candidate sources without changing historical evidence."""

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

ART = Path(__file__).resolve().parent
ROOT = ART.parents[3]
files = json.loads((ART / "changed-files.json").read_text())
entries = []
for name in files:
    source = ROOT / name
    snapshot = ART / "source" / (name + ".txt")
    snapshot.parent.mkdir(parents=True, exist_ok=True)
    checksum = hashlib.sha256()
    with source.open("rb") as input_file, snapshot.open("wb") as output:
        for chunk in iter(lambda: input_file.read(65536), b""):
            checksum.update(chunk)
            output.write(chunk)
    entries.append({"path": name, "snapshot": str(snapshot.relative_to(ART)), "bytes": source.stat().st_size, "sha256": checksum.hexdigest()})
head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
manifest = {
    "schema_version": 1,
    "created_at_utc": datetime.now(timezone.utc).isoformat(),
    "git_head": head,
    "source_state": "Uncommitted candidate; workspace contained unrelated existing changes which were preserved",
    "status": "Interaction plan approved; visual acceptance and complete application regression pending; not deployed",
    "scope": "Ordinary regular topic reply conversations, one nesting level with avatar-aligned 1px trunk and straight branches, natural avatar-radius-plus-gap indentation, compact current / total progress and Collapse label; private messages, embed, chat, admin and activity logs retain their dedicated presentation",
    "proposal": "../../proposals/reply-conversations-20261015.md",
    "reference_scope": ["A01", "A04", "C01", "C03", "C09", "C16 candidate"],
    "files": entries,
}
selected_reference = ART / "guide-redesign/selected-straight-guide.css.txt"
manifest["selected_design_reference"] = {
    "path": str(selected_reference.relative_to(ART)),
    "sha256": hashlib.sha256(selected_reference.read_bytes()).hexdigest(),
    "source": "User-provided HTML/CSS after selecting B; straight branches and parent-avatar trunk explicitly requested",
}
manifest_path = ART / "source-manifest.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
reference_path = ROOT / "docs/design-system/references/manifest.json"
references = json.loads(reference_path.read_text())
supplement = {
    "id": "reply-conversations-20261015",
    "review_date": "2026-10-15",
    "status": "In Progress; interaction plan approved, visual acceptance pending; not deployed",
    "proposal": "../proposals/reply-conversations-20261015.md",
    "verification": "../reviews/reply-conversations-20261015/README.md",
    "source_manifest": "../reviews/reply-conversations-20261015/source-manifest.json",
    "source_manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
    "acceptance_scope": "Ordinary topic grouped replies and navigation; user selected B with straight branches and a trunk descending from the parent avatar, then provided the exact HTML/CSS reference. One-pixel strong border, natural 33px indentation, last-avatar endpoint, compact progress and Collapse. Final appearance and complete application regression pending",
    "excluded": ["Production deployment or settings", "Global tokens", "Private messages", "Embedded views", "Chat", "Admin", "Dedicated activity logs", "Unrelated active theme features"],
    "selected_design_reference": "../reviews/reply-conversations-20261015/guide-redesign/selected-straight-guide.css.txt",
    "selected_design_reference_sha256": manifest["selected_design_reference"]["sha256"],
}
supplements = references.setdefault("supplements", [])
supplements[:] = [entry for entry in supplements if entry.get("id") != supplement["id"]]
supplements.append(supplement)
reference_path.write_text(json.dumps(references, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"source_files": len(entries), "git_head": head, "status": manifest["status"]}))
