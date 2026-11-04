import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import select from "discourse/tests/helpers/d-select";
import AvatarFramePreferences from "discourse/plugins/discourse-avatar-frames/discourse/connectors/user-preferences-profile/avatar-frame-preferences";

module(
  "Integration | Component | Activity cosmetics avatar frames",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.avatar_frames_enabled = true;
      this.owner.lookup("service:site").set("avatar_frames", [
        {
          key: "public-frame",
          name: "Public frame",
          access_mode: "public",
          minimum_activity_level_id: "silver",
          minimum_activity_level: { number: 2 },
        },
        {
          key: "awarded-frame",
          name: "Awarded frame",
          access_mode: "granted",
          minimum_activity_level_id: "gold",
          minimum_activity_level: { number: 3 },
        },
      ]);
      this.currentUser.setProperties({
        custom_fields: { avatar_frame: "public-frame", unrelated: "retained" },
        owned_avatar_frames: ["public-frame", "awarded-frame"],
        available_avatar_frames: [],
        academy_activity_cosmetics: {
          avatar_frames: { unlocked: false, minimum_level: { number: 1 } },
        },
      });
      this.outletArgs = { model: this.currentUser, save() {} };
    });

    test("level-locked frames remain visible and disabled while clearing preserves other preferences", async function (assert) {
      await render(
        <template>
          <AvatarFramePreferences @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert
        .dom('select[name="avatar_frame"] option[value="public-frame"]')
        .isDisabled();
      assert
        .dom('select[name="avatar_frame"] option[value="awarded-frame"]')
        .isDisabled();
      assert.dom(".avatar-frame-preferences").includesText("LV1");
      await select('[name="avatar_frame"]', "none");
      assert.strictEqual(this.currentUser.custom_fields.avatar_frame, null);
      assert.strictEqual(this.currentUser.custom_fields.unrelated, "retained");
    });

    test("only server-authorized frames can be selected", async function (assert) {
      this.currentUser.set("available_avatar_frames", ["public-frame"]);
      await render(
        <template>
          <AvatarFramePreferences @outletArgs={{this.outletArgs}} />
        </template>
      );
      assert
        .dom('select[name="avatar_frame"] option[value="public-frame"]')
        .isEnabled();
      assert
        .dom('select[name="avatar_frame"] option[value="awarded-frame"]')
        .isDisabled();
    });
  }
);
