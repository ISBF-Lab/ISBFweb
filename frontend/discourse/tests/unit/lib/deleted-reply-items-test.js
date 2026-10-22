import { module, test } from "qunit";
import deletedReplyItems from "discourse/lib/deleted-reply-items";

function item(number, attributes = {}, children = []) {
  return {
    key: number,
    node: {
      post: {
        id: number,
        post_number: number,
        reply_to_post_number: 1,
        deleted_post_placeholder: true,
        direct_reply_count: 0,
        total_descendant_count: 0,
        ...attributes,
      },
      children,
    },
  };
}

module("Unit | Utility | deleted-reply-items", function () {
  test("combines adjacent deleted leaves without changing source nodes", function (assert) {
    const items = [item(2), item(3), item(4)];
    const grouped = deletedReplyItems(items);
    assert.strictEqual(grouped.length, 1);
    assert.deepEqual(
      grouped[0].deletedPosts.map((post) => post.post_number),
      [2, 3, 4]
    );
    assert.strictEqual(grouped[0].node, items[0].node);
    assert.strictEqual(items[0].deletedPosts, undefined);
    assert.strictEqual(items.length, 3);
  });

  test("normal replies and missing pages separate deleted groups", function (assert) {
    const normal = item(4, { deleted_post_placeholder: false });
    const gap = { key: "gap:1", gap: true, page: 1 };
    const grouped = deletedReplyItems([
      item(2),
      item(3),
      normal,
      item(5),
      gap,
      item(7),
    ]);
    assert.strictEqual(grouped.length, 5);
    assert.strictEqual(grouped[1], normal);
    assert.strictEqual(grouped[3], gap);
    assert.deepEqual(
      grouped
        .filter((entry) => entry.deletedPosts)
        .map((entry) => entry.deletedPosts.length),
      [2, 1, 1]
    );
  });

  test("keeps deleted parents with replies or known descendants separate", function (assert) {
    const direct = item(2, { direct_reply_count: 1 });
    const descendants = item(3, { total_descendant_count: 1 });
    const loaded = item(4, {}, [item(5).node]);
    const grouped = deletedReplyItems([direct, descendants, loaded, item(6)]);
    assert.deepEqual(grouped.slice(0, 3), [direct, descendants, loaded]);
    assert.strictEqual(grouped.length, 4);
  });

  test("does not combine different parents", function (assert) {
    const grouped = deletedReplyItems([
      item(3, { reply_to_post_number: 2 }),
      item(4, { reply_to_post_number: 8 }),
    ]);
    assert.strictEqual(grouped.length, 2);
  });

  test("a missing root page separates loaded deleted replies", function (assert) {
    const grouped = deletedReplyItems([
      item(2, { root_index: 1 }),
      item(3, { root_index: 2 }),
      item(42, { root_index: 41 }),
      item(43, { root_index: 42 }),
    ]);
    assert.deepEqual(
      grouped.map((entry) => entry.deletedPosts.length),
      [2, 2]
    );
  });

  test("recovering a member splits the group and preserves ordering", function (assert) {
    const items = [item(2), item(3), item(4)];
    items[1].node.post.deleted_post_placeholder = false;
    const grouped = deletedReplyItems(items);
    assert.deepEqual(
      grouped.map((entry) => entry.node.post.post_number),
      [2, 3, 4]
    );
    assert.strictEqual(grouped[1].deletedPosts, undefined);
  });
});
