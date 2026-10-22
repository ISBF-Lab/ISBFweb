"""Measure all three post levels against native CSS and the complete theme."""

import base64
import faulthandler
import gc
import json
import os
from pathlib import Path
import xml.etree.ElementTree as ET

from playwright.sync_api import sync_playwright

ART = Path("/review")
CACHE = Path("/client-cache")
report = {"passed": False, "checks": [], "layouts": [], "errors": [], "production_backend": False}
native = base64.b64decode(json.loads((CACHE / "1accd92b97da6108798af693b282273010d051a0ad52fc638f377dc447297b5d.json").read_text())["body"]).decode()
ET.register_namespace("", "http://www.w3.org/2000/svg")
symbols = {}
for path in Path("/client-assets/fontawesome").glob("*.svg"):
    prefix = "far-" if path.name.startswith("regular-") else ""
    sprite = ET.parse(path)
    for symbol in sprite.iter():
        identifier = prefix + symbol.get("id", "")
        if symbol.tag.endswith("symbol") and identifier in ["comment", "retweet", "heart", "far-heart", "chart-bar", "far-bookmark", "reply"]:
            symbol.set("id", identifier)
            symbols[identifier] = ET.tostring(symbol, encoding="unicode")
del sprite, symbol
gc.collect()
faulthandler.dump_traceback_later(60, repeat=True)


def check(condition, message):
    assert condition, message
    report["checks"].append(message)


def icon(name):
    return f'<svg class="fa d-icon d-icon-{name} svg-icon svg-string" aria-hidden="true"><use href="#{name}"></use></svg>'


def button(classes, name, label="", extra=""):
    return f'<button type="button" class="btn btn-flat no-text {classes}" aria-label="{name}" {extra}>{icon(name)}{label}</button>'


def actions(identifier, state="liked", count="1"):
    if state in ["own", "own-zero"]:
        like = ('<div class="double-button"><button type="button" class="btn btn-flat no-text like-count my-likes post-action-menu__like-count" aria-label="likes">' + icon("heart") + count + '</button></div>') if state == "own" else button("", "heart", extra="disabled")
    else:
        likes = f'<button type="button" class="btn btn-flat no-text like-count regular-likes post-action-menu__like-count" aria-label="likes">{count}</button>' if state != "zero" else ""
        like = f'<div class="double-button post-action-menu__double-button">{likes}{button("toggle-like post-action-menu__like " + ("has-like" if state == "liked" else "like"), "heart" if state == "liked" else "far-heart")}</div>'
    return f'''<nav class="post-controls"><div class="actions" id="{identifier}">
      {button("isbf-topic-card__reply reply", "comment", "2")}
      {button("isbf-topic-card__repost", "retweet")}
      <div class="isbf-topic-card__like">{like}</div>
      <span class="isbf-topic-card__views" aria-label="heat">{icon("chart-bar")}3</span>
      <div class="isbf-topic-card__bookmark">{button("bookmark", "far-bookmark")}</div>
      <div class="isbf-topic-card__more-menu">{button("isbf-topic-card__more", "comment")}</div>
    </div></nav>'''


def fixture():
    op = '<section class="nested-view__op"><div class="nested-view__op-row"><div class="topic-avatar"></div><div class="nested-view__op-body"><p>帖子 · 点赞与热度使用相同间距</p><section class="nested-view__op-menu post-menu-area">' + actions("op") + '</section></div></div></section>'
    child = '<div class="nested-post-children"><section class="nested-post --depth-1"><div class="nested-post__gutter"></div><article class="nested-post__article"><p>评论的回复 · 保留原生动作</p><section class="nested-post__menu post-menu-area">' + actions("child", "unliked", "12") + '</section></article></section></div>'
    root = '<section class="nested-post --depth-0"><div class="nested-post__gutter"></div><article class="nested-post__article"><p>评论 · 本人的帖子显示点赞用户入口</p><section class="nested-post__menu post-menu-area">' + actions("root", "own", "12") + '</section><button type="button" class="nested-post-children__expand">查看回复</button></article>' + child + '</section>'
    more = ''.join('<section class="nested-post --depth-0"><div class="nested-post__gutter"></div><article class="nested-post__article"><p>' + state + '</p><section class="nested-post__menu post-menu-area">' + actions(state, state, "99") + '</section></article></section>' for state in ["zero", "own-zero"])
    flat = '<div class="isbf-topic-card"><article class="isbf-topic-card__article"><div class="post__row"><div class="post__body"><p>普通平铺帖子</p><section class="post__menu-area">' + actions("flat") + '</section></div></div></article></div>'
    return '<div class="nested-view">' + op + root + more + '</div>' + flat


MEASURE = r"""row => {
  const box = el => { const r=el.getBoundingClientRect();return {left:r.left,right:r.right,top:r.top,bottom:r.bottom,width:r.width,height:r.height}; };
  const text = el => {const nodes=[...el.childNodes].filter(n=>n.nodeType===Node.TEXT_NODE&&n.textContent.trim());if(!nodes.length)return null;const range=document.createRange();range.selectNodeContents(nodes[0]);const r=range.getBoundingClientRect();return {left:r.left,right:r.right,width:r.width};};
  const items=[...row.children].filter(el=>el.matches('.isbf-topic-card__reply,.isbf-topic-card__repost,.isbf-topic-card__like,.isbf-topic-card__views,.isbf-topic-card__bookmark'));
  const icons=items.map(el=>box(el.querySelector('.d-icon')));
  const likes=row.querySelector('.like-count');
  const heat=row.querySelector('.isbf-topic-card__views');
  const love=row.querySelector('.isbf-topic-card__like .d-icon');
  const count=likes&&text(likes), views=text(heat);
  return {icons, intervals:icons.slice(1).map((r,i)=>r.left-icons[i].left), likeGap:count?count.left-love.getBoundingClientRect().right:null, heatGap:views.left-heat.querySelector('.d-icon').getBoundingClientRect().right, buttons:[...row.querySelectorAll('button')].filter(el=>!el.closest('.isbf-topic-card__more-menu')).map(el=>({className:el.className,...box(el)})), row:box(row)};
}"""

with sync_playwright() as playwright:
    print("Starting bounded offline browser", flush=True)
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True, args=["--no-sandbox", "--no-zygote", "--single-process", "--in-process-gpu", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=128 --optimize-for-size", "--no-proxy-server"])
    page = browser.new_page(viewport={"width": 390, "height": 1100}, reduced_motion="reduce")
    print("Offline browser page ready", flush=True)
    page.on("pageerror", lambda error: report["errors"].append(str(error)))
    try:
        for width in [390, 320, 1280]:
            page.set_viewport_size({"width": width, "height": 1100})
            for mode in ["light", "dark"]:
                for version in ["before", "candidate"]:
                    print(f"Checking {width}px {mode} {version}", flush=True)
                    css = (ART / f"compiled/{version}-{mode}.css").read_text()
                    colors = (ART / f"compiled/colors-{mode}.css").read_text()
                    style = 'body{margin:0;font:16px system-ui;background:var(--secondary);color:var(--primary)}#main-outlet{max-width:600px;margin:auto}p{margin:8px 0}.fixture-symbols{position:absolute;width:0;height:0;overflow:hidden}.isbf-topic-card__article{padding:16px}.isbf-topic-card__more-menu{display:none}'
                    classes = "discourse-touch mobile-view" if width <= 600 else "discourse-no-touch desktop-view"
                    content = f'<html class="{classes}"><head><style>{native}</style><style>{colors}</style><style>{css}</style><style>{style}</style></head><body><svg class="fixture-symbols">{"".join(symbols.values())}</svg><div class="isbf-v2-shell isbf-v2-shell--topic isbf-v2-shell--topic-feed-style isbf-v2-shell--topic-conversations"></div><main id="main-outlet">{fixture()}</main></body></html>'
                    page.set_content(content)
                    page.wait_for_load_state("networkidle")
                    values = {name: page.locator("#" + name).evaluate(MEASURE) for name in ["op", "root", "child", "zero", "own-zero", "flat"]}
                    report["layouts"].append({"width": width, "palette": mode, "version": version, "rows": values})
                    if version == "candidate":
                        check(page.locator("#op .d-icon use").first.evaluate("el=>el.getBBox().width>0"), f"{width}px {mode}: native SVG glyphs render")
                        for name, value in values.items():
                            label = f"{width}px {mode} {name}"
                            check(len(value["icons"]) == 5, label + ": five primary icons remain")
                            check(max(value["intervals"])-min(value["intervals"]) < 0.6, label + ": icon distances are equal")
                            check(abs(value["heatGap"]-4) < 0.6, label + ": existing heat gap remains 4px")
                            if value["likeGap"] is not None:
                                check(abs(value["likeGap"]-value["heatGap"]) < 0.6, label + ": like and heat icon/count gaps match")
                            check(all(b["height"] >= (44 if width <= 600 else 36)-0.5 for b in value["buttons"]), label + ": button heights remain accessible")
                            toggle = next((b for b in value["buttons"] if "toggle-like" in b["className"]), None)
                            if toggle:
                                check(toggle["width"] >= (44 if width <= 600 else 36)-0.5, label + ": like target width remains accessible")
                        check(not page.evaluate("document.documentElement.scrollWidth>innerWidth+1"), f"{width}px {mode}: no horizontal page overflow")
                        for name in ["op", "root", "child"]:
                            for selector in [".toggle-like", ".like-count"]:
                                target = page.locator("#"+name+" "+selector)
                                if not target.count():
                                    continue
                                target.evaluate("el=>{el.dataset.clicked='no';el.onclick=()=>el.dataset.clicked='yes'}")
                                target.click()
                                check(target.get_attribute("data-clicked") == "yes", f"{width}px {mode} {name}: {selector} remains independently clickable")
                    if width in [390, 1280]:
                        page.locator("#main-outlet").screenshot(path=str(ART / f"{version}-{width}-{mode}.png"))
                    (ART / "browser-progress.json").write_text(json.dumps(report, indent=2) + "\n")
        check(not report["errors"], "no browser errors")
        report["passed"] = True
    finally:
        (ART / "browser-report.json").write_text(json.dumps(report, indent=2) + "\n")
        browser.close()
print(json.dumps({"passed": report["passed"], "checks": len(report["checks"]), "layouts": len(report["layouts"])}))
