import { click, fillIn, find, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import { fixturesByUrl } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("ISBF frontend consistency", function (needs) {
  needs.user();
  needs.settings({ enable_names: true, enable_user_directory: true });
  needs.pretender((server, helper) => {
    server.get("/u/eviltrout.json", () => {
      const data = cloneJSON(fixturesByUrl["/u/eviltrout.json"]);
      data.user.can_edit = true;
      return helper.response(data);
    });
  });

  test("account fields and the native username editing flow stay available", async function (assert) {
    await visit("/u/eviltrout/preferences/account");
    assert
      .dom(document.body)
      .hasClass(
        "is-frontend-preferences",
        "the real route receives the settings scope"
      );
    assert.dom(".pref-email").exists("email fields remain visible");
    assert.dom(".pref-name").exists("name fields remain visible");
    await click(".username-preference__edit-username");
    await fillIn(".username-preference__input", "taken");
    assert
      .dom(".username-preference__submit")
      .isDisabled("native validation still disables submission");
  });

  test("directory retains data and clears its scope when leaving", async function (assert) {
    await visit("/u?period=all");
    assert
      .dom(document.body)
      .hasClass(
        "is-frontend-directory",
        "the query does not bypass scope classification"
      );
    assert
      .dom(".directory-table__row")
      .exists("native directory data has completed loading");
    assert.dom(".time-read").exists("period-dependent columns are retained");
    assert
      .dom(".directory-table__cell--user-field")
      .exists("custom fields are retained");
    await visit("/u/eviltrout/activity/topics");
    assert
      .dom(document.body)
      .doesNotHaveClass(
        "isbf-frontend",
        "the approved public activity route is excluded"
      );
  });

  test("functional-page styles leave the profile upper region unchanged", async function (assert) {
    await visit("/u/eviltrout/preferences/profile");
    const selectors = [
      ".user-main > .about",
      ".user-profile-avatar",
      ".user-profile-names",
      ".user-navigation-primary",
    ];
    const snapshots = selectors.map((selector) => {
      const element = find(selector);
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return {
        selector,
        width: rect.width,
        height: rect.height,
        font: style.font,
        background: style.backgroundColor,
      };
    });
    document.body.classList.remove("isbf-frontend");
    for (const snapshot of snapshots) {
      const element = find(snapshot.selector);
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      assert.deepEqual(
        {
          width: rect.width,
          height: rect.height,
          font: style.font,
          background: style.backgroundColor,
        },
        {
          width: snapshot.width,
          height: snapshot.height,
          font: snapshot.font,
          background: snapshot.background,
        },
        `${snapshot.selector} is identical with and without new styling`
      );
    }
    document.body.classList.add("isbf-frontend");
  });
});
