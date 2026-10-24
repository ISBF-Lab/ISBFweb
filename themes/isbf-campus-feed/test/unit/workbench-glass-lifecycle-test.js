import { module, test } from "qunit";
import { mountWorkbenchGlass } from "../../discourse/lib/workbench-glass";
import { workbenchStage } from "../helpers/workbench-stage";

module("ISBF | Unit | workbench glass lifecycle", function () {
  test("mobile does not initialize graphics, motion, or size observers", function (assert) {
    const fixture = workbenchStage({ desktop: false });
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_plate_color_light: "#ff0000",
    });
    assert.strictEqual(fixture.calls("createProgram").length, 0);
    assert.strictEqual(fixture.observers.length, 0);
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-custom-plate"),
      ""
    );
    destroy();
    assert.strictEqual(fixture.listeners(), 0);
  });

  test("crossing the navigation breakpoint releases and restores desktop resources", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_plate_color_dark: "#112233",
    });
    fixture.show();
    fixture.step();
    fixture.viewport.matches = false;
    fixture.viewport.dispatch("change");
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(fixture.calls("deleteProgram").length, 1);
    assert.false(fixture.classes.has("has-webgl"));
    assert.true(fixture.observers.every((observer) => observer.disconnected));
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-custom-plate"),
      ""
    );
    fixture.viewport.matches = true;
    fixture.viewport.dispatch("change");
    assert.strictEqual(fixture.calls("createProgram").length, 2);
    assert.true(fixture.classes.has("has-webgl"));
    destroy();
    assert.strictEqual(fixture.calls("deleteProgram").length, 2);
    assert.strictEqual(fixture.listeners(), 0);
  });

  test("custom colors survive a breakpoint change before computed styles refresh", function (assert) {
    const fixture = workbenchStage({ reduced: true });
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_plate_color_dark: "#236ea4",
      workbench_plate_learning_resources_color_dark: "#f4c6d4",
    });
    const expected = [244, 198, 212, 255, 35, 110, 164, 255];
    assert.deepEqual(
      [...fixture.calls("texImage2D").at(-1).args.at(-1)],
      expected,
      "explicit colors reach WebGL even while computed styles return the previous theme color"
    );
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-card-ink"),
      "rgb(var(--always-black-rgb))"
    );
    fixture.viewport.matches = false;
    fixture.viewport.dispatch("change");
    fixture.viewport.matches = true;
    fixture.viewport.dispatch("change");
    assert.deepEqual(
      [...fixture.calls("texImage2D").at(-1).args.at(-1)],
      expected,
      "the restored desktop renderer uses the same explicit palette"
    );
    destroy();
  });

  test("the administrator can select traditional layout on both device sizes", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_layout_desktop: "traditional",
      workbench_layout_mobile: "traditional",
    });
    assert.strictEqual(fixture.stage.dataset.workbenchLayout, "traditional");
    fixture.viewport.matches = false;
    fixture.viewport.dispatch("change");
    assert.strictEqual(fixture.stage.dataset.workbenchLayout, "traditional");
    assert.strictEqual(fixture.calls("createProgram").length, 0);
    assert.strictEqual(fixture.observers.length, 0);
    destroy();
    assert.strictEqual(fixture.listeners(), 0);
  });

  test("mobile glass and desktop traditional use independent administrator settings", function (assert) {
    const fixture = workbenchStage({ desktop: false, reduced: true });
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_layout_mobile: "glass",
      workbench_layout_desktop: "traditional",
    });
    assert.strictEqual(fixture.stage.dataset.workbenchLayout, "glass");
    assert.strictEqual(fixture.calls("createProgram").length, 1);
    fixture.viewport.matches = true;
    fixture.viewport.dispatch("change");
    assert.strictEqual(fixture.stage.dataset.workbenchLayout, "traditional");
    assert.strictEqual(fixture.calls("deleteProgram").length, 1);
    fixture.viewport.matches = false;
    fixture.viewport.dispatch("change");
    assert.strictEqual(fixture.stage.dataset.workbenchLayout, "glass");
    assert.strictEqual(fixture.calls("createProgram").length, 2);
    destroy();
    assert.strictEqual(fixture.listeners(), 0);
  });

  test("desktop-only custom colors stay independent when both devices use glass", function (assert) {
    const fixture = workbenchStage({ desktop: false, reduced: true });
    const destroy = mountWorkbenchGlass(fixture.stage, {
      workbench_layout_mobile: "glass",
      workbench_layout_desktop: "glass",
      workbench_plate_color_dark: "#f4c6d4",
    });
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-custom-plate"),
      ""
    );
    fixture.viewport.matches = true;
    fixture.viewport.dispatch("change");
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-custom-plate"),
      "#f4c6d4"
    );
    fixture.viewport.matches = false;
    fixture.viewport.dispatch("change");
    assert.strictEqual(
      fixture.items[0].style.getPropertyValue("--isbf-workbench-custom-plate"),
      ""
    );
    destroy();
    assert.strictEqual(fixture.calls("deleteProgram").length, 3);
  });

  test("intro settles and the renderer sleeps until another interaction", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    fixture.settle();
    assert.strictEqual(fixture.frames(), 0);
    assert.true(fixture.classes.has("has-webgl"));
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
      "1"
    );
    fixture.items[0].dispatch("pointerenter", { pointerType: "mouse" });
    assert.strictEqual(fixture.frames(), 1);
    fixture.settle();
    assert.strictEqual(fixture.frames(), 0);
    assert.notStrictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__face"].style.transform,
      "translateY(0px)"
    );
    destroy();
  });

  test("removal cancels pending frames, observers, listeners, and GPU resources", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    assert.strictEqual(fixture.frames(), 1);
    destroy();
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(fixture.listeners(), 0);
    assert.true(fixture.observers.every((observer) => observer.disconnected));
    assert.strictEqual(fixture.calls("deleteProgram").length, 1);
    assert.false(fixture.classes.has("has-webgl"));
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
      undefined
    );
  });

  test("context loss immediately restores visible fallback and supports restoration", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    fixture.canvas.dispatch("webglcontextlost", { preventDefault() {} });
    assert.false(fixture.classes.has("has-webgl"));
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
      "1"
    );
    fixture.canvas.dispatch("webglcontextrestored");
    assert.true(fixture.classes.has("has-webgl"));
    assert.strictEqual(fixture.calls("createProgram").length, 2);
    destroy();
    assert.strictEqual(fixture.calls("deleteProgram").length, 2);
  });

  for (const options of [{ reduced: true }, { gpu: false }]) {
    test(`static mode remains visible without animation: ${JSON.stringify(options)}`, function (assert) {
      const fixture = workbenchStage(options);
      const destroy = mountWorkbenchGlass(fixture.stage);
      fixture.items[0].dispatch("pointerenter", { pointerType: "mouse" });
      assert.strictEqual(fixture.frames(), 0);
      assert.strictEqual(
        fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
        "1"
      );
      destroy();
    });
  }

  test("enabling reduced motion during intro completes it immediately", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    fixture.step();
    fixture.motion.matches = true;
    fixture.motion.dispatch("change");
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
      "1"
    );
    destroy();
  });

  test("a pending frame respects reduced motion before its change event arrives", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    fixture.step();
    fixture.motion.matches = true;
    fixture.step();
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__label"].style.opacity,
      "1"
    );
    assert.strictEqual(
      fixture.items[0].layers[".isbf-workbench-grid__face"].style.transform,
      "translateY(0px)"
    );
    destroy();
  });

  test("placeholder entries do not acquire interactive motion handlers", function (assert) {
    const fixture = workbenchStage();
    const destroy = mountWorkbenchGlass(fixture.stage);
    fixture.show();
    fixture.settle();
    fixture.items[1].dispatch("pointerenter", { pointerType: "mouse" });
    assert.strictEqual(fixture.frames(), 0);
    assert.strictEqual(fixture.items[1].listenerCount(), 0);
    destroy();
  });

  test("an empty grid does not allocate graphics or observers", function (assert) {
    const fixture = workbenchStage({ empty: true });
    assert.strictEqual(mountWorkbenchGlass(fixture.stage), undefined);
    assert.strictEqual(fixture.calls("createProgram").length, 0);
    assert.strictEqual(fixture.observers.length, 0);
  });
});
