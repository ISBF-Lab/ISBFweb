import assert from "node:assert/strict";
import test from "node:test";
import { inspectStyles, inspectTemplate } from "./check-menus.mjs";

test("native tags are rejected without confusing yielded Option components", () => {
  assert.equal(
    inspectTemplate("new-field.gjs", "<select><option>A</option></select>")
      .length,
    1
  );
  assert.deepEqual(
    inspectTemplate(
      "new-field.gjs",
      '<DSelect as |select|><select.Option @value="a">A</select.Option></DSelect>'
    ),
    []
  );
  assert.deepEqual(
    inspectTemplate(
      "frontend/discourse/app/ui-kit/d-select/native.gjs",
      "<select>"
    ),
    []
  );
});

test("mobile menu sheets and undocumented popovers cannot bypass the standard", () => {
  assert.equal(
    inspectTemplate("new-menu.gjs", "<DMenu @modalForMobile={{true}}>A</DMenu>")
      .length,
    1
  );
  assert.equal(
    inspectTemplate("new-menu.gjs", '<DMenu @surface="popover">A</DMenu>')
      .length,
    1
  );
  assert.deepEqual(
    inspectTemplate(
      "frontend/discourse/app/form-kit/components/fk/control/color.gjs",
      '<DMenu @surface="popover" @modalForMobile={{true}}>Palette</DMenu>'
    ),
    []
  );
});

test("private menu geometry is rejected while layout and shared tokens remain valid", () => {
  const classes = new Set(["sample__menu"]);
  assert.equal(
    inspectStyles(
      "theme/menu.scss",
      ".sample { &__menu { border-radius: 8px; box-shadow: 0 2px 8px black; } }",
      classes
    ).length,
    2
  );
  assert.deepEqual(
    inspectStyles(
      "theme/menu.scss",
      ".sample__menu { width: 260px; border-radius: var(--d-menu-panel-radius); }",
      classes
    ),
    []
  );
  assert.deepEqual(
    inspectStyles(
      "theme/menu.scss",
      ".sample__menu input { border-radius: 8px; }",
      classes
    ),
    []
  );
});

test("custom details menus are rejected", () => {
  assert.equal(
    inspectTemplate(
      "new-menu.gjs",
      '<details class="page__menu"><summary>Menu</summary></details>'
    ).length,
    1
  );
  assert.deepEqual(
    inspectTemplate(
      "article.gjs",
      '<details class="article-notes"><summary>Notes</summary></details>'
    ),
    []
  );
});

test("the canonical shared select import is retained while legacy UI imports are still checked", async () => {
  const { ESLint } = await import("eslint");
  const lint = new ESLint();
  const filePath = "frontend/discourse/app/menu-import-fixture.js";
  const valid = await lint.lintText(
    'import DSelect from "discourse/ui-kit/d-select"; export default DSelect;',
    { filePath }
  );
  assert.equal(
    valid[0].messages.filter(
      (message) => message.ruleId === "discourse/ui-kit-imports"
    ).length,
    0
  );
  const legacy = await lint.lintText(
    'import Button from "discourse/components/d-button"; export default Button;',
    { filePath }
  );
  assert.ok(
    legacy[0].messages.some(
      (message) => message.ruleId === "discourse/ui-kit-imports"
    )
  );
});
