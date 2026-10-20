"""Exercise the complete candidate theme against synthetic APIs in a native client."""
from pathlib import Path

base = Path('/workspace/docs/design-system/reviews/notifications-layout-20261018/check-browser.py')
exec(compile(base.read_text().split('\ncontrol = ', 1)[0], str(base), 'exec'))
requests = []
BaseHandler = Handler


class Handler(BaseHandler):
    def send_value(self, data, kind='application/json', status=200):
        if not isinstance(data, bytes):
            data = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', kind)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        path = urlsplit(self.path).path
        if path.startswith('/theme-javascripts/'):
            data=(ART / 'compiled/theme-native.js').read_text()
            translations=json.loads((ART / 'compiled/translations.json').read_text())
            data+='\nconst previewLocale=window._discourse_locale_data;previewLocale.theme??={};previewLocale.theme[4]??={};\n'
            data+='previewLocale.theme[4].zh_CN={isbf_v2:'+json.dumps(translations['zh_CN'])+'};\n'
            data+='previewLocale.translations.zh_CN??={};previewLocale.translations.zh_CN.js??={};previewLocale.translations.zh_CN.js.theme_translations??={};previewLocale.translations.zh_CN.js.theme_translations[4]=previewLocale.theme[4].zh_CN;\n'
            self.send_value(data.encode(), 'application/javascript')
        elif path.startswith('/posts/by_number/'):
            requests.append(path)
            match = re.fullmatch(r'/posts/by_number/(\d+)/(\d+)\.json', path)
            topic, number = map(int, match.groups())
            if topic == 904:
                return self.send_value({'errors':['Synthetic missing post']}, status=404)
            if topic == 903:
                cooked = '<a class="lightbox"><img src="/fixture/photo-only.png" alt="internal-filename"></a>'
            elif topic == 902:
                cooked = '<p>' + '首帖正文摘要，保留原来的未读跳转位置。' * 35 + '</p>'
            else:
                cooked = '<p>首帖正文，校园活动照片。</p><a class="lightbox"><img src="/fixture/photo.png" alt="internal-filename"><span class="meta">internal-filename 600×400</span></a>'
            self.send_value({'id': topic * 100 + number, 'cooked': cooked})
        elif path == '/filter.json':
            self.send_value({'users':[], 'topic_list':{'topics':[]}})
        else:
            super().do_GET()


server = ThreadingHTTPServer(('127.0.0.1',8765),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
report.update(template_overrides=False, full_native_theme=True, expected_missing_body_status=404)
playwright = sync_playwright().start()
browser = None
page = None
try:
    browser = playwright.chromium.launch(executable_path=os.environ['ISBF_REVIEW_CHROMIUM'], headless=True,
        args=['--no-sandbox','--no-zygote','--disable-dev-shm-usage','--disable-gpu','--renderer-process-limit=1','--num-raster-threads=1','--disable-site-isolation-trials','--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate','--js-flags=--max-old-space-size=128 --optimize-for-size','--no-proxy-server','--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost'])
    page = browser.new_page(viewport={'width':1280,'height':1000},locale='zh-CN',service_workers='block')
    page.on('pageerror',lambda e:report['errors'].append(e.stack))
    page.goto('http://127.0.0.1:8765/t/reading-fixture/314',wait_until='domcontentloaded',timeout=60000)
    page.wait_for_selector('.isbf-continue-reading')
    page.evaluate("window.reviewOwner=moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback()")
    panel = page.locator('.isbf-continue-reading')
    check('isbf-untitled:' not in panel.inner_text(), 'the internal title is absent before loading or scrolling')
    check(panel.locator('.isbf-continue-reading__item').evaluate_all('els=>els.map(el=>+el.dataset.topicId)') == [901,902,903,904,905,906,907], 'suggestions preserve exact source order')
    initial_requests = list(requests)
    check('/posts/by_number/906/1.json' not in requests, 'hidden topics are not requested')
    for topic in [901,902,903,904]:
        panel.locator(f'li[data-topic-id="{topic}"]').scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('li[data-topic-id=\"903\"] .isbf-post-preview__text')?.textContent==='图片'")
    page.wait_for_function("document.querySelector('li[data-topic-id=\"901\"] .isbf-post-preview__text')?.textContent==='首帖正文，校园活动照片。'")
    check(panel.locator('li[data-topic-id="902"] .isbf-post-preview__text').inner_text().startswith('首帖正文摘要'), 'untitled rows render clean first-post text')
    check(panel.locator('li[data-topic-id="904"] .isbf-post-preview__text').inner_text()=='查看帖子','a missing body retains the neutral link label')
    check(panel.locator('li[data-topic-id="906"] .isbf-post-preview__text').inner_text()=='查看帖子','hidden excerpts remain hidden')
    check(panel.locator('.isbf-post-preview__image').count()==0,'the footer displays no thumbnails or image filenames')
    check('internal-filename' not in panel.inner_text() and 'isbf-untitled:' not in panel.inner_text(),'loaded and failed rows expose neither filenames nor placeholder codes')
    check(panel.locator('li[data-topic-id="907"] .isbf-continue-reading__title').inner_text().startswith('ZZZZ'),'explicit titles retain native rendering')
    check(not any(f'/posts/by_number/{topic}/' in path for path in requests for topic in [905,906,907]),'titled and hidden rows make no body requests')
    check(all(path.endswith('/1.json') for path in requests),'body previews always read post one')
    targets=page.evaluate("""() => {const t=reviewOwner.lookup('controller:topic').model.suggestedTopics[1];return {title:t.lastUnreadUrl,replies:t.firstPostUrl,time:t.lastPostUrl,category:t.category.url}}""")
    row=panel.locator('li[data-topic-id="902"]')
    check(all(row.locator(selector).get_attribute('href')==targets[key] for key,selector in [('title','.isbf-continue-reading__title'),('replies','.isbf-continue-reading__replies'),('time','.isbf-continue-reading__time'),('category','.badge-category__wrapper')]),'unread, reply, time and category links retain their exact targets')
    check(panel.locator('a a').count()==0,'preview links contain no nested anchors')
    check(panel.locator('li[data-topic-id="902"] .isbf-continue-reading__unread').count()==1,'untitled rows retain the native unread indicator')
    check(panel.locator('li[data-topic-id="904"] .topic-status.--closed').count()==1,'untitled rows retain locked status')
    check(panel.locator('li[data-topic-id="901"] .isbf-continue-reading__title .sr-only').count()==1,'read topics retain their accessible announcement')
    page.evaluate("""() => {const url=moduleBroker.lookup('discourse/lib/url').default;window.originalRoute=url.routeTo;url.routeTo=href=>window.clickedHref=href;const history=reviewOwner.lookup('service:history-store');window.originalHistorySet=history.set;window.historyWrites=[];history.set=function(key,value){window.historyWrites.push([key,value]);return window.originalHistorySet.call(this,key,value)};}""")
    title=panel.locator('li[data-topic-id="902"] .isbf-continue-reading__title')
    title.focus()
    check('selected' in row.get_attribute('class'),'keyboard focus retains native row selection')
    title.click()
    check(page.evaluate('window.clickedHref')=='http://127.0.0.1:8765'+targets['title'],'pointer clicks retain native unread navigation')
    check(['lastTopicIdViewed',902] in page.evaluate('window.historyWrites'),'preview clicks retain native history')
    page.evaluate("() => {moduleBroker.lookup('discourse/lib/url').default.routeTo=window.originalRoute;reviewOwner.lookup('service:history-store').set=window.originalHistorySet;}")
    for width in [1280,390]:
        page.set_viewport_size({'width':width,'height':1000})
        for mode in ['light','dark']:
            page.evaluate("""({css,mode})=>{const sheet=new CSSStyleSheet();sheet.replaceSync(css);for(const rule of sheet.cssRules)if(rule.selectorText===':root')for(const key of rule.style)if(key.startsWith('--'))document.documentElement.style.setProperty(key,rule.style.getPropertyValue(key));document.documentElement.style.colorScheme=mode;}""",{'css':(ART/f'compiled/colors-{mode}.css').read_text(),'mode':mode})
            row.scroll_into_view_if_needed()
            result=panel.evaluate("""el=>{const title=el.querySelector('li[data-topic-id="902"] .isbf-continue-reading__title');const text=title.querySelector('.isbf-post-preview__text');const style=getComputedStyle(title);return {width:innerWidth,borderRadius:getComputedStyle(el).borderRadius,avatar:el.querySelector('.isbf-continue-reading__avatar').getBoundingClientRect().width,textHeight:text.getBoundingClientRect().height,lineHeight:parseFloat(style.lineHeight),clamp:getComputedStyle(text).webkitLineClamp,bodyOverflow:document.documentElement.scrollWidth>innerWidth+1,panelOverflow:el.scrollWidth>el.clientWidth+1,secondary:getComputedStyle(document.documentElement).getPropertyValue('--secondary').trim()}}""")
            check(not result['bodyOverflow'] and not result['panelOverflow'],f'{width}px {mode}: no horizontal overflow')
            check(result['clamp']=='2' and result['textHeight']<=2*result['lineHeight']+1,f'{width}px {mode}: body preview stays within two lines')
            check(result['borderRadius']=='0px' and result['avatar']==(30 if width==390 else 36),f'{width}px {mode}: square border and avatar dimensions remain')
            check(result['secondary']==('#101413' if mode=='dark' else '#ffffff'),f'{width}px {mode}: the actual theme palette is active')
            report['layouts'].append({**result,'mode':mode})
            panel.screenshot(path=str(ART/f'{width}-{mode}.png'))
    page.evaluate("reviewOwner.lookup('service:more-topics-tabs').selectTab(reviewOwner.lookup('service:more-topics-tabs').tabs.find(t=>t.id==='related-topics'))")
    page.wait_for_function("document.querySelector('.isbf-continue-reading')?.dataset.source==='related'")
    panel.scroll_into_view_if_needed()
    page.wait_for_function("document.querySelector('li[data-topic-id=\"908\"] .isbf-post-preview__text')?.textContent==='首帖正文，校园活动照片。'")
    check(panel.locator('.isbf-continue-reading__item').evaluate_all('els=>els.map(el=>+el.dataset.topicId)')==[908,909],'related topics retain source order and use the same untitled preview')
    page.evaluate("reviewOwner.lookup('service:more-topics-tabs').selectTab(reviewOwner.lookup('service:more-topics-tabs').tabs.find(t=>t.id==='suggested-topics'))")
    page.wait_for_function("document.querySelector('.isbf-continue-reading')?.dataset.source==='suggested'")
    panel.scroll_into_view_if_needed()
    check(requests.count('/posts/by_number/901/1.json')==1,'switching sources reuses the shared body cache')
    check(not report['errors'],'the native client finishes without exceptions')
    report.update(passed=True,body_requests=requests,initial_body_requests=initial_requests)
finally:
    if page is not None and not report['passed']:
        report['debug']={'body':page.locator('body').inner_text()[-3000:],'requests':requests}
        (ART/'failure.html').write_text(page.content())
    (ART/'browser-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    if browser: browser.close()
    playwright.stop()
    server.shutdown()
