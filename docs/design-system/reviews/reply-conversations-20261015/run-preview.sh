#!/bin/bash
set -euo pipefail
ruby /review/compile-style.rb
python3 /review/check-preview.py
