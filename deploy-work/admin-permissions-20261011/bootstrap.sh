#!/bin/bash
set -eu
mkdir -p /src/tmp/admin-permissions-postgres /src/log /task-tools
cp /src/deploy-work/admin-permissions-20261011/test-runtime.rb /task-tools/test-runtime.rb
chown -R postgres:postgres /src/tmp/admin-permissions-postgres
if [ ! -f /src/tmp/admin-permissions-postgres/PG_VERSION ]; then
  su postgres -s /bin/bash -c '/usr/lib/postgresql/18/bin/initdb -D /src/tmp/admin-permissions-postgres -A trust --no-locale --encoding=UTF8' > /src/tmp/admin-permissions-init.log
fi
su postgres -s /bin/bash -c '/usr/lib/postgresql/18/bin/pg_ctl -D /src/tmp/admin-permissions-postgres -l /tmp/admin-permissions-postgres.log -o "-p 15431 -h 127.0.0.1 -k /tmp -c shared_buffers=64MB -c max_connections=40" start'
redis-server --bind 127.0.0.1 --port 16431 --daemonize yes --save '' --appendonly no
createuser -h 127.0.0.1 -p 15431 -U postgres -s discourse
createdb -h 127.0.0.1 -p 15431 -U postgres -O discourse discourse_test_admin_permissions_20261011
for package in /src/frontend/*; do
  name="${package##*/}"
  if [ -d "/task-cache/frontend/$name/node_modules" ] && [ ! -e "$package/node_modules" ]; then
    ln -s "/task-cache/frontend/$name/node_modules" "$package/node_modules"
  fi
done
if [ ! -e /home/codex/discourse ]; then
  mkdir -p /home/codex
  ln -s /task-cache /home/codex/discourse
fi
cd /src
RUBYOPT=-r/task-tools/test-runtime.rb RAILS_ENV=test LOAD_PLUGINS=1 bin/rake db:migrate > tmp/admin-permissions-migrate.log 2>&1
