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
version = os.environ.get('ISBF_TIMELINE_VERSION', 'candidate')
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

geometry = """() => {
  const panel = document.querySelector('.isbf-topic-reading__heading')?.closest('.topic-navigation');
  if (!panel) return null;
  const sheet = panel.querySelector('.timeline-container');
  const box = panel.getBoundingClientRect();
  const style = getComputedStyle(panel);
  const sheetBox = sheet.getBoundingClientRect();
  return { className: panel.className, position: style.position, width: box.width,
    top: box.top, right: innerWidth-box.right, height:box.height,
    sheetPosition: getComputedStyle(sheet).position, sheetWidth:sheetBox.width,
    headingVisible: getComputedStyle(panel.querySelector('.isbf-topic-reading__heading')).display !== 'none',
    close: !!panel.querySelector('.isbf-topic-reading__close'), blur:style.backdropFilter,
    expanded:document.querySelector('.isbf-topic-reading__toggle')?.getAttribute('aria-expanded') };
}"""


def check_float(page):
    result = page.evaluate(geometry)
    assert result and result['expanded'] == 'true', result
    assert result['position'] == 'fixed' and result['sheetPosition'] == 'static', result
    assert result['headingVisible'] and result['close'], result
    assert 0 < result['width'] < min(320, page.viewport_size['width'] - 24), result
    assert abs(result['top'] - 72) < 1 and abs(result['right'] - 12) < 1, result
    assert result['blur'] == 'blur(24px)', result
    return result


os.sched_setaffinity(0, {min(os.sched_getaffinity(0))})
with sync_playwright() as playwright:
    for mobile in [False, True]:
        state = {'posts': copy.deepcopy(fixture['posts']), 'topic': copy.deepcopy(fixture['topic']), 'save_mode': 'success', 'saves': 0}
        view = {'mobile': mobile, 'checks': []}
        report['views'].append(view)
        exec(handlers, globals())
        native_offline = offline
        native_fulfill = LocalRoute.fulfill

        def remap_topic(value, topic_id):
            if isinstance(value, list):
                return [remap_topic(item, topic_id) for item in value]
            if not isinstance(value, dict):
                return value
            mapped = {key: remap_topic(item, topic_id) for key, item in value.items()}
            if mapped.get('topic_id') == 314:
                mapped['topic_id'] = topic_id
            if 'post_stream' in mapped and mapped.get('id') == 314:
                mapped['id'] = topic_id
                if topic_id == 316:
                    posts = copy.deepcopy(state['posts'][:3])
                    posts[0]['cooked'] = '<p>首帖定位夹具</p>' * 40
                    posts[2]['cooked'] = '<p>后续内容定位夹具</p>' * 40
                    posts = remap_topic(posts, topic_id)
                    mapped.update(is_nested_view=False, posts_count=3, highest_post_number=3, reply_count=2)
                    mapped['post_stream'] = {'posts': posts, 'stream': [post['id'] for post in posts]}
            return mapped

        def fixture_fulfill(self, status=200, content_type=None, headers=None, body=b''):
            target = getattr(self.request, 'target_topic', 314)
            if target != 314 and content_type == 'application/json':
                body = json.dumps(remap_topic(json.loads(body), target))
            return native_fulfill(self, status=status, content_type=content_type, headers=headers, body=body)

        LocalRoute.fulfill = fixture_fulfill

        def offline(route):
            request = route.request
            if urlsplit(request.url).path.startswith('/stylesheets/common_theme_4_'):
                return route.fulfill(status=200, content_type='text/css', body=style)
            match = re.search(r'/(?:t|n)/(?:reply-fixture/)?(315|316)(?:/|\.|$)', request.url)
            if match:
                request.target_topic = int(match.group(1))
                start, end = match.span(1)
                request.url = request.url[:start] + '314' + request.url[end:]
            return native_offline(route)

        server = ThreadingHTTPServer(('127.0.0.1', 8765), Handler)
        server.daemon_threads = True
        serving = threading.Thread(target=server.serve_forever, daemon=True)
        serving.start()
        browser = playwright.chromium.launch(
            executable_path=os.environ['ISBF_REVIEW_CHROMIUM'], headless=True,
            env={**os.environ, 'MALLOC_ARENA_MAX': '2', 'LP_NUM_THREADS': '1', 'OMP_NUM_THREADS': '1'},
            args=['--no-sandbox', '--no-zygote', '--disable-dev-shm-usage', '--disable-gpu', '--disable-webgl', '--disable-software-rasterizer', '--renderer-process-limit=1', '--num-raster-threads=1', '--v8-pool-size=1', '--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate', '--js-flags=--max-old-space-size=192 --max-semi-space-size=4 --optimize-for-size', '--no-proxy-server'],
        )
        try:
            context = browser.new_context(viewport={'width': 390 if mobile else 1440, 'height': 844 if mobile else 950}, is_mobile=mobile, has_touch=mobile, locale='zh-CN', service_workers='block')
            context.route('https://**/*', lambda route: route.abort())
            page = context.new_page()
            page.on('pageerror', lambda error: report['errors'].append(str(error)))
            page.goto('http://127.0.0.1:8765/t/reply-fixture/314', wait_until='commit', timeout=30000)
            page.wait_for_selector('.isbf-topic-reading__toggle', timeout=90000)
            page.set_default_timeout(12000)
            print(json.dumps({'stage': 'source_ready', 'version': version, 'mobile': mobile}), flush=True)
            assert page.evaluate('window.isbfTimelineSourceVersion') == version
            assert page.locator('.isbf-topic-reading__toggle').get_attribute('aria-expanded') == 'false'
            page.evaluate("""() => {
              window.timelineFrames=[];
              const panel=document.querySelector('.isbf-topic-reading__heading').closest('.topic-navigation');
              new MutationObserver(() => {
                if(!panel.classList.contains('topic-progress-expanded')) return;
                const box=panel.getBoundingClientRect();
                window.timelineFrames.push({classes:panel.className,position:getComputedStyle(panel).position,width:box.width,heading:getComputedStyle(panel.querySelector('.isbf-topic-reading__heading')).display});
              }).observe(panel,{attributes:true,attributeFilter:['class']});
            }""")
            for cycle in range(3):
                page.locator('.isbf-topic-reading__toggle').click()
                page.wait_for_function("document.querySelector('.isbf-topic-reading__toggle').getAttribute('aria-expanded')==='true'")
                if version == 'before':
                    page.screenshot(path=str(ART / f'before-{"mobile" if mobile else "desktop"}.png'))
                    result = page.evaluate(geometry)
                    view['observed'] = result
                    view['frames'] = page.evaluate('window.timelineFrames')
                    view['reproduced_bottom_sheet'] = not (result['position'] == 'fixed' and result['headingVisible'] and result['sheetPosition'] == 'static')
                    break
                view['checks'].append({'cycle': cycle + 1, **check_float(page)})
                page.locator('.isbf-topic-reading__close').click()
                page.wait_for_function("document.querySelector('.isbf-topic-reading__toggle').getAttribute('aria-expanded')==='false'")
            if version != 'before':
                page.locator('.isbf-topic-reading__toggle').click()
                for width, height in [(320, 568), (600, 450), (390, 844)] if mobile else [(1024, 768), (1440, 950)]:
                    page.set_viewport_size({'width': width, 'height': height})
                    view['checks'].append({'viewport': [width, height], **check_float(page)})
                page.screenshot(path=str(ART / f'candidate-{"mobile" if mobile else "desktop"}.png'))
                page.keyboard.press('Escape')
                assert page.locator('.isbf-topic-reading__toggle').get_attribute('aria-expanded') == 'false'
                print(json.dumps({'stage': 'group_reopens_and_sizes_passed', 'mobile': mobile}), flush=True)
                page.evaluate("() => { window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/t/reply-fixture/315'); }")
                page.wait_for_selector('#topic[data-topic-id="315"] .isbf-topic-reading__heading', state='attached')
                page.wait_for_selector('.isbf-topic-reading__toggle[aria-expanded="false"]')
                page.locator('.isbf-topic-reading__toggle').click()
                view['checks'].append({'topic_switch': 315, **check_float(page)})
                page.locator('.isbf-v2-page-header > span').click()
                page.wait_for_selector('.isbf-topic-reading__toggle[aria-expanded="false"]')
                view['checks'].append({'outside_close': True})
                print(json.dumps({'stage': 'topic_switch_passed', 'mobile': mobile}), flush=True)
                page.evaluate("""() => {
                  const owner=window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback();
                  owner.lookup('service:site-settings').nested_replies_enabled=false;
                  window.moduleBroker.lookup('discourse/lib/url').default.routeTo('/t/reply-fixture/316');
                }""")
                page.wait_for_selector('#topic[data-topic-id="316"]', state='attached')
                page.wait_for_selector('.isbf-topic-reading__toggle')
                page.locator('.isbf-topic-reading__toggle').click()
                view['checks'].append({'ordinary_topic': 316, **check_float(page)})
                page.evaluate("window.moduleBroker.lookup('discourse/lib/get-owner').getOwnerWithFallback().lookup('controller:topic').send('jumpToIndex',2)")
                page.wait_for_selector('#post_2', state='attached')
                page.wait_for_function("Math.abs(document.querySelector('#post_2').getBoundingClientRect().top-60)<2")
                view['checks'].append({'ordinary_second_post_top': page.locator('#post_2').bounding_box()['y']})
                view['frames'] = page.evaluate('window.timelineFrames')
                assert all(frame['position'] == 'fixed' and frame['heading'] != 'none' for frame in view['frames']), view['frames']
                view['passed'] = True
            print(json.dumps({'view': 'mobile' if mobile else 'desktop', 'version': version, 'reproduced': view.get('reproduced_bottom_sheet'), 'passed': view.get('passed')}), flush=True)
        except Exception:
            report['diagnostic'] = page.evaluate("() => ({url:location.href, topic:document.querySelector('#topic')?.dataset.topicId, toggle:document.querySelector('.isbf-topic-reading__toggle')?.outerHTML, headings:document.querySelectorAll('.isbf-topic-reading__heading').length, fixtureFailure:window.fixtureFailure})")
            page.screenshot(path=str(ART / 'failure.png'))
            raise
        finally:
            browser.close()
            server.shutdown()
            server.server_close()
            serving.join(timeout=3)
            (ART / f'browser-{version}.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    if version == 'before':
        report['passed'] = all(view.get('reproduced_bottom_sheet') for view in report['views'])
    else:
        report['passed'] = all(view.get('passed') for view in report['views'])
    assert report['passed'], report
    (ART / f'browser-{version}.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    if version != 'before':
        (ART / 'browser-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
