import {
  clearRender,
  click,
  find,
  findAll,
  render,
  select,
  settled,
  triggerEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DMenu from "discourse/float-kit/components/d-menu";
import DMenus from "discourse/float-kit/components/d-menus";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DNativeSelect from "discourse/ui-kit/d-native-select";
import DSelect from "discourse/ui-kit/d-select";

const trigger = ".d-select__trigger";
const options = ".d-select__menu [role='option']";

module("Integration | ui-kit | DSelect", function (hooks) {
  setupRenderingTest(hooks);

  let consumerSheet;

  hooks.afterEach(() => consumerSheet?.remove());

  test("keeps the native value carrier out of themed layouts", async function (assert) {
    consumerSheet = document.createElement("style");
    consumerSheet.textContent =
      ".legacy-select-layout select { display: block; }";
    document.head.appendChild(consumerSheet);

    await render(
      <template>
        <DMenus />
        <form class="legacy-select-layout">
          <DSelect name="choice" @value="a" as |s|>
            <s.Option @value="a">Alpha</s.Option>
            <s.Option @value="b">Beta</s.Option>
          </DSelect>
        </form>
      </template>
    );

    assert
      .dom(".d-select__native")
      .isNotVisible(
        "theme field rules cannot expose a duplicate native control"
      );
    assert.dom(trigger).isVisible("the shared trigger remains available");
    assert.strictEqual(
      new FormData(find("form")).get("choice"),
      "a",
      "the hidden carrier still submits its value"
    );
    await click(trigger);
    await click(findAll(options)[2]);
    assert.dom(trigger).hasText("Beta", "the visible selection updates");
    assert.strictEqual(
      new FormData(find("form")).get("choice"),
      "b",
      "the selected value still reaches form submission"
    );
  });

  test("required fields report validation on the visible control", async function (assert) {
    await render(
      <template>
        <DMenus />
        <form><DSelect name="choice" required as |s|>
            <s.Option @value="a">Alpha</s.Option>
          </DSelect></form>
      </template>
    );
    assert.false(find("form").checkValidity(), "an empty selection is invalid");
    await settled();
    assert.dom(trigger).isFocused("the visible trigger receives focus");
    assert
      .dom(trigger)
      .hasAttribute(
        "aria-invalid",
        "true",
        "the trigger exposes the validation state"
      );
    assert
      .dom(".d-select__error")
      .hasText(
        find(".d-native-select").validationMessage,
        "the native localized message is presented"
      );
    await click(trigger);
    await click(findAll(options)[1]);
    assert.true(
      find("form").checkValidity(),
      "a selected option satisfies the field"
    );
    assert
      .dom(".d-select__error")
      .doesNotExist("picking clears the validation message");
  });

  test("controlled multiple values update all selections without a callback", async function (assert) {
    this.value = ["a", "c"];
    this.changed = sinon.spy();
    await render(
      <template>
        <DMenus />
        <form><DSelect
            name="choice"
            @multiple={{true}}
            @onChange={{this.changed}}
            @value={{this.value}}
            as |s|
          >
            <s.Option @value="a">Alpha</s.Option>
            <s.Option @value="b">Beta</s.Option>
            <s.Option @value="c">Charlie</s.Option>
          </DSelect></form>
      </template>
    );
    assert.deepEqual(
      new FormData(find("form")).getAll("choice"),
      ["a", "c"],
      "initial multiple values are submitted"
    );
    this.set("value", ["b"]);
    await settled();
    assert.deepEqual(
      new FormData(find("form")).getAll("choice"),
      ["b"],
      "external updates replace the selected values"
    );
    assert.dom(trigger).hasText("Beta", "the visible label updates");
    assert.false(this.changed.called, "external updates do not emit changes");
  });

  test("a pick keeps the form value, label and one change callback in sync", async function (assert) {
    this.changed = sinon.spy();
    await render(
      <template>
        <DMenus />
        <form id="select-form">
          <label for="campus">Campus</label>
          <DSelect
            id="campus"
            name="campus"
            @includeNone={{false}}
            @onChange={{this.changed}}
            @value="a"
            as |s|
          >
            <s.Option @value="a">Alpha</s.Option>
            <s.Option @value="b">Beta</s.Option>
          </DSelect>
        </form>
      </template>
    );
    assert.dom(trigger).hasText("Alpha", "the initial label is visible");
    assert
      .dom("#campus")
      .hasTagName("button", "the label points to the visible control");
    assert.strictEqual(
      new FormData(find("form")).get("campus"),
      "a",
      "the backing control participates in forms"
    );
    await click(trigger);
    await click(findAll(options)[0]);
    assert.false(
      this.changed.called,
      "choosing the current value does not submit it again"
    );
    await click(trigger);
    await click(findAll(options)[1]);
    assert.true(
      this.changed.calledOnceWithExactly("b"),
      "a pick calls the existing value callback once"
    );
    assert.strictEqual(
      new FormData(find("form")).get("campus"),
      "b",
      "the submitted value follows the pick"
    );
    assert.dom(trigger).hasText("Beta", "the visible label follows the pick");
    assert
      .dom(".d-select__menu")
      .doesNotExist("single selection closes the panel");
  });

  test("the native compatibility export preserves values including false and null", async function (assert) {
    this.changed = sinon.spy();
    await render(
      <template>
        <DMenus />
        <DNativeSelect @onChange={{this.changed}} @value={{false}} as |s|>
          <s.Option @value={{false}}>False value</s.Option>
          <s.Option @value={{0}}>Zero value</s.Option>
        </DNativeSelect>
      </template>
    );
    assert.dom(trigger).hasText("False value", "the false value is preserved");
    await select(".d-native-select", "0");
    assert.true(
      this.changed.calledOnceWithExactly("0"),
      "native adapters still emit string values"
    );
    await select(".d-native-select", "__NONE__");
    assert.true(
      this.changed.calledWithExactly(null),
      "clearing retains the existing null convention"
    );
  });

  test("multiple selection keeps its panel open and sends a native input event", async function (assert) {
    this.changed = sinon.spy();
    this.input = sinon.spy();
    await render(
      <template>
        <DMenus />
        <form>
          <DSelect
            name="choices"
            @includeNone={{false}}
            @multiple={{true}}
            @onChange={{this.changed}}
            @onInput={{this.input}}
          >
            <option selected value="a">Alpha</option>
            <option value="b">Beta</option>
          </DSelect>
        </form>
      </template>
    );
    await click(trigger);
    await click(findAll(options)[1]);
    assert.deepEqual(
      this.changed.firstCall.args[0],
      ["a", "b"],
      "selection emits both values"
    );
    assert.true(
      this.input.firstCall.args[0].target instanceof HTMLSelectElement,
      "event adapters receive the native control"
    );
    assert.deepEqual(
      new FormData(find("form")).getAll("choices"),
      ["a", "b"],
      "all selected values are submitted"
    );
    assert
      .dom(".d-select__menu")
      .exists("multiple selection keeps the panel open");
    assert
      .dom(findAll(options)[1])
      .hasAttribute("aria-selected", "true", "the picked option is marked");
  });

  test("dynamic options and controlled values update without emitting a change", async function (assert) {
    this.value = "b";
    this.items = [
      { value: "a", label: "Alpha" },
      { value: "b", label: "Beta" },
    ];
    this.changed = sinon.spy();
    await render(
      <template>
        <DMenus />
        <DSelect
          @includeNone={{false}}
          @onChange={{this.changed}}
          @value={{this.value}}
          as |s|
        >
          {{#each this.items as |item|}}<s.Option
              @value={{item.value}}
            >{{item.label}}</s.Option>{{/each}}
        </DSelect>
      </template>
    );
    this.set("items", [
      { value: "a", label: "Updated Alpha" },
      { value: "b", label: "Updated Beta" },
    ]);
    await settled();
    assert
      .dom(trigger)
      .hasText("Updated Beta", "rebuilt options retain the value");
    this.set("value", "a");
    await settled();
    assert
      .dom(trigger)
      .hasText("Updated Alpha", "external values update the label");
    assert.false(
      this.changed.called,
      "external updates do not submit the field"
    );
  });

  test("keyboard navigation skips disabled options and Escape returns focus", async function (assert) {
    await render(
      <template>
        <DMenus />
        <DSelect @includeNone={{false}} @value="a" as |s|>
          <s.Option @value="a">Alpha</s.Option>
          <option disabled value="b">Beta</option>
          <s.Option @value="c">Charlie</s.Option>
        </DSelect>
      </template>
    );
    await triggerEvent(trigger, "keydown", { key: "ArrowDown" });
    await waitUntil(() => document.activeElement === findAll(options)[0]);
    await triggerEvent(findAll(options)[0], "keydown", { key: "ArrowDown" });
    assert.strictEqual(
      document.activeElement,
      findAll(options)[2],
      "disabled choices are skipped"
    );
    await triggerEvent(findAll(options)[2], "keydown", { key: "Escape" });
    assert.strictEqual(
      document.activeElement,
      find(trigger),
      "Escape restores the trigger"
    );
  });

  test("disabled controls cannot open a menu", async function (assert) {
    await render(
      <template>
        <DMenus /><DSelect disabled @value="a"><option
            value="a"
          >Alpha</option></DSelect>
      </template>
    );
    assert.dom(trigger).isDisabled("the visible control is disabled");
    find(trigger).dispatchEvent(
      new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true })
    );
    assert.dom(".d-select__menu").doesNotExist("a disabled field cannot open");
    assert
      .dom(".d-native-select")
      .isDisabled("the backing form control is also disabled");
  });

  test("a nested selection leaves its parent menu open and destruction clears both", async function (assert) {
    await render(
      <template>
        <DMenus />
        <DMenu
          @contentClass="outer-menu"
          @label="Outer"
          @triggerClass="outer-trigger"
        >
          <:content><DSelect @includeNone={{false}} @value="a"><option
                value="a"
              >Alpha</option><option
                value="b"
              >Beta</option></DSelect></:content>
        </DMenu>
      </template>
    );
    await click(".outer-trigger");
    await click(trigger);
    await click(findAll(options)[1]);
    assert
      .dom(".outer-menu")
      .exists("picking a nested option retains its parent");
    await clearRender();
    assert
      .dom(".outer-menu, .d-select__menu")
      .doesNotExist("destruction releases the whole float family");
  });

  test("nested Escape leaves the parent menu and its draft open", async function (assert) {
    this.closed = sinon.spy();
    this.changed = sinon.spy();
    await render(
      <template>
        <DMenus />
        <DMenu
          @contentClass="outer-menu"
          @label="Outer"
          @onClose={{this.closed}}
          @triggerClass="outer-trigger"
        >
          <:content>
            <input class="draft" value="Keep this draft" />
            <DSelect @onChange={{this.changed}} @value="a" as |s|>
              <s.Option @value="a">Alpha</s.Option>
              <s.Option @value="b">Beta</s.Option>
            </DSelect>
          </:content>
        </DMenu>
      </template>
    );
    await click(".outer-trigger");
    await click(trigger);
    await triggerEvent(findAll(options)[0], "keydown", { key: "Escape" });
    assert.dom(".d-select__menu").doesNotExist("the child closes first");
    assert.dom(".outer-menu .draft").hasValue("Keep this draft");
    assert.false(this.closed.called, "the parent close callback does not run");
    assert.false(this.changed.called, "Escape does not submit a value");
    assert.dom(trigger).isFocused("focus returns to the child trigger");

    await triggerEvent(trigger, "keydown", { key: "Escape" });
    assert.dom(".outer-menu").doesNotExist("the next Escape closes the parent");
    assert.true(this.closed.calledOnce);
    assert.dom(".outer-trigger").isFocused();
  });
});
