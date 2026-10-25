import { settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";

acceptance("ISBF untitled topic lists", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    const response = (request) => {
      const result = JSON.parse(
        JSON.stringify(userFixtures["/topics/created-by/eviltrout.json"])
      );
      result.topic_list.topics = result.topic_list.topics
        .slice(0, 2)
        .map((topic, index) => ({
          ...topic,
          title: index ? "An explicit title" : TITLE,
          fancy_title: index ? "An explicit title" : TITLE,
          excerpt: "<p>A real campus update.</p>",
        }));
      if (request.queryParams.page === "1") {
        result.topic_list.topics = [
          {
            ...result.topic_list.topics[0],
            id: 980303,
            excerpt: "<p>A later campus update.</p>",
          },
        ];
        delete result.topic_list.more_topics_url;
      } else {
        result.topic_list.more_topics_url =
          "/topics/created-by/eviltrout?page=1";
      }
      return helper.response(result);
    };
    server.get("/topics/created-by/eviltrout.json", response);
    server.get("/read.json", response);
    server.get("/filter.json", () =>
      helper.response({ users: [], topic_list: { topics: [] } })
    );
  });

  for (const route of ["topics", "read"]) {
    test(`the real ${route} route replaces internal titles without replacing its list`, async function (assert) {
      await visit(`/u/eviltrout/activity/${route}`);
      assert.dom(".topic-list").exists();
      assert
        .dom(".topic-list .isbf-topic-title-preview")
        .hasText("A real campus update.");
      assert.dom(".topic-list").doesNotContainText("isbf-untitled");
      assert.dom(".topic-list").containsText("An explicit title");
      assert
        .dom(".isbf-feed-card")
        .doesNotExist("the native topic list keeps its layout");
      assert
        .dom(".isbf-topic-title-preview")
        .hasTagName("span", "the existing topic link remains the only anchor");
      assert.dom(".topic-list .title").hasAttribute("href");
    });
  }

  test("sorting and loading another page retain clean topic titles", async function (assert) {
    await visit("/u/eviltrout/activity/topics?order=created&ascending=true");
    await this.owner.lookup("controller:user-topics-list").model.loadMore();
    await settled();
    assert.dom(".topic-list").containsText("A later campus update.");
    assert.dom(".topic-list").doesNotContainText("isbf-untitled");
    assert
      .dom('.topic-list a.title[data-topic-id="980303"]')
      .hasAttribute("href");
  });
});
