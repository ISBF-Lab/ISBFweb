"""Validate and render a locally stored PDF for a forum resume submission."""

from pathlib import Path
import argparse
import json
import os
import subprocess
import sys

from pypdf import PdfReader

MAX_BYTES = 10 * 1024 * 1024
MAX_PAGES = 100
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def render_pdf(directory: Path) -> dict:
    source = directory / "resume.pdf"
    if source.is_symlink() or not source.is_file() or not 0 < source.stat().st_size <= MAX_BYTES:
        raise ValueError("invalid_pdf")
    with source.open("rb") as stream:
        if stream.read(5) != b"%PDF-":
            raise ValueError("invalid_pdf")
        reader = PdfReader(stream, strict=True)
        if reader.is_encrypted:
            raise ValueError("encrypted_pdf")
        count = len(reader.pages)
        if not 1 <= count <= MAX_PAGES:
            raise ValueError("invalid_pdf")
        for page in reader.pages:
            if float(page.mediabox.width) <= 0 or float(page.mediabox.height) <= 0:
                raise ValueError("invalid_pdf")
    subprocess.run(
        ["pdftoppm", "-scale-to", "1400", "-png", str(source), str(directory / "page")],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=20,
        check=True,
    )
    generated = list(directory.glob("page-*.png"))
    if len(generated) != count:
        raise ValueError("preview_failed")
    for number in range(1, count + 1):
        matching = [path for path in generated if path.stem.removeprefix("page-").lstrip("0") == str(number)]
        if len(matching) != 1:
            raise ValueError("preview_failed")
        path = matching[0]
        if path.is_symlink() or not path.is_file():
            raise ValueError("preview_failed")
        with path.open("rb") as image:
            if image.read(8) != PNG_SIGNATURE:
                raise ValueError("preview_failed")
        target = directory / f"preview-{number}.png"
        if target.exists():
            raise ValueError("preview_failed")
        path.rename(target)
        target.chmod(0o600)
    return {"pages": count}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    os.umask(0o077)
    if sys.platform == "linux":
        import resource
        resource.setrlimit(resource.RLIMIT_AS, (256 * 1024 * 1024, 256 * 1024 * 1024))
        resource.setrlimit(resource.RLIMIT_CPU, (22, 24))
    try:
        print(json.dumps(render_pdf(args.directory)))
        return 0
    except ValueError as error:
        code = str(error) if str(error) in {"invalid_pdf", "encrypted_pdf", "preview_failed"} else "invalid_pdf"
        print(json.dumps({"error": code}))
        return 2
    except Exception:
        print(json.dumps({"error": "invalid_pdf"}))
        return 2


if __name__ == "__main__":
    sys.exit(main())
