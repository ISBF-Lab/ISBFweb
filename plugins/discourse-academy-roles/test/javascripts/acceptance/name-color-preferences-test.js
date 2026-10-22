import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Academy name color preferences", function (needs) {
  const state = {};

  needs.settings({ academy_roles_enabled: true });
  needs.user({
    academy_can_wear_name_color: true,
    academy_can_customize_name_color: true,
    academy_display_name_color: null,
  });
  needs.hooks.beforeEach(() => {
    state.fail = false;
    state.revoked = false;
    state.requests = 0;
    state.requestBody = null;
  });
  needs.pretender((server, helper) => {
    server.get("/u/eviltrout.json", () => {
      const json = cloneJSON(userFixtures["/u/eviltrout.json"]);
      json.user.can_edit = true;
      json.user.academy_name_color_preferences = {
        enabled: false,
        color: null,
      };
      json.user.academy_display_name_color = null;
      return helper.response(json);
    });
    server.put("/u/eviltrout.json", (request) => {
      state.requests++;
      state.requestBody = new URLSearchParams(request.requestBody);
      if (state.fail) {
        return helper.response(422, { errors: ["Unable to save preferences"] });
      }
      if (state.revoked) {
        return helper.response({
          user: {
            academy_display_name_color: null,
            academy_can_wear_name_color: false,
            academy_can_customize_name_color: false,
            academy_name_color_preferences: { enabled: false, color: null },
          },
        });
      }
      const color = state.requestBody
        .get("custom_fields[academy_name_color]")
        ?.startsWith("linear-gradient(")
        ? "linear-gradient(90deg, #aabbcc, #123456)"
        : "#aabbcc";
      return helper.response({
        user: {
          academy_display_name_color: color,
          academy_name_color_preferences: { enabled: true, color },
        },
      });
    });
  });

  test("saves through the interface page and applies only the successful server result", async function (assert) {
    await visit("/u/eviltrout/preferences/interface");
    const user = this.owner.lookup("service:current-user");
    const form = formKit(".academy-name-color");
    await form.field("enabled").toggle();
    await form.field("color").fillIn("AbC");

    assert.strictEqual(
      user.academy_display_name_color,
      null,
      "editing leaves the live appearance unchanged"
    );
    await click(".save-changes");

    assert.strictEqual(
      state.requests,
      1,
      "the existing save button sends one request"
    );
    assert.strictEqual(
      state.requestBody.get("custom_fields[academy_name_color_enabled]"),
      "true",
      "the wear preference is included"
    );
    assert.strictEqual(
      state.requestBody.get("custom_fields[academy_name_color]"),
      "#AbC",
      "the color is included"
    );
    assert.strictEqual(
      user.academy_display_name_color,
      "#aabbcc",
      "the authoritative saved color reaches existing cards"
    );
    assert
      .dom(".saved")
      .exists("the normal preferences success state is retained");
  });

  test("saves both gradient stops through the existing interface action", async function (assert) {
    await visit("/u/eviltrout/preferences/interface");
    const form = formKit(".academy-name-color");
    await form.field("enabled").toggle();
    await form.field("color").fillIn("AbC");
    await form.field("gradient").toggle();
    await click(".save-changes");
    assert.strictEqual(
      state.requests,
      0,
      "an incomplete gradient is rejected before saving"
    );
    await form.field("endColor").fillIn("123456");
    await click(".save-changes");
    assert.strictEqual(
      state.requestBody.get("custom_fields[academy_name_color]"),
      "linear-gradient(90deg, #AbC, #123456)",
      "the normal preference payload includes both stops"
    );
    assert.strictEqual(
      this.owner.lookup("service:current-user").academy_display_name_color,
      "linear-gradient(90deg, #aabbcc, #123456)",
      "the saved gradient becomes the public appearance"
    );
    assert.dom(".saved").exists("the normal success feedback is retained");
  });

  test("a failed save keeps the previous appearance", async function (assert) {
    state.fail = true;
    await visit("/u/eviltrout/preferences/interface");
    await formKit(".academy-name-color").field("enabled").toggle();
    await formKit(".academy-name-color").field("color").fillIn("123456");

    await click(".save-changes");

    assert.strictEqual(
      this.owner.lookup("service:current-user").academy_display_name_color,
      null,
      "failed writes cannot change the displayed color"
    );
    assert.dom(".saved").doesNotExist("failed writes do not show success");
  });

  test("invalid color drafts never reach the save endpoint", async function (assert) {
    await visit("/u/eviltrout/preferences/interface");
    await formKit(".academy-name-color").field("color").fillIn("zzzzzz");

    await click(".save-changes");

    assert.strictEqual(
      state.requests,
      0,
      "client validation stops the invalid request"
    );
    assert
      .dom('[data-name="color"]')
      .hasClass("has-error", "the field explains the invalid value");
    assert.dom(".saved").doesNotExist("invalid drafts do not show success");
  });

  test("role loss hides color controls and keeps later unrelated saves from clearing the stored choice", async function (assert) {
    await visit("/u/eviltrout/preferences/interface");
    await formKit(".academy-name-color").field("enabled").toggle();
    await formKit(".academy-name-color").field("color").fillIn("AbC");
    await click(".save-changes");

    state.revoked = true;
    await click(".save-changes");
    assert
      .dom(".academy-name-color")
      .doesNotExist("revoked capabilities hide the controls");
    assert.strictEqual(
      this.owner.lookup("service:current-user").academy_display_name_color,
      null,
      "role loss clears the active color"
    );

    await click(".save-changes");
    assert.strictEqual(
      state.requests,
      3,
      "subsequent interface saves still use the existing endpoint"
    );
    assert.strictEqual(
      state.requestBody.get("custom_fields[academy_name_color]"),
      "#aabbcc",
      "read-only defaults do not overwrite the stored color"
    );
  });
});
