import { find, visit, waitUntil } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";

acceptance("ISBF profile previews", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/user_actions.json", () =>
      helper.response({
        user_actions: [
          {
            action_type: 4,
            post_id: null,
            post_number: 1,
            topic_id: 970001,
            title: TITLE,
            slug: "campus",
            user_id: 19,
            username: "eviltrout",
            avatar_template: "/images/avatar.png",
            created_at: "2026-10-19T00:00:00Z",
            excerpt: '<p>Campus photos.</p><a class="lightbox">[image.png]</a>',
            truncated: true,
          },
        ],
      })
    );
    server.get("/posts/by_number/:topicId/:postNumber.json", (request) => {
      const number = Number(request.params.postNumber);
      return helper.response({
        id: 970010 + number,
        cooked:
          number === 1
            ? '<p>Campus photos.</p><img src="/images/d-logo-sketch-small.png">'
            : "<p>A popular reply.</p>",
      });
    });
    server.get("/u/eviltrout/summary.json", () => {
      const data = cloneJSON(userFixtures["/u/eviltrout/summary.json"]);
      const topic = data.topics[0];
      topic.id = 970001;
      topic.title = TITLE;
      topic.fancy_title = TITLE;
      topic.slug = "campus";
      data.user_summary.topic_ids = [topic.id];
      data.user_summary.replies = [
        {
          topic_id: topic.id,
          post_number: 7,
          like_count: 3,
          created_at: "2026-10-19T00:00:00Z",
        },
      ];
      data.user_summary.links = [];
      return helper.response(data);
    });
    server.get("/filter.json", () =>
      helper.response({
        users: [],
        topic_list: { topics: [] },
      })
    );
  });

  test("historical activity previews its body and image through the real route", async function (assert) {
    await visit("/u/eviltrout/activity");
    await waitUntil(() => find(".isbf-post-preview__image"));
    assert
      .dom(".user-stream-item")
      .hasClass(
        "isbf-activity-item",
        "the historical row receives the custom preview"
      );
    assert
      .dom(".isbf-activity-preview")
      .doesNotContainText("isbf-untitled", "the internal title is not shown");
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus photos.", "image filenames do not replace the body");
    assert.dom(".isbf-post-preview__image").exists("the thumbnail is rendered");
  });

  test("the real summary route preserves each original post target", async function (assert) {
    await visit("/u/eviltrout/summary");
    await waitUntil(() =>
      find(".replies-section .isbf-post-preview__text")?.textContent.includes(
        "A popular reply."
      )
    );
    assert
      .dom(".topics-section .isbf-post-preview__text")
      .hasText("Campus photos.", "a popular topic uses its first post");
    assert
      .dom(".replies-section .isbf-post-preview__text")
      .hasText(
        "A popular reply.",
        "a popular reply uses its actual post number"
      );
    assert
      .dom(".replies-section .isbf-post-preview")
      .hasAttribute(
        "href",
        "/t/campus/970001/7",
        "the reply link retains its post number"
      );
    assert
      .dom(".replies-section .like-count")
      .hasText("3", "the original like count remains");
    assert
      .dom(".isbf-post-preview__image")
      .doesNotExist("the summary stays a text list");
  });
});
