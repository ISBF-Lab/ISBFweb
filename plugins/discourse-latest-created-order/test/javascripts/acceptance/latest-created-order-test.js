import { click, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import discoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import {
  acceptance,
  publishToMessageBus,
} from "discourse/tests/helpers/qunit-helpers";

acceptance("Latest creation order", function (needs) {
  let topics;
  let nextPageTopics;

  needs.settings({ latest_topics_order_by_created: true });

  needs.hooks.beforeEach(() => {
    nextPageTopics = [];
    const template = cloneJSON(
      discoveryFixtures["/latest.json"].topic_list.topics[0]
    );
    topics = [
      {
        ...template,
        id: 10003,
        title: "Pinned older topic",
        created_at: "2026-10-01T00:00:00.000Z",
        pinned: true,
        pinned_globally: true,
        latest_created_order_pinned_at: "2026-10-04T00:00:00.000Z",
      },
      {
        ...template,
        id: 10002,
        title: "Newer topic",
        created_at: "2026-10-03T00:00:00.000Z",
        pinned: false,
        latest_created_order_pinned_at: null,
      },
      {
        ...template,
        id: 10001,
        title: "Older topic with a new reply",
        created_at: "2026-10-02T00:00:00.000Z",
        pinned: false,
        latest_created_order_pinned_at: null,
      },
    ];
  });

  needs.pretender((server, helper) => {
    server.get("/latest.json", (request) => {
      const response = cloneJSON(discoveryFixtures["/latest.json"]);
      const ids = request.queryParams.topic_ids?.split(",").map(Number);
      response.topic_list.topics = cloneJSON(
        request.queryParams.page === "1"
          ? nextPageTopics
          : ids
            ? topics.filter((topic) => ids.includes(topic.id))
            : topics
      );
      response.topic_list.more_topics_url = null;
      return helper.response(response);
    });
  });

  async function updateTopic(topicId) {
    await publishToMessageBus("/latest", {
      message_type: "latest",
      topic_id: topicId,
      payload: {
        category_id: topics[0].category_id,
        bumped_at: new Date().toISOString(),
      },
    });
    await click(".show-more a");
  }

  test("live replies keep older topics below newer topics and pins", async function (assert) {
    await visit("/latest");
    await updateTopic(10001);

    assert
      .dom(".topic-list-item:nth-child(1)")
      .hasAttribute("data-topic-id", "10003", "the pinned topic stays first");
    assert
      .dom(".topic-list-item:nth-child(2)")
      .hasAttribute(
        "data-topic-id",
        "10002",
        "the newer topic stays above the reply"
      );
    assert
      .dom(".topic-list-item:nth-child(3)")
      .hasAttribute(
        "data-topic-id",
        "10001",
        "the older topic retains its creation position"
      );
  });

  test("new topics appear below pins and above older topics", async function (assert) {
    await visit("/latest");
    topics.push({
      ...topics[1],
      id: 10004,
      title: "A newly created topic",
      created_at: "2026-10-05T00:00:00.000Z",
    });
    await updateTopic(10004);

    assert
      .dom(".topic-list-item:nth-child(1)")
      .hasAttribute("data-topic-id", "10003", "the pinned topic stays first");
    assert
      .dom(".topic-list-item:nth-child(2)")
      .hasAttribute(
        "data-topic-id",
        "10004",
        "the new topic comes before older unpinned topics"
      );
    assert
      .dom(".topic-list-item")
      .exists({ count: 4 }, "all topics remain visible");
  });

  test("cleared pins return to their creation position on update", async function (assert) {
    await visit("/latest");
    topics[0].pinned = false;
    topics[0].latest_created_order_pinned_at = null;
    await updateTopic(10003);

    assert
      .dom(".topic-list-item:nth-child(1)")
      .hasAttribute(
        "data-topic-id",
        "10002",
        "the newest unpinned topic comes first"
      );
    assert
      .dom(".topic-list-item:nth-child(3)")
      .hasAttribute(
        "data-topic-id",
        "10003",
        "the cleared pin returns to its creation position"
      );
  });

  test("live updates retain native insertion when disabled", async function (assert) {
    this.siteSettings.latest_topics_order_by_created = false;
    await visit("/latest");
    await updateTopic(10001);

    assert
      .dom(".topic-list-item:nth-child(1)")
      .hasAttribute(
        "data-topic-id",
        "10001",
        "core prepends updated topics when the setting is off"
      );
  });

  test("explicit activity sorting keeps native live insertion", async function (assert) {
    await visit("/latest?order=activity");
    await updateTopic(10001);

    assert
      .dom(".topic-list-item:nth-child(1)")
      .hasAttribute(
        "data-topic-id",
        "10001",
        "the requested activity sort takes precedence"
      );
  });

  test("later pages remain above an older topic introduced by a live reply", async function (assert) {
    await visit("/latest");
    topics.push({
      ...topics[1],
      id: 9999,
      title: "An older topic outside the loaded page",
      created_at: "2026-09-30T00:00:00.000Z",
    });
    await updateTopic(9999);
    nextPageTopics = [
      {
        ...topics[1],
        id: 10005,
        title: "A topic from the next page",
        created_at: "2026-10-01T12:00:00.000Z",
      },
    ];

    const model = this.owner.lookup("service:discovery").currentTopicList;
    model.set("more_topics_url", "/latest?page=1");
    await model.loadMore();
    await settled();

    assert
      .dom(".topic-list-item")
      .exists({ count: 5 }, "live updates and later pages retain all topics");
    assert
      .dom(".topic-list-item:nth-child(4)")
      .hasAttribute(
        "data-topic-id",
        "10005",
        "the next page keeps its creation position"
      );
    assert
      .dom(".topic-list-item:nth-child(5)")
      .hasAttribute(
        "data-topic-id",
        "9999",
        "the old reply stays below the next page"
      );
  });
});
