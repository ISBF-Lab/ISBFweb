import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import { withPluginApi } from "discourse/lib/plugin-api";
import topicDisplayTitle from "discourse/lib/topic-display-title";
import { fancyTitle } from "discourse/lib/topic-fancy-title";

module("Unit | Utility | topic display title", function (hooks) {
  setupTest(hooks);

  test("without a presentation override the original titles and markup remain", function (assert) {
    assert.strictEqual(topicDisplayTitle("A title"), "A title");
    assert.strictEqual(
      fancyTitle("<b>A title</b>", false, { title: "A title" }),
      "<b>A title</b>"
    );
  });

  test("presentation text is escaped without changing source content", function (assert) {
    const resource = { title: "Original title", excerpt: "Body" };
    withPluginApi((api) => {
      api.registerValueTransformer("topic-display-title", ({ context }) => {
        assert.strictEqual(context.resource, resource);
        return "Body <img src=x onerror=alert(1)> & text";
      });
    });
    assert.strictEqual(
      fancyTitle("Original title", false, resource),
      "Body &lt;img src=x onerror=alert(1)&gt; &amp; text"
    );
    assert.deepEqual(resource, { title: "Original title", excerpt: "Body" });
  });

  test("an available localized title precedes presentation overrides", function (assert) {
    let transformed = false;
    withPluginApi((api) => {
      api.registerValueTransformer("topic-display-title", () => {
        transformed = true;
        return "Original-language body";
      });
    });
    const topic = {
      title: "Generated title",
      fancy_title: "<b>Translated &amp; title</b>",
      fancy_title_localized: true,
    };
    assert.strictEqual(
      fancyTitle(topic.fancy_title, false, topic),
      topic.fancy_title
    );
    assert.strictEqual(
      fancyTitle("Highlighted original", false, { topic }),
      topic.fancy_title
    );
    assert.false(
      transformed,
      "selected translations bypass the body preview override"
    );
  });
});
