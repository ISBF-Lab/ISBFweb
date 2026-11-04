import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import AcademyNameColor from "discourse/plugins/discourse-academy-roles/discourse/connectors/user-preferences-interface/academy-name-color";

module(
  "Integration | Component | Activity cosmetics name preset",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.academy_roles_enabled = true;
      this.currentUser.setProperties({
        admin: false,
        moderator: false,
        academy_can_customize_name_color: false,
        academy_can_wear_name_color: false,
        academy_activity_cosmetics: {
          name_color: { configured: true, minimum_level: { number: 2 } },
        },
      });
      this.outletArgs = { model: this.currentUser, save() {} };
    });

    test("locked members see the requirement and retain their enabled preference", async function (assert) {
      this.currentUser.set("custom_fields", {
        academy_name_color_enabled: true,
      });
      await render(
        <template>
          <AcademyNameColor @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert.dom('input[name="enabled"]').isDisabled().isChecked();
      assert.dom(".academy-name-color").includesText("LV2");
      assert.dom('input[name="color"]').doesNotExist();
      assert.true(this.currentUser.custom_fields.academy_name_color_enabled);
    });

    test("unlocked members preview the configured light and dark colors without custom controls", async function (assert) {
      this.currentUser.setProperties({
        academy_can_wear_name_color: true,
        custom_fields: { academy_name_color_enabled: true },
      });
      this.owner.lookup("service:site").set("academy_activity_name_colors", {
        light: "#c2188b",
        dark: "#ef82d1",
      });
      await render(
        <template>
          <AcademyNameColor @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert.dom('input[name="enabled"]').isEnabled();
      assert
        .dom(".academy-name-color__name")
        .hasAttribute("style", /light-dark\(#c2188b, #ef82d1\)/);
      assert.dom('input[name="color"]').doesNotExist();
      assert.dom('input[name="gradient"]').doesNotExist();
    });
  }
);
