"""Render two proposed guide designs without changing application sources."""

import json
import os
from pathlib import Path

from playwright.sync_api import sync_playwright

ART = Path("/review/guide-redesign")
base = Path("/review/index.html").read_text()
variants = {
    "avatar-axis": {"title": "A · 头像连线", "description": "头像沿同一轴线对齐，用一条细线连接，最后一条头像处自然结束。正文获得更多宽度。", "indent": 0},
    "curved-branches": {"title": "B · 圆弧支线", "description": "保留16px缩进，以细竖线和圆弧短支线接入子回复，最后一条头像处收尾。", "indent": 16},
}
for name, variant in variants.items():
    css = (ART / f"{name}.css").read_text()
    html = base.replace("</style>", f"\n{css}\n</style>", 1)
    html = html.replace("<h2>回复对话预览</h2>", f"<h2>{variant['title']}</h2>")
    html = html.replace("此处使用演示数据，尚未上线。", variant["description"])
    (ART / f"{name}.html").write_text(html)

checks = []
errors = []
with sync_playwright() as playwright:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True, args=["--no-sandbox", "--single-process", "--no-zygote", "--disable-gpu", "--disable-dev-shm-usage", "--disable-background-networking", "--font-render-hinting=none"])
    page = browser.new_page(viewport={"width": 390, "height": 1200}, device_scale_factor=1)
    page.on("pageerror", lambda error: errors.append(str(error)))
    for name, variant in variants.items():
        for label, width, height, mode in [("mobile", 390, 1200, "light"), ("mobile-dark", 390, 1200, "dark"), ("narrow", 320, 1200, "light"), ("desktop", 1440, 1200, "light")]:
            page.set_viewport_size({"width": width, "height": height})
            page.goto(f"file:///review/guide-redesign/{name}.html", wait_until="load")
            page.wait_for_selector(".nested-post-children__expand")
            page.evaluate("mode => { document.documentElement.dataset.mode = mode; }", mode)
            assert page.locator(".nested-post-children .nested-post").count() == 3
            assert page.locator(".isbf-topic-reading__toggle").inner_text() == "1 / 2"
            assert page.evaluate("document.documentElement.scrollWidth <= innerWidth")
            root = page.locator(".nested-view__roots > .nested-post").first
            parent_x = root.locator(":scope > .nested-post__gutter .topic-avatar").evaluate("node => node.getBoundingClientRect().left")
            reply_x = root.locator(".nested-post-children .topic-avatar").first.evaluate("node => node.getBoundingClientRect().left")
            assert abs(reply_x - parent_x - variant["indent"]) < 1
            root.screenshot(path=str(ART / f"{name}-{label}.png"))
            checks.append({"variant": name, "viewport": label, "no_horizontal_overflow": True, "preview_replies": 3, "indent_px": reply_x - parent_x})
    assert not errors, errors
    browser.close()

gallery = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>回复连线方案对比</title><style>
*{box-sizing:border-box}body{margin:0;padding:24px;color:#17202a;background:#fff;font:16px/1.5 system-ui,sans-serif}main{max-width:900px;margin:auto}.choices{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}h1{font-size:22px}h2{font-size:18px}p{margin-block:8px 16px}a{color:#1769aa}img{display:block;width:100%;height:auto;border:1px solid #d9e2eb}small{color:#59636e}@media(max-width:600px){body{padding:16px}.choices{grid-template-columns:1fr}}
</style><main><h1>回复连线：两种方案</h1><p>仅设计预览，使用演示数据，未替换组件、未上线。进度和“收起”文案保持简洁。</p><div class="choices">'''
for name, variant in variants.items():
    gallery += f'<section><h2>{variant["title"]}</h2><p>{variant["description"]}</p><p><a href="{name}.html">交互预览</a> · <a href="{name}-mobile-dark.png">深色</a> · <a href="{name}-desktop.png">桌面</a></p><img src="{name}-mobile.png" alt="{variant["title"]}手机预览"></section>'
gallery += '</div><p><small>复用现有42px头像、颜色、间距及1px边框，未新增全局token。样式仍待选择与视觉验收。</small></p></main></html>'
(ART / "index.html").write_text(gallery)
report = {"status": "preview_only", "application_sources_changed": False, "checks": checks, "browser_errors": errors, "limits": "Offline synthetic DOM and API adapters; this does not boot Ember, Rails, or production"}
(ART / "preview-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(report, ensure_ascii=False))
