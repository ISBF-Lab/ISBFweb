"""Preserve the implemented dialog sources and exact verification evidence."""

import hashlib
import json
import os
from pathlib import Path
import subprocess

art = Path(__file__).resolve().parent
root = art.parents[3]
before_root = root / 'deploy-work/dialog-consistency-20261020'
before = {item['path']: item['sha256'] for item in json.loads((before_root / 'before-manifest.json').read_text())}
paths = set(json.loads((art / 'lint-files.json').read_text()))
paths.update([
    'AI-AGENTS.md',
    'docs/design-system/dialogs.md',
    'docs/design-system/ui-status.md',
    'docs/design-system/tokens.md',
    'docs/design-system/components.md',
    'docs/design-system/reference-map.md',
    'docs/design-system/references/README.md',
    'docs/design-system/references/manifest.json',
])


def digest(data):
    return hashlib.sha256(data).hexdigest()


sources = []
for name in sorted(paths):
    data = (root / name).read_bytes()
    snapshot = art / 'source' / f'{name}.txt'
    snapshot.parent.mkdir(parents=True, exist_ok=True)
    snapshot.write_bytes(data)
    old_name = 'AGENTS.md' if name == 'AI-AGENTS.md' else name
    item = {'path': name, 'sha256': digest(data), 'snapshot': str(snapshot.relative_to(art))}
    if old_name in before:
        assert digest((before_root / 'before' / old_name).read_bytes()) == before[old_name]
        item.update({'before_sha256': before[old_name], 'before_snapshot': str((before_root / 'before' / old_name).relative_to(root))})
    sources.append(item)

compilation = json.loads((art / 'compilation.json').read_text())
for compiled in compilation:
    assert digest((root / compiled['file']).read_bytes()) == compiled['sha256'], compiled['file']

env = dict(os.environ)
for name in ['DOCKER_HOST', 'DOCKER_CONTEXT', 'DOCKER_TLS', 'DOCKER_TLS_VERIFY', 'DOCKER_CERT_PATH']:
    env.pop(name, None)
states = []
for name in ['isbf_dialogs_review_20261020', 'isbf_frontend_preview_20261012']:
    command = ['docker', '--host=unix:///var/run/docker.sock', 'inspect', '--format={{.State.Status}}', name]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=10)
    state = result.stdout.strip() if result.returncode == 0 else 'absent' if 'no such object' in result.stderr.lower() else 'unknown'
    states.append({'name': name, 'state': state})
assert states[0]['state'] == 'absent', states
assert states[1]['state'] in ['exited', 'absent'], states
(art / 'resource-final.json').write_text(json.dumps({'containers': states, 'production_inspected_or_used': False}, indent=2) + '\n')

evidence = []
for candidate in sorted(art.iterdir()):
    if not candidate.is_file() or candidate.name == 'source-manifest.json':
        continue
    if candidate.suffix in {'.json', '.jsonl', '.png', '.log', '.md', '.py', '.cjs', '.rb', '.yml', '.gjs'}:
        evidence.append({'path': candidate.name, 'sha256': digest(candidate.read_bytes())})

browser = json.loads((art / 'browser-report.json').read_text())
inventory = json.loads((art / 'inventory.json').read_text())
assert browser['passed'] and len(browser['checks']) == 170
assert not inventory['errors']
for name in ['lint-status.json', 'tool-lint-status.json']:
    assert json.loads((art / name).read_text())['exit_code'] == 0
assert all(item['exit_code'] == 0 for item in json.loads((art / 'policy-status.json').read_text()))
manifest = {
    'change': 'foreground-dialog-consistency-20261020',
    'git_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'source_version': digest('\n'.join(f"{item['path']} {item['sha256']}" for item in sources).encode()),
    'working_tree': 'Contains unrelated existing changes; snapshots preserve the actual complete files, not exclusive ownership of all file content',
    'before_capture': '22 original scope files captured before implementation; later added files have no before snapshot claim',
    'reference': {'path': 'reference.png', 'sha256': digest((art / 'reference.png').read_bytes())},
    'acceptance': 'User confirmed foreground frame, text actions and mobile gutters; final visual review pending',
    'production_deployed': False,
    'verification': {'browser_checks_passed': len(browser['checks']), 'source_candidates': len(inventory['inventory']), 'policy_violations': 0, 'checker_tests_passed': 4, 'native_qunit': 'Unavailable: Rails is stopped', 'native_rspec': 'Unavailable: test gems missing'},
    'sources': sources,
    'evidence': evidence,
}
(art / 'source-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'source_version': manifest['source_version'], 'sources': len(sources), 'evidence': len(evidence), 'containers': states}, ensure_ascii=False))
