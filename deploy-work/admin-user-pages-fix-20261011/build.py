"""Build a release while retaining the complete live plugin and source inventory."""

import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ART = Path(__file__).resolve().parent
ROOT = ART.parents[1]
DOCKER = ["docker", "--host=unix:///var/run/docker.sock"]
BASE_COMMIT = "67706a5a30d71ff0b6793e5b8f55a85c4fe3ebb5"
BASE_IMAGE = "sha256:e748995d9786f7cac5d0fa1eca66e3c0fafd6765dcd50942d0a88d80ade4345a"
BASE_IMAGE_TAG = "local_discourse/isbf_app:user-pages-fix-base-20261011"
BRANCH = "admin-user-pages-fix-20261011"
IMAGE_TAG = "local_discourse/isbf_app:admin-user-pages-fix-20261011"
PLUGINS_WITH_ASSETS = ["discourse-academy-roles"]


def output(arguments, **kwargs):
    return subprocess.check_output(arguments, text=True, **kwargs).strip()


def inventory(container):
    return json.loads(output(DOCKER + ["exec", "-u", "root", "-i", container, "python3", "-"], input=(ROOT / "deploy-work/admin-permissions-20261011/inventory.py").read_text()))


def git(root, *arguments):
    return output(["git", "-c", "safe.directory=" + str(root), "-C", str(root), *arguments])


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def assert_preserved(before, after, changed, externals=None):
    changed = set(changed)
    externals = externals or {}
    assert before["plugins"].keys() == after["plugins"].keys(), "Plugin inventory changed"
    for name, expected in before["plugins"].items():
        actual = after["plugins"][name]
        assert expected["links"] == actual["links"], name + ": internal links changed"
        if name in externals:
            release = externals[name]
            target = "/shared/" + name + "-releases/" + release["commit"] + "/" + name
            assert actual["link"] == actual["resolved"] == target, name + ": wrong release link"
            assert actual["markers"] == {target + "/.release-commit": release["commit"]}
            assert actual["files"] == release["files"], name + ": release source changed"
        else:
            for field in ["link", "resolved", "markers"]:
                assert expected[field] == actual[field], name + ": " + field
            for relative in expected["files"].keys() | actual["files"].keys():
                if "plugins/" + name + "/" + relative not in changed:
                    assert expected["files"].get(relative) == actual["files"].get(relative), name + "/" + relative
    for relative in before["core"].keys() | after["core"].keys():
        if relative not in changed:
            assert before["core"].get(relative) == after["core"].get(relative), relative




def build():
    assert json.loads((ART / "lint-report.json").read_text())["passed"], "Lint must pass before publishing a release"
    assert git(ROOT, "rev-parse", "HEAD") != BASE_COMMIT, "Feature is not committed"
    assert git(ROOT, "diff", "--name-only") == "", "Tracked implementation changes are uncommitted"
    feature_commit = git(ROOT, "rev-parse", "HEAD")
    changed = git(ROOT, "diff", "--name-only", BASE_COMMIT, feature_commit).splitlines()
    assert not any(path.startswith("frontend/") for path in changed), "Core frontend requires a complete build"
    assert output(DOCKER + ["image", "inspect", "local_discourse/isbf_app:latest", "--format", "{{.Id}} {{index .Config.Labels \"org.opencontainers.image.revision\"}} "]) == BASE_IMAGE + " " + BASE_COMMIT, "Known-good production image changed"
    subprocess.run(DOCKER + ["tag", BASE_IMAGE, BASE_IMAGE_TAG], check=True)
    live = inventory("isbf_app")
    assert live["revision"] == BASE_COMMIT and len(live["plugins"]) == 61, "Production baseline changed"
    save_json(ART / "runtime-inventory.json", live)
    externals = {}
    mounts = json.loads(output(DOCKER + ["inspect", "isbf_app", "--format", "{{json .Mounts}} "]))
    shared = next(mount["Source"] for mount in mounts if mount["Destination"] == "/shared")
    context = ART / "image"
    overlay = context / "overlay"
    assets = context / "assets"
    overlay.mkdir(parents=True, exist_ok=True)
    assets.mkdir(parents=True, exist_ok=True)
    container = "isbf_user_pages_build_20261011"
    create = DOCKER + ["create", "--name", container, "--user", "root", "--network", "none", "--memory", "1536m", "--memory-swap", "1536m", "--cpus", "0.75", "--pids-limit", "200", "--mount", "type=bind,src=" + shared + ",dst=/shared,readonly"]
    for name, release in externals.items():
        target = "/shared/" + name + "-releases"
        source = str(Path(release["directory"]).parents[1])
        create += ["--mount", "type=bind,src=" + source + ",dst=" + target + ",readonly"]
    subprocess.run(create + [BASE_IMAGE, "sleep", "infinity"], check=True, stdout=subprocess.DEVNULL)
    copied = []
    removed = []
    try:
        subprocess.run(DOCKER + ["start", container], check=True, stdout=subprocess.DEVNULL)
        existing = inventory(container)
        assert existing["plugins"].keys() == live["plugins"].keys()
        for name, expected in live["plugins"].items():
            actual = existing["plugins"][name]
            for field in ["link", "resolved", "links", "markers"]:
                assert expected[field] == actual[field], name + ": base " + field
            for relative, value in expected["files"].items():
                if actual["files"].get(relative) != value:
                    assert expected["link"] is None
                    copied.append("plugins/" + name + "/" + relative)
            removed += ["plugins/" + name + "/" + relative for relative in actual["files"].keys() - expected["files"].keys()]
        for relative, value in live["core"].items():
            if existing["core"].get(relative) != value:
                assert value is not None
                copied.append(relative)
        for relative in copied:
            target = overlay / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(DOCKER + ["cp", "isbf_app:/var/www/discourse/" + relative, str(target)], check=True)
        if copied:
            subprocess.run(DOCKER + ["cp", str(overlay) + "/.", container + ":/var/www/discourse/"], check=True)
        if removed:
            subprocess.run(DOCKER + ["exec", container, "rm", "-f", *["/var/www/discourse/" + path for path in removed]], check=True)
        assert_preserved(live, inventory(container), [])
        print("Live source aligned; all 61 plugins, hidden files and links retained", flush=True)
        subprocess.run(DOCKER + ["cp", str(ART / "release.bundle"), container + ":/tmp/user-pages-fix.bundle"], check=True)
        subprocess.run(DOCKER + ["cp", str(ART / "compile-release.rb"), container + ":/tmp/user-pages-fix-compile.rb"], check=True)
        with (ART / "compile.log").open("w") as log:
            command = DOCKER + ["exec", "-u", "root", "-w", "/var/www/discourse", container]
            subprocess.run(command + ["git", "-c", "safe.directory=/var/www/discourse", "fetch", "/tmp/user-pages-fix.bundle", "refs/heads/" + BRANCH], stdout=log, stderr=subprocess.STDOUT, check=True)
            subprocess.run(command + ["git", "-c", "safe.directory=/var/www/discourse", "checkout", "--detach", feature_commit], stdout=log, stderr=subprocess.STDOUT, check=True)
            for name, release in externals.items():
                target = "/shared/" + name + "-releases/" + release["commit"] + "/" + name
                subprocess.run(command + ["ln", "-sfn", target, "plugins/" + name], check=True)
            environment = {"RAILS_ENV": "production", "SKIP_DB_AND_REDIS": "1", "LOAD_PLUGINS": "1", "SKIP_EMBER_CLI_COMPILE": "1", "DONT_PRECOMPILE_CSS": "1", "DISCOURSE_REFRESH_MAXMIND_DB_DURING_PRECOMPILE_DAYS": "0", "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "safe.directory", "GIT_CONFIG_VALUE_0": "/var/www/discourse"}
            command = DOCKER + ["exec", "-u", "discourse", "-w", "/var/www/discourse"]
            for key, value in environment.items():
                command += ["-e", key + "=" + value]
            subprocess.run(command + [container, "bin/rails", "runner", "/tmp/user-pages-fix-compile.rb"], stdout=log, stderr=subprocess.STDOUT, check=True)
        assert_preserved(live, inventory(container), changed, externals)
        sources = {"app/assets/generated/" + name: "/var/www/discourse/app/assets/generated/" + name for name in PLUGINS_WITH_ASSETS}
        sources.update({"public/assets": "/tmp/user-pages-public-delta", "tmp/cache/assets/production/stylesheet-manifest": "/var/www/discourse/tmp/cache/assets/production/stylesheet-manifest"})
        for relative, source in sources.items():
            target = assets / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(DOCKER + ["cp", container + ":" + source, str(target)], check=True)
        shutil.copyfile(ART / "release.bundle", context / "release.bundle")
        dockerfile = "FROM " + BASE_IMAGE_TAG + "\nCOPY --chown=discourse:discourse overlay/ /var/www/discourse/\n"
        if removed:
            import shlex
            dockerfile += "RUN rm -f " + " ".join(shlex.quote("/var/www/discourse/" + relative) for relative in removed) + "\n"
        dockerfile += "COPY release.bundle /tmp/user-pages-fix.bundle\n"
        dockerfile += "RUN git -c safe.directory=/var/www/discourse -C /var/www/discourse fetch /tmp/user-pages-fix.bundle refs/heads/" + BRANCH + " && git -c safe.directory=/var/www/discourse -C /var/www/discourse checkout --detach " + feature_commit + " && rm /tmp/user-pages-fix.bundle\n"
        for name, release in externals.items():
            dockerfile += "RUN ln -sfn /shared/" + name + "-releases/" + release["commit"] + "/" + name + " /var/www/discourse/plugins/" + name + "\n"
        dockerfile += "COPY --chown=discourse:discourse assets/ /var/www/discourse/\nLABEL org.opencontainers.image.revision=\"" + feature_commit + "\"\n"
        (context / "Dockerfile").write_text(dockerfile)
        with (ART / "image-build.log").open("w") as log:
            subprocess.run(DOCKER + ["build", "--network=none", "--pull=false", "-t", IMAGE_TAG, str(context)], stdout=log, stderr=subprocess.STDOUT, check=True)
        image_id = output(DOCKER + ["image", "inspect", IMAGE_TAG, "--format", "{{.Id}} "])
        candidate = "isbf_user_pages_candidate_20261011"
        candidate_create = create.copy()
        candidate_create[candidate_create.index(container)] = candidate
        subprocess.run(candidate_create + [image_id, "sleep", "infinity"], check=True, stdout=subprocess.DEVNULL)
        try:
            subprocess.run(DOCKER + ["start", candidate], check=True, stdout=subprocess.DEVNULL)
            final = inventory(candidate)
            assert final["revision"] == feature_commit
            assert_preserved(live, final, changed, externals)
            save_json(ART / "candidate-inventory.json", final)
        finally:
            subprocess.run(DOCKER + ["rm", "-f", candidate], check=True, stdout=subprocess.DEVNULL)
        report = {"branch": BRANCH, "base_commit": BASE_COMMIT, "release_commit": feature_commit, "base_image_id": BASE_IMAGE, "image_tag": IMAGE_TAG, "image_id": image_id, "files": changed, "external_releases": externals, "core_frontend_rebuilt": False, "compiled_plugins": PLUGINS_WITH_ASSETS, "existing_manifest_preserved": True, "plugin_inventory_verified": len(live["plugins"]), "plugin_source_files_verified": sum(len(item["files"]) for item in live["plugins"].values()), "runtime_overlay_files": copied, "removed_runtime_files": removed, "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
        save_json(ART / "release.json", report)
        print(json.dumps({"image_ready": True, "revision": feature_commit, "plugins_verified": 61}), flush=True)
    finally:
        subprocess.run(DOCKER + ["rm", "-f", container], check=True, stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    build()
