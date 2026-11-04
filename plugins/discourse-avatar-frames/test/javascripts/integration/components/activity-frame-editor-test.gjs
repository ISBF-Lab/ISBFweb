import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import AvatarFrameForm from "discourse/plugins/discourse-avatar-frames/admin/components/avatar-frame-form";

module(
  "Integration | Component | Activity cosmetics frame editor",
  function (hooks) {
    setupRenderingTest(hooks);

    test("saves a level requirement while preserving existing frame calibration", async function (assert) {
      this.currentUser.set("admin", true);
      this.owner.lookup("service:site").set("academy_activity_levels", [
        { id: "legacy-0", number: 0, name: "" },
        { id: "silver", number: 1, name: "Contributor" },
      ]);
      this.frame = {
        id: 42,
        key: "bubble",
        name: "Bubble",
        enabled: true,
        access_mode: "public",
        scale: 120,
        offset_x: 0,
        offset_y: 0,
        calibration_confirmed: true,
        image_url: "/frame.png",
        static_url: "/frame.png",
      };
      let saved;
      pretender.put("/avatar-frames/admin/frames/42", (request) => {
        saved = new URLSearchParams(request.requestBody);
        return response({ frame: this.frame });
      });
      pretender.get("/site.json", () => response({ avatar_frames: [] }));
      this.owner.lookup("service:router").transitionTo = () => {};
      await render(
        <template><AvatarFrameForm @frame={{this.frame}} /></template>
      );
      await formKit().field("minimum_activity_level_id").select("silver");
      await formKit().submit();
      assert.true(
        Boolean(saved),
        "the existing frame form makes a save request"
      );
      assert.strictEqual(saved?.get("minimum_activity_level_id"), "silver");
      assert.strictEqual(saved?.get("confirm_calibration"), "true");
    });
  }
);
