#!/bin/bash
set -euo pipefail
umask 0002
python3 /review/prepare.py
export GEM_HOME=/test-gems/ruby/3.4.0
export GEM_PATH="$GEM_HOME:/usr/local/lib/ruby/gems/3.4.0"
export MAKEFLAGS=-j1
gem install --local --no-document --ignore-dependencies --install-dir "$GEM_HOME" /gem-cache/*.gem
ruby /review/dependencies.rb
cat /sys/fs/cgroup/memory.peak
