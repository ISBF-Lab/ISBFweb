import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import {
  processNestedContextResponse,
  processNestedRootResponse,
} from "discourse/lib/nested-topic-model";

module("Unit | Lib | nested-topic-model", function (hooks) {
  setupTest(hooks);

  test("a resolved system target opens the first post without a context chain", function (assert) {
    const model = processNestedContextResponse({
      data: {
        topic: { id: 1, slug: "nested-topic" },
        op_post: { id: 1, post_number: 1 },
        roots: [{ id: 2, post_number: 2, children: [] }],
        sort: "old",
        resolved_target_post_number: 1,
      },
      params: { post_number: 9, context: "0" },
      sort: "old",
      site: this.owner.lookup("service:site"),
      store: this.owner.lookup("service:store"),
    });

    assert.strictEqual(model.opPost.post_number, 1);
    assert.strictEqual(model.targetPostNumber, 1);
    assert.strictEqual(model.postNumber, 1);
    assert.strictEqual(model.context, null);
    assert.false(model.contextMode);
    assert.strictEqual(model.sort, "old");
    assert.strictEqual(model.rootNodes[0].post.post_number, 2);
  });

  test("a flat deep link keeps its outer discussion and exact target", function (assert) {
    const navigation = {
      root_count: 21,
      root_index: 21,
      root_post_number: 22,
      child_page: 1,
      reply_count: 121,
    };
    const options = {
      data: {
        topic: { id: 1, slug: "nested-topic" },
        navigation,
        roots: [
          {
            id: 22,
            post_number: 22,
            root_index: 21,
            target_post_number: 100,
            children_page: 1,
            children: [{ id: 100, post_number: 100, children: [] }],
          },
        ],
        page: 1,
        sort: "old",
        effective_sort: "old",
        has_more_roots: false,
      },
      params: { post_number: 100 },
      sort: "old",
      site: this.owner.lookup("service:site"),
      store: this.owner.lookup("service:store"),
    };
    const model = processNestedContextResponse(options);

    assert.strictEqual(model.targetPostNumber, 100);
    assert.strictEqual(model.rootNodes[0].post.post_number, 22);
    assert.strictEqual(model.rootNodes[0].children[0].post.post_number, 100);
    assert.strictEqual(model.page, 1);
    assert.strictEqual(
      model.firstRootPage,
      1,
      "retains the beginning of the loaded root window"
    );
    const refreshed = processNestedContextResponse(options);
    assert.notStrictEqual(
      model.rootNodes[0]._renderKey,
      refreshed.rootNodes[0]._renderKey,
      "refreshing the same group rebuilds its target page and expansion state"
    );
    assert.false(
      model.contextMode,
      "does not rebuild a deeply indented ancestor chain"
    );
    assert.deepEqual(model.topic.reply_navigation, navigation);
  });

  test("preserves requested and effective sorts", function (assert) {
    const model = processNestedRootResponse({
      data: {
        topic: { id: 1, slug: "nested-topic" },
        roots: [],
        sort: "hot",
        effective_sort: "top",
      },
      params: {},
      site: this.owner.lookup("service:site"),
      siteSettings: this.owner.lookup("service:site-settings"),
      store: this.owner.lookup("service:store"),
    });

    assert.strictEqual(model.sort, "hot", "keeps Hot selected");
    assert.strictEqual(
      model.effectiveSort,
      "top",
      "records the ordering used by the server"
    );
  });
});
