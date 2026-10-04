import { clearRender, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import AcademyStudentInviteForm from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-invite-form";

module("Integration | Component | AcademyStudentInviteForm", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser.set("admin", true);
    this.siteSettings.academy_roles_enabled = true;
    this.siteSettings.invite_expiry_days = 30;
  });

  test("creates an invitation with the entered student number and displays its code", async function (assert) {
    const invitation = {
      student_number: "0002026001",
      invite_key: "single-use-code",
      link: "/invites/single-use-code",
    };
    let createdInvitation;
    const onCreated = (created) => (createdInvitation = created);

    pretender.post("/academy-roles/admin/student-invites", (request) => {
      const parameters = new URLSearchParams(request.requestBody);
      assert.strictEqual(
        parameters.get("student_number"),
        invitation.student_number,
        "the student number preserves leading zeroes"
      );
      assert.true(
        moment(parameters.get("expires_at")).isAfter(moment()),
        "the invitation expires in the future"
      );
      return response(201, invitation);
    });

    await render(
      <template><AcademyStudentInviteForm @onCreated={{onCreated}} /></template>
    );
    await formKit().field("student_number").fillIn(invitation.student_number);
    await formKit().submit();

    assert
      .dom(".academy-student-invite-form")
      .includesText(
        invitation.student_number,
        "the administrator can review the bound student number"
      );
    assert
      .dom(".academy-student-invite-form code")
      .hasText(invitation.invite_key, "the single-use code can be copied");
    assert
      .dom(".academy-student-invite-form form")
      .doesNotExist("a created invitation replaces the entry form");
    assert.deepEqual(
      createdInvitation,
      invitation,
      "the caller receives the created invitation"
    );
  });

  test("requires a student number before submitting", async function (assert) {
    await render(<template><AcademyStudentInviteForm /></template>);
    await formKit().submit();

    assert
      .dom("[data-name='student_number'] .form-kit__errors")
      .exists("the missing student number is explained");
    assert
      .dom(".academy-student-invite-form code")
      .doesNotExist("no invitation is created");
  });

  test("hides the creation form from members and moderators", async function (assert) {
    this.currentUser.set("admin", false);
    await render(<template><AcademyStudentInviteForm /></template>);
    assert
      .dom(".academy-student-invite-form")
      .doesNotExist("a regular member cannot create student invitations");

    await clearRender();
    this.currentUser.set("moderator", true);
    await render(<template><AcademyStudentInviteForm /></template>);
    assert
      .dom(".academy-student-invite-form")
      .doesNotExist("a moderator cannot create student invitations");
  });

  test("hides the creation form when academy membership is disabled", async function (assert) {
    this.siteSettings.academy_roles_enabled = false;
    await render(<template><AcademyStudentInviteForm /></template>);

    assert
      .dom(".academy-student-invite-form")
      .doesNotExist("student invitations require academy membership");
  });
});
