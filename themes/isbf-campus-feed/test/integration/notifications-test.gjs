import {
  clearRender,
  click,
  render,
  settled,
  triggerEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { themePrefix } from "virtual:theme";
import DiscourseURL from "discourse/lib/url";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import Notification from "discourse/models/notification";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import { publishToMessageBus } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";
import ISBFNotificationBell from "../../discourse/components/isbf-notification-bell";
import ISBFNotificationEntry from "../../discourse/components/isbf-notification-entry";
import ISBFNotifications from "../../discourse/components/isbf-notifications";
import NotificationState from "../../discourse/services/isbf-notifications";

module(
  "ISBF | Integration | Component | ISBFNotificationEntry",
  function (hooks) {
    setupRenderingTest(hooks);

    for (const standalone of [false, true]) {
      test(`opens the ${standalone ? "native" : "grouped"} notification target and consumes its unread count once`, async function (assert) {
        const type = this.site.notification_types.replied;
        this.currentUser.set("grouped_unread_notifications", { [type]: 1 });
        const [notification] = await Notification.initializeNotifications([
          {
            id: 93001,
            notification_type: type,
            read: false,
            topic_id: 930,
            post_number: 2,
            slug: "campus",
            data: {
              display_username: "student",
              topic_title: "Campus discussion",
            },
          },
        ]);
        const appEvents = this.owner.lookup("service:app-events");
        const events = sinon.spy(appEvents, "trigger");
        const routeTo = sinon.stub(DiscourseURL, "routeTo");
        const item = new UserMenuNotificationItem({
          notification,
          appEvents,
          currentUser: this.currentUser,
          site: this.site,
          siteSettings: this.siteSettings,
        });
        const entry = {
          action: "replied",
          actionLabel: "replied",
          actor: {
            username: "student",
            avatar_template: "/images/avatar.png",
          },
          created_at: "2026-10-18T01:00:00Z",
          item,
          notification,
        };
        await render(
          <template>
            <ISBFNotificationEntry
              @entry={{entry}}
              @standalone={{standalone}}
            />
          </template>
        );
        const link = standalone
          ? ".isbf-notification-entry__native > li > a"
          : ".isbf-notification-entry__link";

        await click(link);
        assert.true(
          routeTo.calledOnceWithExactly(item.linkHref),
          "navigation retains the original notification target"
        );
        assert.strictEqual(
          events.withArgs("user-menu:notification-click").callCount,
          1,
          "one click publishes one native notification event"
        );
        assert.true(
          notification.read,
          "the original notification becomes read"
        );
        assert
          .dom(".isbf-notification-entry")
          .doesNotHaveClass("is-unread", "the row reflects the read state");
        assert.strictEqual(
          this.currentUser.grouped_unread_notifications[type],
          0,
          "the native unread count is consumed"
        );

        await click(link);
        assert.strictEqual(
          this.currentUser.grouped_unread_notifications[type],
          0,
          "opening the same notification again does not consume another count"
        );
      });
    }
  }
);

module(
  "ISBF | Integration | Component | ISBFNotificationBell",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.isbf_notifications_enabled = true;
      this.currentUser.setProperties({
        id: 42,
        all_unread_notifications_count: 0,
        grouped_unread_notifications: { 1: 1, 2: 2 },
      });
      this.owner.register("service:isbf-notifications", NotificationState);
    });

    test("counts unread notices even after they were seen, caps the badge and hides zero", async function (assert) {
      await render(<template><ISBFNotificationBell /></template>);
      assert
        .dom(".isbf-notification-bell__badge")
        .hasText("3", "seen notices are still counted as unread");

      for (const count of [1, 99, 100]) {
        this.currentUser.set("grouped_unread_notifications", { 1: count });
        await settled();
        assert
          .dom(".isbf-notification-bell__badge")
          .hasText(count > 99 ? "99+" : String(count), "the count is bounded");
      }
      this.currentUser.set("grouped_unread_notifications", {});
      await settled();
      assert
        .dom(".isbf-notification-bell__badge")
        .doesNotExist("zero leaves no empty badge");
    });

    test("uses the account's dot preference and updates through the private notification channel", async function (assert) {
      this.currentUser.set("isbf_notification_badge_style", "dot");
      await render(<template><ISBFNotificationBell /></template>);
      assert
        .dom(".isbf-notification-bell__badge")
        .hasClass("--dot", "the stored preference applies on first render");
      assert
        .dom(".isbf-notification-bell__badge")
        .hasText("", "dot mode contains no visible number");

      await publishToMessageBus("/notification/42", {
        grouped_unread_notifications: {},
        recent: [],
      });
      assert
        .dom(".isbf-notification-bell__badge")
        .doesNotExist("reading in another tab removes the dot");

      await publishToMessageBus("/notification/42", {
        grouped_unread_notifications: { 6: 1 },
        recent: [],
      });
      assert
        .dom(".isbf-notification-bell__badge")
        .exists("a new notification restores the dot");
      assert.strictEqual(
        this.owner.lookup("service:isbf-notifications").linkLabel,
        i18n(themePrefix("isbf_v2.notifications_badge_count"), { count: 1 }),
        "the navigation has a translated unread label in dot mode"
      );
    });
  }
);

module("ISBF | Integration | Component | ISBFNotifications", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.isbf_notifications_enabled = true;
    this.currentUser.setProperties({
      id: 42,
      grouped_unread_notifications: {
        [this.site.notification_types.replied]: 1,
      },
      unread_high_priority_notifications: 0,
      isbf_notification_filter: null,
    });
    this.owner.register("service:isbf-notifications", NotificationState);
    this.requests = [];
    this.savedFilters = [];
    this.markReadRequests = 0;
    this.unread = true;
    const notification = {
      id: 93001,
      notification_type: this.site.notification_types.replied,
      read: false,
      created_at: "2026-10-18T01:00:00Z",
      topic_id: 930,
      post_number: 2,
      data: { display_username: "student", topic_title: "Campus discussion" },
    };
    this.entry = {
      key: "notification-93001",
      action: "replied",
      created_at: notification.created_at,
      actor: {
        id: 43,
        username: "student",
        name: "Student",
        avatar_template: "/images/avatar.png",
      },
      notification,
    };
    pretender.get("/isbf/notifications/groups.json", (request) => {
      this.requests.push(request.queryParams);
      return response({
        groups:
          request.queryParams.filter === "unread" && !this.unread
            ? []
            : [
                {
                  key: "topic-930",
                  kind: "topic",
                  topic: {
                    id: 930,
                    title: "Campus discussion",
                    url: "/t/campus/930",
                  },
                  unread: this.unread,
                  actions: [
                    {
                      key: "replied",
                      count: 1,
                      unread: this.unread,
                      latest: {
                        ...this.entry,
                        notification: { ...notification, read: !this.unread },
                      },
                      detail_url: `/isbf/notifications/groups/930/actions/replied.json?filter=${request.queryParams.filter}&tab=${request.queryParams.tab}`,
                    },
                  ],
                },
              ],
        next_cursor: null,
      });
    });
    pretender.get(
      "/isbf/notifications/groups/930/actions/replied.json",
      (request) => {
        this.requests.push(request.queryParams);
        return response({ entries: [this.entry], next_cursor: null });
      }
    );
    pretender.put("/notifications/mark-read", () => {
      this.markReadRequests++;
      this.unread = false;
      return response({ success: true });
    });
    pretender.put("/u/eviltrout.json", (request) => {
      this.savedFilters.push(
        parsePostData(request.requestBody).custom_fields
          .isbf_notification_filter
      );
      return response({ success: true });
    });
  });

  test("starts with all notifications, filters both tabs and expands without marking read", async function (assert) {
    await render(<template><ISBFNotifications /></template>);
    assert.strictEqual(
      this.requests[0].filter,
      "all",
      "the default includes history"
    );
    assert
      .dom(".isbf-notifications__topic .isbf-notification-unread")
      .exists({ count: 1 }, "only the action indicates unread content");
    assert
      .dom(".isbf-notifications__topic h2 .isbf-notification-unread")
      .doesNotExist("topic headings have no unread dot");
    assert
      .dom("button.isbf-notifications__menu")
      .hasAttribute("aria-expanded", "false", "the menu starts closed");
    assert
      .dom(".isbf-notifications__filter")
      .doesNotExist("the filter is inside the closed menu");

    await click("button.isbf-notifications__menu");
    assert
      .dom(".isbf-notifications__filter")
      .isVisible("opening the menu reveals the filter");
    await click(".isbf-notifications__filter [role='switch']");
    assert.strictEqual(
      this.requests.at(-1).filter,
      "unread",
      "the filter reaches the API"
    );
    assert.deepEqual(
      this.savedFilters,
      ["unread"],
      "the selection is saved to the account"
    );
    await click("button.isbf-notifications__menu");
    assert
      .dom(".isbf-notifications__filter")
      .doesNotExist("closing the menu hides the filter again");
    await click(".isbf-notifications__tabs button:last-child");
    assert.strictEqual(
      this.requests.at(-1).tab,
      "mentions",
      "the mentions tab remains available"
    );
    assert.strictEqual(
      this.requests.at(-1).filter,
      "unread",
      "the filter applies to either tab"
    );
    await click(".isbf-notification-action__toggle");
    assert.strictEqual(
      this.requests.at(-1).filter,
      "unread",
      "lazy details retain the filter"
    );
    assert.strictEqual(
      this.markReadRequests,
      0,
      "browsing and expansion have no marking side effect"
    );
  });

  test("restores the saved filter before loading and remembers turning it off", async function (assert) {
    this.currentUser.set("isbf_notification_filter", "unread");
    await render(<template><ISBFNotifications /></template>);
    assert.strictEqual(
      this.requests[0].filter,
      "unread",
      "the first request uses the account preference"
    );

    await clearRender();
    this.requests = [];
    await render(<template><ISBFNotifications /></template>);
    assert.strictEqual(
      this.requests[0].filter,
      "unread",
      "returning restores the same preference"
    );
    await click("button.isbf-notifications__menu");
    assert
      .dom(".isbf-notifications__filter [role='switch']")
      .hasAttribute(
        "aria-checked",
        "true",
        "the switch restores its saved state"
      );
    await click(".isbf-notifications__filter [role='switch']");
    assert.deepEqual(
      this.savedFilters,
      ["all"],
      "turning the filter off also saves the selection"
    );

    await clearRender();
    this.requests = [];
    await render(<template><ISBFNotifications /></template>);
    assert.strictEqual(
      this.requests[0].filter,
      "all",
      "the next visit includes history again"
    );
  });

  test("keeps the previous filter when saving fails and applies a successful retry", async function (assert) {
    let fail = true;
    let saved;
    pretender.put("/u/eviltrout.json", (request) => {
      saved = parsePostData(request.requestBody).custom_fields;
      return fail
        ? response(500, { errors: ["Failed"] })
        : response({ success: true });
    });
    this.currentUser.set("isbf_notification_badge_style", "dot");
    await render(<template><ISBFNotifications /></template>);
    await click("button.isbf-notifications__menu");
    await click(".isbf-notifications__filter [role='switch']");
    assert
      .dom(".isbf-notifications__filter-error")
      .exists("the failed save offers a retry");
    assert
      .dom(".isbf-notifications__filter [role='switch']")
      .hasAttribute("aria-checked", "false", "the previous selection remains");
    assert.strictEqual(
      this.requests.length,
      1,
      "failure preserves the loaded list"
    );

    fail = false;
    await click(".isbf-notifications__filter-error button");
    assert.deepEqual(
      saved,
      { isbf_notification_filter: "unread" },
      "retry saves only the selected filter"
    );
    assert.strictEqual(
      this.currentUser.isbf_notification_badge_style,
      "dot",
      "the badge preference stays intact"
    );
    assert
      .dom(".isbf-notifications__filter-error")
      .doesNotExist("a successful retry clears the error");
    assert
      .dom("button.isbf-notifications__menu")
      .isFocused("retry keeps focus in the menu when its button disappears");
    assert.strictEqual(
      this.requests.at(-1).filter,
      "unread",
      "success reloads the selected list"
    );
    assert.strictEqual(
      this.markReadRequests,
      0,
      "saving never marks notices read"
    );
  });

  test("saves a personal badge preference and lets a failed save be retried", async function (assert) {
    let fail = true;
    let saved;
    pretender.put("/u/eviltrout.json", (request) => {
      saved = parsePostData(request.requestBody).custom_fields
        .isbf_notification_badge_style;
      return fail
        ? response(500, { errors: ["Failed"] })
        : response({ success: true });
    });
    await render(
      <template><ISBFNotifications /><ISBFNotificationBell /></template>
    );
    await click("button.isbf-notifications__menu");
    await click(".isbf-notifications__badge-options button:last-child");
    assert
      .dom(".isbf-notifications__preference-error")
      .exists("a failed save offers an inline retry");
    assert
      .dom(".isbf-notification-bell__badge")
      .doesNotHaveClass("--dot", "failure preserves the previous appearance");

    fail = false;
    await click(".isbf-notifications__preference-error button");
    assert.strictEqual(
      saved,
      "dot",
      "the selected style is saved to the existing user endpoint"
    );
    assert
      .dom(".isbf-notification-bell__badge")
      .hasClass("--dot", "all entrances use the saved style");
    assert
      .dom(".isbf-notifications__preference-error")
      .doesNotExist("a successful retry clears the error");
  });

  test("refreshes the unread list when another tab marks its notifications read", async function (assert) {
    await render(
      <template><ISBFNotifications /><ISBFNotificationBell /></template>
    );
    await click("button.isbf-notifications__menu");
    await click(".isbf-notifications__filter [role='switch']");
    this.unread = false;
    await publishToMessageBus("/notification/42", {
      grouped_unread_notifications: {},
      recent: [[93001, true]],
    });

    assert
      .dom(".isbf-notifications__topic")
      .doesNotExist("read groups leave the unread list");
    assert
      .dom(".isbf-notifications__status")
      .hasText(
        i18n(themePrefix("isbf_v2.notifications_unread_empty")),
        "an empty unread list has a distinct message"
      );
    assert
      .dom(".isbf-notification-bell__badge")
      .doesNotExist("the badge updates with the same event");
  });

  test("keeps unread state after a failed bulk action and clears it on a successful retry", async function (assert) {
    pretender.put("/notifications/mark-read", () =>
      response(500, { errors: ["Failed"] })
    );
    await render(
      <template><ISBFNotifications /><ISBFNotificationBell /></template>
    );
    await triggerEvent(".isbf-notifications__mark-read", "pointerdown", {
      button: 0,
      isPrimary: true,
      pointerId: 1,
      pointerType: "touch",
    });
    await new Promise((resolve) => setTimeout(resolve, 330));
    await triggerEvent(".isbf-notifications__mark-read", "pointerup", {
      pointerId: 1,
    });
    assert
      .dom(".isbf-notification-bell__badge")
      .hasText("1", "failure keeps the count");
    assert
      .dom(".isbf-notifications__status[role='alert']")
      .exists("failure can be retried");

    pretender.put("/notifications/mark-read", () => {
      this.unread = false;
      return response({ success: true });
    });
    await click(".isbf-notifications__status[role='alert'] button");
    assert
      .dom(".isbf-notification-bell__badge")
      .doesNotExist("a successful bulk action clears the badge");
    assert
      .dom(".isbf-notification-unread")
      .doesNotExist("the refreshed history has no unread dots");
  });
});
