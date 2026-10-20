"""Compile and verify the current sources using one offline tool process."""

import json
import os
from pathlib import Path
import subprocess

art = Path("/review")
command = ["ruby", "bin/qunit", "--theme-name", "ISBF Campus Feed", "--qunit-path", "/theme-qunit", "--filter", "/ISBF.*(post-preview|feed-post-loader|profile previews)/i"]
env = {**os.environ, "RAILS_ENV": "test", "RACK_ENV": "test", "PGHOST": "127.0.0.1", "PGPORT": "5432", "PGUSER": "postgres", "RAILS_DB": "isbf_profile_previews_isolated_test", "DISCOURSE_DB_HOST": "127.0.0.1", "DISCOURSE_REDIS_HOST": "127.0.0.1", "GEM_PATH": "/var/www/discourse/vendor/bundle/ruby/3.4.0:/lint-gems:/usr/local/lib/ruby/gems/3.4.0"}
if not (art / "native-test-attempt.json").exists():
    result = subprocess.run(command, cwd="/workspace", env=env, capture_output=True, text=True, timeout=60)
    output = result.stdout + result.stderr
    (art / "qunit-attempt.log").write_text(output)
    native = {"command": command, "exit_code": result.returncode, "full_preview_started": False, "production_backend_used": False, "tests_executed": 0, "log": "qunit-attempt.log"}
    if "Rails server not responding" in output:
        native["blocked_reason"] = "No isolated Rails test server; full preview stays stopped"
    elif "Bundler::GemNotFound" in output or "Could not find" in output:
        native["blocked_reason"] = "Required native test dependencies are missing in the offline image"
    else:
        native["blocked_reason"] = output[-1200:]
    (art / "native-test-attempt.json").write_text(json.dumps(native, indent=2)+"\n")
    print(json.dumps(native), flush=True)
for command in [["node", "/review/compile.cjs"], ["ruby", "/review/compile-style.rb"], ["node", "/review/compile-browser.cjs"], ["python3", "/review/check-browser.py"]]:
    subprocess.run(command, cwd="/workspace", check=True)
