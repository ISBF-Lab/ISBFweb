#!/bin/bash
set -euo pipefail
if [[ "${ISBF_AI_TEST_ENV:-}" != clean ]]; then
  exec env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin LANG=C.UTF-8 LC_ALL=C.UTF-8 ISBF_AI_TEST_ENV=clean /bin/bash /review/run-specs.sh "$@"
fi
umask 0002
export RAILS_ENV=test RACK_ENV=test LOAD_PLUGINS=1
export RUBYOPT=--disable-yjit MALLOC_ARENA_MAX=2 VIPS_CONCURRENCY=1 OMP_NUM_THREADS=1
export DISABLE_BOOTSNAP=1 SKIP_MULTISITE=1
export SKIP_OPTIMIZE_ICONS=1 SKIP_STRUCTURE_SQL=1
export BUNDLE_GEMFILE=/tmp/spec-work/Gemfile BUNDLE_PATH=/test-gems
export BUNDLE_APP_CONFIG=/tmp/spec-work/.bundle BUNDLE_USER_CONFIG=/tmp/spec-bundle-config
export BUNDLE_USER_CACHE=/tmp/spec-bundle-cache BUNDLE_WITHOUT=development:migrations:generic_import BUNDLE_FROZEN=true
export GEM_HOME=/test-gems/ruby/3.4.0 GEM_PATH=/test-gems/ruby/3.4.0:/usr/local/lib/ruby/gems/3.4.0
export RAILS_DB=isbf_ai_specs PGDATABASE=isbf_ai_specs PGUSER=isbf_ai_specs
export PGHOST=/tmp/spec-services PGPORT=55432 ISBF_SPEC_REDIS_SOCKET=/tmp/spec-services/redis.sock
export XDG_CACHE_HOME=/tmp/spec-cache XDG_CONFIG_HOME=/tmp/spec-config
export SCHEMA=/tmp/spec-structure.sql
python3 /review/prepare.py
cd /tmp/spec-work
bundle check
pg_started=0
redis_started=0
finish() {
  status=$?
  trap - EXIT INT TERM
  if [[ "$redis_started" == 1 ]]; then redis-cli -s "$ISBF_SPEC_REDIS_SOCKET" shutdown nosave >/dev/null 2>&1 || true; fi
  if [[ "$pg_started" == 1 ]]; then "$pg_bin/pg_ctl" -D /tmp/spec-pgdata -m immediate stop >/dev/null 2>&1 || true; fi
  cat /sys/fs/cgroup/memory.peak
  cat /sys/fs/cgroup/memory.events
  exit "$status"
}
trap finish EXIT
trap 'exit 143' TERM INT
pg_bin=/usr/lib/postgresql/18/bin
export PATH="$pg_bin:$PATH"
mkdir -p /tmp/spec-services /tmp/spec-pgdata
"$pg_bin/initdb" -D /tmp/spec-pgdata --username=isbf_ai_specs --auth=trust --no-locale --encoding=UTF8 --wal-segsize=1 --no-sync >/tmp/initdb.log 2>&1
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
redis-server --port 0 --unixsocket "$ISBF_SPEC_REDIS_SOCKET" --unixsocketperm 700 --save '' --appendonly no --maxmemory 32mb --daemonize yes --pidfile /tmp/spec-services/redis.pid --logfile /tmp/spec-services/redis.log
redis_started=1
"$pg_bin/createdb" isbf_ai_specs
"$pg_bin/psql" --set=ON_ERROR_STOP=1 --quiet --file=/workspace/db/structure.sql
"$pg_bin/psql" --set=ON_ERROR_STOP=1 --quiet <<'SQL'
INSERT INTO schema_migration_details (version, created_at)
SELECT version, current_timestamp FROM schema_migrations ON CONFLICT DO NOTHING;
SQL
ruby bin/rake db:migrate
ruby bin/rspec "$@" --format progress
