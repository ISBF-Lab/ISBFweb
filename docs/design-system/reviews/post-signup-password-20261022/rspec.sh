#!/bin/bash
set -euo pipefail
umask 002
cd /workspace
unset GEM_HOME GEM_PATH
export PGHOST=/spec-data/socket PGPORT=15432 PGUSER=postgres
export DISCOURSE_REDIS_HOST=127.0.0.1 DISCOURSE_REDIS_PORT=16379
export RAILS_ENV=test RACK_ENV=test RAILS_DB=isbf_password_setup_test
export BUNDLE_PATH=/spec-data/bundle BUNDLE_WITHOUT=development BUNDLE_WITH=test BUNDLE_FROZEN=true
export DISCOURSE_DB_HOST=/spec-data/socket DISCOURSE_DB_USERNAME=postgres DISCOURSE_DB_PORT=15432
export LOAD_PLUGINS="${ISBF_PASSWORD_SETUP_PLUGINS:-discourse-academy-roles}"
export SKIP_MULTISITE=1 DISABLE_BOOTSNAP=1 RAILS_MAX_THREADS=2 DISCOURSE_SKIP_EMAIL_SETUP=1
export RUBY_GC_HEAP_GROWTH_FACTOR=1.03 MALLOC_ARENA_MAX=2
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=/workspace
mkdir -p /spec-data/socket /spec-data/postgres /spec-data/redis /workspace/tmp /workspace/log
ln -s /var/www/discourse/public/assets /workspace/public/assets
if ! test -f /spec-data/gems-ready; then
  bundle_root="$BUNDLE_PATH/ruby/3.4.0"
  mkdir -p "$bundle_root"
  tar -xf /cached-test-gems.tar -C "$bundle_root"
  for section in gems specifications cache; do
    mkdir -p "$bundle_root/$section"
    for path in /var/www/discourse/vendor/bundle/ruby/3.4.0/"$section"/*; do
      test -e "$path" || continue
      target="$bundle_root/$section/$(basename "$path")"
      test -e "$target" || ln -s "$path" "$target"
    done
  done
  for path in /var/www/discourse/vendor/bundle/ruby/3.4.0/extensions/*/*/*; do
    test -e "$path" || continue
    relative="${path#/var/www/discourse/vendor/bundle/ruby/3.4.0/}"
    target="$bundle_root/$relative"
    mkdir -p "$(dirname "$target")"
    test -e "$target" || ln -s "$path" "$target"
  done
  touch /spec-data/gems-ready
fi
bundle check
for path in \
  plugins/discourse-academy-roles/spec/fabricators/academy_password_setup_user_fabricator.rb \
  plugins/discourse-academy-roles/spec/services/set_initial_password_spec.rb \
  plugins/discourse-academy-roles/spec/services/dismiss_password_setup_spec.rb \
  plugins/discourse-academy-roles/spec/requests/password_setup_controller_spec.rb \
  plugins/discourse-academy-roles/spec/models/password_setup_user_spec.rb \
  plugins/discourse-academy-roles/spec/serializers/password_setup_serializer_spec.rb; do
  ruby -c "$path"
done
if ! test -f /spec-data/postgres/PG_VERSION; then
  /usr/lib/postgresql/18/bin/initdb -D /spec-data/postgres -U postgres --auth=trust --no-locale -E UTF8 > /review/postgres-init.log
fi
/usr/lib/postgresql/18/bin/pg_ctl -D /spec-data/postgres -l /spec-data/postgres.log -o "-k /spec-data/socket -p 15432 -c listen_addresses='' -c shared_buffers=16MB -c max_connections=15 -c work_mem=1MB -c maintenance_work_mem=16MB" -w start
redis-server --port 16379 --bind 127.0.0.1 --maxmemory 32mb --dir /spec-data/redis --save '' --appendonly no --daemonize yes
trap 'redis-cli -p 16379 shutdown nosave || true; /usr/lib/postgresql/18/bin/pg_ctl -D /spec-data/postgres -m immediate stop || true' EXIT
if ! test -f /spec-data/schema-loaded; then
  dropdb --if-exists isbf_password_setup_test
  createdb --encoding=UTF8 --template=template0 isbf_password_setup_test
  bin/rake db:schema:load
  touch /spec-data/schema-loaded
fi
seed_marker=/spec-data/seeded
if test "$LOAD_PLUGINS" != discourse-academy-roles; then
  seed_marker="/spec-data/seeded-${LOAD_PLUGINS//,/--}"
fi
if ! test -f "$seed_marker"; then
  SCHEMA=/spec-data/structure.sql bin/rake db:migrate db:seed
  touch "$seed_marker"
fi
if test "$#" -gt 0; then
  bin/rspec --require /review/rspec-fabricators.rb "$@"
else
  bin/rspec --require /review/rspec-fabricators.rb \
    plugins/discourse-academy-roles/spec/services/set_initial_password_spec.rb \
    plugins/discourse-academy-roles/spec/services/dismiss_password_setup_spec.rb \
    plugins/discourse-academy-roles/spec/requests/password_setup_controller_spec.rb \
    plugins/discourse-academy-roles/spec/models/password_setup_user_spec.rb \
    plugins/discourse-academy-roles/spec/serializers/password_setup_serializer_spec.rb
fi
