import json
import os
from pathlib import Path
import re

from playwright.sync_api import sync_playwright

ROOT = Path("/workspace")
ART = Path("/review")


def component_source(path, named_class=None):
    source = (ROOT / path).read_text()
    if named_class:
        source = "class " + named_class + source.split("export class " + named_class, 1)[1]
    source = source.split("  <template>")[0]
    source = re.sub(r"^import[\s\S]*?;\n", "", source, flags=re.M)
    source = re.sub(r"^  @service .*;\n", "", source, flags=re.M)
    source = re.sub(r"^  @(action|bind|cached)\n", "", source, flags=re.M)
    source = source.replace("@tracked ", "").replace("export default class", "class")
    if path.endswith("components/isbf-topic-reading.gjs") and not named_class:
        source = source.replace("hasProgress = false;", "get hasProgress() { return this.__hasProgress ?? false; } set hasProgress(value) { this.__hasProgress = value; queueMicrotask(() => renderState()); }")
        source = source.replace("header = null;", "get header() { return this.__header ?? null; } set header(value) { this.__header = value; queueMicrotask(() => renderState()); }")
    return source + ("\n}" if path.endswith(".gjs") else "")


classes = "\n".join(component_source(path) for path in [
    "frontend/discourse/app/ui-kit/modifiers/d-close-on-click-outside.js",
    "themes/isbf-campus-feed/javascripts/discourse/modifiers/isbf-close-on-click-outside.js",
    "frontend/discourse/app/components/topic-navigation.gjs",
    "themes/isbf-campus-feed/javascripts/discourse/components/isbf-topic-reading.gjs",
])
classes += "\n" + component_source("themes/isbf-campus-feed/javascripts/discourse/components/isbf-topic-reading.gjs", "ISBFTopicReadingJump")
about = json.loads((ROOT / "themes/isbf-campus-feed/about.json").read_text())
schemes = about["color_schemes"]
light = next(value for name, value in schemes.items() if "Light" in name)
dark = next(value for name, value in schemes.items() if "Dark" in name)
palette = lambda values: ";".join(f"--{key.replace('_', '-')}:#{value.lstrip('#')}" for key, value in values.items())
common = (ROOT / "themes/isbf-campus-feed/common/common.scss").read_text()
start = common.index(":root {")
tokens = common[start:common.index("\n}", start) + 2]
fixture_css = """
html { font-family: system-ui, sans-serif; color: var(--primary); background: var(--secondary); }
body { margin: 0; }
button { font: inherit; cursor: pointer; }
.btn { display: inline-flex; align-items: center; justify-content: center; padding: 8px; border: 1px solid var(--isbf-v2-border); background: var(--isbf-v2-surface); color: var(--isbf-v2-text); }
.btn-flat { border: 0; background: transparent; }
.btn-primary { background: var(--isbf-v2-accent); color: var(--isbf-v2-accent-contrast); }
.btn svg { width: 1em; height: 1em; fill: currentColor; }
.isbf-v2-page-header { display: flex; align-items: center; gap: 12px; position: fixed; inset-block-start: 0; inset-inline-start: var(--isbf-v2-feed-left); width: var(--isbf-v2-feed-width); box-sizing: border-box; height: 60px; padding-inline: 16px; background: var(--isbf-v2-background); z-index: 30; border-bottom: 1px solid var(--isbf-v2-border); }
#main-outlet { width: var(--isbf-v2-feed-width); margin-inline-start: var(--isbf-v2-feed-left); padding-block-start: 60px; border-inline: 1px solid var(--isbf-v2-border); }
.container.posts { display: grid; }
.posts-wrapper { grid-area: posts; }
.fixture-post { padding: 16px; border-bottom: 1px solid var(--isbf-v2-border); font-size: 16px; line-height: 1.45; min-height: 190px; }
.fixture-post h2 { font-size: 18px; margin-block: 0 12px; }
.fixture-side { position: fixed; inset-inline-start: var(--isbf-v2-page-left); inset-block-start: 20px; width: 260px; font-size: 20px; }
.fixture-side p { margin-block: 28px; }
.isbf-v2-rail { position: fixed; inset-inline-start: calc(var(--isbf-v2-feed-left) + var(--isbf-v2-feed-width) + var(--isbf-v2-gap)); inset-block-start: 12px; width: var(--isbf-v2-rail-width); }
.isbf-v2-rail__panel { margin-block-start: 20px; padding: 16px; border: 1px solid var(--isbf-v2-border); border-radius: var(--isbf-v2-radius-md); }
.isbf-v2-rail__panel p { padding-block: 12px; border-bottom: 1px solid var(--isbf-v2-border); }
.fixture-mobile-footer { display: none; }
.isbf-topic-reading__heading h2 { white-space: nowrap; }
.topic-navigation { color: var(--isbf-v2-muted); font-size: var(--isbf-v2-font-xs); }
@media (width < 1280px) { :root { --isbf-v2-feed-left: max(100px, calc((100vw - 600px) / 2)); } .fixture-side, .isbf-v2-rail { display: none; } }
@media (width <= 600px) { :root { --isbf-v2-feed-left: 0px; --isbf-v2-feed-width: calc(100vw - 2px); } .fixture-mobile-footer { display: block; position: fixed; inset: auto 0 0; height: 118px; box-sizing: border-box; padding: 12px; background: var(--secondary); border-top: 1px solid var(--isbf-v2-border); } .fixture-mobile-footer nav { display: flex; justify-content: space-around; margin-block-start: 18px; } }
"""
body = """
<div class="isbf-v2-shell isbf-v2-shell--topic isbf-v2-shell--topic-feed-style">
<aside class="fixture-side"><strong>ISBF-Lab</strong><p>首页</p><p>探索</p><p>通知</p><p>日历</p><p>工作台</p></aside>
<header class="isbf-v2-page-header"><button class="isbf-v2-page-header__back" type="button">←</button><strong>帖子</strong><button class="isbf-topic-reading__toggle" type="button" aria-expanded="false">12 / 48</button></header>
<aside class="isbf-v2-rail"><p>搜索社区</p><div class="isbf-v2-rail__content"><section class="isbf-v2-rail__panel"><h2>最近讨论</h2><p>校园活动筹备讨论</p><p>新学期课程经验分享</p><p>推荐几本好书</p></section><section class="isbf-v2-rail__panel"><h2>社区入口</h2><p>官方消息</p><p>浏览分类</p><p>精华内容</p></section></div></aside></div>
<main id="main-outlet"><div class="container posts"><div class="posts-wrapper"><article class="fixture-post"><h2>校园活动筹备讨论</h2><strong>小林</strong><p>大家好！我们正在筹备下个月的校园开放日活动，欢迎大家一起讨论活动形式、场地安排和志愿者招募等事宜。</p></article><article class="fixture-post"><strong>陈晨</strong><p>我觉得可以增加一个校园导览环节，让新同学更快熟悉校园。也可以准备一些社团体验活动。</p></article><article class="fixture-post"><strong>李明</strong><p>场地方向，图书馆报告厅比较适合，也可以使用教学楼和图书馆之间的公共空间。</p></article><article class="fixture-post"><strong>张华</strong><p>本周可以先整理任务分工，再逐项确认时间安排。</p></article></div>
<div class="topic-navigation with-timeline"><header class="isbf-topic-reading__heading"><h2>阅读进度</h2><button class="isbf-topic-reading__close btn btn-flat" type="button" title="关闭">×</button></header><div class="timeline-container"><div class="topic-timeline"><div class="timeline-scrollarea-wrapper"><div class="timeline-date-wrapper"><a class="start-date" href="#">9月29日</a></div><div class="timeline-scrollarea" style="height:300px"><div class="timeline-padding" style="height:70px"></div><div class="timeline-scroller" data-pointer-drag="none" style="height:50px"><div class="timeline-scroller-content"><div class="timeline-replies">12 / 48</div><div class="timeline-ago">9月30日</div></div><div class="timeline-handle"></div></div><div class="timeline-padding" style="height:180px"></div><div class="timeline-last-read" style="top:220px;height:20px"><button class="back-button" type="button">上次阅读</button></div></div><div class="timeline-date-wrapper"><a class="now-date" href="#">10月2日</a></div></div><div class="timeline-footer-controls"><button class="btn isbf-topic-reading__back btn-default" type="button">返回</button><button class="timeline-open-jump-to-post-prompt-btn btn" type="button">跳转到…</button><button class="btn fixture-bell" type="button" title="通知">♧</button></div></div></div></div>
</div></main><footer class="fixture-mobile-footer"><button class="btn" type="button">回复</button><nav><span>首页</span><span>探索</span><span>通知</span><span>我的</span></nav></footer>
"""
bell = (ROOT / "node_modules/@fortawesome/fontawesome-free/svgs/regular/bell.svg").read_text()
body = body.replace('class="back-button"', 'class="btn btn-primary btn-small back-button"').replace('>上次阅读</button>', '>返回</button>').replace('>♧</button>', '>' + bell + '</button>')
adapters = """
const destructors = new WeakMap();
const registerDestructor = (object, callback) => { const list = destructors.get(object) || []; list.push(callback); destructors.set(object, list); };
const services = { site: { mobileView: innerWidth <= 600 }, composer: { isPreviewActive: false }, modal: { activeModal: null, show() { this.activeModal = {}; } }, menu: { registeredMenus: new Set() } };
class Component { constructor(owner, args) { this.args = args; Object.assign(this, owner); for (let prototype = Object.getPrototypeOf(this); prototype && prototype !== Object.prototype; prototype = Object.getPrototypeOf(prototype)) { for (const [name, descriptor] of Object.entries(Object.getOwnPropertyDescriptors(prototype))) { if (name !== 'constructor' && typeof descriptor.value === 'function' && !Object.hasOwn(this, name)) this[name] = descriptor.value.bind(this); } } } }
class Modifier extends Component {}
const modifier = callback => callback;
const modifierFn = callback => callback;
const EmbedMode = { enabled: false };
const applyValueTransformer = (_, value) => value;
class TrackedMediaQuery { constructor(query) { this.matches = matchMedia(query).matches; } teardown() {} }
const headerOffset = () => 60;
class SwipeEvents { addTouchListeners() {} removeTouchListeners() {} }
const getMaxAnimationTimeMs = () => 0;
const shouldCloseMenu = () => false;
const isDestroying = () => false;
const scheduledCloses = [];
const discourseLater = (callback, delay) => { scheduledCloses.push(delay); return setTimeout(callback, delay); };
const JumpToPost = {};
const jumps = [];
const getOwner = () => ({ lookup: () => ({ get: () => 12, send: (action, index) => jumps.push({action, index}) }) });
const themePrefix = key => key;
const i18n = (_, values) => `${values.current} / ${values.total}`;
const schedule = (_, callback) => requestAnimationFrame(callback);
const eventHandlers = new Map();
let renderState = () => {};
services.appEvents = { on(name, callback) { if (!eventHandlers.has(name)) eventHandlers.set(name, new Set()); eventHandlers.get(name).add(callback); return this; }, off(name, callback) { eventHandlers.get(name)?.delete(callback); return this; }, trigger(name, value) { for (const callback of eventHandlers.get(name) || []) callback(value); renderState(); } };
"""
bindings = """
const topic = { posts_count: 48, archetype: 'regular', currentPost: 12, last_read_post_number: 36, last_read_post_id: 1036, get() { return 12; }, postStream: { stream: Array.from({length:48}, (_, i) => 1001+i), filteredPostsCount: 48, progressIndexOfPostId() { return 12; } } };
const native = new TopicNavigation(services, { topic });
const outletArgs = { topic, get renderTimeline() { return native.info.renderTimeline; }, get topicProgressExpanded() { return native.info.topicProgressExpanded; } };
const reading = new ISBFTopicReading(services, { outletArgs });
const navigation = document.querySelector('.topic-navigation');
const heading = document.querySelector('.isbf-topic-reading__heading');
const toggle = document.querySelector('.isbf-topic-reading__toggle');
const coreOutside = new DCloseOnClickOutside({}, {});
coreOutside.modify(navigation, [native.closeOnClickOutside]);
const cleanSwipe = native.setupSwipe(navigation);
const cleanLayout = reading.syncLayout(heading);
const outside = new ISBFCloseOnClickOutside({}, {});
outside.modify(heading, [reading.closeOnClickOutside, { targetSelector: '.topic-navigation.isbf-topic-reading', secondaryTargetSelector: '.isbf-topic-reading__toggle' }]);
const controls = new ISBFTopicReadingJump(services, {outletArgs:{model:topic, fullscreen:true}});
document.querySelector('.isbf-topic-reading__back').addEventListener('click', controls.goBack);
renderState = () => { const open = native.info.topicProgressExpanded; navigation.className = 'topic-navigation with-timeline' + (open ? ' topic-progress-expanded' : ''); const timeline = navigation.querySelector('.timeline-container'); timeline.classList.toggle('timeline-fullscreen', open); timeline.classList.toggle('show', open); toggle.setAttribute('aria-expanded', String(open)); };
toggle.addEventListener('pointerdown', reading.onTogglePointerDown);
toggle.addEventListener('click', reading.toggleProgress);
document.querySelector('.isbf-topic-reading__close').addEventListener('click', reading.closeProgress);
window.fixture = { native, reading, controls, jumps, scheduledCloses, services, destructors, cleanLayout, cleanSwipe, outside, coreOutside };
window.recreateReading = () => {
  const previous = fixture.reading;
  const close = document.querySelector('.isbf-topic-reading__close');
  toggle.removeEventListener('pointerdown', previous.onTogglePointerDown);
  toggle.removeEventListener('click', previous.toggleProgress);
  close.removeEventListener('click', previous.closeProgress);
  fixture.cleanLayout();
  const next = new ISBFTopicReading(services, { outletArgs });
  fixture.reading = next;
  fixture.cleanLayout = next.syncLayout(heading);
  outside.modify(heading, [next.closeOnClickOutside, { targetSelector:'.topic-navigation.isbf-topic-reading', secondaryTargetSelector:'.isbf-topic-reading__toggle' }]);
  toggle.addEventListener('pointerdown', next.onTogglePointerDown);
  toggle.addEventListener('click', next.toggleProgress);
  close.addEventListener('click', next.closeProgress);
};
window.checkModifier = () => {
  const target = document.querySelector('.isbf-v2-page-header__back');
  const panel = document.createElement('div'); const inside = document.createElement('button'); inside.type = 'button'; inside.textContent = 'Inside'; panel.append(inside); document.body.append(panel);
  const calls = []; const current = new ISBFCloseOnClickOutside({}, {});
  const stop = event => { calls.push('target'); event.stopPropagation(); };
  target.addEventListener('pointerdown', stop);
  current.modify(panel, [() => calls.push('close')]);
  panel.firstChild.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
  target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
  const captureOrder = calls.join(','); calls.length = 0;
  current.cleanup();
  const legacy = new DCloseOnClickOutside({}, {});
  legacy.modify(panel, [() => calls.push('close')]);
  target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
  const defaultOrder = calls.join(','); calls.length = 0;
  legacy.cleanup();
  current.modify(panel, [() => calls.push('close'), { target }]);
  target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
  const excludedOrder = calls.join(','); calls.length = 0;
  current.cleanup(); target.removeEventListener('pointerdown', stop);
  target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
  const afterCleanup = calls.length; panel.remove();
  return { captureOrder, defaultOrder, excludedOrder, afterCleanup };
};
"""
html = "<!doctype html><html lang='zh-CN'><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>时间轴离线布局预览</title><style>"
html += (ART / "compiled/colors-light.css").read_text() + (ART / "compiled/colors-dark.css").read_text().replace(":root", ":root[data-dark]") + tokens + fixture_css + (ART / "compiled/timeline.css").read_text() + "</style>" + body
html += "<script>" + adapters + classes + bindings + "</script></html>"
(ART / "preview.html").write_text(html)
results = []
errors = []
with sync_playwright() as playwright:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True, args=["--no-sandbox", "--disable-dev-shm-usage", "--renderer-process-limit=1"])
    page = browser.new_page(viewport={"width": 1440, "height": 950})
    page.on("pageerror", lambda error: errors.append(str(error)))
    try:
        for width, height, mode, variant in [(1440,950,"light","normal"),(1440,950,"dark","normal"),(390,844,"light","normal"),(390,844,"dark","normal"),(320,568,"light","normal"),(390,450,"dark","normal"),(390,844,"dark","long"),(320,568,"light","long")]:
            page.set_viewport_size({"width":width,"height":height})
            page.goto((ART / "preview.html").as_uri())
            page.wait_for_load_state("networkidle")
            page.wait_for_function("fixture.reading.header !== null")
            if mode == "dark":
                page.evaluate("document.documentElement.setAttribute('data-dark', '')")
            if variant == "long":
                page.evaluate("document.querySelector('.start-date').textContent='29 September 2025'; document.querySelector('.now-date').textContent='13 October 2026'; document.querySelector('.timeline-replies').textContent='12345 / 23456'; document.querySelector('.timeline-ago').textContent='13 October 2026'")
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "false"
            page.locator(".isbf-topic-reading__toggle").click()
            page.wait_for_function("document.querySelector('.topic-navigation.isbf-topic-reading.topic-progress-expanded')")
            geometry = page.evaluate("""() => { const nav=document.querySelector('.topic-navigation'), area=nav.querySelector('.timeline-scrollarea'), handle=nav.querySelector('.timeline-handle'), text=nav.querySelector('.timeline-scroller-content'), date=nav.querySelector('.start-date'), scroller=nav.querySelector('.timeline-scroller'); const rect=e=>{const r=e.getBoundingClientRect();return {left:r.left,right:r.right,top:r.top,bottom:r.bottom,width:r.width,height:r.height}}; return { panel:rect(nav), date:rect(date), text:rect(text), handle:rect(handle), track:rect(area), scrollerHeight:scroller.getBoundingClientRect().height, backdrop:getComputedStyle(nav).backdropFilter, border:getComputedStyle(area).borderRightWidth, pageWidth:document.documentElement.scrollWidth }; }""")
            assert geometry["panel"]["right"] <= width - 11, geometry
            assert geometry["panel"]["width"] < 260, geometry
            assert geometry["text"]["right"] <= geometry["handle"]["left"] + 1, geometry
            assert geometry["date"]["right"] <= geometry["handle"]["left"] + 1, geometry
            assert abs((geometry["handle"]["left"]+geometry["handle"]["right"])/2 - (geometry["track"]["right"]-2)) < 1, geometry
            assert geometry["scrollerHeight"] == 50, geometry
            assert geometry["backdrop"] == "blur(24px)", geometry
            assert geometry["pageWidth"] == width, geometry
            if width <= 600:
                assert geometry["panel"]["bottom"] <= height - 129, geometry
                assert page.locator(".isbf-topic-reading__close").bounding_box()["height"] >= 44
                assert page.locator(".isbf-topic-reading__back").bounding_box()["height"] >= 44
                swipe = page.evaluate("!document.querySelector('.topic-navigation').dispatchEvent(new CustomEvent('swipestart', { cancelable:true }))")
                assert swipe
            suffix = "" if variant == "normal" else "-long"
            page.screenshot(path=str(ART / f"{width}-{height}-{mode}{suffix}.png"), full_page=False)
            back = page.locator(".isbf-topic-reading__back").bounding_box()
            footer = page.locator(".timeline-footer-controls").bounding_box()
            assert back["y"] >= footer["y"] and back["y"] + back["height"] <= footer["y"] + footer["height"] + 1, (back, footer)
            assert not page.locator(".timeline-last-read .back-button").is_visible()
            if width >= 600 or height >= 568:
                page.locator(".isbf-topic-reading__back").click()
                assert page.evaluate("fixture.jumps") == [{"action":"jumpToIndex","index":36}]
            page.locator(".isbf-topic-reading__toggle").click()
            page.locator(".isbf-topic-reading__toggle").click()
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "true"
            page.locator(".isbf-topic-reading__close").click()
            page.wait_for_function("document.activeElement.matches('.isbf-topic-reading__toggle')")
            page.locator(".isbf-topic-reading__toggle").click()
            page.keyboard.press("Escape")
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "false"
            page.locator(".isbf-topic-reading__toggle").click()
            page.locator(".isbf-v2-page-header__back").click()
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "false"
            assert page.evaluate("fixture.scheduledCloses.length") == 0
            page.locator(".isbf-topic-reading__toggle").click()
            page.evaluate("fixture.services.modal.activeModal = {}")
            page.keyboard.press("Escape")
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "true"
            page.evaluate("fixture.services.modal.activeModal = null")
            page.keyboard.press("Escape")
            modifier = page.evaluate("checkModifier()")
            assert modifier == {"captureOrder":"close,target","defaultOrder":"target","excludedOrder":"target","afterCleanup":0}, modifier
            page.locator(".isbf-topic-reading__toggle").click()
            page.evaluate("recreateReading()")
            page.wait_for_function("document.querySelector('.isbf-topic-reading__toggle').getAttribute('aria-expanded') === 'false'")
            page.locator(".isbf-topic-reading__toggle").click()
            assert page.locator(".isbf-topic-reading__toggle").get_attribute("aria-expanded") == "true"
            page.evaluate("fixture.cleanLayout(); fixture.cleanSwipe?.(); fixture.outside.cleanup(); fixture.coreOutside.cleanup(); for(const callback of fixture.destructors.get(fixture.native)||[]) callback(fixture.native)")
            assert not page.locator(".has-isbf-topic-reading").count()
            results.append({"width":width,"height":height,"mode":mode,"variant":variant,"geometry":geometry,"handlers":"passed","modifier":modifier})
        assert not errors, errors
    finally:
        browser.close()
(ART / "preview-verification.json").write_text(json.dumps({"cases":results,"page_errors":errors,"boundary":"Actual SCSS and source event-handler bodies, synthetic markup/data and framework adapters; full Ember application tests and final human visual acceptance remain separate."}, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"offline_cases_passed":len(results),"page_errors":errors},ensure_ascii=False))
