"""Build the offline review bundle without modifying UI or historical archives."""

import hashlib
import html
import json
import posixpath
import re
import zipfile
from pathlib import Path
from urllib.parse import quote, unquote, urlparse

from markdown_it import MarkdownIt

WORK = Path(__file__).resolve().parents[3]
DOCS = WORK / "docs/design-system"
REVIEW = DOCS / "reviews/frontend-20261012-v2"
OLD_REVIEW = DOCS / "reviews/frontend-20261012"
NAME = "isbf-frontend-review-20261012-v2"
PREFIX = NAME + "/"
OUTPUT = WORK / "docs/downloads" / (NAME + ".zip")


def digest(content):
    return hashlib.sha256(content).hexdigest()


baseline = json.loads((DOCS / "baselines/production-20261012/source-map.json").read_text())
for item in baseline:
    assert digest((DOCS / "baselines/production-20261012" / item["path"]).read_bytes()) == item["sha256"]
manifest = json.loads((DOCS / "references/manifest.json").read_text())
for item in manifest["files"] + manifest["evidence"]:
    assert digest((DOCS / "references" / item["archive_path"]).read_bytes()) == item["sha256"]
browser = json.loads((REVIEW / "browser-report.json").read_text())
assert len(browser["records"]) == 58 and all(item.get("passed") for item in browser["records"])
assert len(list((REVIEW / "screenshots").glob("*.png"))) == 32
assert not list(REVIEW.glob("usercard*"))
assert json.loads((REVIEW / "renderer-execution.json").read_text())["exit_code"] == 0
verification = json.loads((DOCS / "frontend-verification-20261012.json").read_text())
source_map_path = DOCS / "frontend-implementation-source-map-20261012.json"
source_map = json.loads(source_map_path.read_text())
assert source_map["code_commit"] == verification["code_commit"]
for item in source_map["files"]:
    assert digest((WORK / item["path"]).read_bytes()) == item["workspace_sha256"], item["path"]
supplement = manifest["supplements"][-1]
assert supplement["kind"] == "frontend_consistency_composition_acceptance"
assert digest(source_map_path.read_bytes()) == supplement["implementation_source_map_sha256"]
actual_source_path = REVIEW / "actual-pages/source.json"
if actual_source_path.exists():
    actual_source = json.loads(actual_source_path.read_text())
    assert actual_source["commit"] == verification["code_commit"]
    assert actual_source["workflow_result"] == "success"
    assert actual_source["workflow_run_id"] == verification["ci_runs"][-1]["run_id"]
    assert len(actual_source["images"]) == actual_source["screenshot_count"]
    for item in actual_source["images"]:
        assert digest((actual_source_path.parent / item["path"]).read_bytes()) == item["sha256"]
    assert len(list(actual_source_path.parent.glob("*.png"))) == actual_source["screenshot_count"]

files = {
    str(path.relative_to(WORK)): path
    for path in DOCS.rglob("*")
    if path.is_file() and not path.is_symlink() and not path.is_relative_to(OLD_REVIEW)
    and "__pycache__" not in path.parts
}
for path in (WORK / "themes/isbf-campus-feed").rglob("*"):
    if path.is_file() and not path.is_symlink() and "__pycache__" not in path.parts:
        files[str(path.relative_to(WORK))] = path
for name in ["AI-AGENTS.md", "AGENTS.md", ".github/workflows/isbf-frontend-consistency.yml"]:
    files[name] = WORK / name

queue = [path for path in files.values() if path.suffix == ".md"]
seen = set(queue)
while queue:
    page = queue.pop()
    for link in re.findall(r"\[[^\]\n]*\]\(([^)\s]+)\)", page.read_text()):
        parsed = urlparse(link)
        if parsed.scheme or link.startswith("/"):
            continue
        path = (page.parent / unquote(parsed.path)).resolve()
        if not path.is_relative_to(WORK) or path.is_relative_to(OLD_REVIEW):
            continue
        relative = str(path.relative_to(WORK))
        if not relative.startswith(("docs/", "frontend/", "app/assets/", "app/views/", "themes/isbf-campus-feed/")):
            continue
        candidates = sorted(path.rglob("*")) if path.is_dir() else [path]
        for candidate in candidates:
            if not candidate.is_file() or candidate.is_symlink() or candidate.suffix == ".zip":
                continue
            files[str(candidate.relative_to(WORK))] = candidate
            if candidate.suffix == ".md" and candidate not in seen:
                seen.add(candidate)
                queue.append(candidate)

raw = {name: path.read_bytes() for name, path in files.items()}
text_extensions = {".md", ".txt", ".scss", ".js", ".gjs", ".ts", ".gts", ".hbs", ".rb", ".json", ".yml", ".py", ".diff", ".erb"}
readable = {name for name in raw if Path(name).suffix in text_extensions}
reader_paths = {name: "read/" + name + ".html" for name in readable}
directory_paths = {posixpath.dirname(name) for name in raw}
directory_readers = {name: "read/" + name + "/index.html" for name in directory_paths}
parser = MarkdownIt("commonmark", {"html": False}).enable("table")
style = "body{font-family:system-ui,sans-serif;max-width:1100px;margin:24px auto;padding:0 20px;line-height:1.6;color:#17202a}pre{overflow:auto;padding:16px;background:#f4f4f4}code{font-family:monospace}table{border-collapse:collapse;width:100%;display:block;overflow:auto}th,td{border:1px solid #ddd;padding:8px;text-align:left}img{max-width:100%}a{overflow-wrap:anywhere}nav{margin-bottom:24px}"


def reader_page(name, content):
    reader = reader_paths[name]
    index_link = posixpath.relpath("INDEX.html", posixpath.dirname(reader))
    source_link = quote(posixpath.relpath(name, posixpath.dirname(reader)))
    navigation = f'<nav><a href="{index_link}">审核包首页</a> · <a href="{source_link}">原始文件</a></nav>'
    return f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(name)}</title><style>{style}</style><body>{navigation}{content}</body></html>'.encode()


def rewrite_links(tokens, name):
    unresolved_links = []
    for index, token in enumerate(tokens):
        if token.type == "heading_open" and index + 1 < len(tokens):
            title = tokens[index + 1].content.lower()
            token.attrSet("id", re.sub(r"[^\w\s-]", "", title).strip().replace(" ", "-"))
        attribute = "href" if token.type == "link_open" else "src" if token.type == "image" else None
        unresolved = False
        if attribute:
            url = token.attrGet(attribute)
            parsed = urlparse(url)
            if not parsed.scheme and not url.startswith("/") and parsed.path:
                target = posixpath.normpath(posixpath.join(posixpath.dirname(name), unquote(parsed.path)))
                output = reader_paths.get(target) or (target if target in raw else directory_readers.get(target.rstrip("/")))
                if output:
                    path = quote(posixpath.relpath(output, posixpath.dirname(reader_paths[name])))
                    token.attrSet(attribute, path + ("#" + parsed.fragment if parsed.fragment else ""))
                elif token.type == "link_open":
                    unresolved = True
                    token.tag = "span"
                    token.attrs = {"title": "该来源未收入离线包；原始路径：" + url}
        if token.type == "link_open":
            unresolved_links.append(unresolved)
        elif token.type == "link_close" and unresolved_links:
            if unresolved_links.pop():
                token.tag = "span"
        if token.children:
            rewrite_links(token.children, name)


for name in readable:
    text = raw[name].decode("utf-8", errors="replace")
    if name.endswith(".md"):
        tokens = parser.parse(text)
        rewrite_links(tokens, name)
        content = parser.renderer.render(tokens, parser.options, {})
    else:
        content = "<h1>" + html.escape(name) + "</h1><pre>" + html.escape(text) + "</pre>"
    raw[reader_paths[name]] = reader_page(name, content)

for directory, reader in directory_readers.items():
    items = []
    for name in sorted(raw):
        if posixpath.dirname(name) != directory:
            continue
        target = reader_paths.get(name, name)
        link = quote(posixpath.relpath(target, posixpath.dirname(reader)))
        items.append(f'<li><a href="{link}">{html.escape(Path(name).name)}</a></li>')
    if items:
        index_link = quote(posixpath.relpath("INDEX.html", posixpath.dirname(reader)))
        raw[reader] = f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><style>{style}</style><body><a href="{index_link}">审核包首页</a><h1>{html.escape(directory)}</h1><ul>{"".join(items)}</ul></body></html>'.encode()

ci_screenshots = sorted(name for name in raw if "/actual-pages/" in name and name.endswith(".png"))
gallery = '<h1>真实页面测试截图</h1><p>来源为GitHub Actions独立数据库及合成数据；不是生产截图，不代表人工视觉批准。</p>'
if ci_screenshots:
    provenance = "docs/design-system/reviews/frontend-20261012-v2/actual-pages/README.md"
    metadata = "docs/design-system/reviews/frontend-20261012-v2/actual-pages/source.json"
    gallery += f'<p>{len(ci_screenshots)}张完整截图 · <a href="{quote(reader_paths[provenance])}">来源与验收范围</a> · <a href="{quote(reader_paths[metadata])}">源码版本和逐文件摘要</a></p>'
if not ci_screenshots:
    gallery += '<p>真实页面检查结果尚未纳入本次构建。请阅读验证记录，不能用离线方案图代替。</p>'
for name in ci_screenshots:
    gallery += f'<details><summary>{html.escape(Path(name).name)}</summary><img loading="lazy" src="{quote(name)}" alt="{html.escape(Path(name).stem)}"></details>'
raw["ACTUAL-PAGES.html"] = f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>{style}</style><body><p><a href="INDEX.html">返回首页</a></p>{gallery}</body></html>'.encode()
links = [
    ("docs/design-system/frontend-implementation-20261012.md", "实现说明与保留范围"),
    ("docs/design-system/frontend-rollout-20261012.md", "19组页面及网址清单"),
    ("docs/design-system/frontend-verification-20261012.json", "真实回归及静态验证结果"),
    ("docs/design-system/ui-status.md", "UI状态"),
    ("docs/design-system/tokens.md", "Design tokens"),
    ("docs/design-system/components.md", "组件规范"),
    ("docs/design-system/reference-map.md", "Reference map"),
    ("docs/design-system/proposals/frontend-consistency-20261012.md", "已确认组合规则"),
]
index = '<h1>ISBF 前台改造审核包 V2</h1><p>三批19组代码已提交Draft PR #52。用户卡、资料上部及一级导航保留；后台排除。未合并、未部署，新页面仍为In Progress。</p><p><a href="docs/design-system/reviews/frontend-20261012-v2/index.html">打开8类离线代表预览</a> · <a href="ACTUAL-PAGES.html">真实页面测试截图</a> · <a href="https://github.com/ISBF-Lab/ISBFweb/pull/52">PR #52</a></p><ul>'
index += ''.join(f'<li><a href="{quote(reader_paths[name])}">{label}</a></li>' for name, label in links)
latest_run = verification["ci_runs"][-1]
if latest_run["result"] == "success":
    index += f'<li>完整回归通过：原生前端{latest_run["native_qunit"]["passed"]}项、主题QUnit{latest_run["theme_qunit"]["passed"]}项、真实页面{latest_run["real_pages"]["passed"]}例；真实页面截图{len(ci_screenshots)}张。</li>'
index += '</ul><p>解压完整压缩包后双击INDEX.html，无需安装依赖。离线原型使用合成示例；真实页面截图另标CI来源。用户卡样例已移除。</p><p>原始证据只供审阅，本包不是可直接部署的主题，也不是完整论坛仓库。所有文件摘要见CHECKSUMS.json。</p>'
raw["INDEX.html"] = f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>{style}</style><body>{index}</body></html>'.encode()
raw["README.md"] = '''# ISBF 前台改造审核包 V2

解压完整文件夹，双击INDEX.html。文档有HTML阅读副本，原始路径和源码均保留。
8类离线预览、16份明暗HTML、32张截图、58项静态检查；用户卡样例已移除。
实际改造覆盖19组，代码和验证记录见首页。真实页面截图另有CI来源标识。
用户卡、资料上部及一级导航、公开活动预览保留；/admin排除。
未合并或部署，页面仍为In Progress，不因自动化测试通过而成为Approved。

核心运行基线132cc95d043、主题4/133字段；恢复自停止的本任务测试副本。
原始Approved附件和运行基线有摘要校验，不重新查询生产。
没有有效的完整改造前截图，也未穷举全部插件及权限状态。
原型不能替代真实行为检查；查看frontend-verification-20261012.json获得准确结果。

本包供代码和设计审阅，不是可安装的主题或完整论坛仓库。
不含数据库、用户表、令牌、凭据、运行环境或工具依赖。
文件摘要见CHECKSUMS.json；可选运行python3 verify-package.py校验解压内容。
阅读入口不需要Python。原历史下载包另行保留，不用于扩展本次批准范围。
'''.encode()
raw["verify-package.py"] = '''import hashlib
import json
from pathlib import Path
root = Path(__file__).resolve().parent
checks = json.loads((root / "CHECKSUMS.json").read_text())
errors = [name for name, expected in checks.items() if not (root / name).is_file() or hashlib.sha256((root / name).read_bytes()).hexdigest() != expected]
print("Verified", len(checks), "files; differences:", errors)
raise SystemExit(bool(errors))
'''.encode()
for name, content in raw.items():
    assert not any(part in {"private", "node_modules", ".git", ".env", "__pycache__"} for part in Path(name).parts), name
    assert not re.search(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----", content), name
    assert "reviews/frontend-20261012/" not in name, name
checksums = {name: digest(content) for name, content in sorted(raw.items())}
raw["CHECKSUMS.json"] = (json.dumps(checksums, ensure_ascii=False, indent=2) + "\n").encode()
OUTPUT.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name, content in sorted(raw.items()):
        archive.writestr(PREFIX + name, content)
with zipfile.ZipFile(OUTPUT) as archive:
    assert archive.testzip() is None
    assert all(digest(archive.read(PREFIX + name)) == expected for name, expected in checksums.items())
checksum = digest(OUTPUT.read_bytes())
OUTPUT.with_suffix(".zip.sha256").write_text(checksum + "  " + OUTPUT.name + "\n")
print(json.dumps({"download": str(OUTPUT), "bytes": OUTPUT.stat().st_size, "sha256": checksum, "files": len(raw), "actual_page_screenshots": len(ci_screenshots), "status": verification["status"]}, ensure_ascii=False))
