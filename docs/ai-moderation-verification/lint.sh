#!/bin/bash
set -euo pipefail
export GEM_HOME=/test-gems/ruby/3.4.0
export GEM_PATH="$GEM_HOME:/usr/local/lib/ruby/gems/3.4.0"
export PATH="/lint-gems/bin:$GEM_HOME/bin:$PATH"
export BUNDLE_GEMFILE=/tmp/lint/Gemfile BUNDLE_PATH=/test-gems BUNDLE_APP_CONFIG=/tmp/lint/.bundle
export BUNDLE_USER_CONFIG=/tmp/lint/bundle-config BUNDLE_USER_CACHE=/tmp/lint/bundle-cache
export RUBOCOP_CACHE_ROOT=/tmp/rubocop-cache
mkdir -p /tmp/lint
cat > /tmp/lint/Gemfile <<'GEMS'
source "https://rubygems.org"
gem "rubocop-discourse", "3.20.0"
gem "syntax_tree", "6.3.0"
GEMS
bundle lock --local
cd /workspace
ruby bin/lint --fix "$@"
cat /sys/fs/cgroup/memory.peak
