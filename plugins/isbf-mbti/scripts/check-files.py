"""List owned candidate files for native lint without changing dependency snapshots."""
import json
import os
from pathlib import Path
import urllib.request


plugin = Path("plugins/isbf-mbti")
files = {path.as_posix() for path in plugin.rglob("*") if path.is_file()}
pr = os.environ.get("PR_NUMBER")
if pr:
    page = 1
    while True:
        url = (
            f"{os.environ['GITHUB_API_URL']}/repos/{os.environ['GITHUB_REPOSITORY']}"
            f"/pulls/{pr}/files?per_page=100&page={page}"
        )
        request = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
                "Accept": "application/vnd.github+json",
            },
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            batch = json.load(response)
        for item in batch:
            path = item["filename"]
            if item["status"] != "removed" and path.startswith("themes/isbf-campus-feed/"):
                files.add(path)
        if len(batch) < 100:
            break
        page += 1
else:
    files.update(
        path.as_posix()
        for path in Path("themes/isbf-campus-feed").rglob("*")
        if path.is_file()
    )
extensions = {".rb", ".js", ".gjs", ".ts", ".gts", ".scss", ".css", ".json", ".yml", ".yaml", ".md", ".py"}
for source in sorted(files):
    if (
        "/data/upstream/" not in source
        and Path(source).suffix in extensions
        and Path(source).is_file()
    ):
        print(source)
