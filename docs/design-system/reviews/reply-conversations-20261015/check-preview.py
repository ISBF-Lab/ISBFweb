"""Offline component-logic harness; this does not boot Ember or a forum backend."""

import json
import os
from pathlib import Path
import re

from playwright.sync_api import sync_playwright

ROOT = Path("/workspace")
ART = Path("/review")


def component_source(path):
    source = (ROOT / path).read_text()
    if path.endswith(".gjs"):
        source = source.split("  <template>")[0] + "\n}"
    source = re.sub(r"^import[\s\S]*?;\n", "", source, flags=re.M)
    source = re.sub(r"^  @service .*;\n", "", source, flags=re.M)
    source = re.sub(r"^  @(action|bind|cached)\n", "", source, flags=re.M)
    return source.replace("@tracked ", "").replace("export default class", "class").replace("export function", "function").replace("export const", "const")


paths = [
    "frontend/discourse/app/lib/flat-replies.js",
    "frontend/discourse/app/components/nested/post-children.gjs",
    "frontend/discourse/app/components/nested/post.gjs",
    "themes/isbf-campus-feed/javascripts/discourse/components/isbf-reply-context.gjs",
    "themes/isbf-campus-feed/javascripts/discourse/lib/reply-navigation.js",
]
classes = "\n".join(component_source(path) for path in paths)
translations = json.loads((ART / "compiled/translations.json").read_text())
if translations["theme"] is None:
    raise RuntimeError("Theme translation scope is missing")
scripts = (ART / "preview-fixture.js").read_text().replace("// SOURCE_CLASSES", classes)
scripts = "const translations = " + json.dumps(translations, ensure_ascii=False) + ";\n" + scripts
palette = "\n".join((ART / f"compiled/colors-{mode}.css").read_text().replace(":root", f':root[data-mode="{mode}"]') for mode in ["light", "dark"])
css = (ART / "compiled/conversations.css").read_text()
fixture_css = """
html { font-family: system-ui, sans-serif; color: var(--primary); background: var(--secondary); }
body { margin: 0; }
* { box-sizing: border-box; }
a { color: var(--isbf-v2-accent); text-decoration: none; }
button { font: inherit; cursor: pointer; }
.btn { display: inline-flex; align-items: center; justify-content: center; min-height: 36px; padding: 8px; border: 1px solid var(--isbf-v2-border); border-radius: var(--isbf-v2-radius-sm); background: var(--isbf-v2-surface); color: var(--isbf-v2-text); }
.btn-flat { border: 0; background: transparent; }
.isbf-v2-page-header { display: flex; align-items: center; gap: 12px; position: fixed; inset-block-start: 0; inset-inline-start: var(--isbf-v2-feed-left); width: var(--isbf-v2-feed-width); height: 60px; padding-inline: 16px; background: var(--isbf-v2-background); z-index: 30; border-bottom: 1px solid var(--isbf-v2-border); }
.isbf-v2-page-header strong { flex: none; }
#main-outlet { width: var(--isbf-v2-feed-width); margin-inline-start: var(--isbf-v2-feed-left); padding-block: 60px 130px; border-inline: 1px solid var(--isbf-v2-border); }
.fixture-side { position: fixed; inset-inline-start: var(--isbf-v2-page-left); inset-block-start: 20px; width: 260px; font-size: 20px; }
.fixture-side p { margin-block: 28px; }
.fixture-rail { position: fixed; inset-inline-start: calc(var(--isbf-v2-feed-left) + var(--isbf-v2-feed-width) + var(--isbf-v2-gap)); inset-block-start: 20px; width: var(--isbf-v2-rail-width); }
.fixture-rail section { padding: 16px; border: 1px solid var(--isbf-v2-border); border-radius: var(--isbf-v2-radius-md); }
.fixture-rail h2 { font-size: 18px; }
.fixture-rail p { font-size: 15px; line-height: 1.5; color: var(--isbf-v2-muted); }
.fixture-op { padding: 16px; border-bottom: 1px solid var(--isbf-v2-border); }
.fixture-op h1 { margin: 8px 0 12px; font-size: var(--isbf-v2-font-xl); }
.fixture-op p { font-size: var(--isbf-v2-font-md); line-height: 1.45; }
.fixture-avatar { display: grid; place-items: center; color: var(--isbf-v2-accent); background: var(--isbf-v2-active-surface); font-size: 18px; }
.post-controls .btn { color: var(--isbf-v2-muted); min-height: 44px; }
.topic-navigation { color: var(--isbf-v2-muted); font-size: var(--isbf-v2-font-xs); }
.timeline-replies { max-width: 260px; line-height: 1.4; white-space: normal; }
.fixture-mobile-footer { display: none; }
.fixture-review-controls { padding: 16px; border-top: 1px solid var(--isbf-v2-border); }
@media (width < 1280px) { :root { --isbf-v2-feed-left: max(100px, calc((100vw - 600px) / 2)); } .fixture-side, .fixture-rail { display: none; } }
@media (width <= 600px) { :root { --isbf-v2-feed-left: 0px; --isbf-v2-feed-width: 100vw; } .fixture-mobile-footer { display: flex; justify-content: space-around; position: fixed; inset: auto 0 0; height: 60px; padding: 16px; border-top: 1px solid var(--isbf-v2-border); background: var(--secondary); z-index: 20; } }
"""
body = """
<div class="isbf-v2-shell isbf-v2-shell--topic isbf-v2-shell--topic-feed-style isbf-v2-shell--topic-conversations">
  <aside class="fixture-side"><strong>ISBF-Lab</strong><p>首页</p><p>探索</p><p>通知</p><p>日历</p><p>工作台</p></aside>
  <header class="isbf-v2-page-header"><button class="btn btn-flat" type="button" aria-label="返回">←</button><strong>帖子</strong><button class="isbf-topic-reading__toggle btn" type="button" aria-expanded="false"></button></header>
  <aside class="fixture-rail"><section><h2>回复对话预览</h2><p>此处使用演示数据，尚未上线。</p><p>可展开组内回复、查看回复对象原文，并切换深层楼层定位与外观。</p><button class="fixture-target btn" type="button">预览定位 #80</button><button class="fixture-reset btn" type="button">恢复三条预览</button><button class="fixture-mode btn" type="button">切换明暗</button></section></aside>
</div>
<main id="main-outlet"><div class="nested-view isbf-reply-conversations has-isbf-topic-reading">
  <article class="fixture-op"><strong>校园生活 · 林溪</strong><h1>一起筹备校园开放日</h1><p>想邀请大家一起讨论校园导览、社团体验和志愿者分工。把你的建议留在下面吧。</p></article>
  <div class="nested-view__roots"></div>
  <div class="topic-navigation with-timeline isbf-topic-reading">
    <header class="isbf-topic-reading__heading"><h2>阅读进度</h2><button class="isbf-topic-reading__close btn btn-flat" type="button" aria-label="关闭">×</button></header>
    <div class="timeline-container"><div class="topic-timeline"><div class="timeline-scrollarea-wrapper"><div class="timeline-date-wrapper"><a class="start-date" href="#">10月15日</a></div><div class="timeline-scrollarea" style="height:220px"><div class="timeline-padding" style="height:30px"></div><div class="timeline-scroller" style="height:60px"><div class="timeline-scroller-content"><div class="timeline-replies"></div><div class="timeline-ago">10月15日</div></div><div class="timeline-handle"></div></div><div class="timeline-padding" style="height:130px"></div></div><div class="timeline-date-wrapper"><a class="now-date" href="#">10月15日</a></div></div><div class="timeline-footer-controls"><button class="isbf-topic-reading__jump btn" type="button">跳转到…</button></div></div></div>
  </div>
</div><aside class="fixture-review-controls">演示数据 · 未上线。可在桌面右侧切换 #80 定位与明暗外观。</aside></main>
<nav class="fixture-mobile-footer"><span>首页</span><span>探索</span><span>通知</span><span>我的</span></nav>
"""
html = '<!doctype html><html lang="zh-CN" data-mode="light"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>回复对话预览</title><style>' + palette + css + fixture_css + '</style><body>' + body + '<script>' + scripts.replace("</script", "<\\/script") + '</script></body></html>'
(ART / "index.html").write_text(html)

html = html.replace('演示数据 · 未上线。可在桌面右侧切换 #80 定位与明暗外观。', '演示数据 · 未上线。<button class="fixture-target btn" type="button">定位 #80</button><button class="fixture-reset btn" type="button">恢复三条</button><button class="fixture-mode btn" type="button">切换明暗</button>')
(ART / "index.html").write_text(html)

checks = []
errors = []
with sync_playwright() as playwright:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True, args=["--no-sandbox", "--single-process", "--no-zygote", "--disable-gpu", "--disable-dev-shm-usage", "--disable-background-networking", "--font-render-hinting=none"])
    page = browser.new_page(viewport={"width": 390, "height": 844}, device_scale_factor=1)
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.goto("file:///review/index.html", wait_until="load")
    page.wait_for_selector(".nested-post-children__expand")

    def count_replies():
        return page.locator(".nested-post-children .nested-post").count()

    assert count_replies() == 3
    assert page.locator(".isbf-topic-reading__toggle").inner_text() == "1 / 2"
    assert page.locator(".timeline-replies").inner_text() == "1 / 2"
    assert "组讨论" not in page.locator("body").inner_text()
    assert "103 条回复" not in page.locator("body").inner_text()
    checks.append("Header and timeline show only the compact current / total index")
    checks.append("Default preview contains the first three replies")
    page.locator(".nested-post-children__expand").click()
    assert count_replies() == 50
    assert page.locator(".nested-post-children__collapse").inner_text() == "收起"
    checks.append("Collapse button uses only the requested short label")
    page.locator(".nested-post-children__load-more").click()
    assert count_replies() == 100
    assert page.locator(".nested-post-children .nested-post.--depth-1").count() == 100
    assert page.evaluate("new Set([...document.querySelectorAll('.nested-post-children article')].map(n => n.dataset.postNumber)).size") == 100
    checks.append("100-deep fixture expands in pages of 50, with each reply rendered once at depth one")
    page.locator(".nested-post-children__collapse").click()
    assert count_replies() == 3
    checks.append("Collapse restores the first three replies")

    toggle = page.locator(".nested-post-children .isbf-reply-context__toggle").first
    toggle.click()
    page.wait_for_selector(".isbf-reply-context__link")
    assert page.locator(".isbf-reply-context__link").first.get_attribute("href") == "/t/campus-open-day/314/2"
    assert page.locator(".isbf-reply-context__preview .cooked").first.evaluate("node => node.getBoundingClientRect().height") <= 44
    requests = page.evaluate("fixture.originalRequests")
    page.locator(".nested-post-children .isbf-reply-context__toggle").first.click()
    page.locator(".nested-post-children .isbf-reply-context__toggle").first.click()
    assert page.evaluate("fixture.originalRequests") == requests
    checks.append("Original preview is capped at two lines, retains canonical link and caches successful loads")

    page.evaluate("fixture.reset(true); fixture.failPrevious()")
    assert page.locator('[data-post-number="80"]').count() == 1
    assert page.locator(".nested-post-children").evaluate("""node => {
      const segments = [...node.children].filter(item => item.matches('.nested-post, .nested-post-children__previous'));
      return segments.slice(1).every((item, index) => Math.abs(item.getBoundingClientRect().top - segments[index].getBoundingClientRect().bottom) < 1);
    }"""), "the target-page gap control must continue the trunk"
    page.locator(".nested-post-children__previous").click()
    page.wait_for_selector(".nested-post-children__error")
    page.locator(".fixture-list-retry").click()
    page.wait_for_selector('.nested-post-children [data-post-number="6"]')
    assert count_replies() == 100
    assert page.locator(".nested-post-children__previous").count() == 0
    checks.append("Target page shows its missing-page gap and retries the earlier page without losing the target")

    page.evaluate("fixture.reset(); fixture.hiddenContext(true)")
    page.locator(".nested-post-children .isbf-reply-context__toggle").first.click()
    page.wait_for_selector(".fixture-context-retry")
    assert "PRIVATE FIXTURE CONTENT" not in page.locator("body").inner_text()
    page.evaluate("fixture.hiddenContext(false)")
    page.locator(".fixture-context-retry").click()
    page.wait_for_selector(".isbf-reply-context__link")
    checks.append("Unavailable original reveals no body and retry recovers")
    page.evaluate("fixture.navigation.jumpToIndex(2)")
    assert page.evaluate("fixtureRoutes.at(-1)") == "/t/campus-open-day/314/103"
    checks.append("Discussion index resolves to the actual root floor before canonical navigation")
    assert page.evaluate("""async () => {
      const model = new ReplyNavigation(topic, appEvents);
      const routes = fixtureRoutes.length;
      const pending = model.jumpToIndex(1);
      model.destroy();
      await pending;
      return fixtureRoutes.length === routes;
    }""")
    checks.append("A destroyed navigation cannot route after an outstanding request resolves")

    screenshots = []
    for label, width, height, mode in [("desktop-light", 1440, 960, "light"), ("desktop-dark", 1440, 960, "dark"), ("mobile-light", 390, 844, "light"), ("mobile-dark", 390, 844, "dark"), ("mobile-320", 320, 780, "light")]:
        page.set_viewport_size({"width": width, "height": height})
        page.evaluate("mode => { document.documentElement.dataset.mode = mode; fixture.reset(); window.scrollTo(0,0); document.querySelector('.topic-navigation').classList.remove('topic-progress-expanded'); }", mode)
        page.locator(".nested-post-children .isbf-reply-context__toggle").first.click()
        page.wait_for_selector(".isbf-reply-context__link")
        page.evaluate("window.scrollTo(0,0)")
        assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth"), label
        indent = page.locator(".nested-post-children .topic-avatar").first.evaluate("node => node.getBoundingClientRect().left") - page.locator(".nested-view__roots > .nested-post .topic-avatar").first.evaluate("node => node.getBoundingClientRect().left")
        assert abs(indent - 33) < 1, (label, indent)
        guide = page.locator(".nested-view__roots > .nested-post").first.evaluate("""root => {
          const gutter = root.querySelector(':scope > .nested-post__gutter');
          const avatar = gutter.querySelector('.avatar').getBoundingClientRect();
          const gutterRect = gutter.getBoundingClientRect();
          const stem = getComputedStyle(gutter, '::after');
          const replies = [...root.querySelectorAll('.nested-post-children .nested-post')];
          const first = replies[0], last = replies.at(-1);
          const firstRect = first.getBoundingClientRect();
          const lastRect = last.getBoundingClientRect();
          const firstAvatar = first.querySelector('.avatar').getBoundingClientRect();
          const lastAvatar = last.querySelector('.avatar').getBoundingClientRect();
          const rail = getComputedStyle(first, '::before');
          const lastRail = getComputedStyle(last, '::before');
          const branch = getComputedStyle(first, '::after');
          return {
            width: parseFloat(rail.borderInlineStartWidth), color: rail.borderInlineStartColor,
            clicks: rail.pointerEvents, branchRadius: parseFloat(branch.borderRadius),
            stemStartsAtAvatar: Math.abs(gutterRect.top + parseFloat(stem.top) - avatar.bottom) < 1,
            stemAlignedToAvatar: Math.abs(gutterRect.left + parseFloat(stem.left) - avatar.left - avatar.width / 2) < 1,
            stemJoinsRail: Math.abs(gutterRect.left + parseFloat(stem.left) - firstRect.left - parseFloat(rail.left)) < 1 && Math.abs(gutterRect.bottom - parseFloat(stem.bottom) - firstRect.top) < 1,
            branchMeetsAvatar: Math.abs(firstRect.left + parseFloat(branch.left) + parseFloat(branch.width) - firstAvatar.left) < 1 && Math.abs(firstRect.top + parseFloat(branch.top) - firstAvatar.top - firstAvatar.height / 2) < 1,
            continuous: replies.slice(1).every((item, index) => Math.abs(item.getBoundingClientRect().top - replies[index].getBoundingClientRect().bottom) < 1),
            endsAtLastAvatar: Math.abs(lastRect.top + parseFloat(lastRail.top) + parseFloat(lastRail.height) - lastAvatar.top - lastAvatar.height / 2) < 1
          };
        }""")
        assert guide["width"] == 1 and guide["branchRadius"] == 0, (label, guide)
        assert all(guide[key] for key in ["stemStartsAtAvatar", "stemAlignedToAvatar", "stemJoinsRail", "branchMeetsAvatar", "continuous", "endsAtLastAvatar"]), (label, guide)
        assert guide["clicks"] == "none"
        assert guide["color"] != "rgba(0, 0, 0, 0)"
        page.screenshot(path=str(ART / f"{label}.png"), full_page=False)
        page.locator(".isbf-topic-reading__toggle").click()
        panel = page.locator(".topic-navigation").bounding_box()
        assert panel and panel["x"] >= 0 and panel["x"] + panel["width"] <= width + 1
        if label in ["desktop-light", "mobile-light"]:
            page.screenshot(path=str(ART / f"{label}-timeline.png"), full_page=False)
            page.locator(".isbf-topic-reading__close").click()
            page.add_style_tag(content=".fixture-mobile-footer, .isbf-v2-page-header { display: none; }")
            page.locator(".nested-view__roots > .nested-post").first.screenshot(path=str(ART / f"thread-{label}.png"))
            page.evaluate("document.querySelector('style:last-of-type').remove()")
        screenshots.append({"name": label, "width": width, "height": height, "horizontal_overflow": False, "indent_px": indent, "thread_guide_width_px": guide["width"], "thread_guide_color": guide["color"], "floating_timeline_inside_viewport": True})
    checks.append("Desktop and 390/320px mobile, light and dark: no horizontal overflow, natural 33px indent, floating group timeline within viewport")
    checks.append("One-pixel straight branches meet reply avatars; the trunk starts at the parent avatar, remains aligned through the group and ends at the last avatar")
    browser.close()
assert not errors, errors
report = {"passed": True, "scope": "Offline harness using actual component class methods and compiled source CSS; synthetic API and DOM rendering adapters. Ember, Rails, composer, browser history and production were not booted.", "checks": checks, "screenshots": screenshots, "browser_errors": errors, "source_files": paths}
(ART / "browser-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(report, ensure_ascii=False))
