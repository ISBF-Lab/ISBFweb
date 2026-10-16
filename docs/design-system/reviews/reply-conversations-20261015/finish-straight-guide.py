"""Record the selected straight guide candidate and its completed local checks."""

import hashlib
import json
from pathlib import Path
import subprocess
import sys

ART = Path(__file__).resolve().parent
ROOT = ART.parents[3]
subprocess.run([sys.executable, str(ART / "finalize-review.py")], check=True)
manifest = json.loads((ART / "source-manifest.json").read_text())
for entry in manifest["files"]:
    assert hashlib.sha256((ROOT / entry["path"]).read_bytes()).hexdigest() == entry["sha256"]
    assert hashlib.sha256((ART / entry["snapshot"]).read_bytes()).hexdigest() == entry["sha256"]
refs = json.loads((ROOT / "docs/design-system/references/manifest.json").read_text())
record = next(item for item in refs["supplements"] if item.get("id") == "reply-conversations-20261015")
assert record["source_manifest_sha256"] == hashlib.sha256((ART / "source-manifest.json").read_bytes()).hexdigest()
assert record["selected_design_reference_sha256"] == hashlib.sha256((ART / "guide-redesign/selected-straight-guide.css.txt").read_bytes()).hexdigest()
assert json.loads((ART / "lint-status.json").read_text())["exit_code"] == 0
assert json.loads((ART / "style-compilation.json").read_text())["scss_compiled"]
browser = json.loads((ART / "browser-report.json").read_text())
assert browser["passed"]
assert all(item["thread_guide_width_px"] == 1 and item["indent_px"] == 33 for item in browser["screenshots"])
subprocess.run(["git", "diff", "--check"], cwd=ROOT, check=True)
verification = json.loads((ART / "final-verification.json").read_text())
verification.update({
    "revision": "Selected B: parent-avatar trunk, straight one-pixel branches and natural indentation",
    "revision_linted_files": 1,
    "source_snapshots_match": True,
    "reference_manifest_matches": True,
    "offline_browser_checks_passed": True,
    "revision_browser_checks": len(browser["checks"]),
    "thread_guide_width_px": 1,
    "natural_indent_px": 33,
    "deployed": False,
})
(ART / "final-verification.json").write_text(json.dumps(verification, indent=2) + "\n")
gallery = ART / "guide-redesign/index.html"
if gallery.exists():
    source = gallery.read_text()
    source = source.replace("<h1>回复连线：两种方案</h1>", '<h1>回复连线：方案记录</h1><p>已选定B的直线修订，<a href="../index.html">查看最新交互预览</a>；下方保留最初两版对比。</p>')
    gallery.write_text(source)
print(json.dumps({"sources_verified": len(manifest["files"]), "lint_passed": True, "browser_checks": len(browser["checks"]), "guide_px": 1, "indent_px": 33, "deployed": False}))
