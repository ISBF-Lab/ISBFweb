"""Check the offline particle registration prototype with a local or remote browser."""

import argparse
import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path

from playwright.sync_api import expect, sync_playwright


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", choices=["chromium", "webkit", "firefox"], default="chromium")
    parser.add_argument("--endpoint", help="Existing Playwright browser WebSocket endpoint")
    parser.add_argument("--url", help="HTML URL as seen by the browser")
    parser.add_argument("--report", type=Path, help="Output JSON report")
    parser.add_argument("--screenshots", action="store_true", help="Save review screenshots")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    url = args.url or (root / "preview.html").as_uri()
    report_path = args.report or root / f"verification-{args.engine}.json"
    images = root / "screenshots"
    images.mkdir(exist_ok=True)
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "engine": args.engine,
        "browser_version": None,
        "layouts": [],
        "scenarios": [],
        "console_errors": [],
        "external_requests": [],
        "screenshots": [],
    }

    with sync_playwright() as playwright:
        browser_type = getattr(playwright, args.engine)
        browser = browser_type.connect(args.endpoint) if args.endpoint else browser_type.launch(headless=True)
        report["browser_version"] = browser.version

        def page_for(width=1440, height=900, theme="light", motion="reduce"):
            context = browser.new_context(
                viewport={"width": width, "height": height},
                color_scheme=theme,
                reduced_motion=motion,
            )
            page = context.new_page()
            page.set_default_timeout(8000)
            page.on("pageerror", lambda error: report["console_errors"].append(str(error)))
            page.on("console", lambda message: report["console_errors"].append(message.text) if message.type == "error" else None)
            page.on("request", lambda request: report["external_requests"].append(request.url) if request.url.startswith(("http:", "https:")) else None)
            page.goto(url, wait_until="networkidle")
            page.evaluate("document.fonts.ready")
            expect(page.locator("#particle-canvas")).to_have_attribute("data-ready", "true")
            return context, page

        def stage(page, name):
            expect(page.locator(f'[data-step="{name}"]')).to_be_visible()
            expect(page.locator("body")).to_have_attribute("data-registration-step", name)

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

        def scenario(name, callback, **options):
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

        def snapshot(page, name):
            if args.screenshots:
                page.screenshot(path=str(images / name), full_page=True)
                report["screenshots"].append(name)

        for width, height in [(320, 720), (390, 844), (768, 1024), (1440, 900)]:
            for theme in ["light", "dark"]:
                context, page = page_for(width, height, theme)
                metrics = page.evaluate("""() => {
                    const control = document.querySelector('#invite-code').getBoundingClientRect();
                    const button = document.querySelector('#invite-form button').getBoundingClientRect();
                    return {viewport: innerWidth, document: document.documentElement.scrollWidth,
                        inputLeft: control.left, inputRight: control.right,
                        buttonHeight: button.height,
                        theme: document.documentElement.dataset.theme,
                        particles: Number(document.querySelector("#particle-canvas").dataset.particleCount),
                        canvasWidth: document.querySelector("#particle-canvas").getBoundingClientRect().width};
                }""")
                assert metrics["document"] <= width, metrics
                assert 0 <= metrics["inputLeft"] < metrics["inputRight"] <= width, metrics
                assert metrics["buttonHeight"] >= 44, metrics
                assert metrics["theme"] == theme, metrics
                assert metrics["particles"] == (6800 if metrics["canvasWidth"] > 500 else 3000), metrics
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
            send(page, "#profile-form", "#signup-username", "isbf_member")
            stage(page, "done")
            snapshot(page, "complete-1440-light.png")
            page.locator("#enter-community-button").click()
            stage(page, "community")
            page.locator("#restart-button").click()
            stage(page, "invite")
            expect(page.locator("#invite-code")).to_have_value("")
            expect(page.locator("#signup-email")).to_have_value("")
            expect(page.locator("#signup-username")).to_have_value("")
        scenario("Complete registration, community preview and restart", complete)

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
            expect(canvas).to_have_attribute("data-mask", "logo")
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
            expect(canvas).to_have_attribute("data-mask", "morph", timeout=20000)
            snapshot(page, "particles-morph-1440-light.png")
            expect(canvas).to_have_attribute("data-mask", "logo", timeout=15000)
            snapshot(page, "particles-logo-1440-light.png")
        scenario("Character particles morph from One to the site logo", morphology, motion="no-preference")

        def offscreen(page):
            page.set_viewport_size({"width": 390, "height": 300})
            canvas = page.locator("#particle-canvas")
            expect(canvas).to_have_attribute("data-animated", "true")
            page.evaluate("window.scrollTo(0, document.documentElement.scrollHeight)")
            page.wait_for_timeout(150)
            paused_frame = frame_count(page)
            page.wait_for_timeout(300)
            assert frame_count(page) == paused_frame
            page.evaluate("window.scrollTo(0, 0)")
            page.wait_for_function("frames => Number(document.querySelector('#particle-canvas').dataset.frameCount) > frames + 2", arg=paused_frame)
            expect(canvas).to_have_attribute("data-particle-count", "3000")
        scenario("Offscreen mobile particles stop drawing and resume", offscreen, width=390, height=844, motion="no-preference")

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

        if args.screenshots:
            context, page = page_for(390, 844, "dark")
            invite(page)
            email(page)
            snapshot(page, "verification-390-dark.png")
            code(page)
            send(page, "#profile-form", "#signup-username", "isbf_member")
            stage(page, "done")
            snapshot(page, "complete-390-dark.png")
            context.close()

        assert not report["console_errors"], report["console_errors"]
        assert not report["external_requests"], report["external_requests"]
        browser.close()

    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"engine": args.engine, "layouts": len(report["layouts"]), "scenarios": len(report["scenarios"]), "console_errors": 0, "external_requests": 0}), flush=True)


if __name__ == "__main__":
    main()
