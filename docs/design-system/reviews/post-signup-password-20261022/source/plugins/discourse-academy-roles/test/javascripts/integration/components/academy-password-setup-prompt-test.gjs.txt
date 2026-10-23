import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import ForgotPassword from "discourse/components/modal/forgot-password";
import ModalContainer from "discourse/components/modal-container";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender from "discourse/tests/helpers/create-pretender";
import AcademyPasswordSetupPrompt from "discourse/plugins/discourse-academy-roles/discourse/components/academy-password-setup-prompt";

class RouterStub extends Service {
  @tracked currentRouteName = "discovery.latest";
  @tracked currentURL = "/latest";

  on() {}
  off() {}
}

module(
  "Integration | Component | AcademyPasswordSetupPrompt",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.academy_roles_enabled = true;
      this.siteSettings.enable_local_logins = true;
      this.siteSettings.enable_discourse_connect = false;
      this.currentUser.setProperties({
        no_password: true,
        academy_password_setup_pending: true,
      });
      this.owner.unregister("service:router");
      this.owner.register("service:router", RouterStub);
      this.router = this.owner.lookup("service:router");
      pretender.delete("/academy-roles/password-setup.json", () => [
        204,
        {},
        "",
      ]);
    });

    test("waits for the homepage and stays dismissed across navigation", async function (assert) {
      this.router.currentURL = "/t/example/280";
      await render(
        <template><AcademyPasswordSetupPrompt /><ModalContainer /></template>
      );
      assert
        .dom(".academy-password-setup")
        .doesNotExist("topic pages do not prompt");

      this.router.currentURL = "/latest?ascending=true";
      await settled();
      assert
        .dom(".academy-password-setup")
        .exists("entering the home feed opens the reminder");
      await click(".academy-password-setup .d-modal__footer .btn-default");
      this.router.currentURL = "/t/example/280";
      await settled();
      this.router.currentURL = "/";
      await settled();
      assert
        .dom(".academy-password-setup")
        .doesNotExist("returning home cannot reopen a dismissed reminder");
    });

    test("waits for an existing task modal to close", async function (assert) {
      this.owner.lookup("service:modal").show(ForgotPassword);
      await render(
        <template><AcademyPasswordSetupPrompt /><ModalContainer /></template>
      );
      assert
        .dom(".forgot-password-modal")
        .exists("the current task remains visible");
      assert
        .dom(".academy-password-setup")
        .doesNotExist("the reminder does not replace it");
      await click(".forgot-password-modal .modal-close");
      assert
        .dom(".academy-password-setup")
        .exists("the reminder opens once the other task closes");
    });

    test("waits for a confirmation dialog to close", async function (assert) {
      const dialog = this.owner.lookup("service:dialog");
      dialog.alert("Existing confirmation");
      await render(
        <template><AcademyPasswordSetupPrompt /><ModalContainer /></template>
      );
      assert
        .dom(".academy-password-setup")
        .doesNotExist("a confirmation takes priority");
      dialog.cancel();
      await settled();
      assert
        .dom(".academy-password-setup")
        .exists("closing the confirmation releases the reminder");
    });

    for (const state of [
      "existing account",
      "has password",
      "impersonating",
      "SSO",
      "local login disabled",
    ]) {
      test(`does not prompt when ${state}`, async function (assert) {
        if (state === "existing account") {
          this.currentUser.set("academy_password_setup_pending", false);
        } else if (state === "has password") {
          this.currentUser.set("no_password", false);
        } else if (state === "impersonating") {
          this.currentUser.set("is_impersonating", true);
        } else if (state === "SSO") {
          this.siteSettings.enable_discourse_connect = true;
        } else {
          this.siteSettings.enable_local_logins = false;
        }
        await render(
          <template><AcademyPasswordSetupPrompt /><ModalContainer /></template>
        );
        assert
          .dom(".academy-password-setup")
          .doesNotExist("only an eligible local account is prompted");
      });
    }
  }
);
