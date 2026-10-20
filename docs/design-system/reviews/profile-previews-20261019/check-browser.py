"""Exercise actual profile routes against synthetic APIs in an offline Ember client."""

from pathlib import Path

base_harness = Path("/workspace/docs/design-system/reviews/notifications-layout-20261018/check-browser.py")
base_source = base_harness.read_text().split("\ncontrol = ", 1)[0]
exec(compile(base_source, str(base_harness), "exec"))

TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]"
USERNAME = fixture["user"]["username"]
category = fixture["site"]["categories"][0]
fixture["user"].update(can_see_summary_stats=True, can_see_user_actions=True, profile_hidden=False)
requests = []
controls = {"failed_images": False}
topic_body = '<p>校园无标题图文。</p><div class="lightbox-wrapper"><a class="lightbox"><img src="/fixture/photo-1.png"><span class="meta">image-file.png 600×400</span></a></div><img src="/fixture/photo-2.png"><img src="/fixture/photo-3.png"><img src="/fixture/photo-4.png">'


def action(topic, post=None, title=TITLE, **extra):
    return {"action_type": 4, "post_id": post, "topic_id": topic, "post_number": 1, "post_type": 1,
            "title": title, "slug": "campus", "user_id": fixture["user"]["id"], "username": USERNAME,
            "avatar_template": "/images/avatar.png", "created_at": "2026-10-19T00:00:00Z", "category_id": category["id"],
            "excerpt": '<p>校园无标题图文。</p><a class="lightbox">[image-file.png]</a>', "truncated": True, **extra}


actions = [action(910001), action(910002, 920002, "正常标题"), action(910003, 920003, hidden=True),
           action(910004, excerpt='<a class="lightbox">[only-photo.png]</a>'),
           action(910005, excerpt='<p>加载失败仍保留干净摘要。</p><a class="lightbox">[failed.png]</a>')]

summary = {"user_summary": {"topic_ids": [910001, 910002, 910004], "replies": [
    {"topic_id": 910001, "post_number": 7, "like_count": 3, "created_at": "2026-10-19T00:00:00Z"}],
    "links": [{"topic_id": 910001, "post_number": 8, "url": "https://example.org/", "title": "A link", "clicks": 2}],
    "most_replied_to_users": [], "most_liked_by_users": [], "most_liked_users": [], "badges": [], "top_categories": [],
    "can_see_summary_stats": True, "can_see_user_actions": True, "likes_given": 4, "likes_received": 5,
    "topics_entered": 6, "posts_read_count": 7, "days_visited": 8, "topic_count": 3, "post_count": 4, "time_read": 60},
    "topics": [{"id": topic, "title": title, "fancy_title": title, "slug": "campus", "posts_count": 10,
                "created_at": "2026-10-19T00:00:00Z", "like_count": 4}
               for topic, title in [(910001, TITLE), (910002, "正常标题"), (910004, TITLE)]], "badges": []}

CachedHandler = Handler


class Handler(CachedHandler):
    def send_json(self, value, status=200):
        data = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        path = urlsplit(self.path).path
        if path.startswith("/u/") and not path.endswith(".json"):
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
        elif path.endswith("/summary.json"):
            self.send_json(summary)
        elif path.startswith("/u/") and path.endswith(".json"):
            self.send_json({"user": fixture["user"]})
        elif path == "/user_actions.json":
            query = parse_qs(urlsplit(self.path).query)
            self.send_json({"user_actions": actions if query.get("offset", ["0"])[0] == "0" else [], "categories": [category]})
        elif path.startswith("/posts/"):
            requests.append(path)
            match = re.fullmatch(r"/posts/by_number/(\d+)/(\d+)\.json", path)
            if match:
                topic, number = map(int, match.groups())
                if topic == 910005:
                    return self.send_json({"errors": ["Synthetic failure"]}, 500)
                if topic >= 930000:
                    if number == 7:
                        time.sleep(0.4)
                    return self.send_json({"id": topic * 10 + number, "cooked": f"<p>Reply {number}</p>"})
                body = topic_body if number == 1 else f"<p>热门回复正文，第 {number} 楼。</p>"
                if topic == 910004:
                    body = '<img src="/fixture/photo-only.png">'
                self.send_json({"id": 920001 if topic == 910001 and number == 1 else topic * 10 + number, "cooked": body})
            elif path == "/posts/920002/cooked":
                self.send_json({"cooked": "<p>正常标题的正文。</p>"})
            else:
                self.send_json({"cooked": "<p>Updated body</p>"})
        elif path.startswith("/fixture/photo-") and controls["failed_images"]:
            self.send_response(404)
            self.end_headers()
        else:
            super().do_GET()


server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
browser = None
page = None
try:
    playwright = sync_playwright().start()
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True,
        args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=128 --optimize-for-size", "--no-proxy-server", "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost"])
    page = browser.new_page(viewport={"width": 1280, "height": 1000}, locale="zh-CN", service_workers="block")
    page.on("pageerror", lambda error: report["errors"].append(str(error)))
    page.add_init_script("window.addEventListener('error',e=>window.fixtureFailure=e.error?.stack||e.message);window.addEventListener('unhandledrejection',e=>window.fixtureFailure=e.reason?.stack||String(e.reason))")
    page.goto(f"http://127.0.0.1:8765/u/{USERNAME}/activity", wait_until="domcontentloaded", timeout=60000)
    page.wait_for_function("window.fixtureFailure || document.querySelector('.isbf-activity-preview')", timeout=60000)
    check(not page.evaluate("window.fixtureFailure || null"), "the full client boots with the actual changed modules")
    page.locator(".isbf-activity-preview").first.scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('.isbf-activity-preview')?.querySelectorAll('.isbf-post-preview__image').length === 3", timeout=30000)
    page.wait_for_load_state("networkidle")
    first = page.locator(".isbf-activity-preview").first
    check(first.locator(".isbf-activity-preview__title").count() == 0, "the historical untitled activity omits its internal title")
    check(first.locator(".isbf-post-preview__text").inner_text() == "校园无标题图文。", "the initial image caption is replaced by the clean cooked body")
    check(first.locator("img.isbf-post-preview__image").evaluate_all("images=>images.every(image=>image.complete&&image.naturalWidth>0)"), "historical activity thumbnails finish loading")
    check(first.locator(".isbf-post-preview__image").count() == 3, "the activity gallery remains bounded to three thumbnails")
    check(page.locator(".user-stream-item.isbf-activity-item").count() == 5, "all public actions use the same preview eligibility as the row styles")
    check(not first.locator("xpath=..").locator(".post-list-item__header").is_visible(), "the duplicate native title header is hidden")
    check("isbf-untitled" not in page.locator(".user-stream").inner_text(), "no visible internal title remains in the actual activity list")
    page.locator(".isbf-activity-preview").nth(2).scroll_into_view_if_needed()
    check("/posts/920003/cooked" not in requests, "hidden activity does not fetch its body")
    page.locator(".isbf-activity-preview").last.scroll_into_view_if_needed()
    page.wait_for_load_state("networkidle")
    check(page.locator(".isbf-activity-preview").last.locator(".isbf-post-preview__text").inner_text() == "加载失败仍保留干净摘要。", "a failed body request retains the clean excerpt")
    if page.locator("#dialog-holder .dialog-body").is_visible():
        report["fixture_dialog"] = page.locator("#dialog-holder .dialog-body").inner_text()
        page.locator("#dialog-holder .dialog-footer button").first.click()
    first.scroll_into_view_if_needed()
    first.locator(".expand-item").click()
    first.locator(".isbf-activity-preview__body .cooked").wait_for()
    check("校园无标题图文。" in first.locator(".isbf-activity-preview__body").inner_text(), "native expansion works without an original post ID")
    first.locator(".collapse-item").click()
    first.locator(".isbf-post-preview").wait_for()
    check(first.locator(".isbf-activity-preview__body").count() == 0, "native collapse restores the bounded preview")
    page.evaluate("window.reviewOwner=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
    page.evaluate("reviewOwner.lookup('service:router').transitionTo('/u/" + USERNAME + "/summary')")
    page.wait_for_selector(".replies-section .isbf-post-preview")
    page.locator(".replies-section").scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('.replies-section .isbf-post-preview__text')?.textContent.includes('第 7 楼')")
    page.wait_for_load_state("networkidle")
    check(page.locator(".replies-section .isbf-post-preview__text").inner_text() == "热门回复正文，第 7 楼。", "the popular reply uses its actual post number")
    check(page.locator(".replies-section .isbf-post-preview").get_attribute("href") == "/t/campus/910001/7", "the reply keeps its original target")
    check(page.locator(".replies-section .like-count").inner_text() == "3", "the reply keeps its original like count")
    check(page.locator(".topics-section .isbf-post-preview__text").first.inner_text() == "校园无标题图文。", "the popular topic uses its first post")
    check(page.locator(".topics-section li").nth(1).inner_text().endswith("正常标题"), "an explicitly titled summary item keeps the native title")
    check(page.locator(".user-content .isbf-post-preview__image").count() == 0, "the summary remains a text-only list")
    page.locator(".links-section").scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('.links-section .isbf-post-preview__text')?.textContent.includes('第 8 楼')")
    check(page.locator(".links-section .isbf-post-preview").get_attribute("href") == "/t/campus/910001/8", "other summary topic links keep their original post targets")
    check("isbf-untitled" not in page.locator(".user-content").inner_text(), "the real summary route displays no internal title markers")
    for width in [1280, 390, 320]:
        page.set_viewport_size({"width": width, "height": 1000})
        for mode in ["light", "dark"]:
            page.evaluate("({css,mode})=>{let style=document.getElementById('profile-palette');if(!style){style=document.createElement('style');style.id='profile-palette';document.head.append(style)}style.textContent=css;document.documentElement.style.colorScheme=mode}", {"css": (ART / f"compiled/colors-{mode}.css").read_text(), "mode": mode})
            page.locator(".replies-and-topics-section").scroll_into_view_if_needed()
            check(not page.evaluate("document.documentElement.scrollWidth > innerWidth + 1"), f"{width}px {mode}: summary has no horizontal overflow")
            check(page.locator(".isbf-post-preview.--summary .isbf-post-preview__text").first.evaluate("node=>getComputedStyle(node).webkitLineClamp") == "2", f"{width}px {mode}: summary previews remain bounded to two lines")
            page.screenshot(path=str(ART / f"summary-{width}-{mode}.png"))
    values = page.evaluate("""async () => {
      const loader=moduleBroker.lookup('profile-preview-review/discourse/lib/feed-post-loader');
      const preview=moduleBroker.lookup('profile-preview-review/discourse/lib/post-preview');
      const target={topicId:930001,postNumber:2};
      const pair=await Promise.all([loader.loadCookedPost(null,target),loader.loadCookedPost(null,target)]);
      const canonical=await loader.loadCookedPost(9300012);
      const other=await loader.loadCookedPost(null,{topicId:930001,postNumber:3});
      const pending=loader.loadCookedPost(null,{topicId:930002,postNumber:7});
      await new Promise(resolve=>setTimeout(resolve,60));loader.invalidateCookedPost(9300027);const hidden=await pending;
      const pendingEdit=loader.loadCookedPost(null,{topicId:930003,postNumber:7});
      await new Promise(resolve=>setTimeout(resolve,60));loader.invalidateCookedPost(9300037,false);const edited=await pendingEdit;
      const cleaned=preview.postPreview('<p>[abc123] 是正文编码。</p><a class="lightbox">[image.png]</a>');
          const polls = await loader.loadPostPolls(940001, 42);
          await loader.loadPostPolls(940001, 42);
          await loader.loadPostPolls(940001, 43);
          return {pair,canonical,other,hidden,edited,cleaned:cleaned.text,polls};
    }""")
    check(values["pair"] == ["<p>Reply 2</p>"] * 2 and values["canonical"] == values["pair"][0], "number lookups share the canonical post cache")
    check(requests.count("/posts/by_number/930001/2.json") == 1 and "/posts/9300012/cooked" not in requests, "concurrent and canonical callers need one body request")
    check(values["other"] == "<p>Reply 3</p>", "two replies in one topic never share the wrong body")
    check(values["hidden"] == "" and values["edited"] == "", "hidden and edited posts reject stale number responses before their IDs were known")
    check(values["cleaned"] == "[abc123] 是正文编码。", "body codes survive while structural image captions are removed")
    check(requests.count("/posts/940001.json") == 2 and values["polls"] is not None, "the deployed poll loader keeps its per-user cache beside body previews")
    check(not report["errors"] and not report["missing_assets"], "the actual client completes without JavaScript errors or missing resources")
    report["passed"] = True
except Exception as error:
    report["failure"] = str(error)
    if page:
        try:
            report["debug"] = {"body": page.locator("body").inner_text()[-2500:], "source_installed": page.evaluate("Boolean(window.profilePreviewSourceInstalled)"), "failure": page.evaluate("window.fixtureFailure || null")}
            page.screenshot(path=str(ART / "failure.png"))
        except Exception as stopped:
            report["debug_unavailable"] = str(stopped)
    raise
finally:
    report["post_requests"] = requests
    (ART / "browser-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    if browser:
        try:
            browser.close()
        except Exception:
            pass
    if "playwright" in globals():
        playwright.stop()
    server.shutdown()
