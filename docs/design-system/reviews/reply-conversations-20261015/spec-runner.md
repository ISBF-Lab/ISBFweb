# Isolated focused Ruby regression runner

The runner uses the cached `local_discourse/isbf_app:join-20261015` image with the
same limits as other review tools: one container, 512MiB RAM with no swap,
0.5 CPU, 192 PIDs, no network, and a read-only image filesystem. PostgreSQL and
Redis run only inside that container through ephemeral Unix sockets. No
production database, environment, data directory, credentials, or Docker socket
is mounted.

The spec mode uses the cached image's unprivileged UID 1000 with the workspace
group ID. PostgreSQL requires an account in the image's passwd database; the
host's UID 1002 has no such account. Group write permissions allow only review
artifacts to be saved, while source mounts remain read-only.

Only run after the other review tool has stopped and the host has at least
1GiB available. `run-tool.py` checks host memory throughout execution, enforces
the timeout, and removes the container afterward.

```bash
ISBF_REPLY_SPEC_RUNNER=1 \
ISBF_REPLY_TOOLS_IMAGE=local_discourse/isbf_app:join-20261015 \
python3 docs/design-system/reviews/reply-conversations-20261015/run-tool.py \
  /bin/bash /review/run-specs.sh
```

Application sources, schema, and test files are mounted read-only. Public static
sources use only images, JavaScript, audio, and the immutable image's error HTML;
workspace uploads and backups are never mounted. The runner
creates a leaf symlink tree in `/tmp/spec-work`; generated files, caches, seeded
database, and service sockets stay in container tmpfs. It uses the image's cached
gems and optional migration gemspecs without downloading dependencies. A missing
dependency is a test-environment failure; the runner does not install anything.

The source's test setting provider normally selects TCP Redis on localhost.
The scratch copy of `config/application.rb` overrides only `redis_config` so it
uses the ephemeral Redis Unix socket. Repository configuration and application
behavior under test are unchanged. The runner clears inherited environment
variables before boot and explicitly sets `RAILS_ENV=test`, `LOAD_PLUGINS=0`,
and the scratch PostgreSQL database name.

The default selection includes the complete navigation and root-service specs,
the new flat conversation request cases, and the ordinary context response
regression. It excludes unrelated existing controller examples to fit the
shared-host budget. Pass explicit `bin/rspec` arguments to override that
selection. JSON results and initialization/seed logs are written to this review
directory; container memory peak and elapsed time are printed on exit.

An environment failure or resource timeout does not establish a test pass.
Never increase the 512MiB limit or start a full forum preview to bypass it.

## Recorded execution

The isolated attempt reached `bundle check` using Ruby 3.4.10. The cached image
contains the production gems, but lacks the locked test dependencies, including
RSpec, rspec-rails, Fabrication, Mocha, WebMock, Shoulda Matchers, and TestProf.
The full missing-dependency list is in `rspec-run.log` and `rspec-status.json`.
No RSpec examples ran, and neither PostgreSQL nor Redis started.

The container peaked at 54,435,840 bytes; cgroup `oom` and `oom_kill` counters
were both zero. The container was removed and the single tool slot released.
No network connection, dependency installation, resource-limit increase, or
production access was attempted. Completing these specs requires an isolated
test image with the Gemfile.lock test dependencies already installed; rerun the
same command and resource limits there.

## Supplemental SQL checks

The cached production gems can run a smaller PostgreSQL/ActiveRecord check
without booting Rails or resolving the test gem group:

```bash
ISBF_REPLY_SPEC_RUNNER=1 \
ISBF_REPLY_TOOLS_IMAGE=local_discourse/isbf_app:join-20261015 \
python3 docs/design-system/reviews/reply-conversations-20261015/run-tool.py \
  /bin/bash /review/run-sql-check.sh
```

This executed 30 checks successfully against ephemeral PostgreSQL 18.6 and
ActiveRecord 8.1.3.1. It loads the actual Navigation, TreeLoader, Sort,
HotScoreCache, and NestedTopic source, using three synthetic tables and simple
visibility actors. Checks cover ranked root indexes, 23-root pagination, pins,
100-level chains, 50-child pagination, three-reply windows, branching, deleted
parents, whisper/activity filtering, orphaned targets, and cycle termination
and deduplication. The peak was 173,756,416 bytes; both OOM counters were zero.
The Unix-socket PostgreSQL process stopped and the tool container was removed.

`navigation-sql-results.json` and `navigation-sql-run.log` record this run.
These checks validate the actual query code against PostgreSQL. They do not
exercise Rails controllers, serializers, Guardian authorization, callbacks, or
the complete RSpec suite. The RSpec dependency blocker above remains open.
