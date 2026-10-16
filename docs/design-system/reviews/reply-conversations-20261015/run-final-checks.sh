#!/bin/bash
set -euo pipefail
ruby /review/check-ruby.rb
node /review/compile.cjs
ruby /review/compile-style.rb
python3 /review/check-preview.py
