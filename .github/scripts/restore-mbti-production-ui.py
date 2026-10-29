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
        or any(
            part in {"", ".", "..", "private", "uploads"} or part.startswith(".")
            for part in value.split("/")
        )
    ):
        raise ValueError("Fixture entries require safe relative POSIX paths")
    path = PurePosixPath(value)
    if not value.startswith(ALLOWED_PREFIXES) or path.suffix not in ALLOWED_SUFFIXES:
        raise ValueError("Fixture entry is outside the allowed public UI paths")
    return path


def _entries(manifest):
    if not isinstance(manifest, dict):
        raise ValueError("Fixture manifest must be an object")
    if type(manifest.get("schema", 1)) is not int or manifest.get("schema", 1) not in {1, 2}:
        raise ValueError("Unsupported fixture schema")
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
        allowed = {"path", "sha256", "base_sha256"}
        if manifest.get("schema") == 2:
            allowed |= {"source_commit", "capture"}
        if entry.keys() - allowed:
            raise ValueError("Unknown fixture source descriptor")
        if "capture" in entry and (entry["capture"] is not True or "source_commit" in entry):
            raise ValueError("Ambiguous fixture source descriptor")
        if "source_commit" in entry and not _valid_hash(entry["source_commit"], 40):
            raise ValueError("Fixture file requires a valid source commit")
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


def _preserved_entries(manifest, entries):
    preserved = manifest.get("preserved_files", [])
    if manifest.get("schema") == 2 and "preserved_files" not in manifest:
        raise ValueError("Schema 2 requires preserved_files")
    if not isinstance(preserved, list):
        raise ValueError("Preserved files must be a list")
    seen = {entry["path"] for entry in entries}
    for entry in preserved:
        if not isinstance(entry, dict) or entry.keys() != {"path", "sha256"}:
            raise ValueError("Invalid preserved file entry")
        _relative_path(entry["path"])
        if entry["path"] in seen:
            raise ValueError("Restored and preserved paths must be unique")
        seen.add(entry["path"])
        if not _valid_hash(entry["sha256"], 64):
            raise ValueError("Preserved file requires a SHA256")
    return preserved


def _audit_entries(manifest, audit, entries, preserved):
    if manifest.get("schema") != 2:
        return {}
    if not isinstance(audit, dict):
        raise ValueError("Schema 2 requires an audit object")
    canonical = json.dumps(audit, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    if _hash(canonical.encode("utf-8")) != manifest["audit_sha256"]:
        raise ValueError("Audit SHA256 differs from the manifest")
    if (
        audit.get("core_head") != manifest["core_head"]
        or not isinstance(audit.get("observed_at"), str)
        or audit["observed_at"][:10] != manifest["observed_date"]
        or not isinstance(audit.get("scope"), str)
        or not audit["scope"].strip()
        or not isinstance(audit.get("files"), list)
    ):
        raise ValueError("Audit metadata differs from the manifest")
    audited = {}
    for entry in audit["files"]:
        if not isinstance(entry, dict):
            raise ValueError("Invalid audit file entry")
        path = entry.get("path")
        _relative_path(path)
        if path in audited:
            raise ValueError("Audit paths must be unique")
        status = entry.get("status")
        if status == "hashed":
            if not _valid_hash(entry.get("sha256"), 64) or type(entry.get("bytes")) is not int or entry["bytes"] < 0:
                raise ValueError("Audit hashed files require SHA256 and byte length")
        elif status != "missing" or "sha256" in entry or "bytes" in entry:
            raise ValueError("Invalid audit file status")
        audited[path] = entry
    declared = {entry["path"] for entry in [*entries, *preserved]}
    hashed = {path for path, entry in audited.items() if entry["status"] == "hashed"}
    if hashed != declared:
        raise ValueError("Audited hashed paths must exactly match restored and preserved paths")
    for entry in [*entries, *preserved]:
        observed = audited.get(entry["path"], {})
        if observed.get("status") != "hashed" or observed.get("sha256") != entry["sha256"]:
            raise ValueError("Fixture path differs from the audit")
    return audited


def _separate_source(source, target):
    source = _root(source)
    if source == target or source in target.parents or target in source.parents:
        raise ValueError("Fixture source and target must be separate checkouts")
    return source


def restore_files(manifest, source, target, *, extra_sources=None, audit=None, capture=None):
    """Validate all sources and target baselines before writing any fixture file."""
    entries = _entries(manifest)
    preserved = _preserved_entries(manifest, entries)
    audited = _audit_entries(manifest, audit, entries, preserved)
    target = _root(target)
    source = _separate_source(source, target)
    extra_sources = {} if extra_sources is None else extra_sources
    if not isinstance(extra_sources, dict):
        raise ValueError("Extra sources must be a commit-to-directory mapping")
    required = {entry["source_commit"] for entry in entries if "source_commit" in entry}
    required.discard(manifest["source_commit"])
    if set(extra_sources) != required:
        raise ValueError("Extra sources must exactly match the declared alternate commits")
    sources = {manifest["source_commit"]: source}
    for commit, directory in extra_sources.items():
        if not _valid_hash(commit, 40):
            raise ValueError("Invalid extra source commit")
        sources[commit] = _separate_source(directory, target)
    capture_root = _separate_source(capture, target) if capture is not None else None
    for path, observed in audited.items():
        if observed["status"] == "missing":
            destination = target.joinpath(*_relative_path(path).parts)
            _assert_no_links(destination)
            if destination.exists():
                raise ValueError(f"Audited missing target must remain absent: {path}")
    prepared = []
    for entry in entries:
        relative = _relative_path(entry["path"])
        if entry.get("capture"):
            if capture_root is None:
                raise ValueError("Capture source directory is required")
            source_file = capture_root.joinpath(*relative.parts).with_suffix(relative.suffix + ".txt")
        else:
            source_file = sources[entry.get("source_commit", manifest["source_commit"])].joinpath(*relative.parts)
        target_file = target.joinpath(*relative.parts)
        _assert_no_links(source_file)
        _assert_no_links(target_file)
        if not source_file.is_file():
            raise ValueError(f"Source file is missing: {relative}")
        content = source_file.read_bytes()
        if _hash(content) != entry["sha256"]:
            raise ValueError(f"Source hash differs from the audit: {relative}")
        if audited and len(content) != audited[entry["path"]]["bytes"]:
            raise ValueError(f"Source byte length differs from the audit: {relative}")
        if target_file.exists() and not target_file.is_file():
            raise ValueError(f"Target is not a regular file: {relative}")
        actual = _hash(target_file.read_bytes()) if target_file.exists() else None
        if actual not in {entry["base_sha256"], entry["sha256"]}:
            raise ValueError(f"Target differs from the pinned base: {relative}")
        prepared.append((entry, target_file, content, actual == entry["sha256"]))
    for entry in preserved:
        destination = target.joinpath(*_relative_path(entry["path"]).parts)
        _assert_no_links(destination)
        if not destination.is_file():
            raise ValueError(f"Preserved target is missing: {entry['path']}")
        content = destination.read_bytes()
        if _hash(content) != entry["sha256"] or (audited and len(content) != audited[entry["path"]]["bytes"]):
            raise ValueError(f"Preserved target differs from the pinned base: {entry['path']}")

    receipt = []
    for entry, destination, content, unchanged in prepared:
        if not unchanged:
            destination.parent.mkdir(parents=True, exist_ok=True)
            _assert_no_links(destination)
            destination.write_bytes(content)
        record = {
            "path": entry["path"],
            "sha256": entry["sha256"],
            "status": "unchanged" if unchanged else "restored",
        }
        if manifest.get("schema") == 2:
            record["origin"] = "runtime_capture" if entry.get("capture") else "git"
            if not entry.get("capture"):
                record["source_commit"] = entry.get("source_commit", manifest["source_commit"])
        receipt.append(record)
    result = {
        "core_head": manifest["core_head"],
        "source_commit": manifest["source_commit"],
        "audit_sha256": manifest["audit_sha256"],
        "files": receipt,
    }
    if manifest.get("schema") == 2:
        result["preserved_files"] = preserved
        result["observed_at"] = audit["observed_at"]
    return result


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
    parser.add_argument("--extra-source", action="append", default=[], metavar="SHA=PATH")
    parser.add_argument("--audit", type=Path)
    parser.add_argument("--capture", type=Path)
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
        extra_sources = {}
        for mapping in args.extra_source:
            commit, separator, directory = mapping.partition("=")
            if not separator or not directory or not _valid_hash(commit, 40) or commit in extra_sources or commit == manifest["source_commit"]:
                raise ValueError("Invalid or duplicate extra source mapping")
            extra_sources[commit] = _root(directory)
        for commit, directory in extra_sources.items():
            if _head(directory) != commit:
                raise ValueError("Extra source HEAD differs from the audited source commit")
        audit = json.loads(args.audit.read_text(encoding="utf-8")) if args.audit else None
        receipt = restore_files(
            manifest, source, target, extra_sources=extra_sources, audit=audit, capture=args.capture
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(receipt, separators=(",", ":"), sort_keys=True))


if __name__ == "__main__":
    main()
