"""List the scoped native lint inputs for the student-number group feature."""
from pathlib import Path

plugin = Path(__file__).resolve().parents[1]
shared = {
    plugin / "plugin.rb",
    plugin / "assets/javascripts/discourse/admin-academy-roles-plugin-route-map.js",
    plugin / "admin/assets/javascripts/discourse/templates/admin-plugins/show/academy-student-invites.gjs",
    plugin / "assets/stylesheets/common/academy-roles.scss",
}
files = {
    path
    for path in plugin.rglob("*")
    if path.is_file()
    and path.suffix in {".rb", ".js", ".gjs", ".scss"}
    and ("student_group" in str(path.relative_to(plugin)) or "student-group" in str(path.relative_to(plugin)))
}
for path in sorted(files | shared):
    print(path.relative_to(Path.cwd()).as_posix())
