/* eslint-disable ember/template-no-pointer-down-event-binding -- Fixtures exercise capture before native bubbling dismissal. */
import { hash } from "@ember/helper";
import { on } from "@ember/modifier";
import {
  clearRender,
  click,
  find,
  render,
  settled,
  triggerEvent,
  waitFor,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import Topic from "discourse/models/topic";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFReplyNavigation from "../../discourse/components/isbf-reply-navigation";
import { ISBFTopicReadingJump } from "../../discourse/components/isbf-topic-reading";
import isbfCloseOnClickOutside from "../../discourse/modifiers/isbf-close-on-click-outside";

module(
  "ISBF | Integration | Component | ISBFReplyNavigation",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.nested_replies_enabled = true;
      this.siteSettings.nested_replies_cap_nesting_depth = true;
      this.siteSettings.nested_replies_max_depth = 1;
      sinon
        .stub(this.owner.lookup("service:router"), "currentURL")
        .get(() => "/t/conversations/990011");
      this.topic = Topic.create({
        id: 990011,
        slug: "conversations",
        title: "Conversations",
        archetype: "regular",
        is_nested_view: true,
        posts_count: 3,
        highest_post_number: 3,
        created_at: "2026-10-14T00:00:00Z",
        last_posted_at: "2026-10-15T00:00:00Z",
        last_read_post_number: 1,
        reply_navigation: { root_count: 2, root_index: 1, reply_count: 2 },
      });
    });

    hooks.afterEach(function () {
      sinon.restore();
    });

    test("native expansion keeps the grouped timeline floating across repeated opens", async function (assert) {
      await render(
        <template>
          <div class="isbf-v2-shell--topic isbf-v2-shell--topic-feed-style">
            <header class="isbf-v2-page-header"></header>
          </div>
          <main id="main-outlet">
            <div class="nested-view">
              <ISBFReplyNavigation @outletArgs={{hash topic=this.topic}} />
            </div>
          </main>
        </template>
      );
      const toggle = ".isbf-topic-reading__toggle";
      const panel = ".topic-navigation:has(.isbf-topic-reading__heading)";
      await waitFor(toggle);
      assert
        .dom(toggle)
        .hasAttribute("aria-expanded", "false", "reading starts collapsed");
      for (let cycle = 0; cycle < 3; cycle++) {
        await click(toggle);
        await waitFor(`${panel}.topic-progress-expanded`);
        assert
          .dom(`${panel} .isbf-topic-reading__heading`)
          .isVisible("the heading survives native rerendering");
        assert.strictEqual(
          getComputedStyle(find(panel)).position,
          "fixed",
          "the panel floats after expansion"
        );
        assert.strictEqual(
          getComputedStyle(find(`${panel} .timeline-container`)).position,
          "static",
          "the native timeline stays inside the panel"
        );
        await click(".isbf-topic-reading__close");
        assert
          .dom(toggle)
          .hasAttribute(
            "aria-expanded",
            "false",
            "explicit closing collapses reading"
          );
      }
      await clearRender();
      assert
        .dom(toggle)
        .doesNotExist("destroying the topic releases its header control");
    });
  }
);

module(
  "ISBF | Integration | Modifier | isbf-close-on-click-outside",
  function (hooks) {
    setupRenderingTest(hooks);

    test("outside dismissal precedes a target that stops bubbling", async function (assert) {
      const close = () => assert.step("close");
      const stop = (event) => {
        assert.step("target");
        event.stopPropagation();
      };
      await render(
        <template>
          <div class="panel" {{isbfCloseOnClickOutside close}}>
            <button class="inside" type="button">Inside</button>
          </div>
          <button
            class="outside"
            type="button"
            {{on "pointerdown" stop}}
          >Outside</button>
        </template>
      );
      await triggerEvent(".inside", "pointerdown");
      await triggerEvent(".outside", "pointerdown");
      assert.verifySteps(
        ["close", "target"],
        "only outside presses dismiss, before bubbling handlers"
      );
    });

    test("the native panel and detached trigger are excluded", async function (assert) {
      const close = () => assert.step("close");
      const options = {
        targetSelector: ".navigation",
        secondaryTargetSelector: ".trigger",
      };
      await render(
        <template>
          <div class="panel" {{isbfCloseOnClickOutside close options}}></div>
          <button class="navigation" type="button">Navigation</button>
          <button class="trigger" type="button">Trigger</button>
          <button class="outside" type="button">Outside</button>
        </template>
      );
      await triggerEvent(".navigation", "pointerdown");
      await triggerEvent(".trigger", "pointerdown");
      await triggerEvent(".outside", "pointerdown");
      assert.verifySteps(
        ["close"],
        "UI kit target exclusions also apply during capture"
      );
    });

    test("changing targets replaces the listener and teardown removes it", async function (assert) {
      const close = () => assert.step("close");
      this.set("options", { targetSelector: ".first" });
      await render(
        <template>
          <div
            class="panel"
            {{isbfCloseOnClickOutside close this.options}}
          ></div>
          <button class="first" type="button">First</button>
          <button class="second" type="button">Second</button>
        </template>
      );
      this.set("options", { targetSelector: ".second" });
      await triggerEvent(".first", "pointerdown");
      await triggerEvent(".second", "pointerdown");
      assert.verifySteps(
        ["close"],
        "a changed target excludes only the new target without duplicate calls"
      );
      await clearRender();
      await triggerEvent(document.body, "pointerdown");
      assert.verifySteps([], "destroyed panels leave no capture listener");
    });
  }
);

module(
  "ISBF | Integration | Component | ISBFTopicReadingJump",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.topic = Topic.create({
        id: 990010,
        archetype: "regular",
        currentPost: 1,
        last_read_post_id: 105,
        last_read_post_number: 5,
      });
      this.topic.postStream.set(
        "stream",
        Array.from({ length: 10 }, (_, index) => 101 + index)
      );
      this.controller = this.owner.lookup("controller:topic");
      this.controller.set("currentPostId", 101);
      this.set("outletArgs", { model: this.topic, fullscreen: true });
    });

    test("the footer returns to the native index within a filtered stream", async function (assert) {
      const jump = sinon.stub(this.controller, "send");
      this.topic.set("last_read_post_number", 9);
      await render(
        <template>
          <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert
        .dom(".isbf-topic-reading__back")
        .exists("the expanded footer offers the previous reading position");
      await click(".isbf-topic-reading__back");
      assert.true(
        jump.calledOnceWithExactly("jumpToIndex", 5),
        "the native jump receives the stream index rather than the post number"
      );
      jump.restore();
    });

    test("nearby or unavailable previous positions do not add a return button", async function (assert) {
      this.topic.set("last_read_post_id", 104);
      await render(
        <template>
          <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert
        .dom(".isbf-topic-reading__back")
        .doesNotExist("a nearby position follows the native return threshold");
      this.topic.set("last_read_post_id", 999);
      await settled();
      assert
        .dom(".isbf-topic-reading__back")
        .doesNotExist(
          "a position absent from the filtered stream cannot be targeted"
        );
    });

    test("other navigation modes keep their existing controls", async function (assert) {
      this.set("outletArgs", { model: this.topic, fullscreen: false });
      await render(
        <template>
          <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert
        .dom(".isbf-topic-reading__back")
        .doesNotExist("collapsed navigation retains its native return control");
      assert
        .dom(".isbf-topic-reading__jump")
        .exists("the existing jump prompt remains available");
      this.topic.set("archetype", "private_message");
      this.set("outletArgs", { model: this.topic, fullscreen: true });
      assert
        .dom(".isbf-topic-reading__back")
        .doesNotExist("private messages do not receive the topic-only footer");
    });
  }
);
