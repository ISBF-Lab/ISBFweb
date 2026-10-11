import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path('/var/www/discourse')
plugins = {}
for entry in sorted((root / 'plugins').iterdir()):
    if not entry.is_dir() and not entry.is_symlink():
        continue
    target = entry.resolve()
    item = {'link': os.readlink(entry) if entry.is_symlink() else None, 'resolved': str(target), 'files': {}, 'links': {}, 'markers': {}}
    for current, directories, files in os.walk(entry, followlinks=True):
        directories[:] = sorted(name for name in directories if name not in ['.git', 'node_modules', 'tmp'])
        for name in directories:
            path = Path(current) / name
            if path.is_symlink():
                item['links'][str(path.relative_to(entry))] = os.readlink(path)
        for name in sorted(files):
            path = Path(current) / name
            relative = str(path.relative_to(entry))
            if name == '.git':
                continue
            if path.is_symlink():
                item['links'][relative] = os.readlink(path)
            if path.is_file():
                item['files'][relative] = hashlib.sha256(path.read_bytes()).hexdigest()
    if entry.is_symlink():
        for parent in [target, *list(target.parents)[:3]]:
            marker = parent / '.release-commit'
            if marker.is_file():
                value = marker.read_text().strip()
                item['markers'][str(marker)] = value if re.fullmatch(r'[a-f0-9]{40}', value) else hashlib.sha256(marker.read_bytes()).hexdigest()
    plugins[entry.name] = item

tracked = subprocess.check_output(['git', '-c', 'safe.directory=' + str(root), '-C', str(root), 'ls-files', '-z']).decode().split('\0')
core = {}
for relative in tracked:
    if not relative or relative.startswith('plugins/'):
        continue
    path = root / relative
    core[relative] = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
head = subprocess.check_output(['git', '-c', 'safe.directory=' + str(root), '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip()
print(json.dumps({'revision': head, 'plugins': plugins, 'core': core}, sort_keys=True))
