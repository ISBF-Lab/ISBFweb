#!/usr/bin/env bash
set -euo pipefail
ruby /review/compile-style.rb
node /review/compile.cjs
node /review/compile-browser.cjs
