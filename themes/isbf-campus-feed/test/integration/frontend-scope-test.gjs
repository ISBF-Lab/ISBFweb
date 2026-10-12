import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import CreateInvite from "discourse/components/modal/create-invite";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFFrontendScope from "../../discourse/components/isbf-frontend-scope";

module("ISBF | Integration | Component | ISBFFrontendScope", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.router = this.owner.lookup("service:router");
    this.router.currentRouteName = "preferences.account";
  });

  test("route transitions remove the previous region's classes", async function (assert) {
    await render(<template><ISBFFrontendScope /></template>);
    assert
      .dom(document.body)
      .hasClass("is-frontend-preferences", "settings are admitted");
    assert
      .dom(document.body)
      .hasClass(
        "has-frontend-user-content",
        "only the lower user region receives rules"
      );

    this.router.currentRouteName = "users";
    await settled();
    assert
      .dom(document.body)
      .hasClass(
        "is-frontend-directory",
        "the directory receives its own scope"
      );
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "is-frontend-preferences",
        "settings rules are released"
      );
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "has-frontend-user-content",
        "user-region rules are released"
      );

    this.router.currentRouteName = "admin.dashboard";
    await settled();
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "isbf-frontend",
        "admin cannot inherit a frontend scope"
      );
  });

  test("an invitation dialog keeps native modal lifecycle and releases its scope", async function (assert) {
    this.router.currentRouteName = "userInvited.show";
    await render(<template><ISBFFrontendScope /></template>);
    const modal = this.owner.lookup("service:modal");
    const closed = modal.show(CreateInvite, { model: {} });
    await settled();
    assert
      .dom(document.body)
      .hasClass(
        "has-frontend-dialog",
        "the admitted native dialog receives the container rules"
      );

    modal.close();
    await closed;
    await settled();
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "has-frontend-dialog",
        "closing the dialog releases its scope"
      );
    assert
      .dom(document.body)
      .hasClass(
        "is-frontend-invitations",
        "the invitation page remains admitted"
      );
  });

  test("draft confirmation rules release on cancellation and navigation", async function (assert) {
    this.router.currentRouteName = "userActivity.drafts";
    await render(<template><ISBFFrontendScope /></template>);
    const dialog = this.owner.lookup("service:dialog");
    const confirmation = dialog.deleteConfirm({
      title: "Synthetic draft deletion",
    });
    await settled();
    assert
      .dom(document.body)
      .hasClass(
        "has-frontend-dialog",
        "the admitted draft confirmation is scoped"
      );
    dialog.cancel();
    await confirmation;
    await settled();
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "has-frontend-dialog",
        "cancellation releases the dialog rules"
      );
    this.router.currentRouteName = "userActivity.topics";
    await settled();
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "isbf-frontend",
        "the approved public activity route remains unchanged"
      );
  });

  test("the same dialog on admin receives no new appearance", async function (assert) {
    this.router.currentRouteName = "admin.users.show";
    await render(<template><ISBFFrontendScope /></template>);
    const modal = this.owner.lookup("service:modal");
    const closed = modal.show(CreateInvite, { model: {} });
    await settled();
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "has-frontend-dialog",
        "the component whitelist cannot override the route boundary"
      );
    modal.close();
    await closed;
  });
});
