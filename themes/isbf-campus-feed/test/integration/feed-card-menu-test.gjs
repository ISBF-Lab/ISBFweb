import {
  clearRender,
  click,
  findAll,
  render,
  settled,
  triggerEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DMenus from "discourse/float-kit/components/d-menus";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFFeedCardMenu from "../../discourse/components/isbf-feed-card-menu";

const trigger = ".isbf-feed-card__menu-trigger";
const items = ".isbf-feed-card__menu [role='menuitem']";

async function renderMenu(context) {
  await render(
    <template>
      <DMenus />
      <button class="outside" type="button">Outside</button>
      <ISBFFeedCardMenu
        @canFlag={{context.canFlag}}
        @canManageHomePin={{context.canPin}}
        @isFlagging={{context.flagging}}
        @isPinning={{context.pinning}}
        @onFlag={{context.flag}}
        @onPin={{context.pin}}
        @onRegisterApi={{context.register}}
        @onUnpin={{context.unpin}}
        @pinned={{context.pinned}}
      />
    </template>
  );
}

module("ISBF | Integration | Feed card menu", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.canFlag = true;
    this.canPin = true;
    this.pinned = true;
    this.pinning = false;
    this.flagging = false;
    this.register = (menu) => {
      this.menu = menu;
    };
    this.flag = sinon.spy();
    this.pin = sinon.spy();
    this.unpin = sinon.spy();
  });

  test("only available actions are rendered and empty menus are hidden", async function (assert) {
    this.canPin = false;
    await renderMenu(this);
    await click(trigger);
    assert.dom(items).exists({ count: 1 });
    await click(items);
    assert.true(this.flag.calledOnce);
    assert.false(this.pin.called);
    await this.menu.close();
    this.set("canFlag", false);
    assert.dom(trigger).doesNotExist();
  });

  test("arrows, Home and End move focus, and Escape returns it", async function (assert) {
    await renderMenu(this);
    await click(trigger);
    const actions = findAll(items);
    assert.strictEqual(document.activeElement, actions[0]);
    await triggerEvent(actions[0], "keydown", { key: "ArrowDown" });
    assert.strictEqual(document.activeElement, actions[1]);
    await triggerEvent(actions[1], "keydown", { key: "End" });
    assert.strictEqual(document.activeElement, actions[2]);
    await triggerEvent(actions[2], "keydown", { key: "Home" });
    assert.strictEqual(document.activeElement, actions[0]);
    await triggerEvent(actions[0], "keydown", { key: "ArrowUp" });
    assert.strictEqual(document.activeElement, actions[2]);
    await triggerEvent(actions[2], "keydown", { key: "Escape" });
    assert.dom(".isbf-feed-card__menu").doesNotExist();
    assert.dom(document.activeElement).hasClass("isbf-feed-card__menu-trigger");
  });

  test("request states disable their actions and keyboard navigation skips them", async function (assert) {
    this.pinning = true;
    await renderMenu(this);
    await click(trigger);
    const actions = findAll(items);
    assert.dom(actions[0]).isDisabled();
    assert.dom(actions[1]).isDisabled();
    assert.dom(actions[2]).isNotDisabled();
    assert.strictEqual(document.activeElement, actions[2]);
    await triggerEvent(actions[2], "keydown", { key: "Home" });
    assert.strictEqual(document.activeElement, actions[2]);
    this.set("pinning", false);
    await settled();
    await triggerEvent(actions[2], "keydown", { key: "Home" });
    assert.strictEqual(document.activeElement, actions[0]);
  });

  test("outside click and destruction release the floating menu", async function (assert) {
    await renderMenu(this);
    await click(trigger);
    await triggerEvent(".outside", "pointerdown");
    assert.dom(".isbf-feed-card__menu").doesNotExist();
    await click(trigger);
    await clearRender();
    assert.dom(".isbf-feed-card-menu").doesNotExist();
  });

  test("pin actions retain their original callbacks", async function (assert) {
    await renderMenu(this);
    await click(trigger);
    await click(findAll(items)[0]);
    assert.true(this.pin.calledOnce);
    await click(findAll(items)[1]);
    assert.true(this.unpin.calledOnce);
    assert.false(this.flag.called);
  });
});
