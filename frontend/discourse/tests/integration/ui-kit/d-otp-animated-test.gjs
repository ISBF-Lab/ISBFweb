import {
  fillIn,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DOtp from "discourse/ui-kit/d-otp";

module("Integration | ui-kit | DOtp animated", function (hooks) {
  setupRenderingTest(hooks);

  test("filters input and emits completion once", async function (assert) {
    const completed = [];
    this.onFill = (code) => completed.push(code);
    await render(
      <template><DOtp @onFill={{this.onFill}} @variant="animated" /></template>
    );

    await triggerEvent(".d-otp-input", "paste", {
      clipboardData: { getData: () => "a1 2-3456x7" },
    });
    await triggerEvent(".d-otp-input", "input");

    assert.dom(".d-otp-animated__slot[data-filled]").exists({ count: 6 });
    assert.dom(".d-otp-input").hasValue("123456");
    assert.dom(".d-otp-input").hasAttribute("autocomplete", "one-time-code");
    assert.deepEqual(completed, ["123456"]);
  });

  test("supports paste, arrow navigation, replacement and deletion", async function (assert) {
    await render(<template><DOtp @variant="animated" /></template>);
    await triggerEvent(".d-otp-input", "paste", {
      clipboardData: { getData: () => "1 2-3" },
    });
    await triggerKeyEvent(".d-otp-input", "keydown", "ArrowLeft");
    await triggerKeyEvent(".d-otp-input", "keydown", "9");
    assert.dom(".d-otp-input").hasValue("129");
    await triggerKeyEvent(".d-otp-input", "keydown", "Backspace");
    assert.dom(".d-otp-input").hasValue("12");
    await triggerKeyEvent(".d-otp-input", "keydown", "Home");
    await triggerKeyEvent(".d-otp-input", "keydown", "Delete");
    assert
      .dom(".d-otp-animated__slot[data-index='0']")
      .doesNotHaveAttribute("data-filled");
    assert
      .dom(".d-otp-animated__slot[data-index='1']")
      .hasAttribute("data-filled");
    await triggerEvent(".d-otp-input", "paste", {
      clipboardData: { getData: () => "654321" },
    });
    assert.dom(".d-otp-input").hasValue("654321");
  });

  test("rejects a code, clears once and accepts a retry", async function (assert) {
    const changes = [];
    this.status = "idle";
    this.changed = (code) => {
      changes.push(code);
      if (!code) {
        this.set("status", "idle");
      }
    };
    await render(
      <template>
        <DOtp
          @onChange={{this.changed}}
          @status={{this.status}}
          @variant="animated"
        />
      </template>
    );
    await fillIn(".d-otp-input", "123456");
    this.set("status", "error");
    await settled();

    assert.dom(".d-otp-input").hasValue("").isFocused();
    assert.dom(".d-otp-animated__slot[data-filled]").doesNotExist();
    assert.deepEqual(changes, ["123456", ""]);
    await fillIn(".d-otp-input", "654321");
    assert.dom(".d-otp-input").hasValue("654321");
  });

  test("external values land and can be cleared", async function (assert) {
    this.value = "";
    const completed = [];
    this.onFill = (code) => completed.push(code);
    await render(
      <template>
        <DOtp
          @onFill={{this.onFill}}
          @value={{this.value}}
          @variant="animated"
        />
      </template>
    );
    this.set("value", "001234");
    await settled();
    assert.dom(".d-otp-input").hasValue("001234");
    assert.deepEqual(completed, ["001234"]);
    this.set("value", "");
    await settled();
    assert.dom(".d-otp-animated__slot[data-filled]").doesNotExist();
  });

  test("a reset supersedes a pending rejection", async function (assert) {
    this.value = "123456";
    this.status = "idle";
    const changes = [];
    this.changed = (value) => changes.push(value);
    await render(
      <template>
        <DOtp
          @onChange={{this.changed}}
          @status={{this.status}}
          @value={{this.value}}
          @variant="animated"
        />
      </template>
    );
    this.set("status", "error");
    this.setProperties({ status: "idle", value: "654321" });
    await settled();
    assert.dom(".d-otp-input").hasValue("654321");
    assert.deepEqual(changes, []);
  });

  test("disabled and accepted inputs ignore further edits", async function (assert) {
    this.disabled = true;
    this.status = "idle";
    this.value = "123456";
    const changes = [];
    this.changed = (code) => changes.push(code);
    await render(
      <template>
        <DOtp
          @disabled={{this.disabled}}
          @onChange={{this.changed}}
          @status={{this.status}}
          @value={{this.value}}
          @variant="animated"
        />
      </template>
    );
    assert.dom(".d-otp-input").isDisabled();
    this.setProperties({ disabled: false, status: "success" });
    await settled();
    assert.dom(".d-otp-input").hasAttribute("readonly");
    await triggerEvent(".d-otp-input", "paste", {
      clipboardData: { getData: () => "987654" },
    });
    assert.dom(".d-otp-input").hasValue("123456");
    assert.deepEqual(changes, []);
  });
});
