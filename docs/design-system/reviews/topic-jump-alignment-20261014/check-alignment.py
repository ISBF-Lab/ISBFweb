import json
import os
from pathlib import Path
import re
import subprocess

from playwright.sync_api import sync_playwright

ROOT = Path('/workspace')
ART = Path('/review')
subprocess.run(['ruby', str(ART / 'compile-css.rb.txt')], check=True)


def source(relative):
    return (ROOT / relative).read_text()


def block(text, selector):
    start = re.search(r'^' + re.escape(selector) + r' \{', text, flags=re.M).start()
    depth = 0
    for end in range(text.index('{', start), len(text)):
        depth += (text[end] == '{') - (text[end] == '}')
        if depth == 0:
            return text[start:end + 1]
    raise ValueError(selector)


common = source('themes/isbf-campus-feed/common/common.scss')
css = '\n'.join([
    block(common, ':root'),
    block(common, '.isbf-v2-page-header'),
    block(common, '.isbf-v2-page-header__back'),
    block(source('app/assets/stylesheets/common/base/header.scss'), '.d-header-wrap'),
    (ART / 'compiled/timeline.css').read_text(),
    'html,body{margin:0} .d-header{display:none} #main-outlet{padding-top:60px}'
    '.topic-post{border-bottom:1px solid #ddd} article{box-sizing:border-box;padding:16px;height:240px}'
    'article p{margin:12px 0} .tall article{height:900px}'
    '#topic-bottom{height:900px} .isbf-v2-page-header{left:0;width:100%}',
])

header = source('frontend/discourse/app/components/glimmer-site-header.gjs')
start = header.index('  recalculateHeaderOffset() {')
end = header.index('\n  @action\n  setupHeader()', start)
recalculate = header[start:end].strip().replace('recalculateHeaderOffset()', 'function recalculateHeaderOffset()', 1)
offset = source('frontend/discourse/app/lib/offset-calculator.js')
offset = re.sub(r'^import .+;\n', '', offset, flags=re.M)
offset = offset.replace('export default function', 'function').replace('export function', 'function')
lock = source('frontend/discourse/app/lib/lock-on.js')
lock = re.sub(r'^import .+;\n', '', lock, flags=re.M)
lock = re.sub(r'^\s*@bind\s*$', '', lock, flags=re.M)
lock = lock.replace('export default class LockOn', 'class LockOn')
script = '\n'.join([
    'const DEBUG=false;', recalculate, offset, lock,
    'const nativeHeader={header:{},_headerWrap:document.querySelector(".d-header-wrap"),'
    '_mainOutletWrapper:document.querySelector("#main-outlet-wrapper")};'
    'window.remeasure=()=>recalculateHeaderOffset.call(nativeHeader);'
    'window.jump=(number)=>{const lock=new LockOn("#post_"+number);'
    'lock._performLocking=lock._performLocking.bind(lock);lock._scrollListener=lock._scrollListener.bind(lock);'
    'lock.lock();return lock;};'
    'window.readGeometry=()=>({headerOffset:headerOffset(),'
    'headerBottom:document.querySelector(".isbf-v2-page-header").getBoundingClientRect().bottom,'
    'postTop:document.querySelector("#post_2").getBoundingClientRect().top,'
    'postBottom:document.querySelector("#post_2").getBoundingClientRect().bottom,'
    'viewportHeight:innerHeight,scrollY:scrollY,'
    'wrapperPointerEvents:getComputedStyle(nativeHeader._headerWrap).pointerEvents});',
])
posts = ''.join(f'<div class="topic-post"><article id="post_{i}"><strong>第{i}条帖子</strong><p>定位验证正文。</p><button>回复</button></article></div>' for i in range(1, 11))
html = '<!doctype html><html><meta charset="utf-8"><style>' + css + '</style><body><div class="discourse-root"><div class="d-header-wrap"><header class="d-header"></header></div><div id="main-outlet-wrapper"><div class="isbf-v2-shell--topic-feed-style"><header class="isbf-v2-page-header"><button class="isbf-v2-page-header__back">返回</button><span>帖子</span></header></div><main id="main-outlet">' + posts + '<div id="topic-bottom"></div></main></div></div><script>' + script + '</script></body></html>'
(ART / 'preview.html').write_text(html)

results = []
os.sched_setaffinity(0, {min(os.sched_getaffinity(0))})
with sync_playwright() as p:
    browser = p.chromium.launch(
        executable_path=os.environ['ISBF_REVIEW_CHROMIUM'],
        headless=True,
        args=['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--disable-software-rasterizer', '--num-raster-threads=1', '--v8-pool-size=1'],
    )
    page = browser.new_page()
    for name, width, height, mobile in [('desktop', 1440, 950, False), ('mobile', 390, 844, True)]:
        page.set_viewport_size({'width': width, 'height': height})
        page.goto('file:///review/preview.html')
        page.evaluate('(mobile)=>document.documentElement.classList.toggle("mobile-view",mobile)', mobile)
        page.evaluate('remeasure()')
        page.evaluate('window.jumpLock=jump(2)')
        page.wait_for_function('Math.abs(readGeometry().postTop-readGeometry().headerBottom)<1')
        geometry = page.evaluate('readGeometry()')
        assert geometry['headerOffset'] == 60, geometry
        assert geometry['postTop'] == geometry['headerBottom'] == 60, geometry
        assert geometry['postBottom'] <= height, geometry
        assert geometry['wrapperPointerEvents'] == 'none', geometry
        page.screenshot(path=str(ART / f'{name}-second-post.png'))
        results.append({'case': f'{name}-second-post', 'passed': True, **geometry})
        page.evaluate('jumpLock.clearLock();window.scrollTo(0,1800);remeasure();window.jumpLock=jump(2)')
        page.wait_for_function('Math.abs(readGeometry().postTop-60)<1')
        results.append({'case': f'{name}-jump-back', 'passed': True, **page.evaluate('readGeometry()')})
        page.evaluate('jumpLock.clearLock();document.querySelector("#post_2").parentElement.classList.add("tall");window.scrollTo(0,1800);remeasure();window.jumpLock=jump(2)')
        page.wait_for_function('Math.abs(readGeometry().postTop-60)<1')
        results.append({'case': f'{name}-tall-post-top', 'passed': True, **page.evaluate('readGeometry()')})
        page.evaluate('jumpLock.clearLock();document.querySelector(".isbf-v2-shell--topic-feed-style").className="other-route";remeasure()')
        assert page.evaluate('readGeometry().headerOffset') == 0
        results.append({'case': f'{name}-outside-topic', 'passed': True})
    browser.close()

(ART / 'verification.json').write_text(json.dumps({
    'scope': 'Offline real DOM geometry using compiled theme SCSS and native recalculateHeaderOffset, headerOffset and LockOn source; application framework and production forum not started.',
    'results': results,
    'human_visual_acceptance': 'Pending user review',
}, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'passed': len(results), 'desktop_mobile_second_post_top': 60}))
