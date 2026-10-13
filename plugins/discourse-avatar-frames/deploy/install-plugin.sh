#!/usr/bin/env bash
set -euo pipefail
commit="${1:?release commit required}"
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || exit 2
source="/shared/discourse-avatar-frames-releases/$commit/discourse-avatar-frames"
target="/var/www/discourse/plugins/discourse-avatar-frames"
[[ -f "$source/plugin.rb" ]] || exit 3
[[ "$(cat "$source/.release-commit")" == "$commit" ]] || exit 4
[[ ! -e "$target" || -L "$target" ]] || exit 5
ln -sfn "$source" "$target"
