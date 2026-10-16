import { module, test } from "qunit";
import {
  flatReplyItems,
  mergeFlatReplyPage,
  mergeFlatReplyPreload,
} from "discourse/lib/flat-reply-pages";

const nodes = (start, length) =>
  Array.from({ length }, (_, index) => ({
    post: { id: start + index, post_number: start + index },
    children: [],
  }));

module("Unit | Lib | flat-reply-pages", function () {
  test("a preview cannot replace a complete loaded page", function (assert) {
    const page = nodes(3, 50);
    const loaded = mergeFlatReplyPage(null, page, { page: 0, count: 100 });
    const restored = mergeFlatReplyPreload(loaded, page.slice(0, 3), {
      count: 100,
    });

    assert.strictEqual(
      restored.childNodes.length,
      50,
      "retains all loaded replies"
    );
    assert.deepEqual(restored.loadedPages, [0], "retains page completeness");
    assert.strictEqual(
      restored.childNodes[3],
      page[3],
      "retains node identity"
    );
  });

  test("disjoint target pages keep separate loadable gaps", function (assert) {
    const all = nodes(3, 200);
    const initial = mergeFlatReplyPreload(
      null,
      [...all.slice(0, 3), ...all.slice(150)],
      { page: 3, count: 200 }
    );
    const merged = mergeFlatReplyPage(initial, all.slice(50, 100), {
      page: 1,
      count: 200,
    });

    assert.deepEqual(
      flatReplyItems(merged)
        .filter((item) => item.gap)
        .map((item) => item.page),
      [0, 2],
      "each missing range has its own load action"
    );
    const filled = mergeFlatReplyPage(
      mergeFlatReplyPage(merged, all.slice(0, 50), { page: 0, count: 200 }),
      all.slice(100, 150),
      { page: 2, count: 200 }
    );
    assert.strictEqual(
      filled.childNodes.length,
      200,
      "merges every page without duplicates"
    );
    assert.false(
      flatReplyItems(filled).some((item) => item.gap),
      "removes filled gaps"
    );
    assert.false(
      filled.hasMore,
      "does not request a page beyond the last reply"
    );
  });

  test("a saved tail reply stays visible while earlier pages are missing", function (assert) {
    const preview = mergeFlatReplyPreload(null, nodes(3, 3), { count: 100 });
    const saved = mergeFlatReplyPage(preview, nodes(103, 1), {
      count: 101,
      saved: true,
    });
    const refreshed = mergeFlatReplyPage(saved, nodes(3, 50), {
      page: 0,
      count: 101,
    });

    assert.strictEqual(
      refreshed.childNodes.at(-1).post.id,
      103,
      "keeps the saved reply"
    );
    assert.deepEqual(
      refreshed.loadedPages,
      [0],
      "does not mark the tail page complete"
    );
    assert.strictEqual(
      flatReplyItems(refreshed).find((item) => item.gap).page,
      1,
      "earlier replies remain loadable"
    );
  });
});
