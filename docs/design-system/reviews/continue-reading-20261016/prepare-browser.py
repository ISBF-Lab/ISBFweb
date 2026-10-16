"""Prepare synthetic local responses and retain only cached code/style resources."""

import base64
import copy
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[4]
ART = Path(__file__).resolve().parent
BASE = ROOT / "deploy-work/reply-conversations-20261015"
fixture = json.loads((BASE / "regressions-20261016/native-fixture.json").read_text())
cache = ART / "asset-cache"
cache.mkdir(exist_ok=True)
retained = 0
for source in (BASE / "interaction-http-cache").glob("*.json"):
    value = json.loads(source.read_text())
    kind = value.get("headers", {}).get("content-type", "")
    if not any(token in kind for token in ["javascript", "text/css"]):
        continue
    (cache / source.name).write_text(json.dumps({"status": value["status"], "headers": {"content-type": kind}, "body": value["body"]}))
    retained += 1

topic = fixture["topic"]
op = copy.deepcopy(fixture["posts"][0])
topic.update(id=314, title="继续阅读隔离验收", slug="reading-fixture", is_nested_view=False, highest_post_number=1, posts_count=1, reply_count=0)
op.update(topic_id=314, topic_slug="reading-fixture", cooked="<p>此正文来自合成夹具，仅用于检查帖子底部组件。</p>", post_number=1)
topic["post_stream"] = {"posts": [op], "stream": [op["id"]]}
category = next(item for item in fixture["site"]["categories"] if item["id"] == topic["category_id"])
category["name"] = "校园交流"
category["slug"] = "campus"
long_category = {**category, "id": 999, "name": "仅限成员查看的分类名称与连续字符" + "M" * 80, "slug": "members", "read_restricted": True}
fixture["site"]["categories"].append(long_category)
author = {"id": 42, "username": "fixture-user", "name": "预览用户", "avatar_template": "/letter_avatar_proxy/v4/letter/f/25/{size}.png"}


def suggestion(identifier, title, replies=0, **changes):
    row = {
        "id": identifier, "title": title, "fancy_title": title, "slug": "reading-item",
        "archetype": "regular", "posts_count": replies + 1, "highest_post_number": replies + 1,
        "reply_count": replies, "category_id": category["id"], "created_at": "2026-10-14T02:00:00Z",
        "bumped_at": "2026-10-16T02:00:00Z", "last_posted_at": "2026-10-16T02:00:00Z",
        "unread_posts": 0, "last_read_post_number": replies + 1, "unseen": False,
        "visible": True, "closed": False, "archived": False,
        "posters": [{"extras": "latest single", "description": "Original Poster", "user": author}],
    }
    row.update(changes)
    return row


topic["suggested_topics"] = [
    suggestion(901, "新学期校园活动与学习资源整理"),
    suggestion(902, "这是一条内容较长的话题标题，用来确认在手机和电脑上最多显示两行，分类、时间与回复信息都能正常排列，不会被标题挤出容器", 3, unread_posts=3, last_read_post_number=1),
    suggestion(903, "同学们有哪些值得分享的读书方法", unseen=True, last_read_post_number=None, posters=[]),
    suggestion(904, "已结束的活动讨论仍然可以继续阅读", 3, closed=True),
    suggestion(905, "嵌套话题的真实新回复", 3, is_nested_view=True, has_new_replies=True, last_read_post_number=1),
    suggestion(906, "嵌套话题不会套用旧版未读计数", 3, is_nested_view=True, unread_posts=3, last_read_post_number=1),
    suggestion(907, "Z" * 180, 3, category_id=999),
]
topic["related_topics"] = [suggestion(908, "相关话题：课程资料与校园生活", 3), suggestion(909, "相关话题也使用同一套继续阅读列表", 0, posters=[])]

html = fixture["html"]
original_shell = (BASE / "interaction-public-shell.html").read_text()
original_entry = re.search(r'src="([^"]+)"(?=[^>]*data-discourse-entrypoint="discourse")', original_shell)[1]
html = re.sub(r'src="[^"]+"(?=[^>]*data-discourse-entrypoint="discourse")', 'src="' + original_entry + '"', html)
html = re.sub(r'(<meta name="csrf-token" content=")[^"]*', r'\1offline-fixture', html)
preloaded_match = re.search(r'(<script type="application/json" id="data-preloaded">)([\s\S]*?)(</script>)', html)
preloaded = json.loads(preloaded_match[2])
settings = json.loads(preloaded["siteSettings"])
settings.update(nested_replies_enabled=False, enable_unified_new=True, ai_embeddings_enabled=True, ai_embeddings_semantic_related_topics_enabled=True, support_mixed_text_direction=True)
preloaded["siteSettings"] = json.dumps(settings)
preloaded["site"] = json.dumps(fixture["site"])
html = html[:preloaded_match.start(2)] + json.dumps(preloaded) + html[preloaded_match.end(2):]
html = html.replace("/fixture-replies.css", "/fixture/theme.css")
html = html.replace("</body>", '<link rel="stylesheet" href="/fixture/colors.css"></body>')
fixture["html"] = html
fixture["posts"] = [op]
(ART / "native-fixture.json").write_text(json.dumps(fixture))
(ART / "fixture-preparation.json").write_text(json.dumps({"synthetic_topics": 9, "cached_code_and_styles": retained, "production_backend_used": False, "production_images_copied": False}, indent=2) + "\n")
print(json.dumps({"synthetic_fixture_prepared": True, "cached_code_and_styles": retained}))
