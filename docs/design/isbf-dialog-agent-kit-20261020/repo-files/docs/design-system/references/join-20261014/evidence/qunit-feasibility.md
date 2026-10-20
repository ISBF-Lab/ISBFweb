# QUnit feasibility and lightweight compilation

No Rails server, browser, or frontend asset build was started for this check.

The two `bin/qunit --dry-run` commands succeeded inside the existing capped tool
container with `TESTEM_DEFAULT_BROWSER=Chromium`, which bypasses browser
detection without starting a browser:

```sh
bin/qunit --dry-run --target isbf-join --parallel 1 \
  plugins/isbf-join/test/javascripts/acceptance/admin-applications-test.js

THEME_IDS=ISOLATED_THEME_ID bin/qunit --dry-run --target core \
  --theme-id ISOLATED_THEME_ID --qunit-path /theme-qunit \
  --module 'ISBF | Integration | Component | ISBFV2UtilityActions | Join' \
  --parallel 1
```

The first selects module file
`discourse/plugins/isbf-join/acceptance/admin-applications-test.js` through
`pnpm ember exam --path dist`. The theme runner selects its module using the
`module` query parameter and `pnpm testem ci -f testem.js`; ordinary file filters
are not forwarded on that runner path. A real isolated imported theme ID must
replace the placeholder when the test environment is available.

`frontend/discourse/dist` contains a development test entrypoint, but its
`BUILD_INFO.json` records core tree
`c2394bebb19b69d50597ff15a5ea289c6aa97451`. The clean current Git tree restricted
to `frontend`, `package.json`, and `pnpm-lock.yaml` hashes to
`ebb7c2bbfee32451ce1d6d66aa2db16657be885a`. This was computed without changing
the Git index or writing objects. The source paths have no working changes.
The normal asset assembler rejects this mismatch, so the cached build was not
used to claim browser test coverage.

There is no generated `isbf-join` plugin bundle or compiled theme bundle
containing the new Join test. The existing calendar browser harness requires a
live Rails server plus Chromium; it does not provide a static offline runner.
The full core asset assembler requests a 2048 MiB Node heap in its low-memory
path, exceeding the 512 MiB tool container budget. No compatible existing
browser-test path was established within that budget, and no stale-build guard
was bypassed.

The authorized substitute is syntax/template compilation, not behavioral QUnit
execution. `frontend-syntax-results.json` records SHA-256 and successful
in-memory Babel transforms for 11 integration/source/test files, including full
content-tag preprocessing and Ember/Glimmer compilation for the three `.gjs`
files. The check uses Node 22.23.3, Babel 7.29.7, Ember 7.2.0, and a 160 MiB Node
heap cap, emits no bundles, and does not start services. The four admin QUnit
tests and one Join menu rendering test remain unexecuted in a browser.
