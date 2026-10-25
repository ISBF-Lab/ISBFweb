import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import topicDisplayTitle from "../../discourse/lib/topic-display-title";

const TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";

module("ISBF | Unit | topic display title", function (hooks) {
  setupTest(hooks);

  test("only generated titles are replaced with clean body text", function (assert) {
    const resource = {
      excerpt: '<p>Campus update 🎓</p><a class="lightbox">[image.png]</a>',
    };
    assert.strictEqual(topicDisplayTitle(TITLE, resource), "Campus update 🎓");
    for (const title of [
      "校园动态",
      "校园动态 [fieldwork]",
      "An explicit title",
      "",
    ]) {
      assert.strictEqual(topicDisplayTitle(title, resource), title);
    }
    assert.strictEqual(
      topicDisplayTitle(TITLE, {
        excerpt: "<p>[fieldwork] stays in the body.</p>",
      }),
      "[fieldwork] stays in the body."
    );
  });

  test("pictures and inaccessible content use translated fallbacks", function (assert) {
    assert.strictEqual(
      topicDisplayTitle(TITLE, { cooked: '<img src="/photo.png">' }),
      "Picture"
    );
    for (const state of [
      { hidden: true },
      { deleted: true },
      { deleted_at: "2026-10-24" },
    ]) {
      assert.strictEqual(
        topicDisplayTitle(TITLE, { cooked: "<p>Private body.</p>", ...state }),
        "View post"
      );
    }
    assert.strictEqual(topicDisplayTitle(TITLE), "View post");
    assert.strictEqual(
      topicDisplayTitle(TITLE, {
        postStream: {
          posts: [
            { post_number: 1, hidden: true, cooked: "<p>Hidden body.</p>" },
          ],
        },
      }),
      "View post"
    );
  });

  test("authorized draft, pending, and search excerpts remain local", function (assert) {
    for (const resource of [
      { excerpt: "<p>Draft body.</p>", data: { title: TITLE } },
      { expandedExcerpt: "<p>Draft body.</p>" },
      { blurb: "<p>Draft <b>body.</b></p>" },
    ]) {
      assert.strictEqual(topicDisplayTitle(TITLE, resource), "Draft body.");
    }
    assert.strictEqual(
      topicDisplayTitle(TITLE, { cooked: `<p>${"🎓".repeat(301)}</p>` }),
      `${"🎓".repeat(300)}…`
    );
  });
});
