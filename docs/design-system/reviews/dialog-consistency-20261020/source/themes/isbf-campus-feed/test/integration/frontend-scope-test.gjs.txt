import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
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
});
