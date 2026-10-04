#!/usr/bin/env bash
set -euo pipefail

# Run only after the isolated tests, source push and database/theme backup.
commit=$1
archive_sha=$2
[[ "$commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$archive_sha" =~ ^[0-9a-f]{64}$ ]]
container=discourse_dev
archive=/home/tangency/isbf-severe-plugin-release.tar
rollback=/home/tangency/isbf-severe-rollback-20261003
release=/opt/isbf-releases/isbf-moderation/$commit

test -s "$rollback/database.dump"
test -s "$rollback/theme-4.zip"
test -s "$rollback/baseline.json"
test "$(sha256sum "$archive" | cut -d ' ' -f 1)" = "$archive_sha"
docker exec "$container" test ! -e /src/plugins/isbf-moderation
docker exec "$container" test ! -L /src/plugins/isbf-moderation
docker exec "$container" test ! -e "$release"
docker exec "$container" mkdir -p "$release"
docker cp "$archive" "$container":/tmp/isbf-severe-plugin-release.tar
docker exec "$container" tar -xf /tmp/isbf-severe-plugin-release.tar -C "$release"
docker exec "$container" chown -R discourse:discourse "$release"
docker exec "$container" ln -s "$release" /src/plugins/isbf-moderation

docker cp /home/tangency/isbf-severe-verify-plugin.rb "$container":/tmp/isbf-severe-verify-plugin.rb
docker exec -u discourse:discourse -w /src "$container" bundle exec rails runner /tmp/isbf-severe-verify-plugin.rb

pid=$(docker exec "$container" ps -eo pid,args | awk '$2 == "puma" && index($0, "tcp://0.0.0.0:3000") { print $1 }')
[[ "$pid" =~ ^[0-9]+$ ]]
docker exec "$container" sh -c "ps -o args= -p $pid | grep -q '^puma .*tcp://0.0.0.0:3000'"
docker exec "$container" kill -TERM "$pid"
for attempt in $(seq 1 30); do
  if ! docker exec "$container" test -e "/proc/$pid"; then break; fi
  sleep 1
done
docker exec "$container" test ! -e "/proc/$pid"
docker exec -d -u discourse:discourse -w /src "$container" bash -lc 'UNICORN_SIDEKIQS=0 bin/rails server -b 0.0.0.0 -p 3000 >> /tmp/isbf-rails.log 2>&1'
for attempt in $(seq 1 20); do
  if docker exec "$container" curl --silent --fail --max-time 3 http://127.0.0.1:3000/srv/status; then
    echo " Plugin $commit loaded; existing development service responding"
    exit 0
  fi
  sleep 2
done
echo "Development service did not respond; inspect /tmp/isbf-rails.log before any further change"
exit 1
