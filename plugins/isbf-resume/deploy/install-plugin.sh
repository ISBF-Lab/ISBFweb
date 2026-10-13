#!/usr/bin/env bash
set -euo pipefail
commit=${1:?merged Core commit required}
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || exit 1
source_dir="/shared/isbf-resume-releases/$commit/isbf-resume"
target=/var/www/discourse/plugins/isbf-resume
test -f "$source_dir/plugin.rb"
test "$(cat "$source_dir/.release-commit")" = "$commit"
bash "$source_dir/deploy/install-runtime.sh"
if test -L "$target"; then
  test "$(readlink "$target")" = "$source_dir"
elif test -e "$target"; then
  # A later full Core release may already contain the plugin.
  cmp "$source_dir/plugin.rb" "$target/plugin.rb"
  cmp "$source_dir/resume_generator.py" "$target/resume_generator.py"
  cmp "$source_dir/resume_schema.json" "$target/resume_schema.json"
else
  ln -s "$source_dir" "$target"
fi
storage=${ISBF_RESUME_STORAGE_PATH:-/shared/isbf-resume-private}
if test ! -e "$storage"; then
  install -d -m 700 -o discourse -g discourse "$storage"
fi
test "$(stat -c '%a' "$storage")" = 700
test "$(stat -c '%u' "$storage")" = "$(id -u discourse)"
