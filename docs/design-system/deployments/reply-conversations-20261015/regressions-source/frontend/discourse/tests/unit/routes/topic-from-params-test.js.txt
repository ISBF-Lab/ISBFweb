import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";
import TopicFromParams, {
  nestedQueryString,
} from "discourse/routes/topic/from-params";

module("Unit | Route | topic.from-params", function (hooks) {
  setupTest(hooks);

  hooks.afterEach(function () {
    this.owner.lookup("controller:nested").unsubscribe();
    sinon.restore();
  });

  test("same-topic original links reuse loaded groups and expansion state", async function (assert) {
    const route = this.owner.lookup("route:topic.from-params");
    const nested = this.owner.lookup("controller:nested");
    const store = this.owner.lookup("service:store");
    const settings = this.owner.lookup("service:site-settings");
    Object.assign(settings, {
      nested_replies_enabled: true,
      nested_replies_cap_nesting_depth: true,
      nested_replies_max_depth: 1,
    });
    const topic = store.createRecord("topic", {
      id: 724,
      slug: "same-topic",
      is_nested_view: true,
    });
    const opPost = store.createRecord("post", {
      id: 2000,
      post_number: 1,
      topic,
    });
    const root = store.createRecord("post", {
      id: 2001,
      post_number: 2,
      topic,
    });
    const child = store.createRecord("post", {
      id: 2002,
      post_number: 6,
      topic,
    });
    nested.setProperties({
      topic,
      opPost,
      rootNodes: [{ post: root, children: [{ post: child, children: [] }] }],
      sort: "top",
      effectiveSort: "old",
      context: null,
      contextMode: false,
    });
    nested.expansionState.set(2, { expanded: true, collapsed: false });
    const expansions = nested.expansionState;
    const children = nested.fetchedChildrenCache;
    sinon.stub(route, "modelFor").returns(topic);

    const result = await route.model({
      id: 724,
      slug: "same-topic",
      nearPost: "6",
    });
    assert.strictEqual(
      result._nested.topic,
      topic,
      "keeps the active topic record"
    );
    assert.strictEqual(
      result._nested.rootNodes,
      nested.rootNodes,
      "keeps all loaded groups without refetching"
    );
    assert.strictEqual(
      result._nested.targetPostNumber,
      6,
      "retains the explicit original target"
    );
    assert.strictEqual(
      nested.expansionState,
      expansions,
      "does not clear expansion state"
    );
    assert.strictEqual(
      nested.fetchedChildrenCache,
      children,
      "does not clear loaded replies"
    );

    const original = await route.model({
      id: 724,
      slug: "same-topic",
      nearPost: "1",
    });
    assert.strictEqual(
      original._nested.targetPostNumber,
      1,
      "the original topic post is also an explicit highlight target"
    );
    assert.strictEqual(
      original._nested.rootNodes,
      nested.rootNodes,
      "jumping to the OP keeps the expanded discussion"
    );
  });

  test("opts out of the global route scroll manager", function (assert) {
    assert.deepEqual(TopicFromParams.prototype.buildRouteInfoMetadata(), {
      scrollOnTransition: false,
    });
  });

  test("encodes nested JSON query params", function (assert) {
    const query = nestedQueryString({
      sort: "new&track_visit=false",
      track_visit: true,
      context: "0&sort=old",
      skipped: null,
    });
    const parsed = new URLSearchParams(query);

    assert.strictEqual(parsed.get("sort"), "new&track_visit=false");
    assert.strictEqual(parsed.get("track_visit"), "true");
    assert.strictEqual(parsed.get("context"), "0&sort=old");
    assert.false(parsed.has("skipped"));
    assert.false(parsed.has("bad"), "does not allow query injection");
  });

  test("saves current nested topic before swapping topics", function (assert) {
    const route = this.owner.lookup("route:topic.from-params");
    const article = document.createElement("article");
    article.dataset.postNumber = "3";
    const wrapper = document.createElement("div");
    wrapper.className = "nested-post";
    wrapper.appendChild(article);
    document.body.appendChild(wrapper);

    let screenTrackStopped = 0;
    let screenTrackStarted = 0;

    Object.defineProperty(route, "appEvents", {
      value: { trigger() {} },
    });
    Object.defineProperty(route, "screenTrack", {
      value: {
        start() {
          screenTrackStarted += 1;
        },
        stop() {
          screenTrackStopped += 1;
        },
      },
    });

    const nestedController = {
      topic: { id: 1 },
      unsubscribeCount: 0,
      savedAnchor: null,
      saveToCache(anchor) {
        this.savedAnchor = anchor;
      },
      setProperties(properties) {
        Object.assign(this, properties);
      },
      subscribe() {},
      unsubscribe() {
        this.unsubscribeCount += 1;
      },
    };
    const topicController = {
      selectedPostIds: [1],
      set(key, value) {
        this[key] = value;
      },
      setProperties(properties) {
        Object.assign(this, properties);
      },
      subscribe() {},
    };
    const nextTopic = {
      id: 2,
      details: { set() {} },
      draft: null,
      highest_post_number: 3,
      last_read_post_number: 1,
      postStream: null,
    };

    route.controllerFor = (name) => {
      if (name === "nested") {
        return nestedController;
      }

      return topicController;
    };

    try {
      route.setupController(
        null,
        {
          _nested: {
            topic: nextTopic,
            contextMode: true,
            sort: "top",
          },
        },
        {}
      );

      assert.strictEqual(
        nestedController.savedAnchor.postNumber,
        3,
        "saves the previous nested topic cache with the current scroll anchor"
      );
      assert.strictEqual(
        nestedController.unsubscribeCount,
        1,
        "unsubscribes the previous nested topic once"
      );
      assert.strictEqual(
        screenTrackStopped,
        1,
        "stops screen tracking for the previous nested topic"
      );
      assert.strictEqual(
        nestedController.topic,
        nextTopic,
        "sets up the new nested topic"
      );
      assert.strictEqual(
        screenTrackStarted,
        1,
        "starts tracking the new topic"
      );
    } finally {
      wrapper.remove();
    }
  });
});
