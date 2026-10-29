import {
  click,
  find,
  focus,
  render,
  triggerKeyEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import DMenu from "discourse/float-kit/components/d-menu";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

const anchor = ".card-anchor";
const trigger = ".fk-d-menu__trigger";
const float = ".fk-d-menu";

async function renderMenu(context) {
  await render(
    <template>
      <div class="card-anchor">
        <button class="profile" type="button">Profile</button>
        <DMenu
          @anchorElement={{context.resolveAnchor}}
          @inline={{true}}
          @label="Actions"
          @offset={{0}}
          @onRegisterApi={{context.registerMenu}}
          @placement="top"
        >
          <:content><button
              class="action"
              type="button"
            >Action</button></:content>
        </DMenu>
      </div>
      <div class="replacement-anchor"></div>
    </template>
  );
  find(anchor).style.cssText =
    "position:fixed;left:100px;top:250px;width:240px;height:64px";
  find(trigger).style.cssText =
    "position:fixed;left:350px;top:260px;width:36px;height:36px";
  find(".replacement-anchor").style.cssText =
    "position:fixed;left:550px;top:250px;width:120px;height:64px";
}

function center(selector) {
  const rect = find(selector).getBoundingClientRect();
  return rect.left + rect.width / 2;
}

async function openMenu() {
  await click(trigger);
  await waitUntil(() =>
    find(float)
      .getAnimations()
      .every(
        (animation) =>
          animation.playState === "finished" || animation.playState === "idle"
      )
  );
}

module("Integration | Component | FloatKit | AnchorElement", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.resolveAnchor = () => find(anchor);
    this.registerMenu = (menu) => {
      this.menu = menu;
    };
  });

  test("an enclosing anchor positions the menu while Escape restores the real button", async function (assert) {
    await renderMenu(this);
    await openMenu();
    assert.true(
      Math.abs(center(float) - center(anchor)) < 1,
      `Menu ${center(float)} is centered on card ${center(anchor)}`
    );
    assert.true(
      Math.abs(center(float) - center(trigger)) > 20,
      `Menu ${center(float)} differs from button ${center(trigger)}`
    );
    assert.dom(trigger).hasAttribute("aria-expanded", "true");

    await focus(".action");
    await triggerKeyEvent(".action", "keydown", "Escape");
    assert.dom(float).doesNotExist();
    assert.strictEqual(document.activeElement, find(trigger));
  });

  test("anchor resizing repositions a menu whose interactive button stays still", async function (assert) {
    await renderMenu(this);
    await openMenu();
    const oldTriggerCenter = center(trigger);
    find(anchor).style.width = "340px";
    await waitUntil(() => Math.abs(center(float) - center(anchor)) < 1);
    assert.strictEqual(center(trigger), oldTriggerCenter);
    assert.true(Math.abs(center(float) - center(anchor)) < 1);
  });

  test("null and disconnected anchors fall back to the button", async function (assert) {
    for (const value of [null, document.createElement("div")]) {
      this.resolveAnchor = () => value;
      await renderMenu(this);
      await openMenu();
      assert.true(
        Math.abs(center(float) - center(trigger)) < 1,
        `Fallback menu ${center(float)} follows button ${center(trigger)}`
      );
      await this.menu.close();
    }
  });

  test("a replaced anchor is observed and positioned on the next update", async function (assert) {
    let replacement = false;
    this.resolveAnchor = () =>
      find(replacement ? ".replacement-anchor" : anchor);
    await renderMenu(this);
    await openMenu();
    replacement = true;
    window.dispatchEvent(new Event("resize"));
    await waitUntil(
      () => Math.abs(center(float) - center(".replacement-anchor")) < 1
    );
    find(".replacement-anchor").style.width = "180px";
    await waitUntil(
      () => Math.abs(center(float) - center(".replacement-anchor")) < 1
    );
    assert.true(Math.abs(center(float) - center(".replacement-anchor")) < 1);
  });
});
