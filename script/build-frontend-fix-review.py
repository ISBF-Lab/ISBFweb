import hashlib
import html
import json
from pathlib import Path
import struct
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
archive_path = Path(sys.argv[1])
metadata = json.loads(Path(sys.argv[2]).read_text())
assert metadata["conclusion"] == "success", "Page verification has not passed"
assert hashlib.sha256(archive_path.read_bytes()).hexdigest() == metadata["artifact_sha256"]
review = root / "docs/design-system/reviews/frontend-fixes-20261013"
review.mkdir(parents=True, exist_ok=True)
regions = {"messages": "私信", "account": "账号设置", "bookmarks": "书签", "drafts": "草稿"}
records = []
sections = []
with zipfile.ZipFile(archive_path) as archive:
    for region, label in regions.items():
        for device in ["desktop", "mobile"]:
            for palette in ["light", "dark"]:
                name = f"{device}-{palette}-{region}.png"
                data = archive.read(f"isbf-frontend-screenshots/{name}")
                assert data.startswith(b"\x89PNG\r\n\x1a\n")
                width, height = struct.unpack(">II", data[16:24])
                (review / name).write_bytes(data)
                records.append({"path": name, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data), "image_pixels": {"width": width, "height": height}})
                sections.append(f'<details><summary>{html.escape(label)} · {device} · {palette}</summary><img src="{name}" alt="{html.escape(label)} {device} {palette}" loading="lazy"></details>')
metadata.update(screenshots=records, screenshot_count=len(records), production_access=False, human_visual_acceptance=False)
(review / "source.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
index = """<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>前台四处修复截图</title>
<style>body{font-family:system-ui,sans-serif;margin:24px;line-height:1.45}details{margin-block:16px}summary{cursor:pointer}img{display:block;max-width:100%;height:auto;margin-block:16px}</style>
<h1>前台四处修复截图</h1>
<p>16张原始截图来自独立GitHub Actions测试库，使用合成用户和英文内容；不是生产截图，也不是新增Approved设计参考。</p>
<p>长页截图的固定导航对应900px高的截图视口。图片未裁切、重绘或美化。</p>
<p><a href="source.json">受测提交、验证结果与图片摘要</a> · <a href="frontend-fixes-20261013.md">修复与发布说明</a></p>
"""
(review / "INDEX.html").write_text(index + "\n".join(sections) + "</html>\n")
notes = root / "docs/design-system/frontend-fixes-20261013.md"
(review / notes.name).write_bytes(notes.read_bytes())
downloads = root / "docs/downloads"
downloads.mkdir(exist_ok=True)
package = downloads / "isbf-frontend-fixes-20261013.zip"
with zipfile.ZipFile(package, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(review.iterdir()):
        if path.is_file():
            archive.write(path, f"isbf-frontend-fixes-20261013/{path.name}")
    archive.write(root / "themes/isbf-campus-feed/stylesheets/frontend-consistency.scss", "isbf-frontend-fixes-20261013/frontend-consistency.scss")
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
digest = hashlib.sha256(package.read_bytes()).hexdigest()
package.with_suffix(".zip.sha256").write_text(f"{digest}  {package.name}\n")
print(json.dumps({"screenshots": len(records), "package": str(package), "bytes": package.stat().st_size, "sha256": digest}))
