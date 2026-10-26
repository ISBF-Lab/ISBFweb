import {
  clearRender,
  click,
  find,
  findAll,
  render,
  settled,
  triggerEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DMenus from "discourse/float-kit/components/d-menus";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFOfficialPicker from "../../discourse/components/isbf-official-picker";

const trigger = ".isbf-official-picker__trigger";
const menu = ".isbf-official-picker__menu";
const rows = `${menu} [role='menuitemradio']`;

async function renderPicker(context) {
  await render(
    <template>
      <DMenus />
      <button class="outside" type="button">Outside</button>
      <ISBFOfficialPicker
        @allKey="isbf_v2.official_all_campuses"
        @items={{context.items}}
        @labelKey="isbf_v2.official_campus"
        @multiple={{context.multiple}}
        @onSelect={{context.select}}
        @selectedIds={{context.selected}}
      />
    </template>
  );
}

module("ISBF | Integration | Component | ISBFOfficialPicker", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.multiple = false;
    this.items = [
      { id: "zhuhai", label: "Zhuhai" },
      { id: "beijing", label: "Beijing" },
      { id: "other", label: "Other campus" },
    ];
    this.selected = ["zhuhai"];
    this.select = sinon.spy();
  });

  test("the selected campus is marked and a pick calls the existing callback once", async function (assert) {
    await renderPicker(this);
    assert
      .dom(trigger)
      .hasText("Zhuhai", "the trigger displays the selected campus");
    assert
      .dom(trigger)
      .hasAttribute(
        "aria-label",
        "Zhuhai",
        "the accessible name includes the visible campus"
      );
    await click(trigger);
    const options = findAll(rows);
    assert
      .dom(options[1])
      .hasAttribute("aria-checked", "true", "the held value is marked");
    await click(options[2]);
    assert.true(
      this.select.calledOnceWithExactly("beijing"),
      "one pick calls the existing callback once"
    );
    assert.dom(menu).doesNotExist("picking closes the menu");
    assert
      .dom(document.activeElement)
      .hasClass(
        "isbf-official-picker__trigger",
        "picking returns focus to the trigger"
      );
  });

  test("arrows, Home, End and type-ahead navigate without applying a filter", async function (assert) {
    await renderPicker(this);
    await triggerEvent(trigger, "keydown", { key: "ArrowDown" });
    const options = findAll(rows);
    await waitUntil(() => document.activeElement === options[1]);
    assert.strictEqual(
      document.activeElement,
      options[1],
      "opening enters at the selected campus"
    );
    await triggerEvent(options[1], "keydown", { key: "ArrowDown" });
    assert.strictEqual(
      document.activeElement,
      options[2],
      "Down advances focus"
    );
    await triggerEvent(options[2], "keydown", { key: "End" });
    assert.strictEqual(
      document.activeElement,
      options[3],
      "End reaches the final campus"
    );
    await triggerEvent(options[3], "keydown", { key: "Home" });
    assert.strictEqual(
      document.activeElement,
      options[0],
      "Home reaches all campuses"
    );
    await triggerEvent(options[0], "keydown", { key: "b" });
    assert.strictEqual(
      document.activeElement,
      options[2],
      "typing finds a campus by name"
    );
    assert.false(
      this.select.called,
      "moving focus leaves the filter unchanged"
    );
    assert
      .dom(options[1])
      .hasAttribute(
        "aria-checked",
        "true",
        "the held selection remains marked"
      );
    await triggerEvent(options[2], "keydown", { key: "Escape" });
    assert.dom(menu).doesNotExist("Escape closes the menu");
    assert.strictEqual(
      document.activeElement,
      find(trigger),
      "Escape returns focus to the trigger"
    );
  });

  test("pointer exploration does not change selection and external values update immediately", async function (assert) {
    await renderPicker(this);
    await click(trigger);
    const options = findAll(rows);
    await triggerEvent(options[2], "pointerover", { pointerType: "mouse" });
    assert.false(this.select.called, "hover does not submit the filter");
    assert
      .dom(options[1])
      .hasAttribute("aria-checked", "true", "hover keeps the selected campus");
    this.set("selected", ["other"]);
    await settled();
    assert
      .dom(trigger)
      .hasText("Other campus", "controlled changes update the trigger");
    assert
      .dom(options[3])
      .hasAttribute(
        "aria-checked",
        "true",
        "controlled changes update the marked row"
      );
    await click(options[0]);
    assert.true(
      this.select.calledOnceWithExactly(""),
      "all campuses keeps the existing empty value"
    );
  });

  test("multi-select keeps the shared surface and toggles without closing", async function (assert) {
    this.multiple = true;
    await renderPicker(this);
    await click(trigger);
    assert
      .dom(`${menu} .d-menu-surface`)
      .exists("multi-select uses the shared surface");
    assert
      .dom(`${menu} [role='menuitemcheckbox']`)
      .exists({ count: 3 }, "all choices retain checkbox semantics");
    await click(findAll(`${menu} [role='menuitemcheckbox']`)[1]);
    assert.true(
      this.select.calledOnceWithExactly("beijing", true),
      "a pick sends the original boolean toggle"
    );
    assert.dom(menu).exists("a toggle keeps the multi-select open");
  });

  test("outside clicks and destruction release the floating menu", async function (assert) {
    await renderPicker(this);
    await click(trigger);
    await triggerEvent(".outside", "pointerdown");
    assert.dom(menu).doesNotExist("an outside click closes the menu");
    await click(trigger);
    await clearRender();
    assert
      .dom(menu)
      .doesNotExist("destroying the picker removes the floating content");
  });
});
