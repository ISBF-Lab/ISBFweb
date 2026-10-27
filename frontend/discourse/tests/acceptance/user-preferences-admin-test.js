import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

for (const mobile of [false, true]) {
  acceptance(
    `User Preferences Admin - ${mobile ? "Mobile" : "Desktop"}`,
    function (needs) {
      let profileRoles;
      needs.user({ admin: true });

      needs.hooks.beforeEach(() => {
        profileRoles = {};
      });

      needs.pretender((server, helper) => {
        server.get("/u/eviltrout.json", () => {
          const response = cloneJSON(userFixtures["/u/eviltrout.json"]);
          Object.assign(response.user, profileRoles);
          return helper.response(response);
        });
      });

      if (mobile) {
        needs.mobileView();
      }

      test("admin entry is in the primary navigation", async function (assert) {
        await visit("/u/eviltrout");

        assert
          .dom(".user-navigation-primary .user-nav__admin a")
          .hasText(
            i18n("admin.user.show_admin_profile"),
            "uses the admin entry label"
          )
          .hasAttribute(
            "href",
            /^\/admin\/users\/\d+\/eviltrout$/,
            "links to the admin page"
          );
        assert
          .dom(".user-admin")
          .doesNotExist("has no duplicate profile header entry");
      });

      test("admin entry follows the viewed user", async function (assert) {
        await visit("/u/charlie/summary");

        assert
          .dom(".user-nav__admin a")
          .hasAttribute(
            "href",
            /^\/admin\/users\/\d+\/charlie$/,
            "links to the viewed user's admin page"
          );
      });

      test("moderators cannot see the admin entry", async function (assert) {
        profileRoles = { admin: false, moderator: true, staff: true };
        updateCurrentUser(profileRoles);
        await visit("/u/eviltrout");

        assert
          .dom(".user-nav__admin")
          .doesNotExist("hides the navigation entry from moderators");
        assert
          .dom(".user-admin")
          .doesNotExist("hides the header entry from moderators");

        await visit("/u/charlie/summary");
        assert
          .dom(".user-nav__admin")
          .doesNotExist("also hides the entry on another user's profile");
      });

      test("members cannot see the admin entry", async function (assert) {
        profileRoles = { admin: false, moderator: false, staff: false };
        updateCurrentUser(profileRoles);
        await visit("/u/eviltrout");

        assert
          .dom(".user-nav__admin")
          .doesNotExist("hides the navigation entry from members");
        assert
          .dom(".user-admin")
          .doesNotExist("hides the header entry from members");

        await visit("/u/charlie/summary");
        assert
          .dom(".user-nav__admin")
          .doesNotExist("also hides the entry on another user's profile");
      });
    }
  );
}

acceptance("User Preferences Admin - Anonymous", function () {
  test("anonymous visitors cannot see the admin entry", async function (assert) {
    await visit("/u/eviltrout");

    assert
      .dom(".user-nav__admin")
      .doesNotExist("hides the navigation entry from anonymous visitors");
    assert
      .dom(".user-admin")
      .doesNotExist("hides the header entry from anonymous visitors");
  });
});
