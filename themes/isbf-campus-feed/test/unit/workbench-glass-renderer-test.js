import { module, test } from "qunit";
import { createWorkbenchRenderer } from "../../discourse/lib/workbench-glass-renderer";
import { graphics } from "../helpers/workbench-graphics";

const layout = {
  size: 80,
  width: 400,
  height: 300,
  dpr: 1,
  centers: [[100, 100]],
};
const visuals = [
  {
    bend: 1,
    glow: 1,
    light: [-0.55, -0.83],
    shift: [0, 0],
    offset: 10.4,
    lift: 0,
    scale: 1,
    glassAlpha: 1,
    plateAlpha: 1,
  },
];
const palette = {
  cards: [{ plate: [105, 181, 230, 255], tint: [0.45, 0.77, 0.98] }],
  shade: 0.35,
};

module("ISBF | Unit | workbench glass renderer", function () {
  test("missing or blocked WebGL leaves the DOM fallback available", function (assert) {
    assert.strictEqual(
      createWorkbenchRenderer({ getContext: () => null }),
      null
    );
    assert.strictEqual(
      createWorkbenchRenderer({
        getContext() {
          throw new Error("Context unavailable");
        },
      }),
      null
    );
  });

  for (const options of [{ compile: false }, { link: false }]) {
    test(`initialization failure releases resources: ${JSON.stringify(options)}`, function (assert) {
      const fixture = graphics(options);
      assert.strictEqual(createWorkbenchRenderer(fixture.canvas), null);
      assert.strictEqual(fixture.calls("deleteProgram").length, 1);
      assert.strictEqual(
        fixture.calls("deleteShader").filter((call) => call.args[0]).length,
        2,
        "both allocated shaders are released"
      );
    });
  }

  test("palette changes redraw without allocating another renderer", function (assert) {
    const fixture = graphics();
    const renderer = createWorkbenchRenderer(fixture.canvas);
    renderer.draw(layout, visuals, palette);
    renderer.draw(layout, visuals, palette);
    assert.strictEqual(fixture.calls("texImage2D").length, 1);
    renderer.draw(layout, visuals, {
      ...palette,
      cards: [{ ...palette.cards[0], plate: [23, 105, 170, 255] }],
    });
    assert.strictEqual(fixture.calls("texImage2D").length, 2);
    assert.strictEqual(fixture.calls("createProgram").length, 1);
    assert.strictEqual(fixture.calls("drawArrays").length, 3);
    renderer.destroy();
  });

  test("each entry receives its own clear-glass color from a shared palette texture", function (assert) {
    const fixture = graphics();
    const renderer = createWorkbenchRenderer(fixture.canvas);
    renderer.draw(
      {
        ...layout,
        centers: [
          [100, 100],
          [200, 100],
        ],
      },
      [visuals[0], visuals[0]],
      {
        shade: 0.22,
        cards: [
          palette.cards[0],
          { plate: [170, 30, 60, 255], tint: [0.67, 0.12, 0.24] },
        ],
      }
    );
    assert.strictEqual(fixture.calls("createTexture").length, 1);
    assert.strictEqual(fixture.calls("texImage2D").length, 1);
    assert.deepEqual(
      [...fixture.calls("texImage2D")[0].args.at(-1)],
      [105, 181, 230, 255, 170, 30, 60, 255],
      "both entry colors are uploaded together, so draws do not mutate the sampled texture"
    );
    assert.strictEqual(
      fixture.calls("uniform4f").filter((call) => call.args[0] === "uTint")[1]
        .args[1],
      0.67
    );
    assert.deepEqual(
      fixture
        .calls("uniform1f")
        .filter((call) => call.args[0] === "uRow")
        .map((call) => call.args[1]),
      [0.25, 0.75]
    );
    assert.strictEqual(
      fixture.calls("uniform1f").find((call) => call.args[0] === "uSoft")
        .args[1],
      1
    );
    renderer.destroy();
  });

  test("destroy is idempotent and prevents drawing with released resources", function (assert) {
    const fixture = graphics();
    const renderer = createWorkbenchRenderer(fixture.canvas);
    renderer.draw(layout, visuals, palette);
    renderer.destroy();
    renderer.destroy();
    renderer.draw(layout, visuals, palette);
    assert.strictEqual(fixture.calls("deleteTexture").length, 1);
    assert.strictEqual(fixture.calls("deleteBuffer").length, 1);
    assert.strictEqual(fixture.calls("deleteProgram").length, 1);
    assert.strictEqual(fixture.calls("deleteShader").length, 2);
    assert.strictEqual(fixture.calls("drawArrays").length, 1);
  });
});
