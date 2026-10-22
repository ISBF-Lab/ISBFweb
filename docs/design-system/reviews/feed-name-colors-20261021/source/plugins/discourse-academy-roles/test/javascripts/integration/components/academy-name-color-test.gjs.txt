import { clearRender, click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import User from "discourse/models/user";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import formKit from "discourse/tests/helpers/form-kit-helper";
import AcademyNameColor from "discourse/plugins/discourse-academy-roles/discourse/connectors/user-preferences-interface/academy-name-color";

module("Integration | Component | AcademyNameColor", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.academy_roles_enabled = true;
    this.currentUser.setProperties({
      academy_can_wear_name_color: true,
      academy_can_customize_name_color: true,
      academy_display_name_color: null,
    });
    this.model = User.create({
      id: this.currentUser.id,
      username: this.currentUser.username,
      name: "Developer",
      custom_fields: { unrelated_preference: "kept" },
      academy_name_color_preferences: { enabled: false, color: null },
    });
    this.outletArgs = { model: this.model, save() {} };
  });

  test("previews a developer's draft and keeps the live appearance unchanged until saving", async function (assert) {
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );

    assert.false(formKit().field("enabled").value(), "wear starts disabled");
    await formKit().field("enabled").toggle();
    await formKit().field("color").fillIn("AbC");

    assert.strictEqual(
      this.model.custom_fields.academy_name_color,
      "#AbC",
      "the selected color becomes a draft"
    );
    assert.strictEqual(
      this.model.custom_fields.unrelated_preference,
      "kept",
      "other preferences survive edits"
    );
    assert.strictEqual(
      this.currentUser.academy_display_name_color,
      null,
      "unsaved previews do not affect cards"
    );
    assert
      .dom(".academy-name-color__name")
      .hasAttribute(
        "style",
        "color: #aabbcc;",
        "the preview normalizes the color safely"
      );

    await formKit().field("enabled").toggle();
    assert.strictEqual(
      formKit().field("color").value(),
      "AbC",
      "turning wear off retains the choice"
    );
    await click(".academy-name-color__reset");
    assert.strictEqual(
      formKit().field("color").value(),
      "",
      "restoring the theme clears the override"
    );
    assert.false(
      formKit().field("enabled").value(),
      "resetting the color preserves the wear switch"
    );
  });

  test("shows only the wear switch to administrators and hides controls for ordinary accounts", async function (assert) {
    this.currentUser.set("academy_can_customize_name_color", false);
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );

    assert.dom('[data-name="enabled"]').exists("administrators can opt in");
    assert
      .dom('[data-name="color"]')
      .doesNotExist("administrators cannot select a custom color");
    await clearRender();
    this.currentUser.set("academy_can_wear_name_color", false);
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );
    assert
      .dom(".academy-name-color")
      .doesNotExist("ordinary accounts see no extra controls");
  });

  test("hides the controls on another account and when the role feature is disabled", async function (assert) {
    this.model.set("id", this.currentUser.id + 1);
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );
    assert
      .dom(".academy-name-color")
      .doesNotExist("another account's choice is private");

    await clearRender();
    this.model.set("id", this.currentUser.id);
    this.siteSettings.academy_roles_enabled = false;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );
    assert
      .dom(".academy-name-color")
      .doesNotExist("disabled role features add no controls");
  });

  test("shows a field error for invalid hex and preserves the input while typing", async function (assert) {
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );

    await formKit().field("color").fillIn("zzzzzz");
    assert
      .dom('[data-name="color"]')
      .hasClass("has-error", "invalid hex is identified at the field");
    assert.strictEqual(
      formKit().field("color").value(),
      "zzzzzz",
      "the field is not rebuilt on each keystroke"
    );
    await formKit().field("color").fillIn("123456");
    assert
      .dom('[data-name="color"]')
      .doesNotHaveClass("has-error", "a valid correction clears the error");
  });
});
