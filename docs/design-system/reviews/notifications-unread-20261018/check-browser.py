"""Run the actual compiled components in a cached Ember client with local fixture APIs."""

import base64
import hashlib
import json
import mimetypes
import os
from pathlib import Path
import re
import sys
import threading
import time
import copy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

from playwright.sync_api import sync_playwright

ART = Path("/review")
OUTPUT = ART / (sys.argv[1] if len(sys.argv) > 1 else ".")
OUTPUT.mkdir(parents=True, exist_ok=True)
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
            cached = Path("/client-cache") / (hashlib.sha256(("https://isbf-one.com" + self.path).encode()).hexdigest() + ".json")
            if cached.is_file():
                data = json.loads(cached.read_text())
                status, kind, body = data["status"], data["headers"]["content-type"], base64.b64decode(data["body"])
                if "text/css" in kind:
                    body = re.sub(rb"\.isbf-v2-side__links\s+span\s*\{\s*display:\s*none\s*;?\s*\}", b".isbf-v2-side__links span:not(.isbf-notification-bell,.isbf-notification-bell__badge){display:none}", body)
                if path.startswith("/theme-javascripts/") and "isbf-topic-card" in body.decode(errors="replace"):
                    text_body = body.decode()
                    match = re.search(r"\nexport\{(\w+) as compatModules", text_body)
                    assert match, "The cached theme must expose its compatibility modules"
                    body = (text_body[:match.start()] + "\nwindow.isbfUnreadCachedTheme=" + match[1] + ";\n" + text_body[match.start():] + "\n" + modules).encode()
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


control = {"fail_style": False, "fail_bulk": False, "delay_bulk": 0, "delay_filter": None}
bulk_started = threading.Event()
types = fixture["site"]["notification_types"]
records = []


def notice(identifier, action, minute, read=False):
    return {
        "id": identifier, "action": action, "read": read,
        "created_at": f"2026-10-18T01:{minute:02d}:00Z",
        "notification_type": types["liked_consolidated" if action == "liked" else action],
        "topic_id": 314 if action != "custom" else None,
        "post_number": 1 if action != "custom" else None,
        "data": {"display_username": "student", "username": "student", "topic_title": "校园讨论", "count": 3, "message": "notifications.custom"},
    }


records.extend([notice(93001, "replied", 1), notice(93002, "liked", 3), notice(93003, "replied", 5, True), notice(93004, "custom", 0, True)])


def entry(record, actor_id=201):
    return {
        "key": f"liked-{actor_id}" if record["action"] == "liked" else f"notification-{record['id']}",
        "action": record["action"], "created_at": record["created_at"],
        "actor": {"id": actor_id, "username": f"student-{actor_id}", "name": f"同学{actor_id}", "avatar_template": "/images/avatar.png"},
        "notification": {key: value for key, value in record.items() if key != "action"},
    }


def selected(query):
    return sorted([
        record for record in records
        if (query.get("filter", ["all"])[0] != "unread" or not record["read"])
        and (query.get("tab", ["all"])[0] != "mentions" or record["action"] == "replied")
    ], key=lambda record: record["created_at"], reverse=True)


def topic_groups(query):
    rows = selected(query)
    topic_rows = [record for record in rows if record["topic_id"]]
    actions = []
    for action in dict.fromkeys(record["action"] for record in topic_rows):
        items = [record for record in topic_rows if record["action"] == action]
        actions.append({
            "key": action, "count": 3 if action == "liked" else len(items),
            "unread": any(not record["read"] for record in items), "latest": entry(items[0]),
            "detail_url": f"/isbf/notifications/groups/314/actions/{action}.json?filter={query.get('filter', ['all'])[0]}&tab={query.get('tab', ['all'])[0]}",
        })
    groups = [{"key": "topic-314", "kind": "topic", "topic": {"id": 314, "title": "校园讨论", "url": "/t/reading-fixture/314"}, "unread": any(not record["read"] for record in topic_rows), "actions": actions}] if actions else []
    groups.extend({"key": f"notification-{record['id']}", "kind": "standalone", "unread": not record["read"], "latest": entry(record)} for record in rows if not record["topic_id"])
    return {"groups": groups, "next_cursor": None}


CachedHandler = Handler


class Handler(CachedHandler):
    def send_json(self, value, status=200):
        body = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        path = urlsplit(self.path).path
        query = parse_qs(urlsplit(self.path).query)
        if path.startswith("/isbf/notifications/"):
            clear_id = self.headers.get("Discourse-Clear-Notifications")
            if clear_id:
                for record in records:
                    if str(record["id"]) == clear_id:
                        record["read"] = True
            report["api_requests"].append({"method": "GET", "path": path, "query": query})
            if "/actions/" in path:
                action = path.rsplit("/", 1)[1].removesuffix(".json")
                rows = [record for record in selected(query) if record["action"] == action]
                entries = [entry(rows[0], actor_id) for actor_id in [201, 202, 203]] if action == "liked" and rows else [entry(record) for record in rows]
                self.send_json({"entries": entries, "next_cursor": None})
            else:
                result = copy.deepcopy(topic_groups(query))
                if control["delay_filter"] == query.get("filter", ["all"])[0]:
                    control["delay_filter"] = None
                    time.sleep(1.2)
                self.send_json(result)
        elif path.startswith("/u/") and path.endswith("/notifications"):
            html = fixture["html"].replace("https://isbf-one.com", "http://127.0.0.1:8765")
            match = re.search(r'(<script type="application/json" id="data-preloaded">)([\s\S]*?)(</script>)', html)
            preloaded = json.loads(match[2])
            preloaded["currentUser"] = json.dumps(fixture["user"])
            body = (html[:match.start(2)] + json.dumps(preloaded) + html[match.end(2):]).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif path.startswith("/u/") and path.endswith(".json"):
            self.send_json({"user": fixture["user"]})
        else:
            super().do_GET()

    def do_PUT(self):
        path = urlsplit(self.path).path
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        params = parse_qs(body.decode())
        report["api_requests"].append({"method": "PUT", "path": path})
        if path == "/u/preview-user.json":
            if control["fail_style"]:
                self.send_json({"errors": ["Synthetic save failure"]}, 500)
            else:
                style = params["custom_fields[isbf_notification_badge_style]"][0]
                fixture["user"]["isbf_notification_badge_style"] = style
                self.send_json({"success": True})
        elif path == "/notifications/mark-read":
            if control["fail_bulk"]:
                self.send_json({"errors": ["Synthetic mark-read failure"]}, 500)
            else:
                for record in records:
                    record["read"] = True
                bulk_started.set()
                time.sleep(control["delay_bulk"])
                self.send_json({"success": True})
        else:
            self.send_json({"success": True})


def publish(page, counts, recent=None):
    page.evaluate("""({counts, recent}) => {
      const data = {grouped_unread_notifications: counts, recent: recent || [],
        unread_notifications: 0, unread_high_priority_notifications: 0,
        all_unread_notifications_count: 0, new_personal_messages_notifications_count: 0,
        read_first_notification: true};
      const run = window.moduleBroker.lookup('@ember/runloop').run;
      run(() => window.MessageBus.callbacks.filter(c => c.channel === '/notification/42').forEach(c => c.func(data)));
    }""", {"counts": counts, "recent": recent or []})


def open_menu(page):
    if not page.locator(".isbf-notifications__menu").evaluate("node => node.open"):
        page.locator(".isbf-notifications__menu summary").click()


def toggle_filter(page):
    open_menu(page)
    page.locator(".isbf-notifications__filter [role='switch']").click()
    page.keyboard.press("Escape")


server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
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
            page.on("pageerror", lambda error: report["errors"].append(str(error)))
            page.on("console", lambda message: report["console_errors"].append(message.text[:1200]) if message.type == "error" else None)
            page.add_init_script("window.addEventListener('error', e=>window.fixtureFailure=e.error?.stack||e.message);window.addEventListener('unhandledrejection',e=>window.fixtureFailure=e.reason?.stack||String(e.reason))")
            page.goto("http://127.0.0.1:8765/u/preview-user/notifications", wait_until="domcontentloaded", timeout=60000)
            page.wait_for_function("window.fixtureFailure || document.querySelector('.isbf-notifications__topic')", timeout=60000)
            check(not page.evaluate("window.fixtureFailure"), "the actual compiled shell and notification components boot")
            page.wait_for_load_state("networkidle", timeout=30000)
            page.evaluate("window.reviewOwner=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
            check(page.locator(".isbf-notifications").count() == 1, "one grouped notification page is rendered")
            check(page.locator(".isbf-notification-bell__badge").first.inner_text() == "2", "all unread records count even when the header's unseen count is zero")
            check(page.locator(".isbf-notifications__standalone").count() == 1, "history remains visible by default")
            check(page.locator(".isbf-notification-unread").count() == 2, "both unread actions retain a dot")
            check(page.locator(".isbf-notifications__topic h2 .isbf-notification-unread").count() == 0, "topic headings have no unread dot")
            check(page.locator(".isbf-notifications__menu .isbf-notifications__filter [role='switch']").count() == 1 and not page.locator(".isbf-notifications__filter").is_visible(), "the unread switch belongs to the closed three-dot menu")
            check(not any(request["method"] == "PUT" for request in report["api_requests"]), "opening the page never marks notices read")

            for count in [0, 1, 99, 100]:
                page.evaluate("count => reviewOwner.lookup('service:current-user').set('grouped_unread_notifications', count ? {6:count} : {})", count)
                page.wait_for_timeout(80)
                badges = page.locator(".isbf-notification-bell__badge")
                check(badges.count() == (0 if count == 0 else 2) and (count == 0 or badges.first.inner_text() == ("99+" if count > 99 else str(count))), f"both entrances handle unread boundary {count}")
            publish(page, {str(types["replied"]): 1, str(types["liked_consolidated"]): 1})
            page.wait_for_timeout(150)

            switch = page.locator(".isbf-notifications__filter [role='switch']")
            toggle_filter(page)
            page.wait_for_function("document.querySelector('.isbf-notifications__filter [role=switch]').getAttribute('aria-checked') === 'true' && !document.querySelector('.isbf-notifications__standalone')")
            check(page.locator(".isbf-notification-entry.is-unread").count() == 2, "unread filtering selects an older unread representative before grouping")
            page.locator(".isbf-notification-action__toggle").first.click()
            page.wait_for_timeout(150)
            check(page.locator(".isbf-notification-action__details .isbf-notification-entry").count() == 2, "the consolidated like notice expands into its existing actor rows")
            detail_requests = [request for request in report["api_requests"] if "/actions/" in request["path"]]
            check(detail_requests[-1]["query"]["filter"] == ["unread"], "lazy detail requests retain the unread filter")
            check(page.locator(".isbf-notification-bell__badge").first.inner_text() == "2", "expansion never consumes unread counts")
            page.locator(".isbf-notifications__tabs button").nth(1).click()
            page.wait_for_function("document.querySelectorAll('.isbf-notification-action').length === 1")
            check(page.locator(".isbf-notification-entry.is-unread").count() == 1, "the mentions tab composes with unread filtering")
            page.locator(".isbf-notifications__tabs button").first.click()
            page.wait_for_function("document.querySelectorAll('.isbf-notification-action').length === 2")
            toggle_filter(page)
            page.wait_for_selector(".isbf-notifications__standalone")

            likes = page.locator(".isbf-notification-action").nth(1)
            likes.locator(".isbf-notification-action__toggle").click()
            page.wait_for_selector(".isbf-notification-action__details .isbf-notification-entry")
            page.evaluate("() => { const url=window.moduleBroker.lookup('discourse/lib/url').default; window.reviewRouteTo=url.routeTo; url.routeTo=()=>{}; }")
            likes.locator(".isbf-notification-action__details .isbf-notification-entry a").first.click()
            page.wait_for_function("document.querySelector('.isbf-notification-bell__badge').textContent.trim() === '1'")
            page.wait_for_timeout(200)
            check(likes.locator(".isbf-notification-entry.is-unread").count() == 0, "all actors sharing one consolidated notification change read state together")
            likes.locator(".isbf-notification-action__details .isbf-notification-entry a").last.click()
            page.wait_for_timeout(200)
            check(page.locator(".isbf-notification-bell__badge").first.inner_text() == "1", "clicking a second actor never deducts the same notice twice")
            page.evaluate("window.moduleBroker.lookup('discourse/lib/url').default.routeTo=window.reviewRouteTo")
            records[1]["read"] = False
            publish(page, {str(types["replied"]): 1, str(types["liked_consolidated"]): 1}, [[93002, False]])
            page.wait_for_timeout(150)

            menu = page.locator(".isbf-notifications__menu summary")
            open_menu(page)
            options = page.locator(".isbf-notifications__badge-options button")
            control["fail_style"] = True
            options.nth(1).click()
            page.wait_for_selector(".isbf-notifications__preference-error")
            check("--dot" not in page.locator(".isbf-notification-bell__badge").first.get_attribute("class"), "a failed preference save preserves numeric badges")
            control["fail_style"] = False
            page.locator(".isbf-notifications__preference-error button").click()
            page.wait_for_selector(".isbf-notification-bell__badge.--dot")
            check(fixture["user"]["isbf_notification_badge_style"] == "dot", "retry saves the dot preference through the user update endpoint")
            check(page.locator(".isbf-v2-side__links a[href$='/notifications']").get_attribute("aria-label").startswith("通知"), "dot mode retains a translated accessible count")
            page.reload(wait_until="domcontentloaded")
            page.wait_for_selector(".isbf-notification-bell__badge.--dot")
            page.wait_for_selector(".isbf-notifications__topic")
            page.evaluate("window.reviewOwner=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
            check(page.locator(".isbf-notifications__standalone").count() == 1, "a fresh client restores the account preference and defaults to all notifications")
            open_menu(page)
            options.first.click()
            page.wait_for_function("!document.querySelector('.isbf-notification-bell__badge.--dot')")
            options.first.focus()
            page.keyboard.press("Escape")
            check(not page.locator(".isbf-notifications__menu").evaluate("node=>node.open"), "Escape closes the notification menu")

            for width in [1280, 900, 390, 320]:
                page.set_viewport_size({"width": width, "height": 900})
                for mode in ["light", "dark"]:
                    colors = (ART / f"compiled/colors-{mode}.css").read_text()
                    page.evaluate("css=>{let node=document.getElementById('review-palette');if(!node){node=document.createElement('style');node.id='review-palette';document.body.append(node)}node.textContent=css}", colors)
                    page.evaluate("mode=>document.documentElement.style.colorScheme=mode", mode)
                    page.wait_for_timeout(100)
                    background = page.locator(".isbf-notifications").evaluate("node=>getComputedStyle(node).backgroundColor")
                    check(background == ("rgb(16, 20, 19)" if mode == "dark" else "rgb(255, 255, 255)"), f"{width}px {mode} uses its actual theme palette")
                    visible = page.locator(".isbf-notification-bell__badge:visible")
                    check(visible.count() == 1, f"one visible badge survives {width}px {mode}, including collapsed navigation")
                    overflow = page.evaluate("document.documentElement.scrollWidth > innerWidth + 1")
                    check(not overflow, f"{width}px {mode} has no horizontal overflow")
                    style = visible.evaluate("node=>({fg:getComputedStyle(node).color,bg:getComputedStyle(node).backgroundColor})")
                    ratio = contrast(style["fg"], style["bg"])
                    check(ratio >= 4.5, f"{width}px {mode} badge text contrast meets AA")
                    centers = page.locator(".isbf-notification-action__label:has(.isbf-notification-unread)").evaluate_all("""labels => labels.map(label => {
                      const text = label.querySelector('span').getBoundingClientRect();
                      const dot = label.querySelector('.isbf-notification-unread').getBoundingClientRect();
                      return Math.abs((text.top + text.bottom - dot.top - dot.bottom) / 2);
                    })""")
                    check(len(centers) == 2 and max(centers) <= 0.5, f"{width}px {mode} centers each action dot on its label")
                    check(not page.locator(".isbf-notifications__filter").is_visible(), f"{width}px {mode} has no separate filter row")
                    page.screenshot(path=str(OUTPUT / f"{width}-{mode}.png"), full_page=False)
                    open_menu(page)
                    bounds = page.locator(".isbf-notifications__menu-items").bounding_box()
                    check(bounds["x"] >= 0 and bounds["x"] + bounds["width"] <= width and page.locator(".isbf-notifications__filter [role='switch']").is_visible(), f"{width}px {mode} keeps the filter inside the visible menu")
                    page.screenshot(path=str(OUTPUT / f"{width}-{mode}-menu.png"), full_page=False)
                    page.locator(".isbf-notifications__filter [role='switch']").focus()
                    page.keyboard.press("Escape")
                    report["layouts"].append({"width": width, "mode": mode, "background": background, "badge_text_contrast": round(ratio, 2), "horizontal_overflow": False})

            page.set_viewport_size({"width": 1280, "height": 900})
            open_menu(page)
            control["fail_bulk"] = True
            page.locator(".isbf-notifications__menu-items > button").click()
            page.wait_for_selector(".isbf-notifications__status[role='alert']")
            check(page.locator(".isbf-notification-bell__badge").first.inner_text() == "2", "failed bulk marking retains unread indicators")
            control["fail_bulk"] = False
            control["delay_bulk"] = 1.5
            bulk_started.clear()
            page.locator(".isbf-notifications__status[role='alert'] button").click()
            check(bulk_started.wait(3), "the delayed bulk request reaches the synthetic backend")
            records.append(notice(93005, "replied", 7))
            publish(page, {str(types["replied"]): 1}, [[record["id"], record["read"]] for record in records])
            page.wait_for_timeout(1800)
            check(page.locator(".isbf-notification-bell__badge").first.inner_text() == "1", "a notification arriving during bulk marking survives the response")
            page.locator(".isbf-notifications__menu summary").focus()
            page.keyboard.press("Escape")
            toggle_filter(page)
            page.wait_for_timeout(150)
            for record in records:
                record["read"] = True
            publish(page, {}, [[record["id"], True] for record in records])
            page.wait_for_function("!document.querySelector('.isbf-notifications__topic') && !document.querySelector('.isbf-notification-bell__badge')")
            check("当前没有未读通知" in page.locator(".isbf-notifications__status").inner_text(), "cross-tab reading clears both badge and unread list")

            control["delay_filter"] = "all"
            toggle_filter(page)
            page.wait_for_timeout(80)
            toggle_filter(page)
            page.wait_for_timeout(1500)
            check(page.locator(".isbf-notifications__topic").count() == 0 and switch.get_attribute("aria-checked") == "true", "a slow old response cannot replace a newer unread-filter result")
            check(not report["errors"], "the real client has no JavaScript runtime errors")
            check(not report["missing_assets"], "all script and style dependencies are local")
            report["passed"] = True
        except Exception as error:
            report["failure"] = str(error)
            report["debug"] = {"failure": page.evaluate("window.fixtureFailure"), "source_installed": page.evaluate("Boolean(window.isbfUnreadSourceInstalled)"), "body": page.locator("body").inner_text()[-2200:]}
            page.screenshot(path=str(OUTPUT / "failure.png"))
            raise
        finally:
            browser.close()
finally:
    server.shutdown()
    (OUTPUT / "browser-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")


