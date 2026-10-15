"""Install a fixed resume release and its narrowly scoped Academy permission delta."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


version = sys.argv[1]
assert len(version) == 40 and all(char in "0123456789abcdef" for char in version)
release = Path("/shared/isbf-resume-releases") / version
manifest = json.loads((release / "sharing-release.json").read_text())
assert manifest["commit"] == version
source = release / "isbf-resume"
assert (source / ".release-commit").read_text().strip() == version
root = Path("/var/www/discourse")
target = root / "plugins/isbf-resume"


def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


for relative, digest in manifest["resume_files"].items():
    path = source / relative
    assert not path.is_symlink() and checksum(path) == digest, relative

previous = Path(manifest["previous_resume"])
assert str(previous).startswith("/shared/isbf-resume-releases/")
if target.is_symlink():
    assert target.resolve() in (source, previous), "Unexpected resume release"
elif target.exists():
    assert target.is_dir()
    for relative, digest in manifest["resume_files"].items():
        assert checksum(target / relative) == digest, relative

for relative, entry in manifest["academy_files"].items():
    assert relative.startswith("plugins/discourse-academy-roles/")
    assert ".." not in Path(relative).parts
    destination = root / relative
    assert not destination.is_symlink()
    assert checksum(release / relative) == entry["after"]
    assert checksum(destination) in (entry["before"], entry["after"]), relative

if "--check" in sys.argv:
    print(json.dumps({"checked": True, "commit": version}))
    sys.exit(0)

dependencies = subprocess.run(
    [
        "/opt/resume-venv/bin/python",
        "-c",
        "from importlib.metadata import version; "
        "assert version('python-docx') == '1.2.0'; "
        "assert version('Pillow') == '12.3.0'; "
        "assert version('pypdf') == '6.10.0'",
    ],
    check=False,
).returncode if Path("/opt/resume-venv/bin/python").is_file() else 1
if dependencies or not all(shutil.which(name) for name in ("soffice", "pdftoppm", "fc-match")):
    subprocess.run(["bash", str(source / "deploy/install-runtime.sh")], check=True)

uid = int(subprocess.check_output(["id", "-u", "discourse"]))
gid = int(subprocess.check_output(["id", "-g", "discourse"]))
for relative, entry in manifest["academy_files"].items():
    destination = root / relative
    if checksum(destination) == entry["after"]:
        continue
    metadata = destination.stat() if destination.exists() else None
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name("." + destination.name + "-resume-" + version[:12])
    with temporary.open("xb") as stream:
        stream.write((release / relative).read_bytes())
    os.chown(temporary, metadata.st_uid if metadata else uid, metadata.st_gid if metadata else gid)
    temporary.chmod((metadata.st_mode & 0o777) if metadata else 0o644)
    assert checksum(destination) == entry["before"], relative
    os.replace(temporary, destination)

if not target.exists() or target.is_symlink() and target.resolve() != source:
    temporary = target.with_name(".isbf-resume-" + version[:12])
    temporary.symlink_to(source)
    os.replace(temporary, target)

for name, default in (
    ("ISBF_RESUME_STORAGE_PATH", "/shared/isbf-resume-private"),
    ("ISBF_RESUME_SHARING_STORAGE_PATH", "/shared/isbf-resume-shares-private"),
):
    storage = Path(os.environ.get(name, default))
    assert storage.is_absolute() and "/public/" not in str(storage)
    if not storage.exists():
        storage.mkdir(mode=0o700)
        os.chown(storage, uid, gid)
    assert storage.is_dir() and not storage.is_symlink()
    assert storage.stat().st_mode & 0o777 == 0o700 and storage.stat().st_uid == uid

# Bootsnap instruction sequences can retain an old shared release's absolute paths.
paths = {str(target / name) for name in manifest["resume_files"] if name.endswith(".rb")}
paths.update(str(root / name) for name in manifest["academy_files"] if name.endswith(".rb"))
invalidated = 0
for path in paths:
    key = 0xCBF29CE484222325
    for byte in path.encode():
        key = ((key ^ byte) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    encoded = format(key, "016x")
    for suffix in ("", "-fstr"):
        cached = root / ("tmp/cache/bootsnap/compile-cache-iseq" + suffix) / encoded[:2] / encoded[2:]
        if cached.is_file():
            cached.unlink()
            invalidated += 1

print(json.dumps({"installed": True, "commit": version, "plugin_cache_entries_invalidated": invalidated}))
