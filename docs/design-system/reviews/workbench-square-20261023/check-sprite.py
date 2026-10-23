"""Run the real Ember topic navigation with local fixture responses only."""

import base64
import copy
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import mimetypes
import os
from pathlib import Path
import re
import threading
from urllib.parse import parse_qs, urlsplit

from playwright.sync_api import sync_playwright

ART = Path('/review')
art = Path('/native-fixture')
work = art / 'regressions-20261016'
fixture = json.loads((work / 'native-fixture.json').read_text())
version = "candidate"
modules = (ART / f'compiled/modules-{version}.js').read_text()
style = (ART / f'compiled/{version}-light.css').read_text()
report = {'passed': False, 'version': version, 'full_ember_application': True,
          'production_backend_used': False, 'views': [], 'errors': [], 'missing_assets': []}

legacy = (art / 'regression-native-browser.py').read_text()
handlers = legacy[legacy.index('            def item(number):'):legacy.index('            server = ThreadingHTTPServer')]
handlers = '\n'.join(line[12:] if line.startswith('            ') else line for line in handlers.splitlines())
handlers = handlers.replace('value = json.loads(cached.read_text())', '''value = json.loads(cached.read_text())
        if path.startswith('/theme-javascripts/') and request.resource_type == 'script':
            original = base64.b64decode(value['body']).decode()
            exported = re.search(r'export\\{(\\w+) as compatModules,\\1 as default\\}', original)
            if exported:
                offset = exported.start()
                original = original[:offset] + '\\nwindow.isbfTimelineCachedTheme=' + exported.group(1) + ';\\n' + modules + '\\n' + original[offset:]
                return route.fulfill(status=200, content_type='application/javascript', body=original)
''')
handlers = handlers.replace('return route.fulfill(status=200, content_type="text/html", body=fixture["html"])', 'return route.fulfill(status=200, content_type="text/html", body=fixture["html"])')

expected = ['learning_resources','library','courses','careers','resume','campus_services','student_identity','alumni','marketplace','teamup']
metrics = '''() => {
 const cards=[...document.querySelectorAll('.isbf-v2-workbench__card')];
 return {keys:cards.map(c=>c.dataset.service),sizes:cards.map(c=>{const r=c.getBoundingClientRect();return [r.x,r.y,r.width,r.height]}),
 overflow:document.documentElement.scrollWidth>innerWidth,
 columns:getComputedStyle(document.querySelector('.isbf-v2-workbench__grid')).getPropertyValue('--workbench-columns').trim(),
 links:cards.filter(c=>c.matches('a')).map(c=>c.getAttribute('href'))};
}'''
os.sched_setaffinity(0, {min(os.sched_getaffinity(0))})
with sync_playwright() as playwright:
 for mobile in [False,True]:
  state={'posts':copy.deepcopy(fixture['posts']),'topic':copy.deepcopy(fixture['topic']),'save_mode':'success','saves':0}
  view={'mobile':mobile,'checks':[]};report['views'].append(view)
  exec(handlers,globals())
  native_offline=offline
  def offline(route):
   if urlsplit(route.request.url).path.startswith('/stylesheets/common_theme_4_'):
    return route.fulfill(status=200,content_type='text/css',body=style)
   return native_offline(route)
  server=ThreadingHTTPServer(('127.0.0.1',8765),Handler);server.daemon_threads=True
  serving=threading.Thread(target=server.serve_forever,daemon=True);serving.start()
  browser=playwright.chromium.launch(executable_path=os.environ['ISBF_REVIEW_CHROMIUM'],headless=True,args=['--no-sandbox','--no-zygote','--disable-dev-shm-usage','--disable-gpu','--renderer-process-limit=1','--num-raster-threads=1','--v8-pool-size=1','--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate','--js-flags=--max-old-space-size=256','--no-proxy-server'])
  context=browser.new_context(viewport={'width':390 if mobile else 1440,'height':844 if mobile else 900},is_mobile=mobile,has_touch=mobile,locale='zh-CN',service_workers='block')
  context.route('https://**/*',lambda route:route.abort())
  page=context.new_page();page.set_default_timeout(15000)
  page.on('pageerror',lambda error:report['errors'].append(str(error)))
  page.on('console',lambda message:print(json.dumps({'console':message.text[:1600]}),flush=True) if message.type=='error' else None)
  try:
   page.goto('http://127.0.0.1:8765/t/reply-fixture/314',wait_until='commit',timeout=30000)
   page.wait_for_selector('.nested-view',timeout=45000)
   page.wait_for_selector('symbol#bag-shopping',state='attached',timeout=15000)
   page.evaluate('''() => {
    window.delayedBagSymbol=document.getElementById('bag-shopping');
    window.delayedBagParent=window.delayedBagSymbol.parentNode;
    window.delayedBagSymbol.remove();
    const o=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback();
    const site=o.lookup('service:site');
    site.setProperties({isbf_alumni:{enabled:true,countries:[]},isbf_marketplace:{category_id:8,private_images:true,version:1},isbf_learning:{category_id:7,grades:[{id:1,label:'Grade 1'}]},isbf_library:{category_id:10,link_sharing:true,catalog_requests:true},isbf_careers:{category_id:11,enabled:true,version:1},isbf_teamup:{category_id:9,enabled:true,version:1}});
    o.lookup('service:site-settings').isbf_resume_enabled=true;
    window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/isbf/workbench');
   }''')
   page.wait_for_timeout(1000)
   print(json.dumps(page.evaluate("() => ({version:window.isbfTimelineSourceVersion,path:location.pathname,settings:window.moduleBroker.lookup('discourse/lib/theme-settings-store').getObjectForTheme(4),themeKeys:Object.keys(window.isbfTimelineCachedTheme||{}).length})")),flush=True)
   page.wait_for_selector('.isbf-v2-workbench__card[data-service="teamup"]',timeout=10000)
   page.wait_for_timeout(150)
   assert page.locator('symbol[id^=isbf-workbench-bag-]').count()==0
   page.evaluate('window.delayedBagParent.appendChild(window.delayedBagSymbol)')
   page.wait_for_selector('symbol[id^=isbf-workbench-bag-]',state='attached',timeout=15000)
   view['checks'].append('delayed shared sprite is corrected after the workbench mounts')
   print(json.dumps({'stage':'native_workbench_ready','mobile':mobile}),flush=True)
   assert page.evaluate('window.isbfTimelineSourceVersion')=='candidate'
   assert page.evaluate("document.querySelector('symbol[id^=isbf-workbench-bag-]').getAttribute('viewBox')")=='-16 -48 480 544'
   assert page.evaluate("document.getElementById('bag-shopping').getAttribute('viewBox')")=='0 0 448 512'
   view['checks'].append('shared original symbol remains unchanged')
   page.evaluate("window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/t/reply-fixture/314')")
   page.wait_for_selector('.isbf-v2-workbench',state='detached')
   assert page.locator('symbol[id^=isbf-workbench-bag-]').count()==0
   page.evaluate("window.delayedBagSymbol.remove();window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/isbf/workbench')")
   page.wait_for_selector('[data-service=teamup]')
   page.wait_for_timeout(150)
   assert page.locator('symbol[id^=isbf-workbench-bag-]').count()==0
   page.evaluate("window.waitingWorkbench=document.querySelector('.isbf-v2-workbench');window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/t/reply-fixture/314')")
   page.wait_for_selector('.isbf-v2-workbench',state='detached')
   page.evaluate('window.delayedBagParent.appendChild(window.delayedBagSymbol)')
   page.wait_for_timeout(150)
   assert page.evaluate("window.waitingWorkbench.querySelector('symbol[id^=isbf-workbench-bag-]')===null")
   assert page.locator('symbol[id^=isbf-workbench-bag-]').count()==0
   view['checks'].append('leaving before the shared sprite arrives cancels pending repair')
   page.evaluate("window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/isbf/workbench')")
   page.wait_for_selector('symbol[id^=isbf-workbench-bag-]',state='attached')
   assert page.locator('symbol[id^=isbf-workbench-bag-]').count()==1
   view['checks'].append('returning with a loaded sprite creates one corrected symbol')
   print(json.dumps({'mobile':mobile,'checks':len(view['checks']),'passed':True}),flush=True)
  except Exception as error:
   report['failure']=str(error)
   report['body']=page.locator('body').inner_text(timeout=5000)[-2500:]
   page.screenshot(path=str(ART/'failure.png'),full_page=False)
   raise
  finally:
   context.close();browser.close();server.shutdown();server.server_close();serving.join(timeout=5)
   (ART/'sprite-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
 assert not report['errors'],report['errors']
 assert not report['missing_assets'],report['missing_assets']
 report['passed']=True
 (ART/'sprite-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
 print(json.dumps({'passed':True,'views':len(report['views']),'errors':report['errors'],'missing_assets':report['missing_assets']}),flush=True)
