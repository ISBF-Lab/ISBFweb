import { find, visit, waitUntil } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import stubIntersectionObserver from "discourse/tests/helpers/stub-intersection-observer";

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
      const number = Number.parseInt(request.params["postNumber.json"], 10);
      return helper.response({
        id: 970010 + number,
        cooked:
          number === 1
            ? '<p>Campus photos.</p><img src="/images/d-logo-sketch-small.png">'
            : "<p>A popular reply.</p>",
      });
    });
    server.get("/u/eviltrout/summary.json", () => {
      return helper.response({
        topics: [
          {
            id: 970001,
            title: TITLE,
            fancy_title: TITLE,
            slug: "campus",
          },
        ],
        users: [],
        badges: [],
        user_summary: {
          topic_ids: [970001],
          replies: [
            {
              topic_id: 970001,
              post_number: 7,
              like_count: 3,
              created_at: "2026-10-19T00:00:00Z",
            },
          ],
          links: [],
          most_replied_to_users: [],
          most_liked_by_users: [],
          most_liked_users: [],
          badges: [],
          top_categories: [],
        },
      });
    });
    server.get("/filter.json", () =>
      helper.response({
        users: [],
        topic_list: { topics: [] },
      })
    );
  });

  test("historical activity previews its body and image through the real route", async function (assert) {
    const observations = stubIntersectionObserver();
    await visit("/u/eviltrout/activity");
    const preview = observations.find(({ element }) =>
      element.classList.contains("isbf-post-preview")
    );
    assert.notStrictEqual(
      preview,
      undefined,
      "the activity preview observes its visibility"
    );
    await preview.trigger();
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
    const observations = stubIntersectionObserver();
    await visit("/u/eviltrout/summary");
    const previews = observations.filter(({ element }) =>
      element.classList.contains("isbf-post-preview")
    );
    assert.strictEqual(
      previews.length,
      2,
      "both summary previews observe visibility"
    );
    for (const preview of previews) {
      await preview.trigger();
    }
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
