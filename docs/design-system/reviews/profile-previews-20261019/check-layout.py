"""Confirm both palettes are active before capturing the two profile regions."""

from pathlib import Path

source = Path("/review/check-browser.py").read_text().split("\nserver = ThreadingHTTPServer", 1)[0]
exec(compile(source, "/review/check-browser.py", "exec"))
if (ART / "native-build.json").exists():
    native = json.loads((ART / "native-build.json").read_text())
    fixture["html"] = re.sub(r'(<script[^>]*src=")([^"]+)("[^>]*data-discourse-entrypoint="discourse")', lambda match: match[1] + "/" + native["entrypoint"] + match[3], fixture["html"])
    fixture["html"] = re.sub(r'(<script[^>]*src=")(/theme-javascripts/[^"]+)("[^>]*data-theme-id="4")', lambda match: match[1] + "/fixture/native-theme.js" + match[3], fixture["html"])
    native_entry = re.search(r'<script[^>]*data-discourse-entrypoint="discourse"[^>]*></script>', fixture["html"])
    assert native_entry
    fixture["html"] = fixture["html"][:native_entry.start()] + fixture["html"][native_entry.end():]
    first_module = re.search(r'<script[^>]*data-theme-id="4"', fixture["html"])
    assert first_module
    fixture["html"] = fixture["html"][:first_module.start()] + native_entry[0] + fixture["html"][first_module.start():]
    modules = ""
    report["native_theme_responses"] = []
    ProfileHandler = Handler

    class Handler(ProfileHandler):
        def do_GET(self):
            if urlsplit(self.path).path == "/fixture/native-theme.js" or urlsplit(self.path).path.startswith("/theme-javascripts/"):
                report["native_theme_responses"].append(urlsplit(self.path).path)
                body = (ART / "compiled/theme-native.js").read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "application/javascript")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            elif urlsplit(self.path).path == "/filter.json":
                self.send_json({"users": [], "topic_list": {"topics": []}})
            else:
                super().do_GET()

    report.update(native_core_entrypoint=native["entrypoint"], native_theme_sha256=native["theme_sha256"], template_overrides=False)

actions[:] = actions[:2]
report.update(passed=False, checks=[], errors=[], layouts=[], actual_palettes_verified=True)
server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
playwright = sync_playwright().start()
browser = None
try:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True,
        args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=128 --optimize-for-size", "--no-proxy-server"])
    page = browser.new_page(viewport={"width": 1280, "height": 1000}, locale="zh-CN", service_workers="block")
    page.on("pageerror", lambda error: report["errors"].append(error.stack))
    page.goto(f"http://127.0.0.1:8765/u/{USERNAME}/summary", wait_until="domcontentloaded", timeout=60000)
    page.wait_for_selector(".replies-section .isbf-post-preview")
    page.locator(".replies-section").scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('.replies-section .isbf-post-preview__text')?.textContent.includes('第 7 楼')")
    page.evaluate("window.reviewOwner=moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
    def clear_fixture_dialog():
        dialog = page.locator("#dialog-holder .dialog-body")
        if dialog.count() and dialog.is_visible():
            report.setdefault("fixture_dialogs", []).append(dialog.inner_text())
            page.locator("#dialog-holder .dialog-footer button").first.click()
            dialog.wait_for(state="hidden")
    clear_fixture_dialog()
    for width in [1280, 390]:
        page.set_viewport_size({"width": width, "height": 1000})
        for mode in ["light", "dark"]:
            page.evaluate("""({css,mode})=>{
              const sheet=new CSSStyleSheet();sheet.replaceSync(css);
              for(const rule of sheet.cssRules)if(rule.selectorText===':root')for(const key of rule.style)if(key.startsWith('--'))document.documentElement.style.setProperty(key,rule.style.getPropertyValue(key));
              document.documentElement.style.colorScheme=mode;
            }""", {"css": (ART / f"compiled/colors-{mode}.css").read_text(), "mode": mode})
            root = page.evaluate("({primary:getComputedStyle(document.documentElement).getPropertyValue('--primary').trim(),secondary:getComputedStyle(document.documentElement).getPropertyValue('--secondary').trim()})")
            check(root["secondary"] == ("#101413" if mode == "dark" else "#ffffff"), f"{width}px {mode}: the approved palette is actually active")
            page.locator(".replies-and-topics-section").scroll_into_view_if_needed()
            check(not page.evaluate("document.documentElement.scrollWidth > innerWidth + 1"), f"{width}px {mode}: summary stays inside the viewport")
            check(page.locator(".isbf-post-preview.--summary .isbf-post-preview__text").first.evaluate("node=>getComputedStyle(node).webkitLineClamp") == "2", f"{width}px {mode}: summary retains the compact two-line rule")
            clear_fixture_dialog()
            page.locator(".replies-and-topics-section").screenshot(path=str(ART / f"summary-{width}-{mode}.png"))
            page.evaluate("reviewOwner.lookup('service:router').transitionTo('/u/" + USERNAME + "/activity')")
            page.wait_for_selector(".isbf-activity-preview", state="attached")
            report["activity_render_debug"] = page.locator(".isbf-activity-preview").first.evaluate("node=>{const ancestors=[];for(let el=node;el&&ancestors.length<8;el=el.parentElement){const style=getComputedStyle(el);ancestors.push({tag:el.tagName,class:el.className,display:style.display,visibility:style.visibility,width:el.getBoundingClientRect().width,height:el.getBoundingClientRect().height})}return ancestors}")
            print(json.dumps({"activity_render_debug": report["activity_render_debug"], "client_errors": report["errors"]}),flush=True)
            page.locator(".isbf-activity-preview").first.scroll_into_view_if_needed()
            page.wait_for_function("document.querySelector('.isbf-activity-preview')?.querySelectorAll('.isbf-post-preview__image').length===3")
            check(page.locator(".isbf-activity-preview").first.locator(".isbf-post-preview__image").evaluate_all("images=>images.every(image=>image.complete&&image.naturalWidth>0)"), f"{width}px {mode}: activity thumbnails finish loading")
            check(not page.evaluate("document.documentElement.scrollWidth > innerWidth + 1"), f"{width}px {mode}: activity stays inside the viewport")
            clear_fixture_dialog()
            page.locator(".isbf-activity-preview").first.screenshot(path=str(ART / f"activity-{width}-{mode}.png"))
            report["layouts"].append({"width": width, "mode": mode, "primary": root["primary"], "secondary": root["secondary"]})
            (ART / "layout-progress.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
            page.evaluate("reviewOwner.lookup('service:router').transitionTo('/u/" + USERNAME + "/summary')")
            page.wait_for_selector(".replies-section .isbf-post-preview")
    check(bool(report.get("native_theme_responses")) and modules == "", "the client loads the complete native theme without review module injection")
    check(not report["errors"], "both regions finish all palette and viewport checks without client exceptions")
    report["passed"] = True
finally:
    if not report["passed"]:
        (ART / "native-failure.html").write_text(page.content())
    (ART / "layout-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    if browser:
        browser.close()
    playwright.stop()
    server.shutdown()
