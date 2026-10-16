#!/usr/bin/env bash
set -euo pipefail
umask 0002

if [[ "${ISBF_REPLY_SQL_ENV:-}" != "clean" ]]; then
  exec env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 ISBF_REPLY_SQL_ENV=clean \
    /bin/bash /review/run-sql-check.sh
fi

export GEM_HOME=/var/www/discourse/vendor/bundle/ruby/3.4.0
export GEM_PATH="$GEM_HOME:/usr/local/lib/ruby/gems/3.4.0"
export RUBYOPT=--disable-yjit MALLOC_ARENA_MAX=2
export PGHOST=/tmp/sql-services PGPORT=55432 PGUSER=isbf_reply_sql PGDATABASE=isbf_reply_sql

pg_started=0
finish() {
  status=$?
  trap - EXIT INT TERM
  if [[ "$pg_started" == "1" ]]; then
    "$pg_bin/pg_ctl" -D /tmp/sql-pgdata -m immediate stop >/dev/null 2>&1 || true
  fi
  printf 'Synthetic SQL runner exit=%s\n' "$status"
  if [[ -f /sys/fs/cgroup/memory.peak ]]; then
    printf 'Container memory peak bytes: '
    cat /sys/fs/cgroup/memory.peak
    cat /sys/fs/cgroup/memory.events
  fi
  exit "$status"
}
trap finish EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

ruby -e 'require "active_record"; require "pg"; puts "Cached ActiveRecord #{ActiveRecord.version}, pg #{PG.library_version}"'
ruby -c /review/check-navigation-sql.rb
pg_bin=
for candidate in /usr/lib/postgresql/15/bin /usr/lib/postgresql/18/bin; do
  if [[ -x "$candidate/initdb" ]]; then
    pg_bin="$candidate"
    break
  fi
done
[[ -n "$pg_bin" ]]
mkdir -p /tmp/sql-services /tmp/sql-pgdata
"$pg_bin/initdb" -D /tmp/sql-pgdata --username=isbf_reply_sql --auth=trust --no-locale --encoding=UTF8 --wal-segsize=1 --no-sync > /review/sql-initdb.log 2>&1
cat >> /tmp/sql-pgdata/postgresql.conf <<'POSTGRES'
listen_addresses = ''
unix_socket_directories = '/tmp/sql-services'
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
"$pg_bin/pg_ctl" -D /tmp/sql-pgdata -l /tmp/sql-services/postgresql.log -w start
pg_started=1
"$pg_bin/createdb" isbf_reply_sql
ruby /review/check-navigation-sql.rb
