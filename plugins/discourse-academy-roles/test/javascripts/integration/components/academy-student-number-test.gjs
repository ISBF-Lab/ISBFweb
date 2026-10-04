import { clearRender, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import AcademyStudentNumber from "discourse/plugins/discourse-academy-roles/discourse/connectors/admin-user-below-names/academy-student-number";

module("Integration | Component | AcademyStudentNumber", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.academy_roles_enabled = true;
  });

  test("shows the bound student number in the administrator's account view", async function (assert) {
    this.currentUser.set("admin", true);
    const outletArgs = { user: { academy_student_number: "0002026001" } };

    await render(
      <template><AcademyStudentNumber @outletArgs={{outletArgs}} /></template>
    );

    assert
      .dom(".academy-student-number .value")
      .hasText(
        outletArgs.user.academy_student_number,
        "the administrator can read the complete student number"
      );
  });

  test("hides student numbers from members and moderators even if supplied in data", async function (assert) {
    const outletArgs = { user: { academy_student_number: "0002026001" } };

    await render(
      <template><AcademyStudentNumber @outletArgs={{outletArgs}} /></template>
    );
    assert
      .dom(".academy-student-number")
      .doesNotExist("an account holder cannot see the student number");

    await clearRender();
    this.currentUser.set("moderator", true);
    await render(
      <template><AcademyStudentNumber @outletArgs={{outletArgs}} /></template>
    );
    assert
      .dom(".academy-student-number")
      .doesNotExist("a moderator cannot see the student number");
  });

  test("identifies older accounts that have no student number binding", async function (assert) {
    this.currentUser.set("admin", true);
    const outletArgs = { user: {} };

    await render(
      <template><AcademyStudentNumber @outletArgs={{outletArgs}} /></template>
    );

    assert
      .dom(".academy-student-number .value")
      .hasText(
        i18n("academy_roles.student_invites.unbound"),
        "older accounts stay unbound"
      );
  });
});
