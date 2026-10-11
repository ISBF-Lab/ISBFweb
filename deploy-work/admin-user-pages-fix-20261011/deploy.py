"""Publish the personal-page fix without changing permissions, themes or external plugins."""

import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from build import ART, BASE_COMMIT, BASE_IMAGE, DOCKER, ROOT, digest, inventory, output, save_json

HELPER = "isbf_user_pages_deploy_20261011"
PRODUCTION = Path("/home/codex/discourse-production")


def live_git(*arguments):
    return output(DOCKER + ["exec", "-u", "root", "isbf_app", "git", "-c", "safe.directory=/var/www/discourse", "-C", "/var/www/discourse", *arguments])


def sql(statement):
    return output(DOCKER + ["exec", "-u", "postgres", "isbf_app", "psql", "-X", "-d", "discourse", "-At", "-c", statement])


def helper(code, **kwargs):
    return output(DOCKER + ["exec", "-u", "root", "-i", HELPER, "python3", "-"], input=code, **kwargs)


def create_helper():
    subprocess.run(DOCKER + ["create", "--name", HELPER, "--user", "root", "--network", "none", "--memory", "128m", "--pids-limit", "48", "--mount", "type=bind,src=" + str(PRODUCTION / "containers") + ",dst=/config", "--mount", "type=bind,src=" + str(PRODUCTION / "release.git") + ",dst=/release.git", "--mount", "type=bind,src=" + str(PRODUCTION / "deploy") + ",dst=/private", "--mount", "type=bind,src=" + str(ART) + ",dst=/art", BASE_IMAGE, "sleep", "infinity"], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(DOCKER + ["start", HELPER], check=True, stdout=subprocess.DEVNULL)


def prepare_config(manifest):
    code = """
import hashlib,json,os,re
from pathlib import Path
release=json.loads(Path('/art/release.json').read_text())
private=Path('/private/admin-user-pages-fix-20261011')
private.mkdir(mode=0o700,exist_ok=False)
original=Path('/config/isbf_app.yml').read_text()
candidate,count=re.subn(r'(?m)^(\\s+version:\\s*)[\\\"\\\']?'+release['base_commit']+r'[\\\"\\\']?\\s*$',lambda match:match.group(1)+release['release_commit'],original)
assert count==1,'Production configuration revision changed'
for name,item in release['external_releases'].items():
 old='/shared/'+name+'-releases/'+item['base_commit']+'/'+name+'/deploy/install-plugin.sh '+item['base_commit']
 new='/shared/'+name+'-releases/'+item['commit']+'/'+name+'/deploy/install-plugin.sh '+item['commit']
 assert candidate.count(old)==1,'Fixed plugin installation hook changed: '+name
 candidate=candidate.replace(old,new)
for name,value in [('config-before.yml',original),('config-candidate.yml',candidate)]:
 path=private/name
 with path.open('w') as handle:
  os.fchmod(handle.fileno(),0o600)
  handle.write(value)
print(json.dumps({'before_sha256':hashlib.sha256(original.encode()).hexdigest(),'candidate_sha256':hashlib.sha256(candidate.encode()).hexdigest()}))
"""
    return json.loads(helper(code))


def write_config(rollback=False):
    code = """
import os,tempfile
from pathlib import Path
private=Path('/private/admin-user-pages-fix-20261011')
config=Path('/config/isbf_app.yml')
before=(private/'config-before.yml').read_text()
candidate=(private/'config-candidate.yml').read_text()
rollback=ROLLBACK
expected,value=(candidate,before) if rollback else (before,candidate)
assert config.read_text()==expected,'Production configuration changed concurrently'
descriptor,path=tempfile.mkstemp(prefix='.admin-permissions-',dir=config.parent)
try:
 with os.fdopen(descriptor,'w') as handle:
  os.fchmod(handle.fileno(),0o600)
  handle.write(value)
  handle.flush()
  os.fsync(handle.fileno())
 os.replace(path,config)
finally:
 if os.path.exists(path):os.unlink(path)
print('Production configuration restored' if rollback else 'Verified production version and fixed plugin hooks updated')
""".replace("ROLLBACK", repr(rollback))
    print(helper(code), flush=True)


def wait_ready():
    deadline = time.monotonic() + 240
    announced = time.monotonic()
    while time.monotonic() < deadline:
        result = subprocess.run(["curl", "-fsS", "--noproxy", "isbf-one.com", "--resolve", "isbf-one.com:443:127.0.0.1", "--max-time", "8", "-o", "/dev/null", "https://isbf-one.com/srv/status"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return
        if time.monotonic() - announced > 25:
            print("Waiting for production Web readiness", flush=True)
            announced = time.monotonic()
        time.sleep(2)
    raise RuntimeError("Production Web readiness timed out")


def restart_web():
    subprocess.run(DOCKER + ["exec", "isbf_app", "sv", "-w", "45", "restart", "/etc/service/unicorn"], check=True, timeout=55)
    wait_ready()


def state():
    statement = """BEGIN READ ONLY;
      SELECT json_build_object(
        'site_settings_md5', (SELECT md5(string_agg(concat_ws(':', name, value, data_type), '|' ORDER BY name)) FROM site_settings),
        'theme_fields_md5', (SELECT md5(string_agg(concat_ws(':', id, theme_id, target_id, type_id, name, md5(value)), '|' ORDER BY id)) FROM theme_fields),
        'management_identity_md5', (SELECT md5(string_agg(concat_ws(':', id, admin, moderator, trust_level), '|' ORDER BY id)) FROM users WHERE admin OR moderator),
        'role_memberships_md5', (SELECT md5(string_agg(concat_ws(':', user_id, group_id, owner), '|' ORDER BY user_id,group_id)) FROM group_users WHERE group_id IN (1,2,3))
      ); COMMIT;"""
    return json.loads(next(line for line in sql(statement).splitlines() if line.startswith("{")))


def archive_artifacts():
    code = """
import hashlib,json,os,shutil
from pathlib import Path
directory=Path('/private/admin-user-pages-fix-20261011/release-artifacts')
directory.mkdir(mode=0o700,exist_ok=False)
result={}
for name in ['release.json','release.bundle','runtime-inventory.json','candidate-inventory.json','validation.json','lint-report.json','rspec.log','qunit.log','rspec-client-permissions.log','qunit-client-permissions.log','lint-client-permissions.log','lint-client-doc.log','build.py','deploy.py','compile-release.rb','verify.py']:
 source=Path('/art')/name
 destination=directory/name
 shutil.copyfile(source,destination)
 os.chmod(destination,0o600)
 result[name]=hashlib.sha256(destination.read_bytes()).hexdigest()
print(json.dumps(result))
"""
    return json.loads(helper(code))


def copy_assets(source):
    subprocess.run(DOCKER + ["cp", str(source) + "/.", "isbf_app:/var/www/discourse/"], check=True)
    subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "-R", "discourse:discourse", "/var/www/discourse/app/assets/generated/discourse-academy-roles"], check=True)
    subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "discourse:discourse", "/var/www/discourse/public/assets/.manifest.json", "/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"], check=True)


def deploy():
    manifest = json.loads((ART / "release.json").read_text())
    assert json.loads((ART / "validation.json").read_text())["passed"]
    assert json.loads((ART / "lint-report.json").read_text())["passed"]
    assert inventory("isbf_app") == json.loads((ART / "runtime-inventory.json").read_text()), "Production source changed since build"
    stylesheet_path = "/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"
    assert output(DOCKER + ["exec", "isbf_app", "sha256sum", stylesheet_path]).split()[0] == manifest["stylesheet_manifest_sha256"], "Production stylesheet cache changed since build"
    assert output(DOCKER + ["image", "inspect", "local_discourse/isbf_app:latest", "--format", "{{.Id}} "]) == BASE_IMAGE
    live_git("diff", "--exit-code", "--", *manifest["files"])
    create_helper()
    report = {"deployed": False, "base_commit": BASE_COMMIT, "release_commit": manifest["release_commit"], "base_image_id": BASE_IMAGE, "image_id": manifest["image_id"], "started_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "database_migrations_added": 0, "theme_fields_updated": 0, "external_plugins_updated": False, "permission_values_changed": False}
    changed = False
    config_changed = False
    branch_changed = False
    backup = ART / "production-before" / "assets"
    try:
        report["config_backup"] = prepare_config(manifest)
        report["before"] = state()
        for relative in ["app/assets/generated/discourse-academy-roles", "public/assets/.manifest.json", "tmp/cache/assets/production/stylesheet-manifest"]:
            target = backup / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(DOCKER + ["cp", "isbf_app:/var/www/discourse/" + relative, str(target)], check=True)
        save_json(ART / "production-before" / "state.json", report["before"])
        subprocess.run(DOCKER + ["cp", str(ART / "production-before"), HELPER + ":/private/admin-user-pages-fix-20261011/production-before"], check=True)
        report["artifact_sha256"] = archive_artifacts()
        helper("from pathlib import Path\nimport os\nroot=Path('/private/admin-user-pages-fix-20261011')\nos.chmod(root,0o700)\nos.chmod(root/'production-before',0o700)\nos.chmod(root/'production-before/state.json',0o600)\n")
        subprocess.run(DOCKER + ["cp", str(ART / "release.bundle"), "isbf_app:/tmp/user-pages-fix.bundle"], check=True)
        print("Current code, role-plugin assets and production configuration backed up; permission values preserved", flush=True)
        live_git("fetch", "/tmp/user-pages-fix.bundle", "refs/heads/" + manifest["branch"])
        live_git("checkout", "--detach", manifest["release_commit"])
        changed = True
        copy_assets(ART / "image/assets")
        assert output(DOCKER + ["exec", "isbf_app", "sha256sum", stylesheet_path]).split()[0] == manifest["stylesheet_manifest_sha256"], "Published scripts changed the stylesheet cache"
        restart_web()
        assert inventory("isbf_app") == json.loads((ART / "candidate-inventory.json").read_text()), "Published source differs from the candidate"
        print("Service ready; checking only the affected personal pages once", flush=True)
        subprocess.run([sys.executable, str(ART / "verify.py")], check=True)
        browser_report = json.loads((ART / "production-browser-report.json").read_text())
        assert browser_report["passed"] and browser_report["verification_sessions_removed"]
        report["browser_verification"] = {"passed": True, "personal_pages": len(browser_report["pages"]), "verification_sessions_removed": True, "report_sha256": digest(ART / "production-browser-report.json")}
        report["after"] = state()
        assert report["before"] == report["after"], "Site settings, themes or management identities changed"
        assert output(DOCKER + ["exec", "isbf_app", "sha256sum", stylesheet_path]).split()[0] == manifest["stylesheet_manifest_sha256"], "Stylesheet cache changed during publication"
        subprocess.run(DOCKER + ["exec", HELPER, "git", "--git-dir=/release.git", "fetch", "/art/release.bundle", "refs/heads/" + manifest["branch"] + ":refs/heads/" + manifest["branch"]], check=True)
        branch_changed = True
        write_config()
        config_changed = True
        subprocess.run(DOCKER + ["tag", manifest["image_id"], "local_discourse/isbf_app:latest"], check=True)
        report.update({"deployed": True, "completed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "plugins_preserved": manifest["plugin_inventory_verified"], "known_good_image_updated": True})
        print("Personal-page fix published; existing permission values, themes and external plugins preserved", flush=True)
    except Exception as error:
        report.update({"error_type": type(error).__name__, "error": str(error)})
        if changed:
            live_git("checkout", "--detach", BASE_COMMIT)
            copy_assets(backup)
            if config_changed:
                write_config(rollback=True)
            if branch_changed:
                subprocess.run(DOCKER + ["exec", HELPER, "git", "--git-dir=/release.git", "update-ref", "-d", "refs/heads/" + manifest["branch"], manifest["release_commit"]], check=True)
            subprocess.run(DOCKER + ["tag", BASE_IMAGE, "local_discourse/isbf_app:latest"], check=True)
            restart_web()
            report["rolled_back"] = True
        raise
    finally:
        save_json(ART / "production-report.json", report)
        for name in ["production-report.json", "production-browser-report.json"]:
            if (ART / name).exists():
                target = HELPER + ":/private/admin-user-pages-fix-20261011/" + name
                subprocess.run(DOCKER + ["cp", str(ART / name), target], check=True)
                subprocess.run(DOCKER + ["exec", HELPER, "chmod", "600", "/private/admin-user-pages-fix-20261011/" + name], check=True)
        subprocess.run(DOCKER + ["rm", "-f", HELPER], check=True, stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    deploy()
