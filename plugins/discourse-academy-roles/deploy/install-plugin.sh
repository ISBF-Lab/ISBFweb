#!/usr/bin/env bash
set -euo pipefail

commit=${1:?merged commit required}
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || exit 1
source="/shared/isbf-academy-roles-releases/$commit/discourse-academy-roles"
target=/var/www/discourse/plugins/discourse-academy-roles
retained="/var/www/discourse/plugins/.discourse-academy-roles.bundled-before-$commit"

test -f "$source/plugin.rb"
test "$(cat "$source/.release-commit")" = "$commit"
grep -Fxq '# name: discourse-academy-roles' "$source/plugin.rb"
if test -L "$target"; then
  test "$(readlink "$target")" = "$source"
elif test -e "$target"; then
  test -d "$target"
  test -f "$target/plugin.rb"
  grep -Fxq '# name: discourse-academy-roles' "$target/plugin.rb"
  test ! -e "$retained"
  test ! -L "$retained"
  mv -- "$target" "$retained"
  if ! ln -s -- "$source" "$target"; then
    mv -- "$retained" "$target"
    exit 1
  fi
else
  ln -s -- "$source" "$target"
fi
