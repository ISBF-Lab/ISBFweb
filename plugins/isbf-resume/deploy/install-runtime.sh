#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" = 0
source_dir=$(cd "$(dirname "$0")/.." && pwd)
test -f "$source_dir/requirements.txt"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends python3-venv libreoffice-writer fonts-noto-cjk poppler-utils
if test ! -e /opt/resume-venv; then
  python3 -m venv /opt/resume-venv
fi
test -x /opt/resume-venv/bin/python
/opt/resume-venv/bin/python -m pip install --disable-pip-version-check -r "$source_dir/requirements.txt"
/opt/resume-venv/bin/python -m pip check
/opt/resume-venv/bin/python -c 'import docx, PIL, pypdf; print("Resume Python dependencies ready")'
soffice --version
pdftoppm -v
fc-match 'Noto Sans CJK SC'
