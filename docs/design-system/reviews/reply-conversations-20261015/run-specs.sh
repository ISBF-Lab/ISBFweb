#!/usr/bin/env bash
set -euo pipefail
umask 0002

if [[ "${ISBF_REPLY_SPEC_ENV:-}" != "clean" ]]; then
  exec env -i \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    ISBF_REPLY_SPEC_ENV=clean \
    /bin/bash /review/run-specs.sh "$@"
fi

export RAILS_ENV=test RACK_ENV=test LOAD_PLUGINS=0
export RUBYOPT=--disable-yjit MALLOC_ARENA_MAX=2 VIPS_CONCURRENCY=1 OMP_NUM_THREADS=1
export DISABLE_BOOTSNAP=1 SKIP_MULTISITE=1
export BUNDLE_GEMFILE=/tmp/spec-work/Gemfile
export BUNDLE_PATH=/var/www/discourse/vendor/bundle
export BUNDLE_APP_CONFIG=/tmp/spec-work/.bundle
export BUNDLE_USER_CONFIG=/tmp/spec-bundle-config
export BUNDLE_USER_CACHE=/tmp/spec-bundle-cache
export BUNDLE_WITHOUT=development:migrations:generic_import BUNDLE_FROZEN=true
export GEM_HOME=/var/www/discourse/vendor/bundle/ruby/3.4.0
export GEM_PATH="$GEM_HOME:/lint-gems:/usr/local/lib/ruby/gems/3.4.0"
export RAILS_DB=isbf_reply_specs PGDATABASE=isbf_reply_specs PGUSER=isbf_reply_specs
export PGHOST=/tmp/spec-services PGPORT=55432
export ISBF_SPEC_REDIS_SOCKET=/tmp/spec-services/redis.sock
export XDG_CACHE_HOME=/tmp/spec-cache XDG_CONFIG_HOME=/tmp/spec-config

started_at=$(date +%s)
pg_started=0
redis_started=0
finish() {
  status=$?
  trap - EXIT INT TERM
  if [[ "$redis_started" == "1" ]]; then
    redis-cli -s "$ISBF_SPEC_REDIS_SOCKET" shutdown nosave >/dev/null 2>&1 || true
  fi
  if [[ "$pg_started" == "1" ]]; then
    "$pg_bin/pg_ctl" -D /tmp/spec-pgdata -m immediate stop >/dev/null 2>&1 || true
  fi
  printf 'Focused RSpec runner exit=%s elapsed_seconds=%s\n' "$status" "$(( $(date +%s) - started_at ))"
  if [[ -f /sys/fs/cgroup/memory.peak ]]; then
    printf 'Container memory peak bytes: '
    cat /sys/fs/cgroup/memory.peak
  fi
  if [[ -f /sys/fs/cgroup/memory.events ]]; then
    cat /sys/fs/cgroup/memory.events
  fi
  exit "$status"
}
trap finish EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

python3 /review/prepare-spec-work.py
cd /tmp/spec-work
ruby --version
bundle check

pg_bin=
for candidate in /usr/lib/postgresql/18/bin /usr/lib/postgresql/15/bin; do
  if [[ -x "$candidate/initdb" ]]; then
    pg_bin="$candidate"
    break
  fi
done
if [[ -z "$pg_bin" ]]; then
  printf 'No cached PostgreSQL server binaries are available\n' >&2
  exit 1
fi
export PATH="$pg_bin:$PATH"
mkdir -p /tmp/spec-services /tmp/spec-pgdata
"$pg_bin/initdb" -D /tmp/spec-pgdata --username=isbf_reply_specs --auth=trust --no-locale --encoding=UTF8 --wal-segsize=1 --no-sync > /review/spec-initdb.log 2>&1
cat >> /tmp/spec-pgdata/postgresql.conf <<'POSTGRES'
listen_addresses = ''
unix_socket_directories = '/tmp/spec-services'
port = 55432
shared_buffers = '8MB'
work_mem = '1MB'
maintenance_work_mem = '8MB'
min_wal_size = '2MB'
max_wal_size = '16MB'
max_connections = 8
max_worker_processes = 0
max_parallel_workers = 0
fsync = off
full_page_writes = off
synchronous_commit = off
POSTGRES
"$pg_bin/pg_ctl" -D /tmp/spec-pgdata -l /tmp/spec-services/postgresql.log -w start
pg_started=1
redis-server --port 0 --unixsocket "$ISBF_SPEC_REDIS_SOCKET" --unixsocketperm 700 \
  --save '' --appendonly no --maxmemory 8mb --maxmemory-policy noeviction \
  --daemonize yes --pidfile /tmp/spec-services/redis.pid --logfile /tmp/spec-services/redis.log
redis_started=1
"$pg_bin/createdb" isbf_reply_specs
"$pg_bin/psql" --set=ON_ERROR_STOP=1 --quiet --file=/workspace/db/structure.sql
"$pg_bin/psql" --set=ON_ERROR_STOP=1 --quiet <<'SQL'
INSERT INTO schema_migration_details (version, created_at)
SELECT version, current_timestamp FROM schema_migrations
ON CONFLICT DO NOTHING;
SQL
ruby bin/rake db:seed > /review/spec-seed.log 2>&1

if [[ "$#" -gt 0 ]]; then
  ruby bin/rspec "$@"
else
  ruby bin/rspec \
    spec/lib/nested_replies/navigation_spec.rb \
    spec/services/nested_topic/list_roots_spec.rb \
    spec/requests/nested_topics_controller_spec.rb \
    --example 'NestedReplies::Navigation|NestedTopic::ListRoots|when replies use flat conversations|#navigation|keeps activity whispers|returns ancestor chain, target post, and siblings' \
    --format progress --format json --out /review/rspec-results.json
fi
