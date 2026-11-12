import { click, currentRouteName, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

/**
 * Workaround for https://github.com/tildeio/router.js/pull/335
 */
async function visitWithRedirects(url) {
  try {
    await visit(url);
  } catch (error) {
    if (error.message !== "TransitionAborted") {
      throw error;
    }
    await settled();
  }
}

acceptance("ISBF profile visibility - preferences", function (needs) {
  needs.user();
  needs.settings({
    allow_users_to_hide_profile: true,
    isbf_profile_visibility_enabled: true,
  });

  let putRequestData;

  needs.pretender((server, helper) => {
    server.get("/u/eviltrout.json", () => {
      const json = cloneJSON(userFixtures["/u/eviltrout.json"]);
      json.user.can_edit = true;
      json.user.user_option.hide_profile = false;
      json.user.isbf_profile_visibility = {
        bio: false,
        summary: true,
        activity: false,
      };
      return helper.response(json);
    });

    server.put("/u/eviltrout.json", (request) => {
      putRequestData = helper.parsePostData(request.requestBody);
      return helper.response({ user: {} });
    });
  });

  needs.hooks.afterEach(() => {
    putRequestData = null;
  });

  test("shows each section as public unless the owner hid it", async function (assert) {
    await visit("/u/eviltrout/preferences/profile");

    const form = formKit(".profile-visibility");
    assert.true(form.field("bio").value(), "about me starts public");
    assert.false(
      form.field("summary").value(),
      "the hidden summary is unchecked"
    );
    assert.true(form.field("activity").value(), "activity starts public");
  });

  test("saves an unchecked section as hidden with the profile", async function (assert) {
    await visit("/u/eviltrout/preferences/profile");
    await formKit(".profile-visibility").field("activity").toggle();
    await click(".save-changes");

    assert.strictEqual(
      putRequestData.custom_fields?.isbf_hide_profile_activity,
      "true",
      "the unchecked section is sent as hidden"
    );
    assert.strictEqual(
      putRequestData.custom_fields?.isbf_hide_profile_bio,
      undefined,
      "an untouched section is not sent"
    );
    assert.strictEqual(
      putRequestData.hide_profile,
      "false",
      "the whole profile stays visible"
    );
  });

  test("locks the sections while the whole profile is hidden", async function (assert) {
    await visit("/u/eviltrout/preferences/profile");

    const form = formKit(".profile-visibility");
    assert.false(form.field("bio").isDisabled(), "sections start editable");

    await form.field("hide_profile").toggle();

    for (const section of ["bio", "summary", "activity"]) {
      assert.true(
        form.field(section).isDisabled(),
        `${section} is locked while everything is hidden`
      );
    }
  });
});

function viewedProfile(needs, hiddenSections, settings = {}) {
  needs.user({ admin: false, moderator: false });
  needs.settings({ isbf_profile_visibility_enabled: true, ...settings });
  needs.pretender((server, helper) => {
    server.get("/u/charlie.json", () => {
      const json = cloneJSON(userFixtures["/u/charlie.json"]);
      json.user.isbf_hidden_profile_sections = hiddenSections;
      return helper.response(json);
    });
  });
}

acceptance("ISBF profile visibility - summary hidden", function (needs) {
  viewedProfile(needs, ["summary"]);

  test("falls back to activity and keeps the header expanded", async function (assert) {
    await visitWithRedirects("/u/charlie");

    assert.strictEqual(currentRouteName(), "userActivity.index");
    assert
      .dom(document.body)
      .hasClass("isbf-profile-summary-hidden", "the summary tab is hidden");
    assert.dom(".user-nav__activity").exists("the activity tab is rendered");
    assert
      .dom(".user-main .about")
      .doesNotHaveClass("collapsed-info", "the public bio stays visible");
  });
});

acceptance("ISBF profile visibility - activity hidden", function (needs) {
  viewedProfile(needs, ["activity"]);

  test("falls back to the summary", async function (assert) {
    await visitWithRedirects("/u/charlie/activity");

    assert.strictEqual(currentRouteName(), "user.summary");
    assert
      .dom(".user-nav__activity")
      .doesNotExist("the activity tab is not rendered");
  });
});

acceptance(
  "ISBF profile visibility - summary and activity hidden",
  function (needs) {
    viewedProfile(needs, ["summary", "activity"]);

    test("shows a placeholder", async function (assert) {
      await visitWithRedirects("/u/charlie");

      assert.strictEqual(currentRouteName(), "user.profilePrivate");
      assert
        .dom(".user-profile-hidden .empty-state__title")
        .hasText(i18n("isbf_profile_visibility.sections_hidden.title"));
      assert
        .dom(".user-main .about")
        .doesNotHaveClass("collapsed-info", "the public bio stays visible");
    });
  }
);

acceptance(
  "ISBF profile visibility - summary hidden and activity tab disabled",
  function (needs) {
    viewedProfile(needs, ["summary"], { hide_user_activity_tab: true });

    test("shows the placeholder instead of an activity page nobody can open", async function (assert) {
      await visitWithRedirects("/u/charlie");

      assert.strictEqual(currentRouteName(), "user.profilePrivate");
    });
  }
);

acceptance("ISBF profile visibility - whole profile hidden", function (needs) {
  needs.user({ admin: false, moderator: false });
  needs.settings({ isbf_profile_visibility_enabled: true });
  needs.pretender((server, helper) => {
    server.get("/u/hideme.json", () =>
      helper.response({
        user: {
          id: 1234,
          username: "hideme",
          name: null,
          avatar_template: "/letter_avatar_proxy/v4/letter/h/8edcca/{size}.png",
          profile_hidden: true,
          title: null,
          primary_group_name: null,
        },
      })
    );
  });

  test("shows the hidden profile placeholder", async function (assert) {
    await visitWithRedirects("/u/hideme");

    assert.strictEqual(currentRouteName(), "user.profilePrivate");
    assert
      .dom(".user-profile-hidden .empty-state__title")
      .hasText(i18n("isbf_profile_visibility.profile_hidden_title"));
  });
});
