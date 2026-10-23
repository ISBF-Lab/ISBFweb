"""Read the deployed affected pages through the host's GET-only TLS proxy."""

import base64
import json
from pathlib import Path
import sys
from urllib.parse import urlsplit

from playwright.sync_api import expect, sync_playwright

config = {}
report = {"passed": False, "views": [], "javascript_errors": [], "failed_assets": [], "blocked_writes": 0, "production_content_submitted": False}


def emit(value):
    print(json.dumps(value, ensure_ascii=False), flush=True)


def readonly(route):
    request = route.request
    path = urlsplit(request.url).path
    if path.startswith("/message-bus/"):
        route.fulfill(status=200, content_type="application/json", body="[]")
    elif request.method not in ["GET", "HEAD"]:
        report["blocked_writes"] += 1
        report.setdefault("blocked_write_paths",[]).append(path)
        route.fulfill(status=200, content_type="application/json", body='{"success":true,"draft_sequence":1}')
    else:
        emit({"rpc": True, "url": request.url, "method": request.method, "headers": {key:value for key,value in request.headers.items() if key.lower() in ["accept","user-agent","x-requested-with"]}, "resource": request.resource_type})
        response = json.loads(sys.stdin.readline())
        if response.get("error"):
            route.abort()
        else:
            route.fulfill(status=response["status"], headers=response["headers"], body=base64.b64decode(response["body"]))


previous=json.loads(Path('/review/production-browser.json').read_text()) if '--mobile-only' in sys.argv else None
if previous:
 report['views']=[v for v in previous['views'] if not v['mobile'] and v.get('passed')]
expected=['learning_resources','library','courses','careers','resume','campus_services','student_identity','alumni','marketplace','teamup']
with sync_playwright() as playwright:
 browser=None
 try:
  for mobile in ([True] if previous else [False,True]):
   browser=playwright.chromium.launch(executable_path='/tools/chromium-1234/chrome-linux64/chrome',headless=True,args=['--no-sandbox','--no-zygote','--disable-dev-shm-usage','--disable-gpu','--renderer-process-limit=1','--num-raster-threads=1','--v8-pool-size=1','--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate','--js-flags=--max-old-space-size=256','--no-proxy-server'])
   agent=f"Mozilla/5.0 ({'Linux; Android 13; Pixel 7' if mobile else 'X11; Linux x86_64'}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{browser.version} {'Mobile ' if mobile else ''}Safari/537.36"
   context=browser.new_context(viewport={'width':390 if mobile else 1440,'height':844 if mobile else 900},is_mobile=mobile,has_touch=mobile,user_agent=agent,locale='zh-CN',service_workers='block')
   context.route('**/*',readonly)
   page=context.new_page();page.set_default_timeout(45000)
   page.on('pageerror',lambda error:report['javascript_errors'].append(str(error)))
   page.on('console',lambda message:emit({'console':message.text[:1800]}) if message.type=='error' else None)
   page.on('response',lambda response:report['failed_assets'].append({'path':urlsplit(response.url).path,'status':response.status}) if response.status>=400 and response.request.resource_type in ['script','stylesheet'] else None)
   view={'mobile':mobile,'checks':[]};report['views'].append(view)
   def check(condition,label):
    assert condition,label
    view['checks'].append(label);emit({'mobile':mobile,'check':label})
   response=page.goto('https://isbf-one.com/isbf/workbench',wait_until='domcontentloaded',timeout=90000)
   check(response.status==200,'workbench document loads')
   page.wait_for_selector('.isbf-v2-workbench__card[data-service=teamup]')
   data=page.locator('.isbf-v2-workbench__card').evaluate_all("nodes=>nodes.map(n=>({key:n.dataset.service,w:n.getBoundingClientRect().width,h:n.getBoundingClientRect().height,href:n.getAttribute('href')}))")
   check([n['key'] for n in data]==expected,'ten entries retain original order')
   check(all(abs(n['w']-n['h'])<1 for n in data),'all cards are square')
   columns=page.locator('.isbf-v2-workbench__grid').evaluate("n=>getComputedStyle(n).getPropertyValue('--workbench-columns').trim()")
   check(columns==('2' if mobile else '5'),'expected two or five columns')
   check(all(p in [n['href'] for n in data] for p in ['/isbf/learning','/isbf/library','/isbf/careers','/isbf/workbench/resume','/isbf/alumni','/isbf/marketplace','/isbf/teamup']),'all seven existing feature links remain available')
   page.wait_for_function("document.querySelector('symbol[id^=isbf-workbench-bag-]')?.getAttribute('viewBox') === '-16 -48 480 544'",timeout=15000)
   check(page.evaluate("document.querySelector('symbol[id^=isbf-workbench-bag-]')?.getAttribute('viewBox')")=='-16 -48 480 544','marketplace handle has a scoped corrected viewport')
   page.evaluate("() => {window.workbenchMotions=[];const original=Element.prototype.animate;Element.prototype.animate=function(...args){window.workbenchMotions.push({key:this.closest('[data-service]')?.dataset.service,duration:args[1]?.duration});return original.apply(this,args)}}")
   group=page.locator('a[data-service=teamup]');group.scroll_into_view_if_needed()
   if mobile:
    with page.expect_response(lambda response:urlsplit(response.url).path=='/filter.json' and 'teamup' in response.url) as teams:
     group.tap()
    check(teams.value.status==200,'existing group data request completes')
    page.wait_for_selector('.isbf-teamup')
    check(page.evaluate("window.workbenchMotions.some(m=>m.key==='teamup'&&m.duration===320)"),'touch click plays the group icon and follows the real link')
    page.evaluate("window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/isbf/workbench')");page.wait_for_selector('[data-service=teamup]')
   else:
    group.hover();check(page.evaluate("window.workbenchMotions.some(m=>m.key==='teamup'&&m.duration===320)"),'mouse hover animates the group icon')
    page.wait_for_timeout(400);check(group.locator('.d-icon').evaluate('n=>n.getAnimations().length')==0,'hover feedback finishes without looping')
   if not mobile:
    page.set_viewport_size({'width':768,'height':900})
    page.screenshot(path='/review/production-tablet.png',full_page=True)
    page.set_viewport_size({'width':1440,'height':900})
   page.screenshot(path=str(Path('/review')/('production-mobile.png' if mobile else 'production-desktop.png')),full_page=True)
   with page.expect_response(lambda response:urlsplit(response.url).path=='/filter.json') as products:
    page.locator('a[data-service=marketplace]').click(no_wait_after=True)
   check(products.value.status==200,'marketplace data request completes')
   count=len(products.value.json()['topic_list']['topics'])
   page.locator('.isbf-marketplace [role=status]').wait_for(state='hidden')
   expect(page.locator('.isbf-marketplace-card')).to_have_count(count)
   check(count>0 and page.locator('.isbf-marketplace [role=alert]').count()==0,'existing marketplace products finish rendering')
   page.evaluate("window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/isbf/workbench')");page.wait_for_selector('[data-service=alumni]')
   page.locator('a[data-service=alumni]').click(no_wait_after=True)
   page.locator('.isbf-alumni-map__canvas.leaflet-container').wait_for(timeout=60000)
   check(True,'existing alumni map finishes initialization')
   view['passed']=True
   context.close();browser.close();browser=None
  assert not report['javascript_errors'],report['javascript_errors']
  assert not report['failed_assets'],report['failed_assets']
  report['passed']=True
 finally:
  if browser:
   try:
    report['diagnostic']={'url':page.url,'body':page.locator('body').inner_text(timeout=5000)[-3500:],'classes':page.locator('body').get_attribute('class')}
    page.screenshot(path='/review/production-failure.png',full_page=False)
   except Exception: pass
   browser.close()
  Path('/review/production-browser.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
  emit({'passed':report['passed'],'views':len(report['views']),'production_content_submitted':False})
