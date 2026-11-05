#!/usr/bin/env python3
"""Enable native theme CSS in the isolated production-baseline QUnit harness."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess


SOURCE_HEAD = "9ca49588e44c18957733311239a0f355314a2980"
TARGET_HEAD = "132cc95d043db01251eedf9c93b3927cd5ffee91"
VIEW = Path("app/views/qunit/qunit.html.erb")
BEFORE_SHA256 = "a2c1ff2a15c3ee3f964961efd629eb47840c716a35689711c32bf39e62314b1b"
AFTER_SHA256 = "a92b055538e80087492340a491c23fb78aa9a68e3955858c09ef955342f49ed1"
BLOCK_SHA256 = "fc97d5e4a0fa6eaf7187724958e8e54add45097520ad8def54b3fac7d10db9e6"
ANCHOR = (
    b"      <%- Discourse.find_plugin_css_assets(include_disabled: true, only: @required_plugins, mobile_view: false, desktop_view: true, request: request).each do |file| %>\n"
    b"        <%= discourse_stylesheet_link_tag(file) %>\n"
    b"      <%- end %>\n"
)
NATIVE_BLOCK = (
    b"\n"
    b"      <%- if theme_id.present? %>\n"
    b"        <%= discourse_stylesheet_link_tag(:common_theme) %>\n"
    b'        <%= discourse_stylesheet_link_tag(:mobile_theme, media: "(width < 40rem)") %>\n'
    b'        <%= discourse_stylesheet_link_tag(:desktop_theme, media: "(width >= 40rem)") %>\n'
    b"      <%- end %>\n"
)


def _hash(data):
    return hashlib.sha256(data).hexdigest()


def _safe_path(path):
    path = Path(os.path.abspath(path))
    for candidate in (path, *path.parents):
        if candidate.is_symlink() or (
            hasattr(candidate, "is_junction") and candidate.is_junction()
        ):
            raise ValueError("Harness paths must not contain symbolic links or junctions")
    return path


def _head(root):
    try:
        top = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
            check=True, capture_output=True, text=True, encoding="utf-8",
        ).stdout.strip()
        if _safe_path(top) != root:
            raise ValueError("Harness root must be a checkout root")
        return subprocess.run(
            ["git", "-C", str(root), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True, encoding="utf-8",
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise ValueError("Could not confirm harness checkout HEAD") from error


def enable_theme_styles(source, target):
    source, target = _safe_path(source), _safe_path(target)
    if source == target or source in target.parents or target in source.parents:
        raise ValueError("Source and target must be separate checkouts")
    for root, expected in ((source, SOURCE_HEAD), (target, TARGET_HEAD)):
        if not root.is_dir() or _head(root) != expected:
            raise ValueError("Harness checkout HEAD differs from its pinned commit")
    source_view, target_view = _safe_path(source / VIEW), _safe_path(target / VIEW)
    native, before = source_view.read_bytes(), target_view.read_bytes()
    if len(native) != 4400 or _hash(native) != AFTER_SHA256:
        raise ValueError("Native source bytes differ from the pinned QUnit view")
    if len(NATIVE_BLOCK) != 286 or _hash(NATIVE_BLOCK) != BLOCK_SHA256:
        raise ValueError("Native theme CSS block differs from its pinned bytes")
    if native.count(ANCHOR) != 1 or native.count(NATIVE_BLOCK) != 1:
        raise ValueError("Native source requires one exact anchor and CSS block")
    if ANCHOR + NATIVE_BLOCK not in native:
        raise ValueError("Native CSS block must immediately follow the anchor")
    unchanged = len(before) == 4400 and _hash(before) == AFTER_SHA256
    if not unchanged and (len(before) != 4114 or _hash(before) != BEFORE_SHA256):
        raise ValueError("Target bytes differ from the pinned QUnit view")
    if before.count(ANCHOR) != 1:
        raise ValueError("Target requires one exact anchor")
    proposed = before if unchanged else before.replace(ANCHOR, ANCHOR + NATIVE_BLOCK, 1)
    if proposed != native or _hash(proposed) != AFTER_SHA256:
        raise ValueError("Proposed harness must equal the pinned native source")
    if not unchanged:
        target_view.write_bytes(proposed)
    return {
        "scope": "test-only QUnit CSS harness",
        "path": VIEW.as_posix(),
        "native_source": SOURCE_HEAD,
        "target_head": TARGET_HEAD,
        "before_sha256": _hash(before),
        "after_sha256": _hash(proposed),
        "native_block_sha256": BLOCK_SHA256,
        "count": 0 if unchanged else 1,
        "wrote": not unchanged,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--target", required=True, type=Path)
    args = parser.parse_args(argv)
    try:
        if os.environ.get("GITHUB_ACTIONS") != "true":
            raise ValueError("This test-only harness runs only in GitHub Actions")
        workspace = os.environ.get("GITHUB_WORKSPACE")
        if not workspace:
            raise ValueError("GITHUB_WORKSPACE is required")
        workspace = _safe_path(workspace)
        source, target = _safe_path(args.source), _safe_path(args.target)
        if target != workspace / "discourse" or source != workspace / "production-ui-baseline":
            raise ValueError("Harness requires isolated GITHUB_WORKSPACE checkouts")
        receipt = enable_theme_styles(source, target)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(receipt, separators=(",", ":"), sort_keys=True))


if __name__ == "__main__":
    main()
