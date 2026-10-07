import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Academy student invitations", function (needs) {
  needs.user({ admin: true });
  needs.settings({
    academy_roles_enabled: true,
    invite_expiry_days: 30,
  });

  needs.pretender((server, helper) => {
    server.get("/admin/plugins/discourse-academy-roles.json", () =>
      helper.response({
        id: "discourse-academy-roles",
        name: "discourse-academy-roles",
        enabled: true,
        has_settings: true,
        humanized_name: "Academy roles",
        is_discourse_owned: false,
        admin_route: {
          label: "academy_roles.student_invites.title",
          location: "discourse-academy-roles",
          use_new_show_route: true,
        },
      })
    );

    server.get("/academy-roles/admin/student-invites", () =>
      helper.response({
        student_invites: [
          {
            id: 1,
            student_number: "0002026001",
            status: "pending",
            expires_at: "2099-01-02T03:04:05Z",
            invite_key: "academy-invite-code",
            link: "/invites/academy-invite-code",
          },
        ],
        has_more: false,
      })
    );
  });

  test("displays the future expiration date on the invitation list", async function (assert) {
    await visit("/admin/plugins/discourse-academy-roles/student-invites");

    assert
      .dom(".academy-student-invites tbody .--overview")
      .hasText(
        "0002026001",
        "the pending invitation displays its student number"
      );
    assert
      .dom(".academy-student-invites tbody td:nth-child(3)")
      .includesText("2099", "the expiration date displays its future year");
  });

  test("renders the student invitation form on the admin new page", async function (assert) {
    await visit("/admin/plugins/discourse-academy-roles/student-invites/new");

    assert
      .dom(".admin-config-area-card__content .academy-student-invite-form")
      .exists("the new page renders the form inside the card content");
    assert
      .dom(".academy-student-invite-form [data-name='student_number'] input")
      .exists("the administrator can enter the student's number");
    assert
      .dom(
        ".academy-student-invite-form [data-name='expires_after_days'] input"
      )
      .hasValue("30", "the form displays the configured invitation lifetime");
    assert
      .dom(".academy-student-invite-form [type='submit']")
      .exists("the administrator can submit the invitation form");
  });

  test("opens the CSV bulk form from the invitation list", async function (assert) {
    await visit("/admin/plugins/discourse-academy-roles/student-invites");

    assert
      .dom(".d-page-subheader__actions .btn-default")
      .hasText(
        i18n("academy_roles.student_invites.bulk.title"),
        "the invitation list offers bulk generation"
      );

    await click(".d-page-subheader__actions .btn-default");

    assert
      .dom(".admin-config-area-card__content .academy-student-invite-bulk-form")
      .exists("the bulk page uses an admin form card");
    assert
      .dom(".academy-student-invite-bulk-form input[type='file']")
      .exists("the administrator can choose a CSV");
    assert
      .dom("[data-name='expires_after_days'] input")
      .hasValue("30", "the configured invitation lifetime is the default");
  });
});
