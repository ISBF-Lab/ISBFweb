import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import { showCreateInviteModal } from "discourse/lib/invite-modal";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import initializer from "discourse/plugins/discourse-academy-roles/discourse/initializers/academy-student-invites";

module(
  "Integration | Component | Modal | AcademyStudentInvite",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.currentUser.set("admin", true);
      this.siteSettings.academy_roles_enabled = true;
      initializer.initialize(this.owner);
    });

    hooks.afterEach(function () {
      this.owner.lookup("service:modal").close();
    });

    test("opens student invitations with either core invite modal feature flag", async function (assert) {
      await render(<template><ModalContainer /></template>);

      for (const enabled of [false, true]) {
        this.siteSettings.enable_invite_modal_with_roles = enabled;
        showCreateInviteModal(this.owner.lookup("route:application"), {
          model: {},
        });
        await settled();

        assert
          .dom(".academy-student-invite-form")
          .exists(
            `the student form opens when the redesigned core modal is ${enabled}`
          );
        this.owner.lookup("service:modal").close();
        await settled();
      }
    });

    test("retains core invite editing with either feature flag", async function (assert) {
      await render(<template><ModalContainer /></template>);

      for (const enabled of [false, true]) {
        this.siteSettings.enable_invite_modal_with_roles = enabled;
        showCreateInviteModal(this.owner.lookup("route:application"), {
          model: { editing: true },
        });
        await settled();

        assert
          .dom(".academy-student-invite-form")
          .doesNotExist(
            `editing retains the core modal when the redesigned modal is ${enabled}`
          );
        assert
          .dom(
            enabled ? ".create-invite-with-roles-modal" : ".create-invite-modal"
          )
          .exists("the existing invitation can be edited");
        this.owner.lookup("service:modal").close();
        await settled();
      }
    });

    test("retains the core create modal when academy membership is disabled", async function (assert) {
      this.siteSettings.academy_roles_enabled = false;
      this.siteSettings.enable_invite_modal_with_roles = false;
      await render(<template><ModalContainer /></template>);

      showCreateInviteModal(this.owner.lookup("route:application"), {
        model: {},
      });
      await settled();

      assert
        .dom(".create-invite-modal")
        .exists("the core invitation flow remains available");
      assert
        .dom(".academy-student-invite-form")
        .doesNotExist("the student invitation flow is disabled");
    });
  }
);
