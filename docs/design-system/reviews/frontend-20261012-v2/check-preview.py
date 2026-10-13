"""Validate only the offline proposal; this does not test forum business behavior."""

import json
import os
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent
PAGES = json.loads((ROOT / "proposal-page-map.json").read_text())
REPORT = ROOT / "browser-report.json"
SHOTS = ROOT / "screenshots"
SHOTS.mkdir(exist_ok=True)
records = []
if os.environ.get("ISBF_REVIEW_RESUME") == "1" and REPORT.exists():
    records = json.loads(REPORT.read_text())["records"]
if os.environ.get("ISBF_REVIEW_REFRESH_MAIN") == "1":
    records = [item for item in records if item.get("width") not in [1440, 390] and item.get("page") != "review-selector" and not (item.get("page") == "modal" and item.get("width") == 600)]
completed = {(item.get("page"), item.get("mode"), item.get("width")) for item in records if item.get("passed")}


def save_report():
    memory = {}
    for name in ["memory.max", "memory.peak", "pids.max"]:
        path = Path("/sys/fs/cgroup") / name
        if path.exists():
            memory[name] = path.read_text().strip()
    path = Path("/sys/fs/cgroup/memory.events")
    if path.exists():
        memory["events"] = dict(line.split() for line in path.read_text().splitlines())
    REPORT.write_text(json.dumps({
        "scope": "offline-proposal-only; not production or business regression",
        "source": "current-theme compiled assets; Approved boundaries and D01–D07 remain documented",
        "resource_limits": memory,
        "records": records,
    }, ensure_ascii=False, indent=2) + "\n")


with sync_playwright() as playwright:
    options = {
        "headless": True,
        "args": ["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--disable-background-networking"],
    }
    if os.environ.get("ISBF_REVIEW_CHROMIUM"):
        options["executable_path"] = os.environ["ISBF_REVIEW_CHROMIUM"]
    browser = playwright.chromium.launch(**options)
    try:
        for mode in ["light", "dark"]:
            context = browser.new_context(viewport={"width": 1440, "height": 1100}, color_scheme=mode)
            page = context.new_page()
            errors = []
            failed = []
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.on("requestfailed", lambda request: failed.append({"url": request.url, "error": request.failure}))
            cases = [(item, width, True) for width in [1440, 390] for item in PAGES]
            if mode == "light":
                cases += [(item, width, False) for width in [600, 601, 1023, 1024, 1279, 1280] for item in PAGES if item["page"] in ["account", "directory", "summary", "modal"]]
            cases = [(item, width, screenshot) for item, width, screenshot in cases if (item["page"], mode, width) not in completed]
            for item, width, screenshot in cases:
                context.close()
                context = browser.new_context(viewport={"width": width, "height": 844 if width <= 600 else 1100}, color_scheme=mode)
                page = context.new_page()
                page.on("pageerror", lambda error: errors.append(str(error)))
                page.on("requestfailed", lambda request: failed.append({"url": request.url, "error": request.failure}))
                errors.clear()
                failed.clear()
                record = {"page": item["page"], "mode": mode, "width": width}
                try:
                    page.set_viewport_size({"width": width, "height": 844 if width <= 600 else 1100})
                    page.goto((ROOT / f'{item["page"]}-{mode}.html').as_uri(), wait_until="networkidle", timeout=15000)
                    page.evaluate("document.fonts.ready")
                    page.locator(".review-content").wait_for(state="visible")
                    metrics = page.evaluate("""() => {
                      const root = getComputedStyle(document.documentElement);
                      const main = document.querySelector('.review-content');
                      const box = main.getBoundingClientRect();
                      const input = document.querySelector('.review-input');
                      const inputStyle = input ? getComputedStyle(input) : null;
                      const dialog = document.querySelector('.review-dialog');
                      return {
                        body_width: document.body.scrollWidth,
                        document_width: document.documentElement.scrollWidth,
                        content_width: box.width,
                        content_left: box.left,
                        primary: root.getPropertyValue('--primary').trim(),
                        secondary: root.getPropertyValue('--secondary').trim(),
                        font: getComputedStyle(main).fontFamily,
                        input_height: input ? input.getBoundingClientRect().height : null,
                        input_radius: inputStyle ? inputStyle.borderRadius : null,
                        input_border: inputStyle ? inputStyle.borderTopWidth : null,
                        dialog_width: dialog ? dialog.getBoundingClientRect().width : null,
                        image_failures: Array.from(document.images).filter(img => !img.complete || img.naturalWidth === 0).length,
                        external_resources: performance.getEntriesByType('resource').filter(item => /^https?:/.test(item.name)).map(item => item.name)
                      };
                    }""")
                    record.update(metrics)
                    assert metrics["primary"] == ("#17202a" if mode == "light" else "#e7e9ea"), "Incorrect palette"
                    assert max(metrics["body_width"], metrics["document_width"]) <= width + 1, "Page has horizontal overflow"
                    assert not metrics["image_failures"], "Image failed to load"
                    assert not metrics["external_resources"], "Offline preview requested an external resource"
                    assert not errors and not failed, "Browser resource or script errors"
                    if metrics["input_radius"] is not None:
                        assert metrics["input_radius"] == "8px" and metrics["input_height"] >= 44 and metrics["input_border"] == "1px", "Control does not match D02"
                    if item["page"] == "modal":
                        assert metrics["dialog_width"] == (width if width <= 600 else min(600, width - 32)), "Dialog does not match D07"
                    if item["page"] == "account":
                        primary = page.locator('.review-button.--primary').first
                        primary.hover()
                        assert primary.evaluate('(element) => getComputedStyle(element).filter') == "brightness(0.92)", "Incorrect primary hover"
                        page.locator('#username').focus()
                        assert page.locator('#username').evaluate('(element) => getComputedStyle(element).outlineWidth') == "2px", "Incorrect focus outline"
                        page.locator('#username').blur()
                        page.mouse.move(0, 0)
                    if screenshot:
                        name = f'{"mobile" if width <= 600 else "desktop"}-{mode}-proposal-{item["page"]}.png'
                        page.screenshot(path=str(SHOTS / name), full_page=True)
                        record["screenshot"] = "screenshots/" + name
                    record["passed"] = True
                except Exception as error:
                    record["passed"] = False
                    record["error"] = str(error).splitlines()[0]
                    record["script_errors"] = list(errors)
                    record["resource_errors"] = list(failed)
                records.append(record)
                save_report()
                memory_events = Path("/sys/fs/cgroup/memory.events").read_text()
                events = dict(line.split() for line in memory_events.splitlines())
                if int(events.get("oom_kill", "0")):
                    raise RuntimeError("Tool container OOM; stopped at the fixed memory budget.")
                print(json.dumps({"page": item["page"], "mode": mode, "width": width, "passed": record["passed"], "error": record.get("error")}, ensure_ascii=False), flush=True)
            if ("review-selector", mode, None) not in completed:
                page.goto((ROOT / "index.html").as_uri(), wait_until="networkidle")
                page.locator("#page").select_option("directory")
                page.locator("#mode").select_option(mode)
                page.locator("#viewport").select_option("390")
                frame = page.frame_locator("#preview")
                frame.locator(".review-heading").wait_for(state="visible")
                records.append({"page": "review-selector", "mode": mode, "passed": frame.locator(".review-heading").inner_text() == "用户目录"})
            context.close()
    finally:
        browser.close()
        save_report()
print(json.dumps({"passed": sum(bool(item.get("passed")) for item in records), "checked": len(records)}), flush=True)
raise SystemExit(0 if all(item.get("passed") for item in records) else 1)
