"""Exercise current signup-password sources against local synthetic APIs."""

from pathlib import Path

base = Path("/workspace/docs/design-system/reviews/notifications-layout-20261018/check-browser.py")
exec(compile(base.read_text().split("\ncontrol = ", 1)[0], str(base), "exec"))

state = {"pending": True, "no_password": True, "failure": None, "hold": False, "requests": []}
fixture["user"].update(no_password=True, academy_password_setup_pending=True)
preload_match = re.search(r'(<script type="application/json" id="data-preloaded">)([\s\S]*?)(</script>)', fixture["html"])
preloaded = json.loads(preload_match[2])
settings = json.loads(preloaded["siteSettings"])
settings.update(academy_roles_enabled=True, enable_local_logins=True, enable_discourse_connect=False, min_password_length=10)
preloaded["siteSettings"] = json.dumps(settings)
preloaded["currentUser"] = json.dumps(fixture["user"])
fixture["html"] = fixture["html"][:preload_match.start(2)] + json.dumps(preloaded) + fixture["html"][preload_match.end(2):]
started = threading.Event()
release = threading.Event()
CachedHandler = Handler


class Handler(CachedHandler):
    def send_json(self, data, status=200):
        body = json.dumps(data).encode() if status != 204 else b""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        target = urlsplit(self.path).path
        if target == "/session/current.json":
            user = dict(fixture["user"], no_password=state["no_password"], academy_password_setup_pending=state["pending"])
            return self.send_json({"current_user": user})
        if target in ["/latest.json", "/hot.json", "/top.json"]:
            return self.send_json({"users": [], "primary_groups": [], "flair_groups": [], "topic_list": {"can_create_topic": True, "draft": None, "draft_key": "new_topic", "draft_sequence": 0, "per_page": 30, "topics": [], "top_tags": []}})
        if target.startswith("/stylesheets/common_theme_4_"):
            body = (ART / "compiled/theme.css").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/css")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        return super().do_GET()

    def password_request(self):
        data = parse_qs(self.rfile.read(int(self.headers.get("Content-Length", "0"))).decode(), keep_blank_values=True)
        state["requests"].append({"method": self.command, "keys": sorted(data)})
        if state["hold"]:
            started.set()
            release.wait(20)
        if state["failure"] == "verification":
            return self.send_json({"error_type": "password_setup_verification_required"}, 403)
        if state["failure"]:
            return self.send_json({"errors": ["模拟网络失败，请重试"]}, 503)
        state["pending"] = False
        if self.command == "DELETE":
            return self.send_json({}, 204)
        state["no_password"] = False
        return self.send_json({"success": True, "no_password": False, "academy_password_setup_pending": False})

    def do_PUT(self):
        if urlsplit(self.path).path == "/academy-roles/password-setup.json":
            return self.password_request()
        return super().do_PUT()

    def do_DELETE(self):
        if urlsplit(self.path).path == "/academy-roles/password-setup.json":
            return self.password_request()
        return super().do_DELETE()


server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
playwright = sync_playwright().start()
browser = None
page = None
report.update(current_password_sources=True, checks=[], errors=[], screenshots=[])


def show():
    state.update(pending=True, no_password=True, failure=None, hold=False)
    page.evaluate("""() => {
      const user=reviewOwner.lookup('service:current-user');
      user.setProperties({no_password:true,academy_password_setup_pending:true,is_impersonating:false});
      reviewOwner.lookup('service:modal').show(passwordSetupReview.modal);
    }""")
    page.wait_for_selector(".academy-password-setup")


def fill(confirmation="setup-password-for-fixture-94!"):
    page.locator('[data-name="password"] input').fill("setup-password-for-fixture-94!")
    page.locator('[data-name="passwordConfirmation"] input').fill(confirmation)


def close():
    page.locator(".academy-password-setup .d-modal__footer .btn-default").click()
    page.wait_for_selector(".academy-password-setup", state="hidden")


try:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True,
        args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=96 --single-threaded --single-threaded-gc --optimize-for-size", "--no-proxy-server", "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost"])
    page = browser.new_page(viewport={"width":1280,"height":900}, locale="zh-CN", timezone_id="Asia/Shanghai", service_workers="block", reduced_motion="reduce")
    page.on("pageerror", lambda error: report["errors"].append(error.stack))
    page.set_default_timeout(15000)
    page.goto("http://127.0.0.1:8765/t/reading-fixture/314", wait_until="domcontentloaded", timeout=60000)
    page.wait_for_function("window.passwordSetupReview && window.moduleBroker", timeout=60000)
    page.evaluate("""() => {
      window.reviewOwner=moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback();
      reviewOwner.lookup('service:dialog').cancel();
    }""")
    page.wait_for_selector(".modal-container", state="attached")
    page.evaluate("""translations => {
      const i18n=moduleBroker.lookup('discourse-i18n').default;
      for(const [locale,messages] of Object.entries(translations)) {
        i18n.translations[locale] ??= {js:{}};
        i18n.translations[locale].js.academy_roles ??= {};
        i18n.translations[locale].js.academy_roles.password_setup=messages;
      }
    }""", json.loads((ART/"compiled/translations.json").read_text()))
    for width in [1280, 390]:
        page.set_viewport_size({"width":width,"height":900})
        page.wait_for_function("mobile=>reviewOwner.lookup('service:site').mobileView===mobile", arg=width==390)
        for mode in ["light","dark"]:
            page.evaluate("""({css,mode})=>{
              const sheet=new CSSStyleSheet();sheet.replaceSync(css);
              for(const rule of sheet.cssRules)if(rule.selectorText===':root')for(const key of rule.style)if(key.startsWith('--'))document.documentElement.style.setProperty(key,rule.style.getPropertyValue(key));
              document.documentElement.style.colorScheme=mode;
            }""", {"css":(ART/f"compiled/colors-{mode}.css").read_text(),"mode":mode})
            show()
            box=page.locator(".academy-password-setup .d-modal__container").evaluate("""n=>{
              const s=getComputedStyle(n),r=n.getBoundingClientRect();
              return {left:r.left,top:r.top,right:r.right,bottom:r.bottom,width:r.width,radii:[s.borderTopLeftRadius,s.borderTopRightRadius,s.borderBottomLeftRadius,s.borderBottomRightRadius],border:s.borderTopWidth,shadow:s.boxShadow};
            }""")
            check(box["radii"]==["16px"]*4 and box["border"]=="1px" and box["shadow"]=="none",f"{width} {mode}: approved shared dialog frame")
            check(box["left"]>=15 and box["right"]<=width-15 and box["top"]>=15 and box["bottom"]<=885,f"{width} {mode}: safe viewport gutters")
            check(page.locator(".academy-password-setup .d-modal__footer .btn").evaluate_all("nodes=>nodes.every(n=>getComputedStyle(n).borderRadius==='999px'&&n.getBoundingClientRect().height>=44)"),f"{width} {mode}: shared pill actions")
            check(page.locator(".academy-password-setup input[autocomplete='new-password']").count()==2,f"{width} {mode}: two password-manager fields")
            filename=f"password-setup-{width}-{mode}.png"
            page.locator(".academy-password-setup").screenshot(path=str(ART/filename))
            report["screenshots"].append(filename)
            report["layouts"].append({"width":width,"mode":mode,**box})
            close()
    show()
    fill("different-password")
    before=len(state["requests"])
    page.locator(".academy-password-setup .btn-primary").click()
    page.wait_for_selector('[data-name="passwordConfirmation"] .form-kit__errors')
    check(len(state["requests"])==before,"mismatched passwords cannot reach the server")
    field=page.locator('[data-name="password"] input')
    page.locator('[data-name="password"] [role="switch"]').click()
    check(field.get_attribute("type")=="text","password visibility can be toggled")
    check(bool(page.locator('[data-name="password"] [role="switch"]').get_attribute("title")),"password visibility has an accessible action name")
    fill()
    state["failure"]="network"
    page.locator(".academy-password-setup .btn-primary").click()
    page.wait_for_selector(".academy-password-setup .alert-error")
    check(field.input_value()=="setup-password-for-fixture-94!" and state["pending"],"a failed save preserves the draft and reminder")
    state.update(failure=None,hold=True)
    page.locator(".academy-password-setup .btn-primary").click()
    check(started.wait(5),"retry reaches the synthetic endpoint")
    check(page.locator(".academy-password-setup .btn-primary").is_disabled() and page.locator('[data-name="password"] input').is_disabled(),"submitting locks both form and action")
    check(page.locator('[data-name="password"] [role="switch"]').is_disabled(),"submitting also locks password visibility")
    page.keyboard.press("Escape")
    check(page.locator(".academy-password-setup").count()==1,"Escape cannot interrupt saving")
    release.set()
    page.wait_for_selector(".academy-password-setup",state="hidden")
    state["hold"]=False
    check(not state["pending"] and not state["no_password"],"successful retry completes initial password setup")
    check(page.evaluate("reviewOwner.lookup('service:current-user').no_password===false"),"the current user reflects a saved password")
    for closing in ["escape","button","backdrop"]:
        show()
        before=len(state["requests"])
        if closing=="escape": page.keyboard.press("Escape")
        elif closing=="button": page.locator(".academy-password-setup .modal-close").click()
        else: page.locator(".d-modal__backdrop").click(position={"x":2,"y":2})
        page.wait_for_selector(".academy-password-setup",state="hidden")
        check(not state["pending"] and state["no_password"] and len(state["requests"])==before+1,f"{closing}: exactly one persisted skip, no password created")
    show()
    state["failure"]="network"
    page.locator(".academy-password-setup .d-modal__footer .btn-default").click()
    page.wait_for_selector(".academy-password-setup .alert-error")
    check(state["pending"],"failed dismissal does not pretend the reminder was saved")
    state["failure"]=None
    close()
    show()
    fill()
    state["failure"]="verification"
    page.locator(".academy-password-setup .btn-primary").click()
    page.wait_for_selector(".forgot-password-modal")
    check(state["pending"] and state["no_password"],"expired trust uses the existing email flow without setting a password")
    page.keyboard.press("Escape")
    page.wait_for_selector(".forgot-password-modal",state="hidden")
    state["failure"]=None
    page.set_viewport_size({"width":390,"height":340})
    show()
    check(page.locator(".d-modal__footer").evaluate("n=>n.getBoundingClientRect().bottom<=innerHeight-15"),"actions remain reachable with the software-keyboard viewport")
    close()
    page.set_viewport_size({"width":1280,"height":900})
    page.evaluate("""()=>{
      reviewOwner.lookup('service:current-user').setProperties({no_password:true,academy_password_setup_pending:true});
      reviewOwner.lookup('service:router').transitionTo('discovery.latest');
    }""")
    page.wait_for_selector(".academy-password-setup")
    check(True,"the real homepage route triggers the registered prompt")
    close()
    page.evaluate("reviewOwner.lookup('service:router').transitionTo('discovery.top')")
    page.wait_for_function("reviewOwner.lookup('service:router').currentRouteName==='discovery.top'")
    check(page.locator(".academy-password-setup").count()==0,"a completed reminder does not repeat on feed navigation")
    check(not report["errors"],"no client exceptions")
    report["passed"]=True
finally:
    release.set()
    if page and not report["passed"]:
        try:
            report["failure_state"] = page.evaluate("""() => {
              const router=reviewOwner.lookup('service:router'),user=reviewOwner.lookup('service:current-user');
              return {url:router.currentURL,route:router.currentRouteName,pending:user.academy_password_setup_pending,noPassword:user.no_password,
                impersonating:user.is_impersonating,activeModal:!!reviewOwner.lookup('service:modal').activeModal,dialog:reviewOwner.lookup('service:dialog').show,
                hiddenContent:reviewOwner.lookup('controller:application').shouldHideScrollableContentBelow,
                settings:{enabled:reviewOwner.lookup('service:site-settings').academy_roles_enabled,local:reviewOwner.lookup('service:site-settings').enable_local_logins,sso:reviewOwner.lookup('service:site-settings').enable_discourse_connect},
                registeredConnectors:moduleBroker.lookup('discourse/lib/plugin-connectors').connectorsFor('main-outlet-bottom').length};
            }""")
            page.screenshot(path=str(ART/"browser-failure.png"))
            (ART/"browser-failure.html").write_text(page.content())
        except Exception:
            pass
    if browser: browser.close()
    playwright.stop()
    server.shutdown()
    report["synthetic_password_requests"]=state["requests"]
    (ART/"browser-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"passed":report["passed"],"checks":len(report["checks"]),"errors":report["errors"]},ensure_ascii=False),flush=True)
