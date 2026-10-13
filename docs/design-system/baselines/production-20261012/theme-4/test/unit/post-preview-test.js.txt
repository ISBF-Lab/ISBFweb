import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import {
  isActivityPreview,
  postPreview,
} from "../../discourse/lib/post-preview";

module("ISBF | Unit | Lib | post-preview", function (hooks) {
  setupTest(hooks);

  test("image metadata is omitted while text and optimized images remain", function (assert) {
    const preview = postPreview(`
      <p>Campus update.</p>
      <div class="lightbox-wrapper">
        <a class="lightbox" href="/uploads/original.png">
          <img src="/uploads/optimized.png" alt="2488243601b3ff3b12a9ad5fad7462c7">
          <span class="meta">2488243601b3ff3b12a9ad5fad7462c7 600×400</span>
        </a>
      </div>
      <p>[2488243601b3ff3b12a9ad5fad7462c7] is a code in the body.</p>
    `);
    assert.strictEqual(
      preview.text,
      "Campus update. [2488243601b3ff3b12a9ad5fad7462c7] is a code in the body.",
      "only image metadata is removed"
    );
    assert.strictEqual(
      preview.images[0].src,
      new URL("/uploads/optimized.png", window.location.href).href,
      "the cooked optimized image is used"
    );
  });

  test("native excerpt lightbox filenames do not become preview text", function (assert) {
    const preview = postPreview(
      '<p>Update</p><a class="lightbox" href="/uploads/image.png">[6d867eb3e135024af266d39ede56e870]</a>'
    );
    assert.strictEqual(preview.text, "Update", "the link caption is omitted");
    assert.deepEqual(
      preview.images,
      [],
      "original image links are not loaded as thumbnails"
    );
  });

  test("only safe post images enter the bounded gallery", function (assert) {
    const preview = postPreview(`
      <script>bad()</script><style>bad styles</style>
      <img class="emoji" src="/emoji/smile.png" alt=":smile:">
      <img src="javascript:bad()"><img class="avatar" src="/avatar.png">
      <img src="/a.png"><img src="/a.png"><img src="/b.png">
      <img src="/c.png"><img src="/d.png">
    `);
    assert.strictEqual(
      preview.text,
      ":smile:",
      "emoji text remains without script or style content"
    );
    assert.deepEqual(
      preview.images.map((image) => new URL(image.src).pathname),
      ["/a.png", "/b.png", "/c.png"],
      "unsafe URLs, avatars, duplicates, and excess images are omitted"
    );
  });

  test("long summaries keep complete Unicode characters", function (assert) {
    const preview = postPreview(`<p>${"🎓".repeat(301)}</p>`);
    assert.strictEqual(
      preview.text,
      `${"🎓".repeat(300)}…`,
      "the summary is bounded without splitting an emoji"
    );
  });

  test("public activity is eligible while other user tools remain native", function (assert) {
    const post = { post_id: 182, action_type: 4, post_type: 1 };
    assert.true(
      isActivityPreview(post, "/u/TerryM/activity"),
      "the activity overview is eligible"
    );
    assert.true(
      isActivityPreview(post, "/u/TerryM/activity/topics?offset=30"),
      "public filtered activity is eligible"
    );
    for (const page of [
      "drafts",
      "bookmarks",
      "pending",
      "messages",
      "notifications",
    ]) {
      assert.false(
        isActivityPreview(post, `/u/TerryM/activity/${page}`),
        `${page} keeps its native UI`
      );
    }
    assert.false(
      isActivityPreview({ ...post, action_type: 12 }, "/u/TerryM/activity"),
      "private messages are excluded"
    );
    assert.false(
      isActivityPreview(post, "/u/TerryM/preferences"),
      "other profile pages are excluded"
    );
  });
});
