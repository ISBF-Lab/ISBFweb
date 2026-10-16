/* eslint-disable ember/template-no-pointer-down-event-binding -- Fixtures exercise capture before native bubbling dismissal. */import { on } from "@ember/modifier";
import { clearRender, click, render, settled, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import Topic from "discourse/models/topic";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { ISBFTopicReadingJump } from "../../discourse/components/isbf-topic-reading";
import isbfCloseOnClickOutside from "../../discourse/modifiers/isbf-close-on-click-outside";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
module("ISBF | Integration | Modifier | isbf-close-on-click-outside", function (hooks) {
  setupRenderingTest(hooks);
  test("outside dismissal precedes a target that stops bubbling", async function (assert) {
    const close = () => assert.step("close");
    const stop = event => {
      assert.step("target");
      event.stopPropagation();
    };
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <div class="panel" {{isbfCloseOnClickOutside close}}>
      <button class="inside" type="button">Inside</button>
    </div>
    <button
      class="outside"
      type="button"
      {{on "pointerdown" stop}}
    >Outside</button>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"panel\"],[4,[32,0],[[32,1]],null],[12],[1,\"\\n  \"],[10,\"button\"],[14,0,\"inside\"],[14,4,\"button\"],[12],[1,\"Inside\"],[13],[1,\"\\n\"],[13],[1,\"\\n\"],[11,\"button\"],[24,0,\"outside\"],[24,4,\"button\"],[4,[32,2],[\"pointerdown\",[32,3]],null],[12],[1,\"Outside\"],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        isbfCloseOnClickOutside,
        close,
        on,
        stop
      }),
      "isStrictMode": true
    }), templateOnly()));
    await triggerEvent(".inside", "pointerdown");
    await triggerEvent(".outside", "pointerdown");
    assert.verifySteps(["close", "target"], "only outside presses dismiss, before bubbling handlers");
  });
  test("the native panel and detached trigger are excluded", async function (assert) {
    const close = () => assert.step("close");
    const options = {
      targetSelector: ".navigation",
      secondaryTargetSelector: ".trigger"
    };
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <div class="panel" {{isbfCloseOnClickOutside close options}}></div>
    <button class="navigation" type="button">Navigation</button>
    <button class="trigger" type="button">Trigger</button>
    <button class="outside" type="button">Outside</button>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"panel\"],[4,[32,0],[[32,1],[32,2]],null],[12],[13],[1,\"\\n\"],[10,\"button\"],[14,0,\"navigation\"],[14,4,\"button\"],[12],[1,\"Navigation\"],[13],[1,\"\\n\"],[10,\"button\"],[14,0,\"trigger\"],[14,4,\"button\"],[12],[1,\"Trigger\"],[13],[1,\"\\n\"],[10,\"button\"],[14,0,\"outside\"],[14,4,\"button\"],[12],[1,\"Outside\"],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        isbfCloseOnClickOutside,
        close,
        options
      }),
      "isStrictMode": true
    }), templateOnly()));
    await triggerEvent(".navigation", "pointerdown");
    await triggerEvent(".trigger", "pointerdown");
    await triggerEvent(".outside", "pointerdown");
    assert.verifySteps(["close"], "UI kit target exclusions also apply during capture");
  });
  test("changing targets replaces the listener and teardown removes it", async function (assert) {
    const close = () => assert.step("close");
    this.set("options", {
      targetSelector: ".first"
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <div
      class="panel"
      {{isbfCloseOnClickOutside close this.options}}
    ></div>
    <button class="first" type="button">First</button>
    <button class="second" type="button">Second</button>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"panel\"],[4,[32,0],[[32,1],[32,2,[\"options\"]]],null],[12],[13],[1,\"\\n\"],[10,\"button\"],[14,0,\"first\"],[14,4,\"button\"],[12],[1,\"First\"],[13],[1,\"\\n\"],[10,\"button\"],[14,0,\"second\"],[14,4,\"button\"],[12],[1,\"Second\"],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        isbfCloseOnClickOutside,
        close,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    this.set("options", {
      targetSelector: ".second"
    });
    await triggerEvent(".first", "pointerdown");
    await triggerEvent(".second", "pointerdown");
    assert.verifySteps(["close"], "a changed target excludes only the new target without duplicate calls");
    await clearRender();
    await triggerEvent(document.body, "pointerdown");
    assert.verifySteps([], "destroyed panels leave no capture listener");
  });
});
module("ISBF | Integration | Component | ISBFTopicReadingJump", function (hooks) {
  setupRenderingTest(hooks);
  hooks.beforeEach(function () {
    this.topic = Topic.create({
      id: 990010,
      archetype: "regular",
      currentPost: 1,
      last_read_post_id: 105,
      last_read_post_number: 5
    });
    this.topic.postStream.set("stream", Array.from({
      length: 10
    }, (_, index) => 101 + index));
    this.controller = this.owner.lookup("controller:topic");
    this.controller.set("currentPostId", 101);
    this.set("outletArgs", {
      model: this.topic,
      fullscreen: true
    });
  });
  test("the footer returns to the native index within a filtered stream", async function (assert) {
    const jump = sinon.stub(this.controller, "send");
    this.topic.set("last_read_post_number", 9);
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@outletArgs\"],[[32,1,[\"outletArgs\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFTopicReadingJump,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-topic-reading__back").exists("the expanded footer offers the previous reading position");
    await click(".isbf-topic-reading__back");
    assert.true(jump.calledOnceWithExactly("jumpToIndex", 5), "the native jump receives the stream index rather than the post number");
    jump.restore();
  });
  test("nearby or unavailable previous positions do not add a return button", async function (assert) {
    this.topic.set("last_read_post_id", 104);
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@outletArgs\"],[[32,1,[\"outletArgs\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFTopicReadingJump,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-topic-reading__back").doesNotExist("a nearby position follows the native return threshold");
    this.topic.set("last_read_post_id", 999);
    await settled();
    assert.dom(".isbf-topic-reading__back").doesNotExist("a position absent from the filtered stream cannot be targeted");
  });
  test("other navigation modes keep their existing controls", async function (assert) {
    this.set("outletArgs", {
      model: this.topic,
      fullscreen: false
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFTopicReadingJump @outletArgs={{this.outletArgs}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@outletArgs\"],[[32,1,[\"outletArgs\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFTopicReadingJump,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-topic-reading__back").doesNotExist("collapsed navigation retains its native return control");
    assert.dom(".isbf-topic-reading__jump").exists("the existing jump prompt remains available");
    this.topic.set("archetype", "private_message");
    this.set("outletArgs", {
      model: this.topic,
      fullscreen: true
    });
    assert.dom(".isbf-topic-reading__back").doesNotExist("private messages do not receive the topic-only footer");
  });
});