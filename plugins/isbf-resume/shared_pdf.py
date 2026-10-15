"""Validate a private PDF, or render one requested page without changing the PDF."""

from pathlib import Path
import argparse
import json
import math
import os
import subprocess
import sys

from pypdf import PdfReader
from pypdf.errors import PdfReadError

MAX_BYTES = 10 * 1024 * 1024
MAX_PAGES = 100
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def validate_pdf(directory: Path) -> int:
    source = directory / "resume.pdf"
    if source.is_symlink() or not source.is_file() or source.stat().st_size == 0:
        raise ValueError("invalid_pdf")
    if source.stat().st_size > MAX_BYTES:
        raise ValueError("pdf_too_large")
    with source.open("rb") as stream:
        if stream.read(5) != b"%PDF-":
            raise ValueError("invalid_pdf")
        reader = PdfReader(stream, strict=True)
        if reader.is_encrypted:
            raise ValueError("pdf_encrypted")
        count = len(reader.pages)
        if count > MAX_PAGES:
            raise ValueError("pdf_too_many_pages")
        if count == 0:
            raise ValueError("invalid_pdf")
        for page in reader.pages:
            dimensions = (float(page.mediabox.width), float(page.mediabox.height))
            if any(not math.isfinite(dimension) or dimension <= 0 for dimension in dimensions):
                raise ValueError("invalid_pdf")
    return count


def render_page(directory: Path, page: int, output: Path) -> None:
    if output.parent != directory or not output.name.startswith("render-") or output.suffix != ".png":
        raise ValueError("preview_failed")
    if output.exists() or output.is_symlink():
        raise ValueError("preview_failed")
    subprocess.run(
        [
            "pdftoppm", "-f", str(page), "-l", str(page), "-singlefile",
            "-scale-to", "1400", "-png", str(directory / "resume.pdf"), str(output.with_suffix("")),
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=20,
        check=True,
    )
    if output.is_symlink() or not output.is_file():
        raise ValueError("preview_failed")
    with output.open("rb") as image:
        if image.read(8) != PNG_SIGNATURE:
            raise ValueError("preview_failed")
    output.chmod(0o600)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--page", type=int)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    os.umask(0o077)
    if sys.platform == "linux":
        import resource
        resource.setrlimit(resource.RLIMIT_AS, (256 * 1024 * 1024, 256 * 1024 * 1024))
        resource.setrlimit(resource.RLIMIT_CPU, (22, 24))
    try:
        count = validate_pdf(args.directory)
        if args.page is not None:
            if not 1 <= args.page <= count or args.output is None:
                raise ValueError("preview_failed")
            render_page(args.directory, args.page, args.output)
        print(json.dumps({"pages": count, "page": args.page}))
        return 0
    except ValueError as error:
        code = str(error)
        if code not in {"invalid_pdf", "pdf_too_large", "pdf_encrypted", "pdf_too_many_pages", "preview_failed"}:
            code = "invalid_pdf"
    except PdfReadError:
        code = "invalid_pdf"
    except subprocess.TimeoutExpired:
        code = "preview_timeout"
    except Exception:
        code = "preview_failed" if args.page is not None else "pdf_validation_failed"
    print(json.dumps({"error": code}))
    return 2


if __name__ == "__main__":
    sys.exit(main())
