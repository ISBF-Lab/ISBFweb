import { run } from "@ember/runloop";
import { clearRender, find, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DHoldButton from "discourse/ui-kit/d-hold-button";
import { i18n } from "discourse-i18n";

const selector = ".d-hold-button";

async function renderButton(context) {
  await render(
    <template>
      <DHoldButton
        @action={{context.confirm}}
        @disabled={{context.disabled}}
        @doneLabel="saved"
        @hint="save"
        @holdTime={{300}}
        @label="save"
        @onError={{context.onError}}
        @pendingLabel="loading"
        @resetAfter={{1200}}
      />
    </template>
  );
}

function pointer(type, options = {}) {
  run(() => {
    find(selector).dispatchEvent(
      new PointerEvent(type, {
        bubbles: true,
        button: 0,
        isPrimary: true,
        pointerId: 1,
        pointerType: "mouse",
        ...options,
      })
    );
  });
}

function key(type, value, options = {}) {
  run(() => {
    find(selector).dispatchEvent(
      new KeyboardEvent(type, {
        bubbles: true,
        cancelable: true,
        key: value,
        ...options,
      })
    );
  });
}

async function withClock(callback) {
  const clock = sinon.useFakeTimers({
    toFake: [
      "setTimeout",
      "clearTimeout",
      "performance",
      "requestAnimationFrame",
      "cancelAnimationFrame",
    ],
  });
  try {
    await callback(clock);
  } finally {
    clock.restore();
  }
}

module("Integration | ui-kit | DHoldButton", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.disabled = false;
    this.confirm = sinon.stub().returns(true);
    this.onError = sinon.spy();
    sinon.stub(this.owner.lookup("service:a11y"), "announce");
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  test("short clicks and 299ms holds do not confirm; 300ms confirms once", async function (assert) {
    await renderButton(this);
    assert.dom(selector).doesNotHaveAttribute("data-fill-visible");
    await withClock(async (clock) => {
      run(() => find(selector).click());
      assert.false(this.confirm.called);
      pointer("pointerdown");
      await clock.tickAsync(299);
      assert.false(this.confirm.called);
      assert.dom(selector).hasAttribute("data-fill-visible");
      pointer("pointerup");
      await clock.tickAsync(250);
      assert.dom(selector).hasAttribute("data-phase", "idle");
      assert.dom(selector).doesNotHaveAttribute("data-fill-visible");
      assert.false(this.confirm.called);

      pointer("pointerdown");
      await clock.tickAsync(300);
      assert.true(this.confirm.calledOnce);
      assert.dom(selector).hasAttribute("data-phase", "done");
      assert.dom(selector).hasAttribute("data-fill-visible");
      pointer("pointerup");
      run(() => find(selector).click());
      await clock.tickAsync(400);
      assert.true(this.confirm.calledOnce);
      await clock.tickAsync(800);
      assert.dom(selector).hasAttribute("data-phase", "idle");
      await clock.tickAsync(220);
      assert.dom(selector).doesNotHaveAttribute("data-fill-visible");
    });
  });

  test("pointer cancellation, drift, capture loss and blur cancel unfinished holds", async function (assert) {
    await renderButton(this);
    await withClock(async (clock) => {
      for (const cancellation of [
        "pointercancel",
        "lostpointercapture",
        "pointerleave",
        "blur",
        "drift",
        "navigation",
      ]) {
        pointer("pointerdown");
        await clock.tickAsync(150);
        if (cancellation === "blur") {
          run(() => window.dispatchEvent(new Event("blur")));
        } else if (cancellation === "navigation") {
          run(() =>
            this.owner.lookup("service:router").trigger("routeWillChange", {
              from: { name: "userNotifications.index" },
              to: { name: "discovery.latest" },
            })
          );
        } else if (cancellation === "drift") {
          pointer("pointermove", { clientX: -100, clientY: -100 });
        } else {
          pointer(cancellation);
        }
        await clock.tickAsync(400);
        assert.dom(selector).hasAttribute("data-phase", "idle", cancellation);
        assert.false(this.confirm.called, cancellation);
      }
    });
  });

  test("Space and Enter require a hold, ignore repeats and support Escape", async function (assert) {
    await renderButton(this);
    await withClock(async (clock) => {
      for (const value of [" ", "Enter"]) {
        key("keydown", value);
        await clock.tickAsync(100);
        key("keydown", value, { repeat: true });
        key("keydown", "Escape");
        await clock.tickAsync(400);
        key("keyup", value);
        assert.false(this.confirm.called);
        assert.dom(selector).hasAttribute("data-phase", "idle");
      }
      key("keydown", "Enter");
      await clock.tickAsync(300);
      key("keydown", "Enter", { repeat: true });
      key("keyup", "Enter");
      assert.true(this.confirm.calledOnce);
      assert.dom(selector).hasAttribute("data-phase", "done");
    });
  });

  test("pending actions block repeats and false results reset without success", async function (assert) {
    let resolve;
    this.confirm = sinon
      .stub()
      .returns(new Promise((done) => (resolve = done)));
    await renderButton(this);
    await withClock(async (clock) => {
      pointer("pointerdown");
      await clock.tickAsync(300);
      pointer("pointerup");
      assert.dom(selector).hasAttribute("data-phase", "pending");
      assert.dom(selector).hasAttribute("aria-busy", "true");
      assert.dom(selector).hasAttribute("aria-disabled", "true");
      pointer("pointerdown");
      key("keydown", "Enter");
      await clock.tickAsync(1000);
      assert.true(this.confirm.calledOnce);
      resolve(false);
      await clock.tickAsync(0);
      assert.dom(selector).hasAttribute("data-phase", "idle");
      assert.dom(selector).doesNotHaveAttribute("aria-busy");
    });
  });

  test("rejections reset and invoke the error handler", async function (assert) {
    const error = new Error("Request failed");
    this.confirm.rejects(error);
    await renderButton(this);
    await withClock(async (clock) => {
      pointer("pointerdown");
      await clock.tickAsync(300);
      pointer("pointerup");
      assert.true(this.onError.calledOnceWithExactly(error));
      assert.dom(selector).hasAttribute("data-phase", "idle");
    });
  });

  test("disabled changes cancel a hold and labels expose one accessible name", async function (assert) {
    await renderButton(this);
    const button = find(selector);
    assert.dom(button).hasAttribute("aria-label", i18n("save"));
    assert.dom(`#${button.getAttribute("aria-describedby")}`).exists();
    assert
      .dom(".d-hold-button__label[aria-hidden='true']")
      .exists({ count: 1 });
    assert.dom(".d-hold-button__clip[aria-hidden='true']").exists();
    await withClock(async (clock) => {
      pointer("pointerdown");
      await clock.tickAsync(100);
      run(() => this.set("disabled", true));
      await clock.tickAsync(400);
      assert.false(this.confirm.called);
      assert.dom(selector).isDisabled();
      assert.dom(selector).hasAttribute("data-phase", "idle");
    });
  });

  test("destruction cancels the pending hold and its scheduled callbacks", async function (assert) {
    await renderButton(this);
    const clock = sinon.useFakeTimers({
      toFake: ["performance", "requestAnimationFrame", "cancelAnimationFrame"],
    });
    try {
      pointer("pointerdown");
      clock.tick(100);
      await clearRender();
      clock.tick(1000);
      await settled();
      assert.false(this.confirm.called);
    } finally {
      clock.restore();
    }
  });
});
