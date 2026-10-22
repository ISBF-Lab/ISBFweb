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

  test("edits a saved gradient, switches to solid color and restores the theme", async function (assert) {
    this.model.set("academy_name_color_preferences", {
      enabled: true,
      color: "linear-gradient(180deg, #aabbcc, #123456)",
    });
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );

    assert.true(
      formKit().field("gradient").value(),
      "saved gradients reopen in gradient mode"
    );
    assert.strictEqual(
      formKit().field("direction").value(),
      "180",
      "saved vertical gradients retain their direction"
    );
    await formKit().field("direction").select("90");
    assert.strictEqual(
      formKit().field("color").value(),
      "aabbcc",
      "the start color is restored"
    );
    assert.strictEqual(
      formKit().field("endColor").value(),
      "123456",
      "the end color is restored"
    );
    await formKit().field("endColor").fillIn("Ff00ff");
    assert.strictEqual(
      this.model.custom_fields.academy_name_color,
      "linear-gradient(90deg, #aabbcc, #Ff00ff)",
      "both stops are included in the save draft"
    );
    assert
      .dom(".academy-name-color__name")
      .hasClass("has-gradient", "the preview displays a gradient");
    await formKit().field("gradient").toggle();
    assert.strictEqual(
      this.model.custom_fields.academy_name_color,
      "#aabbcc",
      "solid mode retains the start color"
    );
    assert
      .dom('[data-name="endColor"]')
      .doesNotExist("the end color is only shown for gradients");
    await click(".academy-name-color__reset");
    assert.strictEqual(
      this.model.custom_fields.academy_name_color,
      "",
      "reset clears both overrides"
    );
    assert.true(formKit().field("enabled").value(), "reset preserves wear");
  });

  test("keeps incomplete gradients out of the preview and shows the missing stop error", async function (assert) {
    const outletArgs = this.outletArgs;
    await render(
      <template><AcademyNameColor @outletArgs={{outletArgs}} /></template>
    );
    await formKit().field("enabled").toggle();
    await formKit().field("color").fillIn("123456");
    await formKit().field("gradient").toggle();
    await formKit().field("endColor").fillIn("");
    assert
      .dom('[data-name="endColor"]')
      .hasClass("has-error", "the end color is required");
    assert
      .dom(".academy-name-color__name")
      .doesNotHaveClass(
        "has-gradient",
        "invalid gradients never become styles"
      );
    await formKit().field("endColor").fillIn("abcdef");
    assert
      .dom('[data-name="endColor"]')
      .doesNotHaveClass("has-error", "a valid end color clears the error");
    assert
      .dom(".academy-name-color__name")
      .hasClass("has-gradient", "the completed gradient previews immediately");
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
