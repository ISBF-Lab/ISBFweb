import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import userFixtures from "discourse/tests/fixtures/user-fixtures";
import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";

const PERSONAL_ROUTES = [
  "/u/eviltrout/summary",
  "/u/eviltrout/activity/bookmarks",
  "/u/eviltrout/notifications",
  "/u/eviltrout/preferences/profile",
  "/u/eviltrout/messages",
];

function setupUserPages(
  needs,
  {
    admin = false,
    moderatorRole = true,
    effectiveModerator = false,
    permission = false,
    featureEnabled = true,
  } = {}
) {
  const state = {};

  needs.settings({ academy_roles_enabled: featureEnabled });
  needs.user({
    admin,
    moderator: effectiveModerator,
    academy_moderator_role: moderatorRole,
    academy_moderator_permissions: { user_admin: permission, review: false },
    academy_activity_level: 0,
    academy_official_member: false,
  });
  needs.hooks.beforeEach(() => {
    state.permission = permission;
    state.status = permission === false ? 403 : 200;
    state.requests = 0;
  });
  needs.pretender((server, helper) => {
    for (const username of ["eviltrout", "charlie"]) {
      server.get(`/u/${username}.json`, () => {
        const json = cloneJSON(userFixtures[`/u/${username}.json`]);
        json.user.academy_activity_level = 0;
        json.user.academy_official_member = false;
        if (username === "eviltrout") {
          json.user.admin = admin;
          json.user.moderator = moderatorRole;
          json.user.can_edit = true;
        }
        if (state.permission === undefined || state.permission === null) {
          delete json.user.academy_can_see_staff_info;
        } else {
          json.user.academy_can_see_staff_info = state.permission;
        }
        return helper.response(json);
      });
      server.get(`/u/${username}/staff-info.json`, () => {
        state.requests++;
        return helper.response(
          state.status,
          state.status === 200
            ? { number_of_flags: 2, number_of_suspensions: 1 }
            : { errors: ["Staff information unavailable"] }
        );
      });
    }
    server.get("/u/missing-personal-profile.json", () =>
      helper.response(404, { errors: ["User not found"] })
    );
  });

  return state;
}

acceptance("Academy user pages without staff information", function (needs) {
  const state = setupUserPages(needs);

  test("opens personal pages with management permissions disabled", async function (assert) {
    for (const route of PERSONAL_ROUTES) {
      await visit(route);

      assert.true(currentURL().startsWith(route), `${route} stays accessible`);
      assert.dom(".user-main").exists(`${route} renders the personal page`);
    }

    assert.strictEqual(
      state.requests,
      0,
      "restricted staff information is never requested"
    );
    await click(".user-profile-toggle-btn");
    assert
      .dom(".staff-counters")
      .doesNotExist("management statistics remain hidden");
  });

  test("keeps personal and public profiles accessible with another management permission", async function (assert) {
    await visit("/");
    updateCurrentUser({
      moderator: true,
      academy_moderator_permissions: { user_admin: false, review: true },
    });

    for (const route of [...PERSONAL_ROUTES, "/u/charlie/summary"]) {
      await visit(route);

      assert.true(currentURL().startsWith(route), `${route} stays accessible`);
      assert.dom(".user-main").exists(`${route} renders the profile`);
    }

    assert.strictEqual(
      state.requests,
      0,
      "another management permission does not request staff information"
    );
  });

  test("preserves the missing profile error", async function (assert) {
    await visit("/u/missing-personal-profile/summary");

    assert.strictEqual(
      currentURL(),
      "/404",
      "a missing profile still reaches the error page"
    );
  });
});

acceptance("Academy user pages with staff information", function (needs) {
  const state = setupUserPages(needs, {
    effectiveModerator: true,
    permission: true,
  });

  test("loads authorized management statistics", async function (assert) {
    await visit("/u/eviltrout/summary");
    await click(".user-profile-toggle-btn");

    assert.strictEqual(
      state.requests,
      1,
      "authorized staff information is requested"
    );
    assert.dom(".staff-counters").exists("management statistics are displayed");
  });

  test("opens the profile and clears old statistics after a permission denial", async function (assert) {
    state.status = 403;
    await visit("/");
    updateCurrentUser({
      number_of_flags: 7,
      number_of_suspensions: 3,
      can_remove_password: true,
    });

    await visit("/u/eviltrout/summary");

    assert.strictEqual(
      currentURL(),
      "/u/eviltrout/summary",
      "the optional request does not break the profile"
    );
    assert.dom(".user-main").exists("the profile still renders");
    await click(".user-profile-toggle-btn");
    assert
      .dom(".staff-counters")
      .doesNotExist("previous management statistics are cleared");
    const user = this.owner.lookup("service:current-user");
    assert.false(
      user.academy_can_see_staff_info,
      "the unavailable permission is recorded"
    );
    assert.strictEqual(
      user.can_remove_password,
      undefined,
      "previous management actions are cleared"
    );
  });

  test("continues the native behavior when the capability field is absent", async function (assert) {
    state.permission = undefined;

    await visit("/u/eviltrout/summary");
    await click(".user-profile-toggle-btn");

    assert.strictEqual(
      state.requests,
      1,
      "older profile responses keep the native request"
    );
    assert
      .dom(".staff-counters")
      .exists("authorized legacy statistics are displayed");
  });

  test("propagates a server error from staff information", async function (assert) {
    await visit("/u/eviltrout/summary");
    state.status = 500;
    const user = this.owner.lookup("service:current-user");

    await assert.rejects(
      user.findStaffInfo(),
      (error) => error.jqXHR?.status === 500,
      "server failures retain their original error"
    );
  });
});

acceptance("Academy personal pages for ordinary users", function (needs) {
  const state = setupUserPages(needs, { moderatorRole: false });

  test("opens an ordinary user's bookmarks without management information", async function (assert) {
    await visit("/u/eviltrout/activity/bookmarks");

    assert.dom(".bookmark-list-item").exists("the user's bookmarks render");
    assert.strictEqual(
      state.requests,
      0,
      "ordinary users do not request staff information"
    );
  });
});

acceptance("Academy personal pages for developers", function (needs) {
  const state = setupUserPages(needs, {
    admin: true,
    moderatorRole: false,
    permission: true,
  });

  test("keeps developers' management information accessible", async function (assert) {
    await visit("/u/eviltrout/summary");
    await click(".user-profile-toggle-btn");

    assert
      .dom(".staff-counters")
      .exists("developers retain their management information");
    assert.strictEqual(
      state.requests,
      1,
      "developers keep the original request"
    );
  });
});

acceptance("Personal pages with academy roles disabled", function (needs) {
  const state = setupUserPages(needs, {
    effectiveModerator: true,
    permission: null,
    featureEnabled: false,
  });

  test("keeps native moderator profile behavior", async function (assert) {
    await visit("/u/eviltrout/summary");
    await click(".user-profile-toggle-btn");

    assert
      .dom(".staff-counters")
      .exists("native moderator statistics remain available");
    assert.strictEqual(
      state.requests,
      1,
      "native moderators keep the original request"
    );
  });
});
