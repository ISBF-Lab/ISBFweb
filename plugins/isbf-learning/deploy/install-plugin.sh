#!/usr/bin/env bash
set -euo pipefail
commit=${1:?merged commit required}
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || exit 1
source="/shared/isbf-learning-releases/$commit/isbf-learning"
target=/var/www/discourse/plugins/isbf-learning
test -f "$source/plugin.rb"
test "$(cat "$source/.release-commit")" = "$commit"
if test -L "$target"; then
  test "$(readlink "$target")" = "$source"
else
  test ! -e "$target"
  ln -s "$source" "$target"
fi
install -d -m 700 -o discourse -g discourse /shared/isbf-learning-private
