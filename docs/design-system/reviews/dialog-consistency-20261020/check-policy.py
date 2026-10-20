"""Record the final dialog policy and its focused checker regression tests."""

import json
from pathlib import Path
import subprocess

art = Path('/review')
commands = [
    ('policy', ['pnpm', 'lint:dialogs', '--report', '/review/inventory.json']),
    ('policy-tests', ['pnpm', 'exec', 'node', '--test', 'script/check-isbf-dialogs.test.mjs']),
]
results = []
for name, command in commands:
    result = subprocess.run(command, cwd='/workspace', text=True, capture_output=True)
    output = result.stdout + result.stderr
    (art / f'{name}.log').write_text(output)
    results.append({'command': command, 'exit_code': result.returncode, 'log': f'{name}.log'})
    print(output, flush=True)
(art / 'policy-status.json').write_text(json.dumps(results, indent=2) + '\n')
raise SystemExit(max(item['exit_code'] for item in results))
