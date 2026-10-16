import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { withPluginApi } from "discourse/lib/plugin-api";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { eq } from "discourse/truth-helpers";

acceptance("More topics - Plugin API", function (needs) {
  needs.user();

  test("the content wrapper can replace one topic and yield for others", async function (assert) {
    withPluginApi((api) => {
      api.renderInOutlet(
        "more-topics-content",
        <template>
          {{#if (eq @outletArgs.topic.id 280)}}
            <p class="custom-more-topics">Custom topics for
              {{@outletArgs.topic.id}}</p>
          {{else}}
            {{yield}}
          {{/if}}
        </template>
      );
    });

    await visit("/t/-/280");
    assert
      .dom(".custom-more-topics")
      .hasText(
        "Custom topics for 280",
        "the wrapper receives the existing topic"
      );
    assert
      .dom(".more-topics__lists")
      .doesNotExist("a replacement does not duplicate the default list");
    await visit("/t/-/54077");
    assert
      .dom("#suggested-topics-title")
      .exists("yielding retains the native list for another topic");
  });

  test("displays the tabs", async function (assert) {
    withPluginApi((api) => {
      api.registerMoreTopicsTab({
        id: "my-tab",
        name: "News",
        component: <template>hello there!</template>,
        condition: ({ context, topic }) =>
          context === "topic" && topic.id === 280,
      });

      api.registerMoreTopicsTab({
        id: "my-pm-tab",
        name: "Other",
        component: <template>hi!</template>,
        condition: ({ context }) => context === "pm",
      });
    });

    await visit("/t/-/280");
    assert.dom(".more-topics__container li").exists({ count: 2 });
    assert.dom(".more-topics__container li:last-of-type").hasText("News");

    await click(`.more-topics__container button[title="News"]`);
    assert.dom(".more-topics__lists").hasText("hello there!");

    await visit("/t/-/12");
    assert.dom(".more-topics__container li").exists({ count: 2 });
    assert.dom(".more-topics__container li:last-of-type").hasText("Other");

    await click(`.more-topics__container button[title="Other"]`);
    assert.dom(".more-topics__lists").hasText("hi!");

    await visit("/t/-/54077");
    assert.dom(".more-topics__container li").doesNotExist();
    assert.dom(".more-topics__container #suggested-topics-title").exists();
  });
});
