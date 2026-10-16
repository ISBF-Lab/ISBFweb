"""Run the actual compiled components in a cached Ember client with local fixture APIs."""

import base64
import hashlib
import json
import mimetypes
import os
from pathlib import Path
import re
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

from playwright.sync_api import sync_playwright

ART = Path("/review")
fixture = json.loads((ART / "native-fixture.json").read_text())
modules = (ART / "compiled/browser-modules.js").read_text()
report = {"passed": False, "full_ember_client": True, "production_backend_used": False, "checks": [], "layouts": [], "errors": [], "console_errors": [], "missing_assets": [], "api_requests": []}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def do_GET(self):
        path = urlsplit(self.path).path
        status, kind, body = 200, "application/json", b"{}"
        if path.startswith("/t/") and not path.endswith(".json"):
            kind = "text/html"
            body = fixture["html"].replace("https://isbf-one.com", "http://127.0.0.1:8765").encode()
        elif path == "/fixture/theme.css":
            kind, body = "text/css", (ART / "compiled/theme.css").read_bytes()
        elif path == "/fixture/colors.css":
            kind, body = "text/css", (ART / "compiled/colors-light.css").read_bytes()
        elif path.startswith("/assets/") and (Path("/client-assets") / path.removeprefix("/assets/")).is_file():
            target = Path("/client-assets") / path.removeprefix("/assets/")
            kind = mimetypes.guess_type(path)[0] or "application/javascript"
            body = target.read_bytes()
        else:
            cached = ART / "asset-cache" / (hashlib.sha256(("https://isbf-one.com" + self.path).encode()).hexdigest() + ".json")
            if cached.is_file():
                data = json.loads(cached.read_text())
                status, kind, body = data["status"], data["headers"]["content-type"], base64.b64decode(data["body"])
                if path.startswith("/theme-javascripts/") and "isbf-topic-card" in body.decode(errors="replace"):
                    body += ("\n" + modules).encode()
            elif path.startswith("/t/") and path.endswith(".json"):
                body = json.dumps(fixture["topic"]).encode()
            elif path == "/site.json":
                body = json.dumps(fixture["site"]).encode()
            elif path == "/session/current.json":
                body = json.dumps({"current_user": fixture["user"]}).encode()
            elif path == "/presence/get":
                channels = parse_qs(urlsplit(self.path).query).get("channels[]", [])
                body = json.dumps({channel: {"users": [], "count": 0, "last_id": 0} for channel in channels}).encode()
            elif "topic-tracking-state" in path or "topic_tracking_state" in path:
                body = b"[]"
            elif path.startswith("/message-bus/"):
                status, body = 204, b""
            elif path.endswith((".png", ".jpg", ".svg", ".webp", ".ico")):
                kind, body = "image/png", Path("/fixture-avatar.png").read_bytes()
                if not body:
                    status = 204
            elif path.endswith((".woff", ".woff2", ".ttf")):
                status, body = 204, b""
            elif path.endswith((".js", ".css")):
                report["missing_assets"].append(path)
                status, body = 404, b"Missing cached asset"
            else:
                report["api_requests"].append({"method": self.command, "path": path})
                body = json.dumps({"success": True, "draft_sequence": 1, "drafts": [], "user_actions": [], "notifications": [], "users": [], "topics": [], "groups": [], "count": 0}).encode()
        self.send_response(status)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

    do_POST = do_GET
    do_PUT = do_GET
    do_DELETE = do_GET
    do_HEAD = do_GET


def check(condition, message):
    assert condition, message
    report["checks"].append(message)
    print(json.dumps({"check": message}), flush=True)


def contrast(first, second):
    def luminance(color):
        channels = [int(channel) / 255 for channel in re.findall(r"\d+", color)[:3]]
        linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4 for value in channels]
        return sum(weight * value for weight, value in zip([0.2126, 0.7152, 0.0722], linear))
    high, low = sorted([luminance(first), luminance(second)], reverse=True)
    return (high + 0.05) / (low + 0.05)


server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True,
            args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=192", "--no-proxy-server"],
        )
        try:
            context = browser.new_context(viewport={"width": 1280, "height": 900}, locale="zh-CN", service_workers="block")
            context.route("https://**/*", lambda route: route.abort())
            page = context.new_page()
            def page_error(error):
                report["errors"].append(getattr(error, "stack", str(error)))
                print(json.dumps({"browser_error": report["errors"][-1]}), flush=True)
            page.on("pageerror", page_error)
            def console_message(message):
                if message.type == "error":
                    report["console_errors"].append(message.text[:1800])
                    print(json.dumps({"console_error": message.text[:1800]}), flush=True)
            page.on("console", console_message)
            page.add_init_script("window.addEventListener('error',e=>window.fixtureFailure=e.error?.stack||e.message);window.addEventListener('unhandledrejection',e=>window.fixtureFailure=e.reason?.stack||String(e.reason))")
            page.goto("http://127.0.0.1:8765/t/reading-fixture/314", wait_until="domcontentloaded", timeout=60000)
            try:
                page.wait_for_function("window.fixtureFailure || document.querySelector('.isbf-continue-reading')", timeout=60000)
                assert not page.evaluate("window.fixtureFailure"), page.evaluate("window.fixtureFailure")
            except Exception:
                report["debug"] = {"source_installed": page.evaluate("Boolean(window.isbfReviewSourceInstalled)"), "body": page.locator("body").inner_text()[-2400:], "modules": page.evaluate("Object.keys(requirejs.entries).filter(n => /isbf-review|more-topics/.test(n))")}
                raise
            page.wait_for_load_state("networkidle", timeout=30000)
            panel = page.locator(".isbf-continue-reading")
            check(panel.count() == 1, "one actual continue-reading panel replaces the original footer")
            check(panel.locator("table").count() == 0, "the topic sources render semantic lists without tables")
            check(panel.locator(".isbf-continue-reading__heading").inner_text() == "接着看看", "the Chinese heading is translated")
            page.evaluate("window.reviewOwner=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
            page.evaluate("() => { const s=reviewOwner.lookup('service:more-topics-tabs'); s.selectTab(s.tabs.find(t=>t.id==='suggested-topics')); }")
            page.wait_for_function("document.querySelector('.isbf-continue-reading').dataset.source==='suggested'")
            check(panel.locator(".isbf-continue-reading__item").evaluate_all("els=>els.map(el=>Number(el.dataset.topicId))") == [901, 902, 903, 904, 905, 906, 907], "suggestions preserve exact source IDs and ordering")
            check(panel.locator("[data-topic-id='901'] .isbf-continue-reading__replies").inner_text().strip() == "0 回复", "zero replies are explicit")
            check(panel.locator("[data-topic-id='902'] .isbf-continue-reading__replies").inner_text().strip() == "3 回复", "actual reply counts retain their label")
            dots = panel.locator(".isbf-continue-reading__item:has(.isbf-continue-reading__unread)").evaluate_all("els=>els.map(el=>Number(el.dataset.topicId))")
            check(dots == [902, 905], "only flat unread replies or the native nested new-reply flag produce a dot")
            check(panel.locator("[data-topic-id='903'] a.isbf-continue-reading__avatar").count() == 0, "a missing creator gets a default image without a fabricated profile")
            check(panel.locator("[data-topic-id='904'] .topic-status.--closed").count() == 1, "locked state remains identifiable")
            check(panel.locator("a a").count() == 0, "topic, category, activity and reply links are never nested")
            targets = page.evaluate("""() => {const topic=reviewOwner.lookup('controller:topic').model; const first=topic.suggestedTopics[0];return {title:first.lastUnreadUrl,replies:first.firstPostUrl,time:first.lastPostUrl,category:first.category.url,browse:topic.category.url}}""")
            first_row = panel.locator("[data-topic-id='901']")
            check(all(first_row.locator(selector).get_attribute("href") == targets[key] for key, selector in [("title", ".isbf-continue-reading__title"), ("replies", ".isbf-continue-reading__replies"), ("time", ".isbf-continue-reading__time"), ("category", ".badge-category__wrapper")]), "topic, replies, activity and category retain their exact native targets")
            check(panel.locator(".isbf-continue-reading__browse-all").get_attribute("href") == targets["browse"], "browse all retains the original category target")

            page.evaluate("""() => { const s=reviewOwner.lookup('service:topic-tracking-state'); const category_id=reviewOwner.lookup('controller:topic').model.category_id;s.loadStates([
              {topic_id:99101,category_id,last_read_post_number:1,highest_post_number:2,notification_level:2},
              {topic_id:99102,category_id,last_read_post_number:null,highest_post_number:1,notification_level:2,created_in_new_period:true,is_seen:false}
            ]); }""")
            print(json.dumps({"tracking": page.evaluate("() => {const s=reviewOwner.lookup('service:topic-tracking-state');return {new:s.countNew(),unread:s.countUnread(),messageCount:s.messageCount,unified:reviewOwner.lookup('service:site-settings').enable_unified_new,footer:document.querySelector('.isbf-continue-reading__footer')?.innerText}}")}), flush=True)
            page.locator(".isbf-continue-reading__remaining a[href='/new?subset=topics']").wait_for()
            check(panel.locator("a[href='/new?subset=topics']").inner_text() == "还有 1 个新话题", "remaining new-topic copy uses the real tracking count")
            check(panel.locator("a[href='/new?subset=replies']").count() == 1, "new and unread browse entries both remain available")
            page.evaluate("reviewOwner.lookup('service:topic-tracking-state').updateSeen(99101,2)")
            page.wait_for_function("!document.querySelector('.isbf-continue-reading a[href=\"/new?subset=replies\"]')")
            check(panel.locator("a[href='/new?subset=topics']").count() == 1, "reading an unread topic updates the footer without changing new-topic counts")

            for width in [320, 390, 1280]:
                page.set_viewport_size({"width": width, "height": 900})
                for mode in ["light", "dark"]:
                    page.evaluate("css => {let style=document.getElementById('review-palette'); if(!style){style=document.createElement('style');style.id='review-palette';document.body.append(style)} style.textContent=css}", (ART / f"compiled/colors-{mode}.css").read_text())
                    page.evaluate("mode=>document.documentElement.style.colorScheme=mode", mode)
                    panel.scroll_into_view_if_needed()
                    layout = panel.evaluate("""el => {
                      const box=el.getBoundingClientRect();
                      const rows=[...el.querySelectorAll('.isbf-continue-reading__item')];
                      const overflowing=[...el.querySelectorAll('a,img,button')].filter(n=>{const b=n.getBoundingClientRect();return b.width>0&&(b.left<box.left-1||b.right>box.right+1)}).map(n=>n.className);
                      const title=el.querySelector('[data-topic-id="907"] .isbf-continue-reading__title');
                      const style=getComputedStyle(title);const avatar=el.querySelector('.isbf-continue-reading__avatar').getBoundingClientRect();
                      const meta=el.querySelector('.isbf-continue-reading__metadata');
                      return {width:box.width,padding:getComputedStyle(el).padding,avatar:avatar.width,overflowing,panelOverflow:el.scrollWidth>el.clientWidth+1,titleHeight:title.getBoundingClientRect().height,titleLineHeight:parseFloat(style.lineHeight),titlePadding:parseFloat(style.paddingTop)+parseFloat(style.paddingBottom),rowHeights:rows.map(r=>r.getBoundingClientRect().height),rowBorders:rows.map(r=>({top:getComputedStyle(r).borderTopWidth,bottom:getComputedStyle(r).borderBottomWidth})),metadataColor:getComputedStyle(meta).color,readTitleColor:getComputedStyle(el.querySelector('.visited .isbf-continue-reading__title')).color,background:getComputedStyle(el).backgroundColor,bodyOverflow:document.documentElement.scrollWidth>innerWidth+1};
                    }""")
                    check(not layout["overflowing"] and not layout["bodyOverflow"] and not layout["panelOverflow"], f"{width}px {mode}: long titles and metadata stay within the content column")
                    check(layout["titleHeight"] <= 2 * layout["titleLineHeight"] + layout["titlePadding"] + 1, f"{width}px {mode}: unbroken long titles clamp to two lines")
                    check(layout["avatar"] == (30 if width <= 600 else 36), f"{width}px {mode}: avatar size matches the approved local dimensions")
                    check(layout["background"] == ("rgb(16, 20, 19)" if mode == "dark" else "rgb(255, 255, 255)"), f"{width}px {mode}: the actual theme palette is active")
                    check(all(row["bottom"] == "0px" and row["top"] in ["0px", "1px"] for row in layout["rowBorders"]), f"{width}px {mode}: only single subtle row separators remain")
                    layout["metadataContrast"] = round(contrast(layout["metadataColor"], layout["background"]), 2)
                    layout["readTitleContrast"] = round(contrast(layout["readTitleColor"], layout["background"]), 2)
                    check(min(layout["metadataContrast"], layout["readTitleContrast"]) >= 4.5, f"{width}px {mode}: secondary text and read titles remain readable")
                    layout.update(viewport=width, palette=mode)
                    report["layouts"].append(layout)
                    page.set_viewport_size({"width": width, "height": 1400})
                    panel.scroll_into_view_if_needed()
                    panel.screenshot(path=str(ART / f"{width}-{mode}.png"))
                    page.set_viewport_size({"width": width, "height": 900})

            page.set_viewport_size({"width": 1280, "height": 900})
            related = panel.get_by_role("button").filter(has_text="相关")
            check(related.count() == 1, "the existing related-topic switch remains available")
            related.click()
            page.wait_for_function("document.querySelector('.isbf-continue-reading').dataset.source==='related'")
            check(panel.locator(".isbf-continue-reading__item").evaluate_all("els=>els.map(el=>Number(el.dataset.topicId))") == [908, 909], "related topics use their own original source and order")
            check(page.evaluate("reviewOwner.lookup('service:key-value-store').get('more-topics-preference-topic')") == "related-topics", "native mode preference persistence is retained")
            panel.screenshot(path=str(ART / "related-desktop-dark.png"))
            page.evaluate("() => {const s=reviewOwner.lookup('service:more-topics-tabs');s.selectTab(s.tabs.find(t=>t.id==='suggested-topics'))}")
            title = panel.locator(".isbf-continue-reading__title").first
            title.focus()
            page.keyboard.press("Tab")
            page.keyboard.press("Shift+Tab")
            focus = title.evaluate("el=>({focused:document.activeElement===el,visible:el.matches(':focus-visible'),outline:getComputedStyle(el).outlineStyle})")
            check(focus["focused"] and focus["visible"] and focus["outline"] != "none", "keyboard focus is visible on the native topic link")
            report["computed_styles"] = panel.evaluate("""el=>{const names=['.isbf-continue-reading__item','.isbf-continue-reading__item + .isbf-continue-reading__item','.visited .isbf-continue-reading__title','.isbf-continue-reading__metadata'];return Object.fromEntries(names.map(s=>{const c=getComputedStyle(el.querySelector(s));return [s,{borderTop:c.borderTop,borderBottom:c.borderBottom,color:c.color,fontWeight:c.fontWeight}]}))}""")
            page.evaluate("""() => {const url=window.moduleBroker.lookup('discourse/lib/url').default;window.savedReviewRoute=url.routeTo;url.routeTo=href=>window.reviewRoute=href;const history=reviewOwner.lookup('service:history-store');window.savedHistorySet=history.set;window.reviewHistory=[];history.set=function(key,value){window.reviewHistory.push([key,value]);return window.savedHistorySet.call(this,key,value)};document.querySelector('.isbf-continue-reading__list').addEventListener('click',e=>e.preventDefault());} """)
            expected = title.evaluate("el=>el.href")
            formatted_title = title.locator("span[dir='auto']")
            check(formatted_title.count() == 1 and formatted_title.evaluate("el=>getComputedStyle(el).pointerEvents") == "none", "native formatted title content keeps the anchor as the click target")
            formatted_title.click(force=True)
            report["navigation"] = {"expected": expected, "actual": page.evaluate("window.reviewRoute"), "history": page.evaluate("window.reviewHistory")}
            check(report["navigation"]["actual"] == expected and ["lastTopicIdViewed", 901] in report["navigation"]["history"], "normal title clicks retain native route and list history")
            page.evaluate("window.reviewRoute=null")
            title.click(modifiers=["Control"])
            check(page.evaluate("window.reviewRoute") is None, "modified clicks retain the browser's native link behavior")
            page.evaluate("() => {window.moduleBroker.lookup('discourse/lib/url').default.routeTo=window.savedReviewRoute}")
            page.evaluate("() => {reviewOwner.lookup('service:history-store').set=window.savedHistorySet}")
            check(not report["missing_assets"], "all code and styles are served from local cached assets")
            check(not report["errors"], "the real Ember component flow produces no browser exceptions")
            report["passed"] = True
        finally:
            browser.close()
finally:
    server.shutdown()
    (ART / "browser-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"passed": report["passed"], "checks": len(report["checks"]), "layouts": len(report["layouts"])}))
