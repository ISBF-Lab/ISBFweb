"""Prepare synthetic topic-footer content using the cached native client shell."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[4]
ART = Path(__file__).resolve().parent
fixture = json.loads((ROOT / 'docs/design-system/reviews/continue-reading-20261016/native-fixture.json').read_text())
TITLE = '校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]'
for row in fixture['topic']['suggested_topics'][:4] + [fixture['topic']['suggested_topics'][5], fixture['topic']['related_topics'][0]]:
    row.update(title=TITLE, fancy_title=TITLE, excerpt=None)
fixture['topic']['suggested_topics'][5].update(hidden=True, excerpt='Hidden text must not appear')
html = fixture['html']
native = json.loads((ROOT / 'docs/design-system/reviews/profile-previews-20261019/native-build.json').read_text())
html = re.sub(r'(<script[^>]*src=")([^"]+)("[^>]*data-discourse-entrypoint="discourse")', lambda m:m[1] + '/' + native['entrypoint'] + m[3], html)
entry = re.search(r'<script[^>]*data-discourse-entrypoint="discourse"[^>]*></script>', html)
assert entry
html = html[:entry.start()] + html[entry.end():]
theme = re.search(r'<script[^>]*data-theme-id="4"', html)
assert theme
html = html[:theme.start()] + entry[0] + html[theme.start():]
fixture['html'] = html
(ART / 'native-fixture.json').write_text(json.dumps(fixture))
(ART / 'compiled/browser-modules.js').write_text('')
(ART / 'fixture-preparation.json').write_text(json.dumps({'synthetic_content':True,'native_core_entrypoint':native['entrypoint'],'template_overrides':False,'production_backend_used':False},indent=2)+'\n')
