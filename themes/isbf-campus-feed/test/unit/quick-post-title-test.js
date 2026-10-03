import { module, test } from "qunit";
import { quickPostTitle } from "../../discourse/lib/quick-post-title";

module("ISBF Campus Feed | Unit | Lib | quick-post-title", function () {
  test("preserves enough text when the minimum title length exceeds 80", function (assert) {
    const title = quickPostTitle("学".repeat(150), 120, 200);

    assert.strictEqual(
      title,
      "学".repeat(120),
      "the generated title meets the configured minimum"
    );
  });

  test("limits Unicode characters without splitting an emoji", function (assert) {
    const title = quickPostTitle(`${"a".repeat(78)}🎓毕业`, 1, 80);

    assert.strictEqual(
      title,
      `${"a".repeat(78)}🎓`,
      "the emoji remains intact at the title boundary"
    );
    assert.strictEqual(
      quickPostTitle(`${"a".repeat(79)}🎓毕业`, 1, 80),
      "a".repeat(79),
      "an emoji that exceeds the client length limit is omitted in full"
    );
  });

  test("counts emoji as characters when applying the minimum length", function (assert) {
    const title = quickPostTitle("🎓🎓🎓", 6, 80);

    assert.true(
      Array.from(title).length >= 6,
      "the title meets the server's character limit"
    );
  });
});
