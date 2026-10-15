import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import AcademyModeratorPermissions from "discourse/plugins/discourse-academy-roles/discourse/components/academy-moderator-permissions";

const SETTINGS = {
  internal_boards: "academy_moderators_access_internal_boards",
  user_admin: "academy_moderators_access_user_admin",
  hidden_content: "academy_moderators_view_hidden_content",
  review: "academy_moderators_review_content",
  edit_others: "academy_moderators_edit_others_content",
  delete_others: "academy_moderators_delete_others_content",
  manage_topics: "academy_moderators_manage_topics",
  edit_users: "academy_moderators_edit_users",
  suspend_users: "academy_moderators_suspend_users",
  silence_users: "academy_moderators_silence_users",
  delete_users: "academy_moderators_delete_users",
  anonymize_users: "academy_moderators_anonymize_users",
  manage_categories: "moderators_manage_categories",
  manage_groups: "moderators_manage_groups",
  publish_activities: "academy_moderators_publish_activities",
  publish_official: "academy_moderators_publish_official",
  review_resources: "academy_moderators_review_resources",
  review_resumes: "academy_moderators_review_resumes",
  manage_resources: "academy_moderators_manage_resources",
  view_emails: "moderators_view_emails",
  trace_anonymous: "academy_moderators_trace_anonymous",
};

module(
  "Integration | Component | AcademyModeratorPermissions",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.currentUser.set("admin", true);
      this.model = {
        settings: SETTINGS,
        values: Object.fromEntries(
          Object.values(SETTINGS).map((name) => [name, false])
        ),
      };
    });

    test("renders twenty-one switches for developers", async function (assert) {
      await render(
        <template>
          <AcademyModeratorPermissions @model={{this.model}} />
        </template>
      );
      assert
        .dom("[role='switch']")
        .exists({ count: 21 }, "all independent capabilities are configurable");
      assert
        .form()
        .field(SETTINGS.review_resumes)
        .hasTitle(
          "Review shared resumes (optional)",
          "resume review has its own configurable capability"
        );
      assert
        .dom(".academy-moderator-permissions")
        .includesText(
          "Review reports and queued content",
          "permission labels are translated"
        );
      assert
        .dom("[role='switch'][aria-checked='true']")
        .doesNotExist("the initial permissions are disabled");
    });

    test("does not render the configuration to moderators", async function (assert) {
      this.currentUser.setProperties({ admin: false, moderator: true });
      await render(
        <template>
          <AcademyModeratorPermissions @model={{this.model}} />
        </template>
      );
      assert
        .dom("form")
        .doesNotExist("configuration requires the developer role");
    });

    test("saves only changed switches and uses the saved values for subsequent edits", async function (assert) {
      const requests = [];
      pretender.put("/admin/site_settings/bulk_update", (request) => {
        requests.push(new URLSearchParams(request.requestBody));
        return response(204);
      });
      await render(
        <template>
          <AcademyModeratorPermissions @model={{this.model}} />
        </template>
      );
      await formKit().field(SETTINGS.review).toggle();
      await formKit().field(SETTINGS.suspend_users).toggle();
      assert.strictEqual(
        requests.length,
        0,
        "draft changes apply together when saved"
      );
      await formKit().submit();
      assert.strictEqual(
        requests[0].get(`settings[${SETTINGS.review}][value]`),
        "true",
        "review access is enabled"
      );
      assert.strictEqual(
        requests[0].get(`settings[${SETTINGS.suspend_users}][value]`),
        "true",
        "suspension access is enabled"
      );
      assert.strictEqual(
        [...requests[0].keys()].length,
        2,
        "unchanged settings are omitted"
      );
      assert
        .dom(".form-kit__alert.alert-success")
        .exists("the completed save is confirmed");
      await formKit().field(SETTINGS.review).toggle();
      await formKit().submit();
      assert.strictEqual(
        requests[1].get(`settings[${SETTINGS.review}][value]`),
        "false",
        "a saved permission can be revoked"
      );
      assert.strictEqual(
        [...requests[1].keys()].length,
        1,
        "the other saved capability is retained"
      );
    });

    test("retains draft changes after a rejected save", async function (assert) {
      const requests = [];
      let reject = true;
      pretender.put("/admin/site_settings/bulk_update", (request) => {
        requests.push(new URLSearchParams(request.requestBody));
        return reject
          ? response(422, { errors: ["The update was rejected"] })
          : response(204);
      });
      await render(
        <template>
          <AcademyModeratorPermissions @model={{this.model}} />
        </template>
      );
      await formKit().field(SETTINGS.review).toggle();
      await formKit().submit();
      assert
        .dom(".form-kit__alert.alert-success")
        .doesNotExist("a rejected update is not confirmed");
      assert
        .dom(`[data-name='${SETTINGS.review}'] [role='switch']`)
        .hasAttribute("aria-checked", "true", "the draft remains editable");
      reject = false;
      await formKit().submit();
      assert.strictEqual(
        requests[1].get(`settings[${SETTINGS.review}][value]`),
        "true",
        "retry submits the same draft"
      );
    });
  }
);
