"""Deploy the verified candidate, preserving data and providing bounded rollback."""

import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from build import ART, BASE_COMMIT, BASE_IMAGE, DOCKER, PLUGINS_WITH_ASSETS, ROOT, digest, inventory, output, save_json

HELPER = "isbf_admin_permissions_deploy_20261011"
PRODUCTION = Path("/home/codex/discourse-production")


def live_git(*arguments):
    return output(DOCKER + ["exec", "-u", "root", "isbf_app", "git", "-c", "safe.directory=/var/www/discourse", "-C", "/var/www/discourse", *arguments])


def sql(statement):
    return output(DOCKER + ["exec", "-u", "postgres", "isbf_app", "psql", "-X", "-d", "discourse", "-At", "-c", statement])


def state():
    statement = """BEGIN READ ONLY;
      SELECT json_build_object(
        'active_theme', (SELECT value FROM site_settings WHERE name='default_theme_id'),
        'theme_field_count', (SELECT count(*) FROM theme_fields),
        'unrelated_theme_md5', (SELECT md5(string_agg(concat_ws(':', id, theme_id, target_id, type_id, name, md5(value)), '|' ORDER BY id)) FROM theme_fields WHERE id NOT IN (200,201,206,305,306,316)),
        'feature_settings_md5', (SELECT md5(string_agg(concat_ws(':', name, value, data_type), '|' ORDER BY name)) FROM site_settings WHERE name NOT LIKE 'academy_moderators_%' AND name NOT IN ('academy_activity_category','moderators_manage_categories','moderators_manage_groups','moderators_view_emails')),
        'management_identity_md5', (SELECT md5(string_agg(concat_ws(':', id, admin, moderator, trust_level), '|' ORDER BY id)) FROM users WHERE admin OR moderator),
        'role_memberships_md5', (SELECT md5(string_agg(concat_ws(':', user_id, group_id, owner), '|' ORDER BY user_id,group_id)) FROM group_users WHERE group_id IN (1,2,3)),
        'marketplace_topics', (SELECT count(*) FROM topics WHERE category_id=8 AND deleted_at IS NULL),
        'marketplace_fields', (SELECT count(*) FROM topic_custom_fields WHERE name LIKE 'isbf_marketplace%'),
        'learning_courses_md5', (SELECT md5(value) FROM plugin_store_rows WHERE plugin_name='isbf-learning' AND key='courses'),
        'user_count', (SELECT count(*) FROM users),
        'post_count', (SELECT count(*) FROM posts),
        'topic_count', (SELECT count(*) FROM topics)
      ); COMMIT;"""
    return json.loads(next(line for line in sql(statement).splitlines() if line.startswith("{")))


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
private=Path('/private/admin-permissions-20261011')
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
private=Path('/private/admin-permissions-20261011')
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


def clear_plugin_styles():
    command = DOCKER + ["exec", "-u", "discourse", "-w", "/var/www/discourse", "-e", "RAILS_ENV=production", "isbf_app", "bin/rails", "runner"]
    output(command + ['%w[discourse-academy-roles isbf-anonymous].each { |name| Stylesheet::Manager.clear_plugin_cache!(name) }'])


def backup_private_data(release_commit):
    assert len(release_commit) == 40 and all(character in "0123456789abcdef" for character in release_commit)
    code = """
import hashlib,json,os,subprocess
from pathlib import Path
directory=Path(BACKUP_DIRECTORY)
directory.parent.mkdir(mode=0o700,exist_ok=True)
directory.mkdir(mode=0o700,exist_ok=False)
os.chmod(directory.parent,0o700)
result={}
for name,command in {
 'database.dump':['runuser','-u','postgres','--','pg_dump','-U','postgres','-Fc','discourse'],
 'uploads.tar.gz':['tar','-C','/shared','-czf','-','uploads'],
}.items():
 path=directory/name
 with path.open('wb') as handle:
  os.fchmod(handle.fileno(),0o600)
  subprocess.run(command,stdout=handle,check=True)
 value=hashlib.sha256()
 with path.open('rb') as handle:
  for part in iter(lambda:handle.read(1048576),b''):value.update(part)
 result[name]={'path':str(path),'bytes':path.stat().st_size,'sha256':value.hexdigest()}
print(json.dumps(result))
""".replace("BACKUP_DIRECTORY", repr("/shared/admin-permissions-backups/20261011-" + release_commit[:12]))
    return json.loads(output(DOCKER + ["exec", "-u", "root", "-i", "isbf_app", "python3", "-"], input=code))


def retire_orphaned_sidekiqs():
    code = """
import json,os,re,signal,time
from pathlib import Path
retired=[]
for directory in Path('/proc').iterdir():
 if not directory.name.isdigit():continue
 try:
  status=(directory/'status').read_text()
  command=(directory/'cmdline').read_bytes().replace(b'\\0',b' ').decode().strip()
  if not re.search(r'^PPid:\\s+1$',status,re.M):continue
  if not re.fullmatch(r'sidekiq [0-9.]+ discourse \\[\\d+ of \\d+ busy\\]',command):continue
  start=(directory/'stat').read_text().rsplit(')',1)[1].split()[19]
  pid=int(directory.name)
  os.kill(pid,signal.SIGTSTP)
  assert (directory/'stat').read_text().rsplit(')',1)[1].split()[19]==start
  os.kill(pid,signal.SIGTERM)
  retired.append(pid)
 except FileNotFoundError:continue
deadline=time.monotonic()+40
while time.monotonic()<deadline:
 live=[]
 for pid in retired:
  status=Path('/proc/'+str(pid)+'/status')
  if status.exists() and not re.search(r'^State:\\s+Z',status.read_text(),re.M):live.append(pid)
 if not live:break
 time.sleep(0.25)
else:raise RuntimeError('Orphaned Sidekiq did not exit gracefully')
print(json.dumps({'gracefully_retired_orphaned_sidekiq_pids':retired}))
"""
    return json.loads(output(DOCKER + ["exec", "-u", "root", "-i", "isbf_app", "python3", "-"], input=code))


def archive_release_artifacts():
    code = """
import hashlib,json,os,shutil
from pathlib import Path
directory=Path('/private/admin-permissions-20261011/release-artifacts')
directory.mkdir(mode=0o700,exist_ok=False)
files={}
for name in ['release.json','release.bundle','isbf-learning.bundle','isbf-official.bundle','runtime-inventory.json','candidate-inventory.json','validation.json','lint-report.json','preview-browser-report.json']:
 source=Path('/art')/name
 target=directory/name
 shutil.copyfile(source,target)
 os.chmod(target,0o600)
 value=hashlib.sha256(target.read_bytes()).hexdigest()
 assert value==hashlib.sha256(source.read_bytes()).hexdigest()
 files[name]=value
print(json.dumps({'path':str(directory),'files_sha256':files}))
"""
    return json.loads(helper(code))


def theme_payload():
    snapshot = json.loads((ART / "current-theme.json").read_text())
    fields = []
    for item in snapshot["fields"]:
        if item["id"] in [200, 201, 206, 305, 306, 316]:
            source = ROOT / "themes/isbf-campus-feed/javascripts" / (item["name"])
            fields.append({"id": item["id"], "name": item["name"], "before": item["value"], "after": source.read_text()})
    stored = sql("BEGIN READ ONLY; SELECT value FROM site_settings WHERE name='academy_activity_category'; COMMIT;").splitlines()
    old = next((value for value in stored if value not in ["BEGIN", "COMMIT"]), None)
    return {"theme_id": snapshot["theme_id"], "fields": fields, "activity_category": 5, "activity_before": old}


def run_theme(mode):
    command = DOCKER + ["exec", "-u", "discourse", "-w", "/var/www/discourse", "-e", "RAILS_ENV=production", "-e", "GIT_CONFIG_COUNT=1", "-e", "GIT_CONFIG_KEY_0=safe.directory", "-e", "GIT_CONFIG_VALUE_0=/var/www/discourse", "isbf_app", "bin/rails", "runner", "/tmp/admin-permissions-theme.rb", "/tmp/admin-permissions-theme.json", mode]
    value = output(command)
    print(value, flush=True)


def switch_external(manifest, rollback=False):
    for name, release in manifest["external_releases"].items():
        before = "/shared/" + name + "-releases/" + release["base_commit"] + "/" + name
        after = "/shared/" + name + "-releases/" + release["commit"] + "/" + name
        expected, target = (after, before) if rollback else (before, after)
        current = output(DOCKER + ["exec", "isbf_app", "readlink", "/var/www/discourse/plugins/" + name])
        if rollback and current == target:
            continue
        code = "import os\nfrom pathlib import Path\npath=Path('/var/www/discourse/plugins/' + NAME)\nassert path.is_symlink() and os.readlink(path)==EXPECTED,'Plugin link changed concurrently'\nassert Path(TARGET+'/plugin.rb').is_file()\ntemporary=path.with_name(path.name+'.admin-permissions-pending')\nassert not temporary.exists() and not temporary.is_symlink()\nos.symlink(TARGET,temporary)\nos.replace(temporary,path)\n"
        code = code.replace("NAME", repr(name)).replace("EXPECTED", repr(expected)).replace("TARGET", repr(target))
        output(DOCKER + ["exec", "-u", "root", "-i", "isbf_app", "python3", "-"], input=code)


def deploy():
    manifest = json.loads((ART / "release.json").read_text())
    assert json.loads((ART / "preview-browser-report.json").read_text())["passed"], "Isolated browser verification must pass"
    assert json.loads((ART / "lint-report.json").read_text())["passed"]
    assert inventory("isbf_app") == json.loads((ART / "runtime-inventory.json").read_text()), "Production source changed since build"
    assert output(DOCKER + ["image", "inspect", "local_discourse/isbf_app:latest", "--format", "{{.Id}} "]) == BASE_IMAGE
    live_git("diff", "--exit-code", "--", *manifest["files"])
    create_helper()
    report = {"deployed": False, "base_commit": BASE_COMMIT, "release_commit": manifest["release_commit"], "base_image_id": BASE_IMAGE, "image_id": manifest["image_id"], "started_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "container_recreated": False, "database_migrations_added": 0}
    changed = False
    external_changed = False
    theme_changed = False
    config_changed = False
    branch_changed = False
    backup = ART / "production-before"
    backup.mkdir(mode=0o700, exist_ok=False)
    try:
        report["config_backup"] = prepare_config(manifest)
        report["before"] = state()
        for name in PLUGINS_WITH_ASSETS:
            subprocess.run(DOCKER + ["cp", "isbf_app:/var/www/discourse/app/assets/generated/" + name, str(backup / name)], check=True)
        for source, destination in {"public/assets/.manifest.json": "public-manifest.json", "tmp/cache/assets/production/stylesheet-manifest": "stylesheet-manifest"}.items():
            subprocess.run(DOCKER + ["cp", "isbf_app:/var/www/discourse/" + source, str(backup / destination)], check=True)
        old_public = json.loads((backup / "public-manifest.json").read_text())
        new_public = json.loads((ART / "image/assets/public/assets/.manifest.json").read_text())
        assert all(new_public.get(key) == value for key, value in old_public.items()), "Existing asset manifest entry omitted"
        report["private_data_backup"] = backup_private_data(manifest["release_commit"])
        save_json(backup / "private-data-backup.json", report["private_data_backup"])
        save_json(backup / "theme.json", theme_payload())
        save_json(ART / "theme-update.json", json.loads((backup / "theme.json").read_text()))
        subprocess.run(DOCKER + ["cp", str(backup), HELPER + ":/private/admin-permissions-20261011/production-before"], check=True)
        report["release_artifact_archive"] = archive_release_artifacts()
        for name, release in manifest["external_releases"].items():
            destination = "/shared/" + name + "-releases/" + release["commit"]
            output(DOCKER + ["exec", "isbf_app", "test", "!", "-e", destination])
            subprocess.run(DOCKER + ["cp", str(Path(release["directory"]).parent), "isbf_app:" + destination], check=True)
            subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "-R", "discourse:discourse", destination], check=True)
        for source, destination in {"release.bundle": "/tmp/admin-permissions.bundle", "theme-update.rb": "/tmp/admin-permissions-theme.rb", "theme-update.json": "/tmp/admin-permissions-theme.json"}.items():
            subprocess.run(DOCKER + ["cp", str(ART / source), "isbf_app:" + destination], check=True)
        print("Database, uploads, current theme, settings, configuration and known-good image backed up", flush=True)
        report["background_process_cutover"] = retire_orphaned_sidekiqs()
        live_git("fetch", "/tmp/admin-permissions.bundle", "refs/heads/" + manifest["branch"])
        live_git("checkout", "--detach", manifest["release_commit"])
        changed = True
        external_changed = True
        switch_external(manifest)
        subprocess.run(DOCKER + ["cp", str(ART / "image/assets") + "/.", "isbf_app:/var/www/discourse/"], check=True)
        subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "-R", "discourse:discourse", *["/var/www/discourse/app/assets/generated/" + name for name in PLUGINS_WITH_ASSETS]], check=True)
        subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "discourse:discourse", "/var/www/discourse/public/assets/.manifest.json", "/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"], check=True)
        run_theme("check")
        theme_changed = True
        run_theme("apply")
        clear_plugin_styles()
        restart_web()
        assert inventory("isbf_app") == json.loads((ART / "candidate-inventory.json").read_text()), "Live source differs from verified candidate"
        print("Web ready; verifying the permission page and existing desktop/mobile features", flush=True)
        subprocess.run([sys.executable, str(ART / "verify.py"), "production"], check=True)
        assert json.loads((ART / "production-browser-report.json").read_text())["passed"]
        report["after"] = state()
        assert report["before"] == report["after"], "Unrelated theme, roles, feature settings or business counts changed"
        subprocess.run(DOCKER + ["exec", "-u", "root", HELPER, "git", "--git-dir=/release.git", "fetch", "/art/release.bundle", "refs/heads/" + manifest["branch"] + ":refs/heads/" + manifest["branch"]], check=True)
        branch_changed = True
        write_config()
        config_changed = True
        subprocess.run(DOCKER + ["tag", manifest["image_id"], "local_discourse/isbf_app:latest"], check=True)
        report.update({"deployed": True, "completed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "plugins_verified": manifest["plugin_inventory_verified"], "existing_public_manifest_entries_preserved": len(old_public), "theme_fields_updated": 6, "permission_switches": 20, "permissions_default_off": True, "known_good_image_updated": True})
        print("Permission release and existing desktop/mobile features verified", flush=True)
    except Exception as error:
        report.update({"error_type": type(error).__name__, "error": str(error)})
        if changed:
            if theme_changed:
                run_theme("rollback")
            if external_changed:
                switch_external(manifest, rollback=True)
            live_git("checkout", "--detach", BASE_COMMIT)
            for name in PLUGINS_WITH_ASSETS:
                subprocess.run(DOCKER + ["cp", str(backup / name) + "/.", "isbf_app:/var/www/discourse/app/assets/generated/" + name + "/"], check=True)
            subprocess.run(DOCKER + ["cp", str(backup / "public-manifest.json"), "isbf_app:/var/www/discourse/public/assets/.manifest.json"], check=True)
            subprocess.run(DOCKER + ["cp", str(backup / "stylesheet-manifest"), "isbf_app:/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"], check=True)
            subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "-R", "discourse:discourse", *["/var/www/discourse/app/assets/generated/" + name for name in PLUGINS_WITH_ASSETS]], check=True)
            subprocess.run(DOCKER + ["exec", "isbf_app", "chown", "discourse:discourse", "/var/www/discourse/public/assets/.manifest.json", "/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"], check=True)
            if config_changed:
                write_config(rollback=True)
            if branch_changed:
                subprocess.run(DOCKER + ["exec", HELPER, "git", "--git-dir=/release.git", "update-ref", "-d", "refs/heads/" + manifest["branch"], manifest["release_commit"]], check=True)
            clear_plugin_styles()
            restart_web()
            report["rolled_back"] = True
        raise
    finally:
        save_json(ART / "production-report.json", report)
        subprocess.run(DOCKER + ["cp", str(ART / "production-report.json"), HELPER + ":/private/admin-permissions-20261011/production-report.json"], check=True)
        if (ART / "production-browser-report.json").exists():
            subprocess.run(DOCKER + ["cp", str(ART / "production-browser-report.json"), HELPER + ":/private/admin-permissions-20261011/production-browser-report.json"], check=True)
            subprocess.run(DOCKER + ["exec", HELPER, "chmod", "600", "/private/admin-permissions-20261011/production-browser-report.json"], check=True)
        subprocess.run(DOCKER + ["exec", HELPER, "chmod", "600", "/private/admin-permissions-20261011/production-report.json"], check=True)
        subprocess.run(DOCKER + ["rm", "-f", HELPER], check=True, stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    deploy()
