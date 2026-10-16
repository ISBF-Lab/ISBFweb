"""Prepare an ephemeral test tree without writing through source mounts."""

from pathlib import Path
import shutil


SOURCE = Path("/workspace")
WORK = Path("/tmp/spec-work")
IMAGE_SOURCE = Path("/var/www/discourse")
WORK.mkdir()

for name in ["app", "lib", "frontend", "node_modules", "db", "script"]:
    source = SOURCE / name
    if not source.exists():
        raise RuntimeError(f"Required read-only source is missing: {source}")
    (WORK / name).symlink_to(source, target_is_directory=True)

for name in ["config", "bin", "spec"]:
    destination = WORK / name
    destination.mkdir()
    for source in (SOURCE / name).iterdir():
        if name == "config" and source.name == "discourse.conf":
            continue
        (destination / source.name).symlink_to(source, target_is_directory=source.is_dir())

(WORK / "public").mkdir()
for name in ["images", "javascripts", "audio"]:
    source = SOURCE / "public" / name
    if not source.exists():
        source = IMAGE_SOURCE / "public" / name
    if source.exists():
        (WORK / "public" / name).symlink_to(source, target_is_directory=True)
for source in (IMAGE_SOURCE / "public").glob("*.html"):
    (WORK / "public" / source.name).symlink_to(source)

for name in ["Gemfile", "Gemfile.lock", ".rspec", "Rakefile", "config.ru"]:
    shutil.copyfile(SOURCE / name, WORK / name)

for name in ["config/application.rb", "config/boot.rb", "config/environment.rb", "spec/rails_helper.rb", "bin/rspec", "bin/rake"]:
    destination = WORK / name
    destination.unlink()
    shutil.copyfile(SOURCE / name, destination)

for name in ["vendor", "migrations"]:
    source = IMAGE_SOURCE / name
    if not source.exists():
        raise RuntimeError(f"Cached image source is missing: {source}")
    (WORK / name).symlink_to(source, target_is_directory=True)

for name in ["tmp", "log", "plugins", "public/uploads", "public/backups", "public/assets", "public/stylesheets"]:
    (WORK / name).mkdir(parents=True, exist_ok=True)

application = WORK / "config/application.rb"
source = application.read_text()
anchor = "GlobalSetting.load_defaults\n"
if source.count(anchor) != 1:
    raise RuntimeError("Cannot locate the isolated Redis adapter insertion point")
source = source.replace(anchor, anchor + '''
# The isolated review runner only exposes an ephemeral Redis Unix socket.
GlobalSetting.define_singleton_method(:redis_config) do
  { path: ENV.fetch("ISBF_SPEC_REDIS_SOCKET"), db: 1 }.freeze
end
''')
application.write_text(source)

for name in ["asset-processor", "pretty-text-processor"]:
    source = IMAGE_SOURCE / "tmp" / name
    if source.is_dir():
        shutil.copytree(source, WORK / "tmp" / name)

print("Prepared /tmp/spec-work; application sources remain read-only", flush=True)
