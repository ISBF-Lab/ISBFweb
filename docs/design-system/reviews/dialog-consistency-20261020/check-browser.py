"""Exercise current dialog sources in the cached full client with synthetic APIs."""

from pathlib import Path

base = Path("/workspace/docs/design-system/reviews/notifications-layout-20261018/check-browser.py")
exec(compile(base.read_text().split("\ncontrol = ", 1)[0], str(base), "exec"))

from urllib.parse import parse_qs

state = {"fail": False, "requests": [], "hold": False}
started = threading.Event()
release = threading.Event()
CachedHandler = Handler


class Handler(CachedHandler):
    def send_json(self, value, status=200):
        body = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if urlsplit(self.path).path.startswith("/stylesheets/common_theme_4_"):
            body = (ART / "compiled/theme.css").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/css")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def do_POST(self):
        target = urlsplit(self.path).path
        if target.startswith(("/isbf/api/entries", "/isbf/learning/courses", "/isbf/library/")):
            data = parse_qs(self.rfile.read(int(self.headers.get("Content-Length", "0"))).decode(), keep_blank_values=True)
            data = {key: value[0] for key, value in data.items()}
            state["requests"].append({"method": self.command, "path": target, "data": data})
            if state["hold"]:
                started.set()
                release.wait(20)
            if state["fail"]:
                return self.send_json({"errors": ["Synthetic save failure"]}, 503)
            if target.startswith("/isbf/learning/"):
                return self.send_json({"success": True, "pending": True, "reviewable_id": 321})
            if target.startswith("/isbf/library/"):
                kind = "category" if "/categories" in target else "group"
                return self.send_json({"success": True, "pending": False, kind: {"id": 123, "name": data.get("name")}})
            return self.send_json({"entry": {"id": 123}})
        super().do_POST()

    do_PATCH = do_POST


server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
playwright = sync_playwright().start()
browser = None
page = None
report.update(current_dialog_sources=True, checks=[], errors=[], screenshots=[])


def show(kind, model=None):
    page.evaluate("""({kind,model}) => {
      const sources=window.dialogReviewModules;
      let component;
      model=model||{};
      if(kind==='generic') component=sources.fixtures.Generic;
      else if(kind==='resource'||kind==='course') {
        component=sources.fixtures[kind==='resource'?'Resource':'Course'];
        model={grades:[{id:'2026',label:'2026年级'}],grade:'2026',request:true,...model,
          onSubmitted:(result,grade)=>{window.dialogResult={result,grade};reviewOwner.lookup('service:modal').close();}};
      } else if(kind==='calendar') {
        component=sources['discourse/components/isbf-calendar-entry-editor'].default;
        model={selectedDate:'2026-10-20',...model,onSaved:()=>{window.calendarReloads=(window.calendarReloads||0)+1;}};
      } else {
        component=moduleBroker.lookup('discourse/components/modal/'+kind).default;
        if(kind==='jump-to-post') model={postCount:100,jumpToIndex:(n)=>{window.jumpedTo=n;},jumpToDate:()=>{}};
        if(kind==='avatar-selector') model={user:reviewOwner.lookup('service:current-user')};
      }
      document.querySelector('#dialog-review-trigger')?.focus();
      reviewOwner.lookup('service:modal').show(component,{model});
    }""", {"kind": kind, "model": model})
    page.wait_for_selector(".d-modal__container", timeout=15000)


def close():
    page.keyboard.press("Escape")
    page.wait_for_selector(".d-modal__container", state="hidden")


def frame(selector=".d-modal__container"):
    return page.locator(selector).evaluate("""node=>{
      const s=getComputedStyle(node),r=node.getBoundingClientRect();
      return {left:r.left,top:r.top,right:r.right,bottom:r.bottom,width:r.width,height:r.height,
        radii:[s.borderTopLeftRadius,s.borderTopRightRadius,s.borderBottomLeftRadius,s.borderBottomRightRadius],
        border:s.borderTopWidth,background:s.backgroundColor,shadow:s.boxShadow};
    }""")


def consistent(label, width, height):
    geometry = frame()
    check(geometry["radii"] == ["16px"] * 4, f"{label}: four corners share the approved radius")
    check(geometry["border"] == "1px" and geometry["shadow"] == "none", f"{label}: shared outline and surface")
    check(geometry["left"] >= 15 and geometry["right"] <= width - 15 and geometry["top"] >= 15 and geometry["bottom"] <= height - 15, f"{label}: all edges stay inside the viewport gutter")
    buttons = page.locator(".d-modal__footer .btn:not(.no-text)")
    if buttons.count():
        check(buttons.evaluate_all("nodes=>nodes.every(n=>getComputedStyle(n).borderRadius==='999px'&&n.getBoundingClientRect().height>=44)"), f"{label}: text actions use pills and accessible target sizes")
    report["layouts"].append({"label": label, **geometry})


try:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True,
        args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=96 --single-threaded --single-threaded-gc --optimize-for-size", "--no-proxy-server", "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost"])
    print("Browser launched", flush=True)
    page = browser.new_page(viewport={"width": 1280, "height": 900}, locale="zh-CN", timezone_id="Asia/Shanghai", service_workers="block", reduced_motion="reduce")
    page.on("pageerror", lambda error: report["errors"].append(error.stack))
    page.set_default_timeout(15000)
    page.goto("http://127.0.0.1:8765/t/reading-fixture/314", wait_until="domcontentloaded", timeout=60000)
    print("Fixture document loaded", flush=True)
    page.wait_for_function("window.dialogReviewModules && window.moduleBroker", timeout=60000)
    print("Current dialog modules installed", flush=True)
    page.evaluate("window.reviewOwner=moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
    page.wait_for_selector(".modal-container", state="attached")
    page.evaluate("""()=>{
      reviewOwner.lookup('service:dialog').cancel();
      const trigger=document.createElement('button');trigger.id='dialog-review-trigger';trigger.textContent='Review trigger';document.body.append(trigger);
    }""")

    for width in [1280, 390]:
        page.set_viewport_size({"width": width, "height": 900})
        page.evaluate("mobile=>{document.documentElement.classList.toggle('mobile-view',mobile);document.documentElement.classList.toggle('desktop-view',!mobile);document.documentElement.classList.toggle('mobile-device',mobile);}", width == 390)
        for mode in ["light", "dark"]:
            page.evaluate("""({css,mode})=>{
              const sheet=new CSSStyleSheet();sheet.replaceSync(css);
              for(const rule of sheet.cssRules)if(rule.selectorText===':root')for(const key of rule.style)if(key.startsWith('--'))document.documentElement.style.setProperty(key,rule.style.getPropertyValue(key));
              document.documentElement.style.colorScheme=mode;
            }""", {"css": (ART / f"compiled/colors-{mode}.css").read_text(), "mode": mode})
            check(page.evaluate("getComputedStyle(document.documentElement).getPropertyValue('--secondary').trim()") == ("#101413" if mode == "dark" else "#ffffff"), f"{width} {mode}: actual palette is active")
            page.evaluate("""css=>{
              document.querySelectorAll('link[href*="common_theme_4_"],link[href="/fixture/theme.css"]').forEach(n=>n.disabled=true);
              const style=document.createElement('style');style.id='before-dialog-styles';style.textContent=css;document.head.append(style);
            }""", (ART / "compiled/before-theme.css").read_text())
            show("jump-to-post")
            before_name=f"before-{width}-{mode}-jump-to-post.png"
            page.locator(".d-modal__container").screenshot(path=str(ART / before_name))
            close()
            page.evaluate("""()=>{
              document.querySelector('#before-dialog-styles').remove();
              document.querySelectorAll('link[href*="common_theme_4_"],link[href="/fixture/theme.css"]').forEach(n=>n.disabled=false);
            }""")
            for kind in ["jump-to-post", "calendar", "resource"]:
                show(kind)
                consistent(f"{width} {mode} {kind}", width, 900)
                filename = f"{width}-{mode}-{kind}.png"
                page.locator(".d-modal__container").screenshot(path=str(ART / filename))
                report["screenshots"].append(filename)
                close()
            for variant in ["isbf-flag-modal", "isbf-resume-confirmation", "isbf-learning-share-dialog", "ai-summary-modal"]:
                show("generic", {"class": variant, "paragraphs": ["验证实际业务类名的共享外框与按钮。"]})
                consistent(f"{width} {mode} {variant}", width, 900)
                close()
            show("generic", {"paragraphs": ["长内容用于验证正文独立滚动与底部操作可访问。" * 3] * 40})
            consistent(f"{width} {mode} long content", width, 900)
            check(page.locator(".d-modal__body").evaluate("n=>n.scrollHeight>n.clientHeight"), f"{width} {mode}: long content scrolls inside the body")
            check(page.locator(".d-modal__footer").evaluate("n=>n.getBoundingClientRect().bottom<=innerHeight-15"), f"{width} {mode}: actions remain visible")
            close()
            page.evaluate("()=>{reviewOwner.lookup('service:dialog').confirm({title:'确认删除',message:'测试内容会保留，取消即可关闭。'});}")
            page.wait_for_selector(".dialog-content")
            check(frame(".dialog-content")["radii"] == ["16px"] * 4, f"{width} {mode}: confirmations share the frame")
            check(page.locator(".dialog-footer .btn-default").evaluate("n=>getComputedStyle(n).borderRadius") == "999px", f"{width} {mode}: confirmation cancel shares the pill")
            page.locator(".dialog-footer .btn-default").click()
            page.wait_for_selector(".dialog-content", state="hidden")
    show("jump-to-post")
    page.locator("#post-jump").fill("42")
    page.locator(".d-modal__footer .btn-primary").click()
    page.wait_for_selector(".d-modal__container", state="hidden")
    check(page.evaluate("window.jumpedTo") == 42, "the native jump action and modal dismissal still work")

    state["fail"] = True
    show("calendar")
    page.keyboard.press("Shift+Tab")
    page.keyboard.press("Shift+Tab")
    check(page.locator(".d-modal").evaluate("n=>n.contains(document.activeElement)"), "keyboard focus stays within the shared dialog")
    page.locator('[data-name="title"] input').fill("  Study session  ")
    page.locator('[data-name="note"] textarea').fill("Bring notes")
    page.locator('[data-name="allDay"] label').click()
    page.locator('[data-name="title"] input').press("Enter")
    page.wait_for_selector(".form-kit__alert")
    check(page.locator('[data-name="title"] input').input_value() == "  Study session  ", "calendar failure preserves edited fields")
    state["fail"] = False
    state["hold"] = True
    page.locator(".d-modal__footer .btn-primary").click()
    check(started.wait(5), "calendar retry reaches the synthetic server")
    check(page.locator(".d-modal__footer .btn-primary").is_disabled() and page.locator('[data-name="title"] input').is_disabled(), "calendar controls lock while saving")
    page.keyboard.press("Escape")
    check(page.locator(".d-modal__container").count() == 1, "Escape cannot discard an in-flight calendar save")
    release.set()
    page.wait_for_selector(".d-modal__container", state="hidden")
    state["hold"] = False
    payload = state["requests"][-1]["data"]
    check(payload["entry[title]"] == "Study session" and payload["entry[starts_at]"] == "2026-10-20T00:00:00.000Z" and payload["entry[ends_at]"] == "2026-10-21T00:00:00.000Z", "all-day dates retain the exclusive UTC end and trimmed title")
    check(page.evaluate("window.calendarReloads") == 1, "successful calendar retry refreshes the agenda once")
    for kind in ["resource", "course"]:
        show(kind)
        check(page.locator(".d-modal__footer .btn-primary").is_disabled(), f"{kind}: an empty course name cannot submit")
        page.locator('[data-name="name"] input').fill("  Economics  ")
        page.locator('[data-name="name"] input').press("Enter")
        page.wait_for_selector(".d-modal__container", state="hidden")
        check(page.evaluate("window.dialogResult.result.reviewable_id===321&&window.dialogResult.grade==='2026'"), f"{kind}: pending review and selected parent reach the caller")
    show("resource", {"library": True, "kind": "category", "request": False})
    page.locator('[data-name="name"] input').fill("Research")
    page.locator(".d-modal__footer .btn-primary").click()
    page.wait_for_selector(".d-modal__container", state="hidden")
    check(state["requests"][-1]["path"] == "/isbf/library/categories", "library category uses its original endpoint")
    check(page.evaluate("window.dialogResult.grade===123"), "created category ID reaches the caller")

    page.set_viewport_size({"width": 390, "height": 340})
    page.evaluate("document.documentElement.classList.add('keyboard-visible');document.documentElement.style.setProperty('--composer-vh','3.4px')")
    show("calendar")
    consistent("keyboard-size viewport", 390, 340)
    close()
    page.evaluate("document.documentElement.classList.remove('keyboard-visible');document.documentElement.style.removeProperty('--composer-vh')")
    page.set_viewport_size({"width": 1280, "height": 900})
    for css_class in ["fk-d-menu-modal", "chat-message-actions"]:
        show("generic", {"class": css_class, "paragraphs": ["Menu fixture"]})
        before = frame()
        page.evaluate("document.body.classList.add('admin-interface')")
        after = frame()
        check(before["radii"] == after["radii"] and before["border"] == after["border"], f"{css_class}: mobile menu chrome stays outside the foreground rules")
        page.evaluate("document.body.classList.remove('admin-interface')")
        close()
    page.evaluate("document.body.classList.add('admin-interface')")
    show("generic", {"paragraphs": ["Admin fixture"]})
    original_admin = frame()
    page.evaluate("document.querySelector('.d-modal').classList.add('fk-d-menu-modal')")
    excluded_admin = frame()
    check(original_admin["radii"] == excluded_admin["radii"] and original_admin["border"] == excluded_admin["border"], "admin appearance is independent of the foreground task rules")
    close()
    page.evaluate("document.body.classList.remove('admin-interface')")
    check(not report["errors"], "current dialogs complete without client exceptions")
    report["passed"] = True
except Exception as error:
    report["failure"] = str(error)
    print("Validation failure:", error, flush=True)
    raise
finally:
    release.set()
    report["api_requests"] = state["requests"]
    (ART / "browser-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    if page and not report["passed"]:
        try:
            (ART / "browser-failure.html").write_text(page.content())
            page.screenshot(path=str(ART / "browser-failure.png"), timeout=10000)
        except Exception as capture_error:
            print("Failure capture:", capture_error, flush=True)
    if browser:
        browser.close()
    playwright.stop()
    server.shutdown()
