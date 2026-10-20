"""Record native test attempts without starting a forum or reaching a real backend."""

import json
import os
from pathlib import Path
import subprocess

art = Path("/review")
commands = {
    "rspec": ["ruby", "bin/rspec", "plugins/isbf-notifications/spec/requests/users_controller_spec.rb"],
    "qunit": ["ruby", "bin/qunit", "--theme-name", "ISBF Campus Feed", "--qunit-path", "/theme-qunit", "--filter", "/ISBFNotifications/i"],
}
results = {"preview_forum_started": False, "production_backend_used": False}
environment = {
    **os.environ,
    "RAILS_ENV": "test", "RACK_ENV": "test", "PGHOST": "127.0.0.1",
    "PGPORT": "5432", "PGUSER": "postgres", "RAILS_DB": "isbf_notifications_isolated_test",
    "DISCOURSE_DB_HOST": "127.0.0.1", "DISCOURSE_REDIS_HOST": "127.0.0.1",
    "GEM_PATH": "/var/www/discourse/vendor/bundle/ruby/3.4.0:/lint-gems:/usr/local/lib/ruby/gems/3.4.0",
}
for name, command in commands.items():
    result = subprocess.run(command, cwd="/workspace", env=environment, capture_output=True, text=True, timeout=60)
    output = result.stdout + result.stderr
    (art / f"{name}-attempt.log").write_text(output)
    results[name] = {"command": command, "exit_code": result.returncode, "log": f"{name}-attempt.log"}
    if "Bundler::GemNotFound" in output or "Rails server not responding" in output:
        results[name]["tests_executed"] = 0
        results[name]["blocked_reason"] = (
            "Required Ruby test gems are absent in the offline image"
            if name == "rspec"
            else "No isolated Rails test server; full preview remains stopped"
        )
    print(json.dumps({"suite": name, **results[name]}), flush=True)
    print(output[-5000:], flush=True)
(art / "native-test-attempts.json").write_text(json.dumps(results, indent=2) + "\n")
