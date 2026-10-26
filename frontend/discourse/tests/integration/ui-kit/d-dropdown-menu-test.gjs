import {
  click,
  focus,
  render,
  triggerKeyEvent,
  waitFor,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";

module("Integration | ui-kit | DDropdownMenu", function (hooks) {
  setupRenderingTest(hooks);

  test("wrapped actions share the same row surface and keep their callback", async function (assert) {
    this.report = sinon.spy();
    await render(
      <template>
        <DDropdownMenu as |menu|>
          <menu.item><div class="double-button"><DButton
                class="wrapped-report"
                @action={{this.report}}
              >Report</DButton></div></menu.item>
        </DDropdownMenu>
      </template>
    );
    await waitFor(".wrapped-report[data-d-menu-row]");
    assert
      .dom(".wrapped-report")
      .hasAttribute(
        "data-d-menu-row",
        "",
        "composed buttons use the shared row surface"
      );
    await click(".wrapped-report");
    assert.true(this.report.calledOnce, "the original action is called once");
  });

  test("shared navigation moves once and skips disabled actions", async function (assert) {
    await render(
      <template>
        <DDropdownMenu as |menu|>
          <menu.item><DButton class="first">First</DButton></menu.item>
          <menu.item><DButton @disabled={{true}}>Disabled</DButton></menu.item>
          <menu.item><DButton class="last">Last</DButton></menu.item>
        </DDropdownMenu>
      </template>
    );
    await focus(".first");
    await triggerKeyEvent(".first", "keydown", "ArrowDown");
    assert.dom(".last").isFocused("the next available action receives focus");
    await triggerKeyEvent(".last", "keydown", "Home");
    assert.dom(".first").isFocused("Home returns to the first action");
  });

  test("dropdown menu", async function (assert) {
    await render(<template><DDropdownMenu class="test" /></template>);

    assert
      .dom("ul.dropdown-menu.test")
      .exists("it renders the dropdown menu with custom class");
  });

  test("dropdown menu item", async function (assert) {
    await render(
      <template>
        <DDropdownMenu as |dm|><dm.item
            class="test"
          >test</dm.item></DDropdownMenu>
      </template>
    );

    assert
      .dom("li.dropdown-menu__item.test")
      .exists("it renders the item with custom class")
      .hasText("test");
  });

  test("dropdown menu divider", async function (assert) {
    await render(
      <template>
        <DDropdownMenu as |dm|><dm.divider class="test" /></DDropdownMenu>
      </template>
    );

    assert
      .dom("li.test hr.dropdown-menu__divider")
      .exists("it renders the divider with custom class");
  });
});
