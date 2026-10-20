# Static Join page verification

Run only after the shared tool container's execution slot is released. Do not
start another container or a Rails server. The runner starts and closes its
loopback static server, one Chromium browser, and at most one page. It streams
original resources from the ZIP and serves integrated resources through the
current asset manifest. Browser screenshots use reduced motion and a device
scale factor of one at 1365×900 and 390×844.

```sh
docker exec \
  -e PYTHONPATH=/home/codex/discourse/deploy-work/frontend-consistency-20261012/tools/python \
  -e LD_LIBRARY_PATH=/home/codex/discourse/deploy-work/frontend-consistency-20261012/tools/libs \
  -e PYTHONDONTWRITEBYTECODE=1 \
  isbf_join_tools_20261014 \
  python3 deploy-work/isbf-join-20261014/tools/verify_join_reference.py
```

Python 3.13.5 imports the mounted greenlet 3.5.6 and Playwright successfully.
The integrated HTML receives the CSP parsed directly from PagesController.
Chromium uses software ANGLE/SwiftShader, one renderer, one raster thread,
single-threaded V8 and GC, and a 96 MiB renderer JS heap limit. A watchdog stops
this task's uniquely marked browser if the working set approaches the container
cap, an OOM event occurs, or available host memory falls below 512 MiB. Launch
requires at least 1 GiB available host memory.

Results go to `docs/design-system/references/join-20261014/browser-validation.json`
and its `screenshots/` directory. Screenshots cover the original and integrated
opening and idle contact dialog, plus the integrated error and success states.
Geometry/style comparisons use a one-pixel tolerance, and the receipt records
whether paired PNG files are byte-identical. If PNGs differ, inspect the paired
screenshots before claiming visual equivalence.

CSRF and application responses are explicitly mocked. The first application
POST returns 503, and the retry returns 201. The harness checks a cookie-backed
CSRF fetch, exact POST field names and headers, field retention, stable retry ID,
and the original success message. It never accesses a database; actual backend
behavior is covered by the separately passing 44-example RSpec suite. A scene
fallback or unsafe resource use stops the full visual comparison and is recorded
as an unvalidated fallback, never as a passing 3D scene check.
