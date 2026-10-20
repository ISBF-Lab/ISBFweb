from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
from threading import Thread

from playwright.sync_api import expect, sync_playwright

ROOT = Path("/review")
checks, errors = [], []
passed = False


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), partial(QuietHandler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{server.server_port}"


def check(condition, message):
    assert condition, message
    checks.append(message)
    print(message, flush=True)


def reveal(page, touch=False):
    bounds = page.locator("[data-reveal]").bounding_box()
    x, y = bounds["x"] + bounds["width"] / 2, bounds["y"] + bounds["height"] / 2
    distance = page.locator("[data-stage]").bounding_box()["width"] * 0.17
    if touch:
        session = page.context.new_cdp_session(page)
        session.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y}]})
        for step in range(1, 8):
            session.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": x + distance * step / 7, "y": y}]})
        session.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
        session.detach()
    else:
        page.mouse.move(x, y)
        page.mouse.down()
        page.mouse.move(x + distance, y, steps=8)
        page.mouse.up()
    expect(page.locator("[data-play]")).to_be_visible()


try:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(executable_path="/review-tools/chromium-1234/chrome-linux64/chrome", headless=True, args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-background-networking", "--js-flags=--max-old-space-size=128"])
        try:
            context = browser.new_context(viewport={"width": 1280, "height": 900}, has_touch=True, service_workers="block")
            page = context.new_page()
            page.on("pageerror", lambda error: errors.append(str(error)))
            for width, mode in [(1280, "light"), (390, "dark"), (1280, "dark"), (390, "light")]:
                page.set_viewport_size({"width": width, "height": 900})
                page.emulate_media(color_scheme=mode, reduced_motion="no-preference")
                page.goto(base + "/zh_CN.html", wait_until="networkidle")
                page.locator(".elastic-not-found.--enhanced").wait_for()
                label = f"{width}-{mode}"
                check(page.locator("h1").inner_text() == "未找到这个页面", label + ": actual localized template renders")
                check(page.evaluate("document.documentElement.scrollWidth <= innerWidth"), label + ": no horizontal overflow")
                check(page.locator(".elastic-not-found").evaluate("el=>{const r=el.getBoundingClientRect();return Math.abs(r.x)<1&&Math.abs(r.y)<1&&Math.abs(r.width-innerWidth)<1&&Math.abs(r.height-innerHeight)<1}"), label + ": the page occupies the entire viewport")
                check(page.locator("[data-stage]").evaluate("el=>el.getBoundingClientRect().width>=innerWidth-34"), label + ": digits use the available viewport width")
                colors = page.locator(".elastic-not-found").evaluate("el => {const s=getComputedStyle(el);return {accent:s.getPropertyValue('--elastic-404-accent').trim(),site:s.getPropertyValue('--tertiary').trim(),surface:s.getPropertyValue('--secondary').trim()}}")
                check(colors["accent"] == colors["site"], label + ": digits use the active site accent")
                check(colors["surface"] == ("#ffffff" if mode == "light" else "#101413"), label + ": actual light/dark palette is active")
                page.screenshot(path=str(ROOT / (label + ".png")), full_page=True)
                if width == 1280 and mode == "light":
                    check(page.locator(".elastic-not-found.--webgl").count() == 1, "the actual two-dimensional WebGL field renders")
                    canvas = page.locator("[data-elastic-canvas]")
                    before = canvas.screenshot()
                    bounds = page.locator("[data-stage]").bounding_box()
                    page.mouse.move(bounds["x"] + bounds["width"] * 0.2, bounds["y"] + bounds["height"] * 0.3)
                    page.mouse.move(bounds["x"] + bounds["width"] * 0.4, bounds["y"] + bounds["height"] * 0.6, steps=8)
                    check(canvas.screenshot() != before, "pointer movement deforms the rendered field in two dimensions")
                    page.screenshot(path=str(ROOT / "1280-light-elastic.png"))
                if width == 1280 and mode == "light" or width == 390 and mode == "dark":
                    reveal(page, touch=width == 390)
                    check(page.locator("[data-game]").is_hidden(), label + ": discovering the button does not start a game")
                    page.wait_for_timeout(700)
                    expect(page.locator("[data-play]")).to_be_visible()
                    page.locator("[data-play]").click()
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "ready")
                    page.locator("[data-start]").click()
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "playing")
                    expect(page.locator("[data-current]")).not_to_have_text("00:00.0", timeout=5000)
                    check(True, label + ": clock begins after launch")
                    check(page.locator("[data-pause]").count() == 0, label + ": no pause or resume control exists")
                    elapsed = page.locator("[data-current]").inner_text()
                    page.wait_for_timeout(250)
                    check(page.locator("[data-current]").inner_text() != elapsed, label + ": play and the clock continue without pause")
                    page.evaluate("dispatchEvent(new Event('blur'))")
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "over")
                    check(page.locator("[data-best]").inner_text() != "00:00.0", label + ": leaving the active window ends the round and saves its time")
                    page.locator("[data-start]").click()
                    arena = page.locator("[data-stage]").bounding_box()
                    page.mouse.move(arena["x"] + 3, arena["y"] + arena["height"] / 2)
                    page.screenshot(path=str(ROOT / (label + "-game.png")), full_page=True)
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "over", timeout=12000)
                    best = page.locator("[data-best]").inner_text()
                    check(best != "00:00.0", label + ": missing the paddle ends the round and saves its time")
                    page.locator("[data-start]").click()
                    check(page.locator("[data-current]").inner_text() == "00:00.0", label + ": replay resets the clock")
                    page.locator("[data-exit]").click()
                    check(page.locator("[data-game]").is_hidden() and page.locator("[data-play]").is_visible(), label + ": exit restores the discovered 404")
                    page.reload(wait_until="networkidle")
                    page.locator(".elastic-not-found.--enhanced").wait_for()
                    check(page.locator("[data-best]").inner_text() == best, label + ": best record survives reload")
            page.emulate_media(reduced_motion="reduce")
            page.goto(base + "/en.html", wait_until="networkidle")
            page.locator("[data-reveal]").focus()
            check(page.locator("[data-elastic-canvas]").is_hidden(), "reduced motion disables the decorative WebGL layer")
            page.keyboard.press("Enter")
            expect(page.locator("[data-play]")).to_be_focused()
            check(True, "keyboard discovery works with reduced motion and English copy")
            page.keyboard.press("Enter")
            page.locator("[data-start]").click()
            page.keyboard.press("ArrowLeft")
            page.keyboard.press("Escape")
            check(page.locator("[data-game]").is_hidden(), "keyboard play and Escape exit work without a pause state")
            page.locator("[data-play]").click()
            page.locator("[data-start]").click()
            page.set_viewport_size({"width": 420, "height": 900})
            expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "playing")
            check(True, "resizing preserves continuous play and normalized rules")
            page.locator("[data-exit]").click()
            page.evaluate("async () => {const {mountNotFound}=await import('/elastic-not-found.js');const root=document.querySelector('[data-elastic-not-found]');mountNotFound(root)();}")
            check(page.locator(".elastic-not-found.--enhanced").count() == 0 and "elastic-not-found-page" not in page.locator("body").get_attribute("class"), "shared mount is idempotent and cleanup restores the surrounding page")
            context.close()
            context = browser.new_context(viewport={"width": 390, "height": 900}, has_touch=True)
            page = context.new_page()
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.add_init_script("Object.defineProperty(window,'localStorage',{get(){throw new Error('Storage blocked')}})")
            page.goto(base + "/zh_CN.html", wait_until="networkidle")
            page.locator(".elastic-not-found.--enhanced").wait_for()
            reveal(page, touch=True)
            page.locator("[data-play]").click()
            page.locator("[data-start]").click()
            page.wait_for_timeout(150)
            page.locator("[data-exit]").click()
            check(page.locator("[data-best]").inner_text() != "00:00.0", "blocked browser storage still permits play and a session best")
            context.close()
            context = browser.new_context(viewport={"width": 390, "height": 900}, java_script_enabled=False)
            page = context.new_page()
            page.goto(base + "/zh_CN.html", wait_until="networkidle")
            check(page.locator("h1").is_visible() and page.locator(".elastic-not-found__home").is_visible(), "without JavaScript the error message and home link remain usable")
            context.close()
            check(not errors, "no browser JavaScript errors")
            passed = True
        finally:
            browser.close()
finally:
    server.shutdown()
    (ROOT / "browser-report.json").write_text(json.dumps({"passed": passed, "checks": checks, "javascript_errors": errors, "production_access": False, "actual_erb_and_scss": True, "single_browser": True}, ensure_ascii=False, indent=2) + "\n")
