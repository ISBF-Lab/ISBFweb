#!/bin/bash
set -euo pipefail
python3 /review/prepare.py
ruby /review/dependencies.rb
