"""Verify the unpacked kit using Python 3 standard libraries."""
import hashlib
import json
from pathlib import Path, PurePosixPath

root = Path(__file__).resolve().parent
manifest = json.loads((root / "MANIFEST.json").read_text(encoding="utf-8"))
for item in manifest["files"]:
    relative = PurePosixPath(item["path"])
    assert not relative.is_absolute() and ".." not in relative.parts
    source = root.joinpath(*relative.parts)
    assert source.is_file(), item["path"]
    digest = hashlib.sha256()
    with source.open("rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            digest.update(block)
    assert digest.hexdigest() == item["sha256"], item["path"]
print("Verified " + str(len(manifest["files"])) + " files; deployment " + manifest["deployment_source_version"])
