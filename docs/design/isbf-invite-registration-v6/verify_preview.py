"""Check the offline nebula and confetti registration preview with a local or remote browser."""

import argparse
import json
import hashlib
from datetime import datetime, timedelta, timezone
from pathlib import Path

from playwright.sync_api import expect, sync_playwright


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", choices=["chromium", "webkit", "firefox"], default="chromium")
    parser.add_argument("--endpoint", help="Existing Playwright browser WebSocket endpoint")
    parser.add_argument("--url", help="HTML URL as seen by the browser")
    parser.add_argument("--report", type=Path, help="Output JSON report")
    parser.add_argument("--screenshots", action="store_true", help="Save review screenshots")
    parser.add_argument("--filter", help="Run scenarios whose names contain this text")
    parser.add_argument("--group", choices=["all", "registration", "fullscreen", "interactions", "effects"], default="all", help="Run all checks or a shorter group")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    url = args.url or (root / "preview.html").as_uri()
    report_path = args.report or root / f"verification-{args.engine}.json"
    images = root / "screenshots"
    images.mkdir(exist_ok=True)
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "engine": args.engine,
        "group": args.group,
        "html_sha256": hashlib.sha256((root / "preview.html").read_bytes()).hexdigest(),
        "browser_version": None,
        "layouts": [],
        "scenarios": [],
        "console_errors": [],
        "external_requests": [],
        "forum_navigation_requests": [],
        "screenshots": [],
    }

    with sync_playwright() as playwright:
        browser_type = getattr(playwright, args.engine)
        browser = browser_type.connect(args.endpoint) if args.endpoint else browser_type.launch(headless=True)
        report["browser_version"] = browser.version

        def page_for(width=1440, height=900, theme="light", motion="reduce", initial="register", touch=False, controlled=False):
            context = browser.new_context(
                viewport={"width": width, "height": height},
                color_scheme=theme,
                reduced_motion=motion,
                has_touch=touch,
                device_scale_factor=3 if touch else 1,
            )
            page = context.new_page()
            if controlled:
                page.clock.install(time=datetime(2026, 10, 9, tzinfo=timezone.utc))
            page.set_default_timeout(8000)
            page.on("pageerror", lambda error: report["console_errors"].append(str(error)))
            page.on("console", lambda message: report["console_errors"].append(message.text) if message.type == "error" else None)
            page.on("request", lambda request: (report["forum_navigation_requests"] if request.url == "https://isbf-one.com/" else report["external_requests"]).append(request.url) if request.url.startswith(("http:", "https:")) else None)
            context.route("https://isbf-one.com/", lambda route: route.fulfill(status=200, content_type="text/html", body="<title>Intercepted forum homepage</title>"))
            page.goto(url, wait_until="networkidle")
            page.evaluate("document.fonts.ready")
            expect(page.locator("#particle-canvas")).to_have_attribute("data-ready", "true")
            if initial == "register":
                page.locator("#open-registration").click()
                expect(page.locator("body")).to_have_attribute("data-view", "register")
            elif initial == "login":
                page.locator('[data-nav="login"]').click()
                expect(page.locator("body")).to_have_attribute("data-view", "login")
            return context, page

        def stage(page, name):
            expect(page.locator(f'[data-step="{name}"]')).to_be_visible()
            expect(page.locator("body")).to_have_attribute("data-registration-step", name)

        def waiting_notice(page):
            notice = page.locator("#success-notice")
            expect(notice).to_be_visible()
            expect(page.locator("#success-notice-text")).to_have_text("5 秒后进入论坛首页")
            metrics = notice.evaluate("""element => {
                const box=element.getBoundingClientRect();
                const canvas=document.querySelector('.particle-stage').getBoundingClientRect();
                const style=getComputedStyle(element);
                return {left:box.left,right:box.right,width:box.width,height:box.height,
                    center:box.left+box.width/2,expected:canvas.left+canvas.width/2,
                    font:style.fontSize,line:style.lineHeight,background:style.backgroundColor};
            }""")
            assert abs(metrics['center']-metrics['expected']) < 1, metrics
            assert 0 <= metrics['left'] < metrics['right'] <= page.viewport_size['width'], metrics
            assert metrics['font'] == '14px' and metrics['line'] == '20px', metrics
            assert metrics['height'] == 20 and metrics['background'] == 'rgba(0, 0, 0, 0)', metrics
            expect(page.locator('#done-title')).to_have_attribute('aria-describedby','success-notice-text')
            assert page.locator('#fallback-rain').count() == 0

        def advance_to_home(page):
            deadline = int(page.locator('#success-view').get_attribute('data-redirect-at'))
            remaining = deadline - page.evaluate('Date.now()')
            assert remaining > 0, remaining
            page.clock.run_for(remaining)
            page.wait_for_url('https://isbf-one.com/', timeout=8000)

        def send(page, form, field, value):
            page.locator(field).fill(value)
            page.locator(f"{form} button[type=submit]").click()

        def invite(page):
            send(page, "#invite-form", "#invite-code", "ISBF2026")
            stage(page, "email")

        def email(page, value="student@example.com"):
            send(page, "#email-form", "#signup-email", value)
            stage(page, "verify")

        def code(page):
            send(page, "#verify-form", "#email-code", "123456")
            stage(page, "profile")

        scenario_index = 0

        def scenario(name, callback, **options):
            nonlocal scenario_index
            scenario_index += 1
            if args.group == "registration" and scenario_index > 15:
                return
            if args.group == "fullscreen" and scenario_index <= 15:
                return
            if args.group == "interactions" and not 16 <= scenario_index <= 30:
                return
            if args.group == "effects" and scenario_index <= 30:
                return
            if args.filter and args.filter.casefold() not in name.casefold():
                return
            context, page = page_for(**options)
            try:
                callback(page)
                report["scenarios"].append({"name": name, "status": "passed"})
                print(f"PASS {args.engine}: {name}", flush=True)
            except Exception:
                page.screenshot(path=str(images / f"failure-{args.engine}.png"), full_page=True)
                raise
            finally:
                context.close()
                report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")

        def snapshot(page, name):
            if args.screenshots:
                page.screenshot(path=str(images / name), full_page=True)
                report["screenshots"].append(name)

        for width, height in [(320, 720), (390, 844), (768, 1024), (1440, 900)]:
            if args.group in ["fullscreen", "interactions", "effects"] or args.filter:
                continue
            for theme in ["light", "dark"]:
                context, page = page_for(width, height, theme, initial="welcome")
                expect(page.locator("#access-panel")).to_be_hidden()
                assert page.locator("main input:visible").count() == 0
                if width in [390, 1440]:
                    snapshot(page, f"welcome-{width}-{theme}.png")
                page.locator("#open-registration").click()
                expect(page.locator("#access-panel")).to_be_visible()
                metrics = page.evaluate("""() => {
                    const control = document.querySelector('#invite-code').getBoundingClientRect();
                    const button = document.querySelector('#invite-form button').getBoundingClientRect();
                    return {viewport: innerWidth, document: document.documentElement.scrollWidth,
                        inputLeft: control.left, inputRight: control.right,
                        buttonHeight: button.height,
                        theme: document.documentElement.dataset.theme,
                        particles: Number(document.querySelector("#particle-canvas").dataset.particleCount),
                        canvasWidth: document.querySelector("#particle-canvas").getBoundingClientRect().width,
                        canvasHeight: document.querySelector("#particle-canvas").getBoundingClientRect().height,
                        canvasLeft: document.querySelector("#particle-canvas").getBoundingClientRect().left,
                        canvasTop: document.querySelector("#particle-canvas").getBoundingClientRect().top,
                        panel: document.querySelector("#access-panel").getBoundingClientRect().toJSON()};
                }""")
                assert metrics["document"] <= width, metrics
                assert 0 <= metrics["inputLeft"] < metrics["inputRight"] <= width, metrics
                assert metrics["buttonHeight"] >= 44, metrics
                assert metrics["theme"] == theme, metrics
                assert abs(metrics["canvasWidth"] - width) < 1, metrics
                assert abs(metrics["canvasHeight"] - height) < 1, metrics
                assert abs(metrics["canvasLeft"]) < 1 and abs(metrics["canvasTop"]) < 1, metrics
                assert abs(metrics["panel"]["x"] + metrics["panel"]["width"] / 2 - width / 2) < 1, metrics
                assert metrics["particles"] == (6800 if metrics["canvasWidth"] > 820 else 3000), metrics
                assert page.locator('[data-progress][aria-current="step"]').count() == 1
                report["layouts"].append({"width": width, "height": height, "theme": theme, "status": "passed"})
                if width in [390, 1440]:
                    snapshot(page, f"registration-{width}-{theme}.png")
                page.locator('[data-nav="login"]').click()
                expect(page.locator("#login-view")).to_be_visible()
                assert page.locator("#login-view input[name=invite]").count() == 0
                assert page.locator("#login-view input#invite-code").count() == 0
                assert page.evaluate("document.documentElement.scrollWidth") <= width
                if width in [390, 1440] and theme == "light":
                    snapshot(page, f"login-{width}-{theme}.png")
                page.locator(".login__invite-link").click()
                stage(page, "invite")
                context.close()

        def login_entry(page):
            page.locator('[data-nav="login"]').click()
            expect(page.locator("#login-view")).to_be_visible()
            expect(page.locator(".login__invite-link")).to_have_text("通过邀请码注册")
            assert page.locator("#login-view input").count() == 3
            page.locator(".login__invite-link").click()
            stage(page, "invite")
        scenario("Login has a registration link and no invite textbox", login_entry)

        def empty_invite(page):
            page.locator("#invite-form button").click()
            expect(page.locator("#invite-error")).to_have_text("请输入邀请码。")
            expect(page.locator("#invite-code")).to_be_focused()
            expect(page.locator("#invite-code")).to_have_attribute("aria-invalid", "true")
        scenario("Empty invitation has a focused accessible error", empty_invite)

        for value, expected in [
            ("INVALID", "暂时无法识别这个邀请码，请检查后再试。"),
            ("EXPIRED2026", "这个邀请码已过期，请联系社区管理员获取新的邀请。"),
            ("USED2026", "这个邀请码已使用。如果你已有账号，请返回登录。"),
        ]:
            def invitation_error(page, value=value, expected=expected):
                send(page, "#invite-form", "#invite-code", value)
                expect(page.locator("#invite-error")).to_have_text(expected)
                stage(page, "invite")
            scenario(f"Invitation error: {value}", invitation_error)

        def case_insensitive(page):
            send(page, "#invite-form", "#invite-code", "isbf2026")
            stage(page, "email")
            expect(page.locator('[data-progress="1"]')).to_have_class("signup-progress__step is-complete")
        scenario("Valid invitation ignores letter case", case_insensitive)

        def email_errors(page):
            invite(page)
            page.locator("#email-form button").click()
            expect(page.locator("#email-error")).to_have_text("请输入电子邮件地址。")
            send(page, "#email-form", "#signup-email", "invalid-address")
            expect(page.locator("#email-error")).to_have_text("请输入有效的电子邮件地址。")
            send(page, "#email-form", "#signup-email", "member@example.com")
            expect(page.locator("#email-error")).to_have_text("这个邮箱已有账号，请返回登录。")
            stage(page, "email")
        scenario("Email format and existing account errors", email_errors)

        def retry_email(page):
            invite(page)
            send(page, "#email-form", "#signup-email", "retry@example.com")
            expect(page.locator("#email-error")).to_have_text("暂时无法发送验证码，请稍后重试。")
            page.locator("#email-form button").click()
            stage(page, "verify")
        scenario("Email send failure can be retried", retry_email)

        def drafts(page):
            invite(page)
            page.locator("#signup-email").fill("draft@example.com")
            page.locator("#back-button").click()
            stage(page, "invite")
            expect(page.locator("#invite-code")).to_have_value("ISBF2026")
            page.locator('[data-nav="login"]').click()
            page.locator(".login__invite-link").click()
            stage(page, "invite")
            page.locator("#invite-form button").click()
            stage(page, "email")
            expect(page.locator("#signup-email")).to_have_value("draft@example.com")
        scenario("Back and view changes preserve drafts", drafts)

        def otp_errors(page):
            invite(page)
            email(page)
            page.locator("#verify-form button").click()
            expect(page.locator("#code-error")).to_have_text("请输入六位数字验证码。")
            send(page, "#verify-form", "#email-code", "333333")
            expect(page.locator("#code-error")).to_have_text("验证码不正确，请检查后再试。")
            expect(page.locator("#otp-control")).to_have_class("otp has-errors")
            snapshot(page, "code-error-1440-light.png")
            send(page, "#verify-form", "#email-code", "000000")
            expect(page.locator("#code-error")).to_have_text("验证码已过期，请重新发送。")
            code(page)
        scenario("OTP empty, wrong and expired states recover", otp_errors)

        def otp_input(page):
            invite(page)
            email(page)
            page.locator("#email-code").press_sequentially("12ab34cd5678")
            expect(page.locator("#email-code")).to_have_value("123456")
            assert page.locator(".otp__digit").all_text_contents() == list("123456")
            expect(page.locator("#email-code")).to_have_attribute("autocomplete", "one-time-code")
            page.locator("#email-code").fill("")
            page.locator("#email-code").evaluate("""input => {
                const data = new DataTransfer();
                data.setData('text/plain', '123 456');
                input.dispatchEvent(new ClipboardEvent('paste', {clipboardData: data, bubbles: true, cancelable: true}));
            }""")
            expect(page.locator("#email-code")).to_have_value("123456")
        scenario("OTP filters pasted input and supports autofill", otp_input)

        def change_email(page):
            invite(page)
            email(page)
            page.locator("#email-code").fill("333333")
            page.locator("#change-email-button").click()
            stage(page, "email")
            expect(page.locator("#email-code")).to_have_value("")
            email(page, "changed@example.com")
            expect(page.locator("#verification-email")).to_have_text("changed@example.com")
        scenario("Changing email clears old OTP", change_email)

        def resend(page):
            page.clock.install()
            invite(page)
            email(page)
            expect(page.locator("#resend-button")).to_be_disabled()
            page.clock.fast_forward(31000)
            expect(page.locator("#resend-button")).to_be_enabled()
            page.locator("#resend-button").click()
            expect(page.locator("#resend-notice")).to_have_text("验证码已重新发送，请查收邮箱。")
            expect(page.locator("#resend-button")).to_be_disabled()
        scenario("Resend is available after its countdown", resend)

        def usernames(page):
            invite(page)
            email(page)
            code(page)
            page.locator("#profile-form button").click()
            expect(page.locator("#username-error")).to_have_text("请选择一个用户名。")
            send(page, "#profile-form", "#signup-username", "a")
            expect(page.locator("#username-error")).to_have_text("用户名需要包含 2–20 个字符。")
            send(page, "#profile-form", "#signup-username", "admin")
            expect(page.locator("#username-error")).to_have_text("这个用户名已被占用，换一个试试。")
            send(page, "#profile-form", "#signup-username", "campus_member")
            stage(page, "done")
            expect(page.locator("#particle-canvas")).to_have_attribute("data-mask", "check")
        scenario("Username validation leads to completion", usernames)

        def complete(page):
            invite(page)
            snapshot(page, "email-1440-light.png")
            email(page)
            snapshot(page, "verification-1440-light.png")
            code(page)
            snapshot(page, "profile-1440-light.png")
            fixed = datetime(2026, 10, 9, tzinfo=timezone.utc)
            page.clock.install(time=fixed)
            page.clock.pause_at(fixed + timedelta(seconds=1))
            send(page, "#profile-form", "#signup-username", "isbf_member")
            page.clock.run_for(750)
            stage(page, "done")
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            expect(page.locator("#access-panel")).to_be_hidden()
            assert page.locator("main input:visible").count() == 0
            waiting_notice(page)
            snapshot(page, "complete-1440-light.png")
            deadline = int(page.locator("#success-view").get_attribute("data-redirect-at"))
            remaining = deadline - page.evaluate("Date.now()")
            assert 4800 <= remaining <= 5000, remaining
            expect(page.locator('#redirect-progress')).to_have_attribute('data-remaining','static')
            page.clock.run_for(remaining - 1)
            assert page.url.startswith(url), page.url
            before = len(report["forum_navigation_requests"])
            page.clock.run_for(1)
            page.wait_for_url("https://isbf-one.com/")
            assert len(report["forum_navigation_requests"]) == before + 1
        scenario("Completion shows the centered waiting hint and redirects once after exactly five seconds", complete)

        def cancellation(page):
            page.clock.install()
            send(page, "#invite-form", "#invite-code", "ISBF2026")
            expect(page.locator("#invite-code")).to_have_attribute("readonly", "")
            page.locator('[data-nav="login"]').click()
            page.clock.fast_forward(2000)
            page.locator(".login__invite-link").click()
            stage(page, "invite")
            expect(page.locator("#invite-form button")).to_be_enabled()
            assert page.locator("#invite-code").get_attribute("readonly") is None
        scenario("Navigation cancels pending invitation validation", cancellation)

        def keyboard_theme(page):
            page.locator("#invite-code").focus()
            page.keyboard.press("Tab")
            expect(page.locator("#invite-form button")).to_be_focused()
            assert page.locator("#invite-form button").evaluate("element => getComputedStyle(element).outlineStyle") != "none"
            page.locator('[data-theme-mode="dark"]').click()
            expect(page.locator("html")).to_have_attribute("data-theme", "dark")
            page.reload(wait_until="networkidle")
            expect(page.locator("html")).to_have_attribute("data-theme", "dark")
            page.locator('[data-theme-mode="auto"]').click()
            page.emulate_media(color_scheme="light")
            expect(page.locator("html")).to_have_attribute("data-theme", "light")
            page.emulate_media(color_scheme="dark")
            expect(page.locator("html")).to_have_attribute("data-theme", "dark")
        scenario("Keyboard focus and persistent automatic themes", keyboard_theme)

        def frame_count(page):
            return int(page.locator("#particle-canvas").get_attribute("data-frame-count"))

        def pixel_hash(page):
            bitmap = page.locator("#particle-canvas").evaluate("canvas => canvas.toDataURL()")
            return hashlib.sha256(bitmap.encode()).hexdigest()

        def reduced_motion(page):
            canvas = page.locator("#particle-canvas")
            expect(canvas).to_have_attribute("data-animated", "false")
            expect(page.locator("#particle-motion-button")).to_have_attribute("aria-pressed", "false")
            before = pixel_hash(page)
            initial_frame = frame_count(page)
            page.wait_for_timeout(250)
            assert frame_count(page) == initial_frame
            assert pixel_hash(page) == before
            invite(page)
            expect(canvas).to_have_attribute("data-mask", "nebula")
            assert pixel_hash(page) != before
            before = pixel_hash(page)
            paused_frame = frame_count(page)
            page.locator('[data-theme-mode="dark"]').click()
            page.wait_for_function("frames => Number(document.querySelector('#particle-canvas').dataset.frameCount) > frames", arg=paused_frame)
            expect(canvas).to_have_attribute("data-animated", "false")
            assert pixel_hash(page) != before
        scenario("Reduced motion preserves static shapes and theme feedback", reduced_motion)

        def animation_control(page):
            canvas = page.locator("#particle-canvas")
            control = page.locator("#particle-motion-button")
            expect(canvas).to_have_attribute("data-animated", "true")
            initial_frame = frame_count(page)
            page.wait_for_function("frames => Number(document.querySelector('#particle-canvas').dataset.frameCount) > frames + 2", arg=initial_frame)
            control.click()
            expect(canvas).to_have_attribute("data-animated", "false")
            expect(control).to_have_attribute("aria-pressed", "false")
            paused_frame = frame_count(page)
            bitmap = pixel_hash(page)
            page.wait_for_timeout(300)
            assert frame_count(page) == paused_frame
            assert pixel_hash(page) == bitmap
            control.click()
            expect(canvas).to_have_attribute("data-animated", "true")
            page.wait_for_function("frames => Number(document.querySelector('#particle-canvas').dataset.frameCount) > frames + 2", arg=paused_frame)
        scenario("Particles animate, freeze on pause and resume", animation_control, motion="no-preference")

        def morphology(page):
            canvas = page.locator("#particle-canvas")
            expect(canvas).to_have_attribute("data-mask", "one")
            expect(canvas).to_have_attribute("data-mask", "morph", timeout=30000)
            snapshot(page, "particles-morph-1440-light.png")
            expect(canvas).to_have_attribute("data-mask", "logo", timeout=25000)
            snapshot(page, "particles-logo-1440-light.png")
        scenario("Character particles morph from One to the site logo", morphology, motion="no-preference", initial="welcome")

        def viewport_changes(page):
            canvas = page.locator("#particle-canvas")
            page.locator("#invite-code").focus()
            for width, height in [(390, 400), (844, 390), (390, 844)]:
                page.set_viewport_size({"width": width, "height": height})
                page.wait_for_function("dimensions => { const bounds = document.querySelector('#particle-canvas').getBoundingClientRect(); return Math.abs(bounds.width-dimensions[0]) < 1 && Math.abs(bounds.height-dimensions[1]) < 1; }", arg=[width,height])
                assert page.evaluate("document.documentElement.scrollWidth") <= width
                page.locator("#invite-code").scroll_into_view_if_needed()
                bounds = page.locator("#invite-code").bounding_box()
                assert 0 <= bounds["y"] and bounds["y"] + bounds["height"] <= height, bounds
                expect(canvas).to_have_attribute("data-particle-count", "3000")
                assert canvas.evaluate("element => element.width / element.getBoundingClientRect().width") <= 1.51
            page.locator("#close-access-button").click()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            initial_frame = frame_count(page)
            page.wait_for_function("frames => Number(document.querySelector('#particle-canvas').dataset.frameCount) > frames + 2", arg=initial_frame)
        scenario("Fullscreen canvas follows touch orientation and keyboard-sized viewports", viewport_changes, width=390, height=844, touch=True, motion="no-preference")

        def canvas_fallback(page):
            page.add_init_script("""(() => {
                const original = HTMLCanvasElement.prototype.getContext;
                HTMLCanvasElement.prototype.getContext = function(...args) {
                    return this.id === 'particle-canvas' ? null : original.apply(this, args);
                };
            })();""")
            page.reload(wait_until="networkidle")
            expect(page.locator("#particle-fallback")).to_be_visible()
            expect(page.locator("#particle-canvas")).to_be_hidden()
            expect(page.locator("#particle-motion-button")).to_be_hidden()
            invite(page)
            stage(page, "email")
        scenario("Canvas fallback preserves registration without animation", canvas_fallback)

        def system_motion(page):
            canvas = page.locator("#particle-canvas")
            control = page.locator("#particle-motion-button")
            page.emulate_media(reduced_motion="reduce")
            expect(canvas).to_have_attribute("data-animated", "false")
            expect(control).to_have_attribute("aria-pressed", "false")
            control.click()
            expect(canvas).to_have_attribute("data-animated", "true")
            page.emulate_media(reduced_motion="no-preference")
            expect(canvas).to_have_attribute("data-animated", "true")
            control.click()
            expect(canvas).to_have_attribute("data-animated", "false")
            page.emulate_media(reduced_motion="reduce")
            page.emulate_media(reduced_motion="no-preference")
            expect(canvas).to_have_attribute("data-animated", "false")
            expect(control).to_have_attribute("aria-pressed", "false")
        scenario("System motion preference and manual choice work together", system_motion, motion="no-preference")

        def login_alternatives(page):
            page.locator('[data-nav="login"]').click()
            page.locator("#login-email").fill("student@example.com")
            page.locator("#show-code-login-button").click()
            expect(page.locator("#login-code-form")).to_be_visible()
            expect(page.locator("#login-code-email")).to_have_value("student@example.com")
            page.locator("#login-code-form button[type=submit]").click()
            expect(page.locator("#login-dialog")).to_be_visible()
            page.locator("#close-login-dialog-button").click()
            page.locator("#show-password-login-button").click()
            expect(page.locator("#login-form")).to_be_visible()
        scenario("Login alternatives remain interactive", login_alternatives)

        def welcome_and_drafts(page):
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            expect(page.locator("#access-panel")).to_be_hidden()
            expect(page.locator("#demo-guide")).to_be_hidden()
            assert page.locator("main input:visible").count() == 0
            page.locator("#open-registration").click()
            stage(page, "invite")
            expect(page.locator("#invite-title")).to_be_focused()
            page.locator("#invite-code").fill("draft_invite")
            page.locator("#close-access-button").click()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            expect(page.locator("#open-registration")).to_be_focused()
            page.locator("#open-registration").click()
            expect(page.locator("#invite-code")).to_have_value("draft_invite")
            page.keyboard.press("Escape")
            expect(page.locator("#access-panel")).to_be_hidden()
            expect(page.locator("#open-registration")).to_be_focused()
        scenario("Welcome hides inputs and opening or closing preserves drafts and focus", welcome_and_drafts, initial="welcome")

        def close_pending(page):
            page.clock.install()
            send(page, "#invite-form", "#invite-code", "ISBF2026")
            expect(page.locator("#invite-code")).to_have_attribute("readonly", "")
            page.locator("#close-access-button").click()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            page.clock.fast_forward(2000)
            page.locator("#open-registration").click()
            stage(page, "invite")
            expect(page.locator("#invite-code")).to_have_value("ISBF2026")
            expect(page.locator("#invite-form button")).to_be_enabled()
            assert page.locator("#invite-code").get_attribute("readonly") is None
        scenario("Closing cancels pending validation without losing input", close_pending)

        def closed_countdown(page):
            page.clock.install()
            invite(page)
            email(page)
            page.locator("#email-code").fill("12")
            page.locator("#close-access-button").click()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            page.clock.fast_forward(31000)
            page.locator("#open-registration").click()
            stage(page, "verify")
            expect(page.locator("#email-code")).to_have_value("12")
            expect(page.locator("#resend-button")).to_be_enabled()
        scenario("Closed verification restores its OTP and elapsed resend countdown", closed_countdown)

        def hash_history(page):
            page.locator("#open-registration").click()
            page.locator("#invite-code").fill("history_draft")
            page.locator('[data-nav="login"]').click()
            expect(page.locator("body")).to_have_attribute("data-view", "login")
            page.go_back()
            expect(page.locator("body")).to_have_attribute("data-view", "register")
            expect(page.locator("#invite-code")).to_have_value("history_draft")
            page.go_back()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            page.go_forward()
            expect(page.locator("body")).to_have_attribute("data-view", "register")
            expect(page.locator("#invite-code")).to_have_value("history_draft")
        scenario("Browser history follows welcome, registration and login", hash_history, initial="welcome")

        def deep_links(page):
            for fragment, view in [("register","register"),("login","login"),("welcome","welcome"),("unknown","welcome")]:
                page.goto(f"{url}#{fragment}", wait_until="networkidle")
                expect(page.locator("body")).to_have_attribute("data-view", view)
                if view == "welcome":
                    expect(page.locator("#access-panel")).to_be_hidden()
                else:
                    expect(page.locator("#access-panel")).to_be_visible()
            page.goto(f"{url}#login", wait_until="networkidle")
            assert page.locator("#login-view input[name=invite_code]").count() == 0
            page.locator(".login__invite-link").click()
            stage(page, "invite")
        scenario("Direct hashes open the matching centered view", deep_links)

        def escape_priority(page):
            page.locator("#demo-guide summary").click()
            expect(page.locator("#demo-guide")).to_have_attribute("open", "")
            page.keyboard.press("Escape")
            assert page.locator("#demo-guide").get_attribute("open") is None
            expect(page.locator("#access-panel")).to_be_visible()
            page.locator('[data-nav="login"]').click()
            page.locator("#login-form button[type=submit]").click()
            expect(page.locator("#login-dialog")).to_be_visible()
            page.keyboard.press("Escape")
            expect(page.locator("#login-dialog")).to_be_hidden()
            expect(page.locator("body")).to_have_attribute("data-view", "login")
            page.keyboard.press("Escape")
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
        scenario("Escape closes the top explanation before the form", escape_priority)

        def nebula_opening(page):
            canvas = page.locator("#particle-canvas")
            initial = pixel_hash(page)
            page.locator("#open-registration").click()
            expect(canvas).to_have_attribute("data-phase", "scatter")
            snapshot(page, "scatter-1440-dark.png")
            expect(canvas).to_have_attribute("data-phase", "nebula")
            assert pixel_hash(page) != initial
            assert int(canvas.get_attribute("data-visible-nebula")) > 1000
            assert int(canvas.get_attribute("data-inside-clear-zone")) == 0
            assert page.locator("main input").evaluate_all("elements => elements.every(element => getComputedStyle(element).textAlign === 'center')")
            pixels = canvas.evaluate("""canvas => {
                const box = document.querySelector('#invite-code').getBoundingClientRect();
                const bounds = canvas.getBoundingClientRect();
                const ratio = canvas.width / bounds.width;
                const data = canvas.getContext('2d').getImageData(Math.floor((box.left-bounds.left-20)*ratio), Math.floor((box.top-bounds.top-20)*ratio), Math.floor((box.width+40)*ratio), Math.floor((box.height+40)*ratio)).data;
                let colored=0; for(let offset=3;offset<data.length;offset+=4) if(data[offset]) colored++;
                return colored;
            }""")
            assert pixels == 0, pixels
            edge_pixels = canvas.evaluate("""canvas => {
                const panel=document.querySelector('#access-panel').getBoundingClientRect();
                const box=canvas.getBoundingClientRect();
                const ratio=canvas.width/box.width;
                const x=panel.left-box.left,y=panel.top-box.top;
                const bands=[[x-8,y,8,panel.height],[x+panel.width,y,8,panel.height],
                    [x,y-8,panel.width,8],[x,y+panel.height,panel.width,8]];
                return bands.map(([a,b,c,d])=>{
                    const data=canvas.getContext('2d').getImageData(Math.floor(a*ratio),Math.floor(b*ratio),Math.ceil(c*ratio),Math.ceil(d*ratio)).data;
                    let count=0;for(let i=3;i<data.length;i+=4)if(data[i])count++;
                    return count;
                });
            }""")
            assert all(value > 0 for value in edge_pixels), edge_pixels
            snapshot(page, "nebula-1440-dark.png")
            before = pixel_hash(page)
            page.wait_for_timeout(400)
            assert pixel_hash(page) != before
            page.locator("#close-access-button").click()
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            page.wait_for_timeout(1000)
            expect(canvas).to_have_attribute("data-phase", "welcome")
            assert canvas.get_attribute("data-mask") in ["one", "logo", "morph"]
        scenario("Click scatters characters into a moving cloud touching all four form edges with centered inputs", nebula_opening, motion="no-preference", theme="dark", initial="welcome")

        def success_animation(page):
            invite(page)
            email(page)
            code(page)
            send(page, "#profile-form", "#signup-username", "campus_member")
            expect(page.locator("#particle-canvas")).to_have_attribute("data-phase", "gather")
            expect(page.locator("#access-panel")).to_have_attribute("inert", "")
            pause_time = datetime.fromtimestamp(page.evaluate("Date.now()") / 1000, tz=timezone.utc) + timedelta(seconds=1)
            page.clock.pause_at(pause_time)
            snapshot(page, "gather-1440-dark.png")
            page.clock.run_for(1200)
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            expect(page.locator("#access-panel")).to_be_hidden()
            expect(page.locator("#particle-canvas")).to_have_attribute("data-phase", "success")
            assert page.locator("main input:visible").count() == 0
            snapshot(page, "complete-1440-dark.png")
            bitmap = pixel_hash(page)
            page.clock.run_for(250)
            assert pixel_hash(page) != bitmap
            expect(page.locator("#particle-canvas")).to_have_attribute("data-confetti", "moving")
            waiting_notice(page)
            advance_to_home(page)
        scenario("Nebula gathers into a check above confetti while the form disappears and the waiting hint appears", success_animation, motion="no-preference", theme="dark", controlled=True)

        def success_cancel(page):
            invite(page)
            email(page)
            code(page)
            pause_time = datetime.fromtimestamp(page.evaluate('Date.now()') / 1000, tz=timezone.utc) + timedelta(seconds=1)
            page.clock.pause_at(pause_time)
            send(page, "#profile-form", "#signup-username", "campus_member")
            page.clock.run_for(750)
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            waiting_notice(page)
            original = page.locator("#success-view").get_attribute("data-redirect-at")
            page.locator('[data-theme-mode="dark"]').click()
            assert page.locator("#success-view").get_attribute("data-redirect-at") == original
            page.locator("#particle-motion-button").click()
            assert page.locator("#success-view").get_attribute("data-redirect-at") == original
            page.keyboard.press("Escape")
            expect(page.locator("body")).to_have_attribute("data-view", "welcome")
            expect(page.locator('#success-notice')).to_be_hidden()
            page.clock.run_for(5200)
            assert page.url.startswith(url), page.url
            page.locator("#open-registration").click()
            page.clock.run_for(1200)
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            waiting_notice(page)
            assert int(page.locator("#success-view").get_attribute("data-redirect-at")) > int(original)
            expect(page.locator("#access-panel")).to_be_hidden()
            page.locator('[data-nav="login"]').click()
            expect(page.locator("body")).to_have_attribute("data-view", "login")
            page.clock.run_for(5200)
            assert page.url.startswith(url), page.url
        scenario("Themes and pause retain the deadline; leaving cancels it and reentry restarts it", success_cancel, controlled=True)

        def fallback_success(page):
            page.add_init_script("""(() => {
                const original=HTMLCanvasElement.prototype.getContext;
                HTMLCanvasElement.prototype.getContext=function(...args){return this.id==='particle-canvas'?null:original.apply(this,args)};
            })();""")
            page.reload(wait_until="networkidle")
            expect(page.locator("#particle-fallback")).to_have_attribute("data-scene", "nebula")
            invite(page)
            email(page)
            code(page)
            send(page, "#profile-form", "#signup-username", "campus_member")
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            expect(page.locator(".particle-stage__fallback-check")).to_be_visible()
            expect(page.locator("#access-panel")).to_be_hidden()
            waiting_notice(page)
            expect(page.locator('#fallback-confetti')).to_be_visible()
            assert page.locator('#fallback-confetti span').count() == 18
            page.wait_for_url("https://isbf-one.com/", timeout=8000)
        scenario("Canvas fallback completes registration with a static check, confetti, hint and redirect", fallback_success)

        def paused_success(page):
            invite(page)
            email(page)
            code(page)
            page.locator("#particle-motion-button").click()
            expect(page.locator("#particle-canvas")).to_have_attribute("data-animated", "false")
            page.clock.pause_at(datetime(2026, 10, 9, tzinfo=timezone.utc) + timedelta(minutes=2))
            send(page, "#profile-form", "#signup-username", "campus_member")
            page.clock.run_for(1050)
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            expect(page.locator("#particle-canvas")).to_have_attribute("data-phase", "success")
            expect(page.locator("#access-panel")).to_be_hidden()
            waiting_notice(page)
            bitmap = pixel_hash(page)
            progress = float(page.locator('#redirect-progress').get_attribute('data-remaining'))
            page.clock.run_for(300)
            assert pixel_hash(page) == bitmap
            assert float(page.locator('#redirect-progress').get_attribute('data-remaining')) < progress - 0.04
            advance_to_home(page)
        scenario("Manual pause shows a static check and confetti while waiting progress and navigation continue", paused_success, motion="no-preference", controlled=True)

        def success_confetti(page):
            invite(page)
            email(page)
            code(page)
            page.clock.pause_at(datetime(2026, 10, 9, tzinfo=timezone.utc) + timedelta(minutes=2))
            send(page, "#profile-form", "#signup-username", "campus_member")
            page.clock.run_for(1800)
            expect(page.locator("#success-view")).to_have_attribute("data-ready", "true")
            canvas = page.locator("#particle-canvas")
            expect(canvas).to_have_attribute("data-confetti", "moving")
            expect(canvas).to_have_attribute("data-confetti-count", "180")
            waiting_notice(page)
            deadline = page.locator("#success-view").get_attribute("data-redirect-at")

            corners = canvas.evaluate("""canvas => {
                const context=canvas.getContext('2d');
                function count(x){
                    const data=context.getImageData(Math.floor(x*canvas.width),Math.floor(canvas.height*0.7),Math.floor(canvas.width*0.22),Math.floor(canvas.height*0.3)).data;
                    let count=0;for(let i=3;i<data.length;i+=4)if(data[i])count++;
                    return count;
                }
                return [count(0),count(0.78)];
            }""")
            assert all(value > 0 for value in corners), corners
            bitmap = pixel_hash(page)
            page.clock.run_for(800)
            assert pixel_hash(page) != bitmap
            snapshot(page, "success-confetti-1440-dark.png")
            page.locator('[data-theme-mode="light"]').click()
            page.clock.run_for(100)
            snapshot(page, "success-confetti-1440-light.png")
            page.locator('[data-theme-mode="dark"]').click()
            page.clock.run_for(100)
            page.locator("#particle-motion-button").click()
            page.clock.run_for(50)
            expect(canvas).to_have_attribute("data-confetti", "static")
            frozen = pixel_hash(page)
            progress = float(page.locator('#redirect-progress').get_attribute('data-remaining'))
            page.clock.run_for(250)
            assert pixel_hash(page) == frozen
            assert float(page.locator('#redirect-progress').get_attribute('data-remaining')) < progress - 0.03
            assert page.locator("#success-view").get_attribute("data-redirect-at") == deadline
            page.locator("#particle-motion-button").click()
            page.clock.run_for(3000)
            expect(canvas).to_have_attribute('data-confetti','finished')
            assert canvas.get_attribute('data-visible-confetti') == '0'
            assert page.url.startswith(url), page.url
        scenario("Three-color ribbons burst from both bottom corners, freeze independently of waiting progress, and finish once", success_confetti, motion="no-preference", theme="dark", controlled=True)

        def mobile_success(page):
            invite(page)
            email(page)
            code(page)
            page.clock.pause_at(datetime(2026, 10, 9, tzinfo=timezone.utc) + timedelta(minutes=2))
            send(page, '#profile-form', '#signup-username', 'isbf_member')
            page.clock.run_for(2400)
            expect(page.locator('#success-view')).to_have_attribute('data-ready','true')
            expect(page.locator('#particle-canvas')).to_have_attribute('data-confetti-count','80')
            waiting_notice(page)
            deadline = page.locator('#success-view').get_attribute('data-redirect-at')
            snapshot(page, 'complete-390-light.png')
            page.locator('[data-theme-mode="dark"]').click()
            page.clock.run_for(100)
            snapshot(page, 'complete-390-dark.png')
            for width,height in [(320,720),(844,390)]:
                page.set_viewport_size({'width':width,'height':height})
                page.wait_for_timeout(120)
                page.clock.run_for(100)
                waiting_notice(page)
                assert page.evaluate('document.documentElement.scrollWidth') <= width
                assert page.locator('#success-view').get_attribute('data-redirect-at') == deadline
                expect(page.locator('#particle-canvas')).to_have_attribute('data-confetti-count','80')
                snapshot(page, f'complete-{width}-dark.png')
            pixels = page.locator('#particle-canvas').evaluate("""canvas => {
                const hint=document.querySelector('#success-notice').getBoundingClientRect();
                const box=canvas.getBoundingClientRect(), ratio=canvas.width/box.width;
                const data=canvas.getContext('2d').getImageData(Math.floor((hint.left-box.left)*ratio),Math.floor((hint.top-box.top)*ratio),Math.floor(hint.width*ratio),Math.floor(hint.height*ratio)).data;
                let count=0;for(let i=3;i<data.length;i+=4)if(data[i])count++;
                return count;
            }""")
            assert pixels == 0, pixels
        scenario('Mobile confetti and the centered waiting hint remain clear through themes, narrow screens and rotation', mobile_success, width=390, height=844, touch=True, motion='no-preference', controlled=True)

        if args.screenshots and args.group in ["all", "registration"]:
            context, page = page_for(390, 844, "dark")
            invite(page)
            email(page)
            snapshot(page, "verification-390-dark.png")
            code(page)
            send(page, "#profile-form", "#signup-username", "isbf_member")
            stage(page, "done")
            waiting_notice(page)
            snapshot(page, "complete-static-390-dark.png")
            context.close()

        assert not report["console_errors"], report["console_errors"]
        assert not report["external_requests"], report["external_requests"]
        browser.close()

    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"engine": args.engine, "layouts": len(report["layouts"]), "scenarios": len(report["scenarios"]), "console_errors": 0, "external_requests": 0}), flush=True)


if __name__ == "__main__":
    main()
