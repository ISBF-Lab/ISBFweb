from pathlib import Path
import os
import runpy
import shutil

runpy.run_path("/prior-review/prepare-spec-work.py")
work = Path("/tmp/spec-work")
(work / "themes").symlink_to("/workspace/themes")


def copy_code_tree(source, destination):
    if destination.is_symlink():
        destination.unlink()
    elif destination.exists():
        shutil.rmtree(destination)
    destination.mkdir()
    for directory, subdirectories, filenames in os.walk(source):
        relative = Path(directory).relative_to(source)
        target = destination / relative
        target.mkdir(exist_ok=True)
        if source.name == "app" and relative == Path("assets"):
            subdirectories[:] = [name for name in subdirectories if name != "generated"]
        for filename in filenames:
            if source.name == "config" and filename == "discourse.conf":
                continue
            original = Path(directory) / filename
            copied = target / filename
            if original.suffix in [".rb", ".rake"]:
                shutil.copyfile(original, copied)
            else:
                copied.symlink_to(original)
    if source.name == "app":
        (destination / "assets/generated").mkdir(exist_ok=True)


for name in ["app", "lib", "db", "config", "spec", "plugins"]:
    copy_code_tree(Path("/workspace") / name, work / name)

application = work / "config/application.rb"
contents = application.read_text()
contents = contents.replace("GlobalSetting.load_defaults\n", '''GlobalSetting.load_defaults
GlobalSetting.define_singleton_method(:redis_config) do
  { path: ENV.fetch("ISBF_SPEC_REDIS_SOCKET"), db: 1 }.freeze
end
''')
application.write_text(contents)

gem_home = Path("/test-gems/ruby/3.4.0")
for part in ["gems", "specifications", "cache"]:
    target = gem_home / part
    target.mkdir(parents=True, exist_ok=True)
    for source_home in [Path("/var/www/discourse/vendor/bundle/ruby/3.4.0"), Path("/lint-gems")]:
        for source in (source_home / part).glob("*"):
            if not (target / source.name).exists():
                (target / source.name).symlink_to(source)
extensions = Path("/var/www/discourse/vendor/bundle/ruby/3.4.0/extensions")
if extensions.exists() and not (gem_home / "extensions").exists():
    shutil.copytree(extensions, gem_home / "extensions", symlinks=True)
print("Prepared isolated plugin and gem paths", flush=True)
