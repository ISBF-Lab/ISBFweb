import { currentURL, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import topFixtures from "discourse/tests/fixtures/top-fixtures";
import select from "discourse/tests/helpers/d-select";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import {
  disableLoadMoreObserver,
  enableLoadMoreObserver,
} from "discourse/ui-kit/d-load-more";

acceptance("ISBF top topics route", function (needs) {
  needs.user();
  needs.hooks.beforeEach(() => disableLoadMoreObserver());
  needs.hooks.afterEach(() => enableLoadMoreObserver());
  needs.pretender((server, helper) => {
    server.get("/review/count.json", () => helper.response({ count: 0 }));
    server.get("/filter.json", () =>
      helper.response({ users: [], topic_list: { topics: [] } })
    );
    server.post("/isbf/views/impressions", () =>
      helper.response({ success: true })
    );
    const response = (request) => {
      const data = cloneJSON(topFixtures["/top.json"]);
      const page = request.queryParams.page === "1";
      data.topic_list.for_period = request.queryParams.period || "monthly";
      data.topic_list.topics = data.topic_list.topics
        .slice(0, 2)
        .map((topic, index) => ({
          ...topic,
          id: 981100 + (page ? 2 : index),
          title: `Campus discussion ${page ? 3 : index + 1}`,
          fancy_title: `Campus discussion ${page ? 3 : index + 1}`,
          category_id: 1,
          excerpt: "<p>A campus discussion excerpt.</p>",
        }));
      data.topic_list.more_topics_url = page
        ? null
        : `/top.json?page=1&period=${data.topic_list.for_period}`;
      if (page) {
        data.topic_list.topics = data.topic_list.topics.slice(0, 1);
      }
      return helper.response(data);
    };
    server.get("/top.json", response);
  });

  test("the top route has its own header and period changes retain other filters", async function (assert) {
    await visit("/top?status=closed");
    assert.dom(".isbf-v2-shell--top").exists();
    assert.dom(".isbf-top-topics__heading").hasTagName("h1");
    assert.dom(".isbf-v2-feed-header").doesNotExist();
    assert.dom(".isbf-v2-compose").doesNotExist();
    assert.dom(".isbf-v2-mobile-compose").doesNotExist();
    assert.dom(".period-chooser").doesNotExist();
    assert.dom(".isbf-top-topics__item").exists({ count: 2 });
    await select(".isbf-top-topics__select", "yearly");
    assert.strictEqual(currentURL(), "/top?period=yearly&status=closed");
    assert.dom(".isbf-top-topics__rank").hasText("1");
  });

  test("native pagination appends results and navigation releases the outlet", async function (assert) {
    await visit("/top?period=monthly");
    const controller = this.owner.lookup("controller:discovery.top");
    await controller.model.list.loadMore();
    await settled();
    assert.dom(".isbf-top-topics__item").exists({ count: 3 });
    assert
      .dom(".isbf-top-topics__item:last-child .isbf-top-topics__rank")
      .hasText("3");
    assert.dom(".isbf-top-topics").containsText("Campus discussion 3");
    await visit("/latest");
    assert.dom(".isbf-top-topics").doesNotExist();
    assert.dom(".isbf-v2-shell--feed").exists();
    assert.dom(".topic-list").exists();
  });
});
