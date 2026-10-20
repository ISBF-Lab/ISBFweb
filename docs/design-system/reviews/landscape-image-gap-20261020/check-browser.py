"""Measure the image box itself against compiled current theme styles."""

import base64
import json
import os
from pathlib import Path

from playwright.sync_api import sync_playwright

ART = Path("/review")
report = {"passed": False, "checks": [], "layouts": [], "errors": [], "production_backend": False}


def check(condition, message):
    assert condition, message
    report["checks"].append(message)


def image(width, height):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}"><rect width="100%" height="100%" fill="#26779a"/><path d="M0 0L{width} {height}M{width} 0L0 {height}" stroke="#92d2e0" stroke-width="24"/><rect x="8" y="8" width="{width-16}" height="{height-16}" fill="none" stroke="#e0f0ed" stroke-width="16"/></svg>'
    return "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode()


def markup(width, height, identifier, classes="", delayed=False):
    source = "" if delayed else f' src="{image(width, height)}"'
    return f'<div class="lightbox-wrapper"><a class="lightbox" href="#viewer" data-image="{identifier}"><img id="{identifier}" class="{classes}" width="{width}" height="{height}" style="aspect-ratio:{width}/{height}"{source}><div class="meta"><span class="filename">image</span><span class="informations">{width}×{height}</span><span>↗</span></div></a></div>'


def bounds(page, selector):
    return page.locator(selector).evaluate("el=>{const r=el.getBoundingClientRect(),s=getComputedStyle(el);return {width:r.width,height:r.height,bottom:r.bottom,top:r.top,objectFit:s.objectFit,aspectRatio:s.aspectRatio}}")


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(executable_path=os.environ["ISBF_REVIEW_CHROMIUM"], headless=True, args=["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage", "--disable-gpu", "--renderer-process-limit=1", "--num-raster-threads=1", "--disable-site-isolation-trials", "--disable-features=BackForwardCache,MediaRouter,OptimizationHints,Translate", "--js-flags=--max-old-space-size=128 --optimize-for-size", "--no-proxy-server"])
    page = browser.new_page(viewport={"width": 1280, "height": 950}, reduced_motion="reduce")
    page.on("pageerror", lambda error: report["errors"].append(str(error)))
    try:
        for width in [1280, 390]:
            page.set_viewport_size({"width": width, "height": 950})
            for mode in ["light", "dark"]:
                results = {}
                for version in ["before", "candidate"]:
                    css = (ART / f"compiled/{version}-{mode}.css").read_text()
                    colors = (ART / f"compiled/colors-{mode}.css").read_text()
                    fixtures = markup(690, 347, "landscape") + markup(690, 388, "wide") + markup(347, 690, "portrait") + markup(690, 690, "square") + markup(690, 347, "delayed", delayed=True)
                    fixture_style = 'body{margin:0;padding:16px;font:16px system-ui;color:var(--primary);background:var(--secondary)}.fixture-card{max-width:512px;margin:auto;border:1px solid var(--primary-low);padding:16px}.isbf-feed-card__body{max-height:none}.fixture-others{margin-top:24px}.fixture-others img{margin:0}h1{font-size:18px}.fixture-card .lightbox-wrapper{display:block}#viewer{border:1px solid currentColor;padding:8px}'
                    controls = '<div class="fixture-others"><img id="emoji" class="emoji" width="20" height="20" src="' + image(20, 20) + '"><img id="thumbnail" class="thumbnail" width="100" height="60" src="' + image(100, 60) + '"><video id="video" width="640" height="360"></video><div class="d-image-grid" data-columns="2"><div class="d-image-grid-column">' + markup(347, 690, "grid1") + '</div><div class="d-image-grid-column">' + markup(690, 347, "grid2") + '</div></div></div>'
                    page.set_content(f'<html><head><style>{colors}</style><style>{css}</style><style>{fixture_style}</style></head><body><article class="fixture-card"><h1>横图显示检查</h1><div class="isbf-feed-card__body is-expanded">{fixtures}{controls}</div><div class="cooked">{markup(690,347,"topic")}</div><p>回复 · 点赞 · 收藏</p><div id="viewer" hidden>原图查看器入口</div></article></body></html>')
                    page.wait_for_function("[...document.images].filter(i=>i.id!=='delayed').every(i=>i.complete&&i.naturalWidth>0)")
                    values = {identifier: bounds(page, "#" + identifier) for identifier in ["landscape", "wide", "portrait", "square", "emoji", "thumbnail", "video", "grid1", "grid2", "topic", "delayed"]}
                    results[version] = values
                    page.locator('#landscape').hover()
                    page.locator('.fixture-card').screenshot(path=str(ART / f'{version}-{width}-{mode}.png'))
                    if version == "candidate":
                        for identifier, ratio in [("landscape", 690/347), ("wide", 690/388), ("portrait", 347/690), ("square", 1), ("delayed", 690/347)]:
                            actual = values[identifier]
                            check(abs(actual['height']-actual['width']/ratio) < 1, f'{width}px {mode}: {identifier} box follows its declared aspect ratio')
                        image_box = bounds(page, '#landscape')
                        link_box = bounds(page, '[data-image="landscape"]')
                        meta_box = bounds(page, '[data-image="landscape"] .meta')
                        check(abs(link_box['bottom']-image_box['bottom']) < 1 and abs(meta_box['bottom']-image_box['bottom']) < 1, f'{width}px {mode}: image and metadata share the same bottom edge')
                        page.locator('#delayed').evaluate('(el,src)=>el.src=src', image(690,347))
                        page.wait_for_function("document.querySelector('#delayed').naturalWidth>0")
                        loaded = bounds(page, '#delayed')
                        check(abs(loaded['height']-loaded['width']*347/690) < 1, f'{width}px {mode}: the loaded image has no internal blank space')
                        check(not page.evaluate('document.documentElement.scrollWidth>innerWidth+1'), f'{width}px {mode}: content stays within the viewport')
                before, after = results['before'], results['candidate']
                check(before['landscape']['height'] - after['landscape']['height'] > 40, f'{width}px {mode}: original landscape whitespace is reproduced and removed')
                for identifier in ['emoji','thumbnail','video','grid1','grid2','topic']:
                    check(all(abs(before[identifier][key]-after[identifier][key]) < 1 for key in ['width','height']), f'{width}px {mode}: {identifier} dimensions remain unchanged')
                report['layouts'].append({'width':width,'mode':mode,'before':before,'after':after})
                (ART/'browser-progress.json').write_text(json.dumps(report,indent=2)+'\n')
        check(not report['errors'], 'no browser errors')
        report['passed'] = True
    finally:
        (ART/'browser-report.json').write_text(json.dumps(report,indent=2)+'\n')
        browser.close()
print(json.dumps({'passed':report['passed'],'checks':len(report['checks']),'layouts':len(report['layouts'])}))
