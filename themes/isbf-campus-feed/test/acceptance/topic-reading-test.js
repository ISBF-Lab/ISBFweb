import {
  click,
  find,
  triggerEvent,
  triggerKeyEvent,
  visit,
  waitFor,
} from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const TOPIC = "/t/internationalization-localization/280";
const TOGGLE = ".isbf-topic-reading__toggle";
const NAVIGATION = ".topic-navigation:has(.isbf-topic-reading__heading)";

function topicReadingPretender(server, helper) {
  server.get("/t/280/excerpts.json", () => helper.response([]));
  server.get("/filter.json", () =>
    helper.response({ users: [], topic_list: { topics: [] } })
  );
  server.post("/isbf/views/impressions", () => helper.response({}));
  server.post("/isbf/views/post-impressions", () => helper.response({}));
}

acceptance("ISBF floating topic reading", function (needs) {
  needs.user();
  needs.pretender(topicReadingPretender);

  test("the header controls the single native timeline at desktop widths", async function (assert) {
    await visit(TOPIC);
    assert
      .dom(TOGGLE)
      .hasAttribute("aria-expanded", "false", "reading starts collapsed");
    assert
      .dom(".isbf-v2-rail")
      .doesNotHaveClass(
        "has-topic-reading",
        "the rail reserves no reading space"
      );
    await triggerEvent(TOGGLE, "pointerdown");
    await click(TOGGLE);
    await waitFor(`${NAVIGATION}.topic-progress-expanded`);
    assert
      .dom(`${NAVIGATION} .isbf-topic-reading__heading`)
      .isVisible("native class updates retain the floating heading");
    assert.strictEqual(
      getComputedStyle(find(NAVIGATION)).position,
      "fixed",
      "the navigation remains a floating panel after expansion"
    );
    assert.strictEqual(
      getComputedStyle(find(`${NAVIGATION} .timeline-container`)).position,
      "static",
      "the native timeline does not become a bottom sheet"
    );
    assert
      .dom(TOGGLE)
      .hasAttribute("aria-expanded", "true", "the header expands reading");
    assert
      .dom(".topic-navigation .timeline-container")
      .exists({ count: 1 }, "reading uses one native timeline");
    await triggerEvent(TOGGLE, "pointerdown");
    await click(TOGGLE);
    await triggerEvent(TOGGLE, "pointerdown");
    await click(TOGGLE);
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "true",
        "reopening does not inherit an outside close"
      );
    await click(".isbf-topic-reading__close");
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "false",
        "the close control collapses reading"
      );
    assert
      .dom(TOGGLE)
      .isFocused("explicit closing returns focus to the opener");
  });

  test("an outside press closes reading without taking the clicked target's focus", async function (assert) {
    await visit(TOPIC);
    await click(TOGGLE);
    const outside = find(".isbf-v2-page-header__back");
    outside.focus();
    await triggerEvent(outside, "pointerdown");
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "false",
        "an outside press collapses reading"
      );
    assert
      .dom(outside)
      .isFocused("outside dismissal retains the intended focus");
    await click(TOGGLE);
    assert
      .dom(TOGGLE)
      .hasAttribute("aria-expanded", "true", "reading can immediately reopen");
  });

  test("Escape closes reading and leaving the topic removes its opener", async function (assert) {
    await visit(TOPIC);
    await click(TOGGLE);
    await triggerKeyEvent(TOGGLE, "keydown", "Escape");
    assert
      .dom(TOGGLE)
      .hasAttribute("aria-expanded", "false", "Escape collapses reading");
    assert.dom(TOGGLE).isFocused("Escape returns focus to the opener");
    await visit("/latest");
    assert.dom(TOGGLE).doesNotExist("the topic opener is removed when leaving");
    assert.dom(NAVIGATION).doesNotExist("the reading layout is released");
  });

  test("another topic starts collapsed after navigating with reading open", async function (assert) {
    await visit(TOPIC);
    await click(TOGGLE);
    await visit("/t/1-3-0beta9-no-rate-limit-popups/28830");
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "false",
        "a new topic does not inherit expanded reading"
      );
    assert
      .dom(".topic-navigation")
      .exists(
        { count: 1 },
        "the new topic retains a single navigation instance"
      );
  });

  test("jumping still opens the native modal and Escape closes the modal first", async function (assert) {
    await visit(TOPIC);
    await click(TOGGLE);
    await click(".timeline-open-jump-to-post-prompt-btn");
    assert.dom(".d-modal").exists("the native jump flow remains available");
    await triggerKeyEvent(".d-modal input", "keydown", "Escape");
    assert.dom(".d-modal").doesNotExist("Escape dismisses the jump modal");
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "true",
        "the modal does not consume reading's Escape"
      );
  });
});

acceptance("ISBF floating topic reading on touch", function (needs) {
  needs.user();
  needs.mobileView();
  needs.pretender(topicReadingPretender);

  test("reading does not start the bottom-sheet swipe behavior", async function (assert) {
    await visit(TOPIC);
    await click(TOGGLE);
    const navigation = find(NAVIGATION);
    const swipe = new CustomEvent("swipestart", { cancelable: true });
    assert.false(
      navigation.dispatchEvent(swipe),
      "the sheet gesture is cancelled before its native handler"
    );
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "true",
        "the floating timeline remains open"
      );
    assert
      .dom(".timeline-scroller[data-pointer-drag]")
      .exists("the native timeline drag remains installed");
    await click(".isbf-topic-reading__close");
    assert
      .dom(TOGGLE)
      .hasAttribute(
        "aria-expanded",
        "false",
        "touch users can close explicitly"
      );
  });
});
