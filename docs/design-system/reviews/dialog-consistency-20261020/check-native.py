"""Record actual native-suite availability without starting a forum backend."""

import json
import os
from pathlib import Path
import subprocess

art = Path("/review")
env = {
    **os.environ,
    "RAILS_ENV": "test", "RACK_ENV": "test", "LOAD_PLUGINS": "0",
    "PGHOST": "127.0.0.1", "PGPORT": "5432", "PGUSER": "postgres",
    "RAILS_DB": "isbf_dialogs_isolated_test", "DISCOURSE_DB_HOST": "127.0.0.1",
    "DISCOURSE_REDIS_HOST": "127.0.0.1",
    "GEM_PATH": "/var/www/discourse/vendor/bundle/ruby/3.4.0:/lint-gems:/usr/local/lib/ruby/gems/3.4.0",
}
commands = {
    "qunit": ["ruby", "bin/qunit", "--theme-name", "ISBF Campus Feed", "--qunit-path", "/theme-qunit", "--filter", "/ISBF.*(Dialog consistency|ISBFV2Calendar|ISBFFrontendScope)/i"],
    "rspec": ["ruby", "bin/rspec", "themes/isbf-campus-feed/spec/system/frontend_consistency_spec.rb"],
}
results = []
for name, command in commands.items():
    try:
        result = subprocess.run(command, cwd="/workspace", env=env, capture_output=True, text=True, timeout=45)
        output = result.stdout + result.stderr
        status = result.returncode
    except subprocess.TimeoutExpired as error:
        output = str(error)
        status = 124
    (art / f"native-{name}.log").write_text(output)
    results.append({"suite": name, "command": command, "exit_code": status, "full_preview_started": False, "production_backend_used": False, "log": f"native-{name}.log"})
(art / "native-test-attempt.json").write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results), flush=True)
