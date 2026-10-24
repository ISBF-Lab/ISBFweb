import { module, test } from "qunit";
import {
  workbenchColor,
  workbenchColors,
  workbenchInk,
} from "../../discourse/lib/workbench-colors";

module("ISBF | Unit | workbench colors", function () {
  test("only complete hex colors are accepted", function (assert) {
    assert.strictEqual(workbenchColor(" #AABBCC "), "#aabbcc");
    for (const value of [
      null,
      "",
      "red",
      "#abc",
      "#12345z",
      "#ffffff;background:red",
      123456,
    ]) {
      assert.strictEqual(workbenchColor(value), "");
    }
  });

  test("module overrides inherit the shared default in the selected palette", function (assert) {
    const settings = {
      workbench_panel_color_light: "#ffffff",
      workbench_panel_color_dark: "#112233",
      workbench_plate_color_light: "#123456",
      workbench_plate_color_dark: "#abcdef",
      workbench_plate_library_color_light: "#998877",
    };
    const keys = ["learning_resources", "library"];
    const light = workbenchColors(settings, "light", keys);
    const dark = workbenchColors(settings, "dark", keys);
    assert.strictEqual(light.panel, "#ffffff");
    assert.strictEqual(light.plates.join(","), "#123456,#998877");
    assert.strictEqual(dark.panel, "#112233");
    assert.strictEqual(dark.plates.join(","), "#abcdef,#abcdef");
  });

  test("invalid and unset values leave the theme fallback intact", function (assert) {
    const colors = workbenchColors(
      {
        workbench_plate_color_dark: "unsafe",
        workbench_plate_library_color_dark: "#bad",
      },
      "dark",
      ["library"]
    );
    assert.strictEqual(colors.panel, "");
    assert.strictEqual(colors.plates[0], "");
  });

  test("light and dark backgrounds choose contrasting existing foreground tokens", function (assert) {
    assert.strictEqual(
      workbenchInk([255, 255, 255]),
      "rgb(var(--always-black-rgb))"
    );
    assert.strictEqual(
      workbenchInk([10, 20, 30]),
      "var(--token-color-text-inverse)"
    );
  });
});
