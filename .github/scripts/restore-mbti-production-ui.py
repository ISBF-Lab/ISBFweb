#!/usr/bin/env python3
"""Restore an audited public UI fixture only inside GitHub Actions."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import subprocess


ALLOWED_PREFIXES = (
    "frontend/discourse/",
    "app/assets/stylesheets/common/components/",
)
ALLOWED_SUFFIXES = {".js", ".gjs", ".ts", ".gts", ".scss"}


def _hash(data):
    return hashlib.sha256(data).hexdigest()


def _valid_hash(value, length):
    return isinstance(value, str) and re.fullmatch(rf"[0-9a-f]{{{length}}}", value)


def _assert_no_links(path):
    for candidate in (path, *path.parents):
        if candidate.is_symlink() or (
            hasattr(candidate, "is_junction") and candidate.is_junction()
        ):
            raise ValueError("Fixture roots and paths must not contain symbolic links")
        if candidate != path and candidate.exists() and not candidate.is_dir():
            raise ValueError("Fixture path ancestors must be directories")


def _root(path):
    path = Path(os.path.abspath(path))
    _assert_no_links(path)
    if not path.is_dir():
        raise ValueError("Fixture source and target must be existing directories")
    return path


def _relative_path(value):
    if (
        not isinstance(value, str)
        or not value
        or "\\" in value
        or ":" in value
        or "\0" in value
        or PurePosixPath(value).is_absolute()
        or PureWindowsPath(value).drive
        or any(part in {"", ".", ".."} for part in value.split("/"))
    ):
        raise ValueError("Fixture entries require safe relative POSIX paths")
    path = PurePosixPath(value)
    if not value.startswith(ALLOWED_PREFIXES) or path.suffix not in ALLOWED_SUFFIXES:
        raise ValueError("Fixture entry is outside the allowed public UI paths")
    return path


def _entries(manifest):
    if not isinstance(manifest, dict):
        raise ValueError("Fixture manifest must be an object")
    for field in ("core_head", "source_commit"):
        if not _valid_hash(manifest.get(field), 40):
            raise ValueError(f"Fixture manifest requires a valid {field}")
    if not _valid_hash(manifest.get("audit_sha256"), 64):
        raise ValueError("Fixture manifest requires the audit SHA256")
    if not isinstance(manifest.get("observed_date"), str) or not re.fullmatch(
        r"\d{4}-\d{2}-\d{2}", manifest["observed_date"]
    ):
        raise ValueError("Fixture manifest requires an observation date")
    entries = manifest.get("files")
    if not isinstance(entries, list) or not entries:
        raise ValueError("Fixture manifest requires a nonempty files list")
    seen = set()
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError("Fixture file entry must be an object")
        relative = _relative_path(entry.get("path"))
        if relative in seen:
            raise ValueError("Fixture paths must be unique")
        seen.add(relative)
        if not _valid_hash(entry.get("sha256"), 64):
            raise ValueError("Fixture file requires a valid source SHA256")
        if "base_sha256" not in entry or (
            entry["base_sha256"] is not None
            and not _valid_hash(entry["base_sha256"], 64)
        ):
            raise ValueError("Fixture file requires a base SHA256 or explicit null")
    return entries


def restore_files(manifest, source, target):
    """Validate the complete fixture before restoring only its declared public files."""
    entries = _entries(manifest)
    source = _root(source)
    target = _root(target)
    if source == target or source in target.parents or target in source.parents:
        raise ValueError("Fixture source and target must be separate checkouts")
    prepared = []
    for entry in entries:
        relative = _relative_path(entry["path"])
        source_file = source.joinpath(*relative.parts)
        target_file = target.joinpath(*relative.parts)
        _assert_no_links(source_file)
        _assert_no_links(target_file)
        if not source_file.is_file():
            raise ValueError(f"Source file is missing: {relative}")
        content = source_file.read_bytes()
        if _hash(content) != entry["sha256"]:
            raise ValueError(f"Source hash differs from the audit: {relative}")
        if target_file.exists() and not target_file.is_file():
            raise ValueError(f"Target is not a regular file: {relative}")
        actual = _hash(target_file.read_bytes()) if target_file.exists() else None
        if actual not in {entry["base_sha256"], entry["sha256"]}:
            raise ValueError(f"Target differs from the pinned base: {relative}")
        prepared.append((entry, target_file, content, actual == entry["sha256"]))

    receipt = []
    for entry, destination, content, unchanged in prepared:
        if not unchanged:
            destination.parent.mkdir(parents=True, exist_ok=True)
            _assert_no_links(destination)
            destination.write_bytes(content)
        receipt.append(
            {
                "path": entry["path"],
                "sha256": entry["sha256"],
                "status": "unchanged" if unchanged else "restored",
            }
        )
    return {
        "core_head": manifest["core_head"],
        "source_commit": manifest["source_commit"],
        "audit_sha256": manifest["audit_sha256"],
        "files": receipt,
    }


def _head(path):
    try:
        return subprocess.run(
            ["git", "-C", str(path), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise ValueError("Could not confirm the local checkout HEAD") from error


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--target", required=True, type=Path)
    args = parser.parse_args(argv)
    if os.environ.get("GITHUB_ACTIONS") != "true":
        parser.error("This fixture restoration runs only in GitHub Actions")
    try:
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        _entries(manifest)
        source = _root(args.source)
        target = _root(args.target)
        if _head(source) != manifest["source_commit"]:
            raise ValueError("Source HEAD differs from the audited source commit")
        if _head(target) != manifest["core_head"]:
            raise ValueError("Target HEAD differs from the pinned Core commit")
        receipt = restore_files(manifest, source, target)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(receipt, separators=(",", ":"), sort_keys=True))


if __name__ == "__main__":
    main()
