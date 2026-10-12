import { module, test } from "qunit";
import { frontendConsistencyScope } from "../../discourse/lib/frontend-consistency-scope";

module("ISBF | Unit | Lib | frontend-consistency-scope", function () {
  test("only registered preference subroutes receive functional-page rules", function (assert) {
    for (const child of [
      "account",
      "security",
      "profile",
      "emails",
      "notifications",
      "tracking",
      "users",
      "tags",
      "interface",
      "apps",
      "navigation-menu",
      "calendar-subscriptions",
      "email",
      "second-factor",
    ]) {
      assert.deepEqual(
        frontendConsistencyScope(`preferences.${child}`),
        { id: "preferences", layout: "feature", userContent: true },
        `${child} styles the lower region without changing its profile parent`
      );
    }
    assert.strictEqual(
      frontendConsistencyScope("preferences.plugin-setting"),
      null,
      "unknown plugin settings are not silently assigned a new design"
    );
    assert.strictEqual(
      frontendConsistencyScope("preferences.account.plugin-panel"),
      null,
      "plugin descendants do not inherit approval from a parent setting"
    );
  });

  test("directory and invitation filters use separate page scopes", function (assert) {
    assert.strictEqual(
      frontendConsistencyScope("users").id,
      "directory",
      "the native user directory is admitted"
    );
    assert.strictEqual(
      frontendConsistencyScope("userInvited.show").id,
      "invitations",
      "the native resetNamespace invitation route is admitted"
    );
    assert.strictEqual(
      frontendConsistencyScope("user.invited.show"),
      null,
      "a guessed route namespace is not used as a fallback"
    );
  });

  test("private lists and profile lower routes have explicit scopes", function (assert) {
    const routes = {
      "userActivity.bookmarks": "bookmarks",
      "userActivity.bookmarksWithReminders": "bookmarks",
      "userActivity.drafts": "drafts",
      "userActivity.pending": "pending",
      "user.summary": "profile-summary",
      "user.badges": "profile-badges",
      "user.deletedPosts": "deleted-posts",
      "user.profile-hidden": "profile-hidden",
    };
    for (const [route, id] of Object.entries(routes)) {
      assert.deepEqual(
        frontendConsistencyScope(route),
        { id, layout: "feed", userContent: true },
        `${route} only targets the lower profile region`
      );
    }
    for (const route of [
      "userPrivateMessages.user.index",
      "userPrivateMessages.user.warnings",
      "userPrivateMessages.group.archive",
      "userPrivateMessages.tags.show",
    ]) {
      assert.strictEqual(
        frontendConsistencyScope(route).id,
        "messages",
        `${route} retains the private message list`
      );
    }
    assert.strictEqual(
      frontendConsistencyScope("userPrivateMessages.plugin-messages"),
      null,
      "unknown private message extensions are excluded"
    );
    assert.strictEqual(
      frontendConsistencyScope("badges.show").id,
      "badges",
      "the native badge grant list receives collection rules"
    );
  });

  test("loading, admin, authentication and approved surfaces stay outside the rollout", function (assert) {
    for (const route of [
      null,
      undefined,
      "",
      "adminUsers.show",
      "admin.plugins.show",
      "login",
      "signup",
      "session",
      "tagGroups.index",
      "discovery.latest",
      "userActivity.topics",
      "userActivity.replies",
      "userNotifications.index",
      "isbf-calendar",
      "isbf-alumni",
      "isbf-marketplace",
      "user.card",
    ]) {
      assert.strictEqual(
        frontendConsistencyScope(route),
        null,
        `${String(route)} cannot activate new visual rules`
      );
    }
  });
});
