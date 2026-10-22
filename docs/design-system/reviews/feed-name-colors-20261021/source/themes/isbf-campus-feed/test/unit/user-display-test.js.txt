import { module, test } from "qunit";
import { i18n } from "discourse-i18n";
import {
  displayIdentity,
  displayName,
  feedAuthorColor,
  notificationDisplayLabel,
} from "../../discourse/lib/user-display";

function notificationItem(
  type,
  data = {},
  name = "林同学",
  enableNames = true
) {
  return {
    notification: {
      acting_user_name: name,
      data: { display_username: "student", ...data },
    },
    renderDirector: { notificationName: type, username: "student" },
    siteSettings: { enable_names: enableNames },
  };
}

module("ISBF | Unit | Lib | user-display", function () {
  test("feed colors accept saved theme or hex colors and ignore arbitrary CSS", function (assert) {
    assert.strictEqual(
      feedAuthorColor({ academy_display_name_color: "theme" }),
      "var(--isbf-v2-accent)",
      "theme colors follow the active palette"
    );
    assert.strictEqual(
      feedAuthorColor({ academy_display_name_color: "#123abc" }),
      "#123abc",
      "validated custom colors retain their value"
    );
    for (const color of [
      null,
      "red",
      "var(--danger)",
      "#123abc;display:none",
    ]) {
      assert.strictEqual(
        feedAuthorColor({ academy_display_name_color: color }),
        null,
        "unsupported values cannot become inline styles"
      );
    }
  });

  test("saved current-user appearance overrides an older list object", function (assert) {
    const creator = { id: 1, academy_display_name_color: "theme" };
    assert.strictEqual(
      feedAuthorColor(creator, {
        id: 1,
        academy_display_name_color: "#123456",
      }),
      "#123456",
      "a successful preference save updates already loaded cards"
    );
    assert.strictEqual(
      feedAuthorColor(creator, { id: 1, academy_display_name_color: null }),
      null,
      "turning wear off clears stale list color"
    );
    assert.strictEqual(
      feedAuthorColor(creator, {
        id: 2,
        academy_display_name_color: "#123456",
      }),
      "var(--isbf-v2-accent)",
      "another viewer's preference does not change this author"
    );
  });

  test("a filled name is the primary name and retains the account identifier", function (assert) {
    const user = { name: "林同学", username: "student" };
    assert.strictEqual(
      displayName(user),
      "林同学",
      "the primary name uses the account name"
    );
    assert.strictEqual(
      displayIdentity(user),
      "林同学 @student",
      "notifications include both identities"
    );
    assert.strictEqual(
      displayIdentity({ name: "student", username: "student" }),
      "student @student",
      "an identical name retains the username identifier"
    );
  });

  test("missing and whitespace-only names fall back without duplicate identifiers", function (assert) {
    for (const name of [undefined, null, "", " \t\n "]) {
      const user = { name, username: "student" };
      assert.strictEqual(
        displayName(user),
        "student",
        "an empty name uses the username"
      );
      assert.strictEqual(
        displayIdentity(user),
        "student",
        "an empty name is not repeated"
      );
    }
    assert.strictEqual(
      displayName(null),
      undefined,
      "a missing actor has no invented name"
    );
  });

  test("received notifications use the current actor name independently of username preference", function (assert) {
    const item = notificationItem("mentioned", { display_name: "Old name" });
    assert.strictEqual(
      notificationDisplayLabel(item, "student"),
      "林同学 @student",
      "the serialized current name takes precedence over a stored label"
    );
    item.notification.acting_user_name = "";
    assert.strictEqual(
      notificationDisplayLabel(item, "student"),
      "student",
      "clearing a name does not restore a historical name"
    );
  });

  test("disabled names and deleted actors preserve their fallback", function (assert) {
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("mentioned", {}, "林同学", false),
        "student"
      ),
      "student",
      "disabled names are not displayed"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("mentioned", { display_username: null }),
        "Deleted user"
      ),
      "Deleted user",
      "a deleted actor keeps the native label"
    );
  });

  test("two-person and multi-person likes keep native counts and translation", function (assert) {
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("liked", {
          count: 2,
          username2: "friend",
          name2: "王同学",
        }),
        "Original summary"
      ),
      i18n("notifications.liked_by_2_users", {
        username: "林同学 @student",
        username2: "王同学 @friend",
      }),
      "both actors retain names and usernames"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("liked", { count: 4 }),
        "Original summary"
      ),
      i18n("notifications.liked_by_multiple_users", {
        username: "林同学 @student",
        count: 3,
      }),
      "the count of other users is preserved"
    );
  });

  test("reaction counts distinguish several actors from one actor reacting to several posts", function (assert) {
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("reaction", { count: 4 }),
        "student"
      ),
      "林同学 @student",
      "one actor reacting to several posts remains one actor"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("reaction", {
          count: 2,
          username2: "friend",
          name2: "王同学",
        }),
        "Original summary"
      ),
      i18n("notifications.reaction_2_users", {
        username: "林同学 @student",
        username2: "王同学 @friend",
      }),
      "two actors retain the native translation"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("reaction", { count: 4, username2: "friend" }),
        "Original summary"
      ),
      i18n("notifications.reaction_multiple_users", {
        username: "林同学 @student",
        count: 3,
      }),
      "several actors retain the original count"
    );
  });

  test("group mentions and moved posts retain their extra information", function (assert) {
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("group_mentioned", { group_name: "classmates" }),
        "student @classmates"
      ),
      "林同学 @student @classmates",
      "the mentioned group remains present"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("moved_post"),
        "Original summary"
      ),
      i18n("notifications.user_moved_post", { username: "林同学 @student" }),
      "the moved-post action remains in its translation"
    );
  });

  test("system labels and consolidated reply summaries keep their native meaning", function (assert) {
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("watching_first_post"),
        "New topic"
      ),
      "New topic",
      "a descriptive label is not replaced by an actor"
    );
    assert.strictEqual(
      notificationDisplayLabel(notificationItem("granted_badge"), null),
      null,
      "a label-free notification stays label-free"
    );
    assert.strictEqual(
      notificationDisplayLabel(
        notificationItem("replied", {
          consolidated_count: 3,
          reply_to_post_number: 1,
        }),
        "3 new replies"
      ),
      "3 new replies",
      "a reply bucket is not presented as one actor"
    );
  });
});
