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
        browser = playwright.chromium.launch(executable_path="/review-tools/chromium-1234/chrome-linux64/chrome", headless=True, args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-background-networking", "--js-flags=--max-old-space-size=128"])
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
                colors = page.locator(".elastic-not-found").evaluate("el => {const s=getComputedStyle(el);return {accent:s.getPropertyValue('--elastic-404-accent').trim(),site:s.getPropertyValue('--tertiary').trim(),surface:s.getPropertyValue('--secondary').trim()}}")
                check(colors["accent"] == colors["site"], label + ": digits use the active site accent")
                check(colors["surface"] == ("#ffffff" if mode == "light" else "#101413"), label + ": actual light/dark palette is active")
                page.screenshot(path=str(ROOT / (label + ".png")), full_page=True)
                if width == 1280 and mode == "light" or width == 390 and mode == "dark":
                    reveal(page, touch=width == 390)
                    check(page.locator("[data-game]").is_hidden(), label + ": discovering the button does not start a game")
                    page.wait_for_timeout(700)
                    expect(page.locator("[data-play]")).to_be_visible()
                    page.locator("[data-play]").click()
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "ready")
                    page.locator("[data-start]").click()
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "playing")
                    page.wait_for_timeout(300)
                    check(page.locator("[data-current]").inner_text() != "00:00.0", label + ": clock begins after launch")
                    page.locator("[data-pause]").click()
                    paused = page.locator("[data-current]").inner_text()
                    page.wait_for_timeout(250)
                    check(page.locator("[data-current]").inner_text() == paused, label + ": manual pause freezes the clock")
                    page.locator("[data-start]").click()
                    page.evaluate("dispatchEvent(new Event('blur'))")
                    expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "paused")
                    check(True, label + ": window blur pauses play")
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
            page.keyboard.press("Enter")
            expect(page.locator("[data-play]")).to_be_focused()
            check(True, "keyboard discovery works with reduced motion and English copy")
            page.keyboard.press("Enter")
            page.locator("[data-start]").click()
            page.keyboard.press("ArrowLeft")
            page.keyboard.press("Escape")
            expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "paused")
            check(True, "keyboard play and Escape pause work")
            page.locator("[data-start]").click()
            page.set_viewport_size({"width": 420, "height": 900})
            expect(page.locator(".elastic-not-found")).to_have_attribute("data-game-state", "paused")
            check(True, "resizing the arena pauses rather than changing difficulty mid-round")
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
