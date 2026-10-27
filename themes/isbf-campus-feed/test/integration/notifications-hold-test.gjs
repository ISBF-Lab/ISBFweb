import Service from "@ember/service";
import {
  click,
  find,
  render,
  settled,
  triggerEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DMenus from "discourse/float-kit/components/d-menus";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFNotifications from "../../discourse/components/isbf-notifications";

const button = ".isbf-notifications__mark-read";

class NotificationsStub extends Service {
  filter = "all";
  version = 0;
  numberStyle = true;
  dotStyle = false;

  retryBadgeStyle() {}

  retryFilter() {}

  saveBadgeStyle() {}

  saveFilter() {}
}

async function renderNotifications() {
  await render(<template><DMenus /><ISBFNotifications /></template>);
}

async function hold() {
  await triggerEvent(button, "pointerdown", {
    button: 0,
    isPrimary: true,
    pointerId: 1,
    pointerType: "touch",
  });
  await new Promise((resolve) => setTimeout(resolve, 330));
  await triggerEvent(button, "pointerup", { pointerId: 1 });
}

module("ISBF | Integration | Notifications hold", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser.setProperties({
      unread_high_priority_notifications: 0,
      unread_notifications: 3,
      all_unread_notifications_count: 3,
      grouped_unread_notifications: { liked: [1, 2, 3] },
    });
    this.owner.register("service:isbf-notifications", NotificationsStub);
    this.notifications = this.owner.lookup("service:isbf-notifications");
    this.requests = 0;
    this.loads = 0;
    pretender.get("/isbf/notifications/groups.json", () => {
      this.loads++;
      return response({ groups: [], next_cursor: null });
    });
    pretender.put("/notifications/mark-read", () => {
      this.requests++;
      return response({ success: true });
    });
    sinon.stub(this.owner.lookup("service:a11y"), "announce");
    this.modal = sinon.stub(this.owner.lookup("service:modal"), "show");
    this.modal.callsFake((_component, options) => {
      this.confirmation = options.model;
      return new Promise((resolve) => (this.closeConfirmation = resolve));
    });
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  test("the action is outside the menu and a click does not mark read", async function (assert) {
    await renderNotifications();
    assert
      .dom(".isbf-notifications__actions > .d-hold-button")
      .exists({ count: 1 });
    await click(button);
    assert.strictEqual(this.requests, 0);
    await click(
      find(".isbf-notifications__menu summary") ||
        find(".isbf-notifications__menu")
    );
    assert.dom(".isbf-notifications__menu-items .d-hold-button").doesNotExist();
    assert
      .dom(
        '.isbf-notifications__menu-items a[href="/my/preferences/notifications"]'
      )
      .exists();
    assert.dom(".isbf-notifications__filter").exists();
    assert.dom(".isbf-notifications__badge-options").exists();
  });

  test("a successful hold marks read once, updates counts and refreshes", async function (assert) {
    await renderNotifications();
    await hold();
    assert.strictEqual(this.requests, 1);
    assert.strictEqual(this.loads, 2);
    assert.strictEqual(this.currentUser.all_unread_notifications_count, 0);
    assert.deepEqual(this.currentUser.grouped_unread_notifications, {});
    assert.dom(button).hasAttribute("data-phase", "done");
    assert.false(this.modal.called);
  });

  test("high priority notifications retain confirmation and cancellation makes no request", async function (assert) {
    this.currentUser.set("unread_high_priority_notifications", 2);
    await renderNotifications();
    await hold();
    assert.true(this.modal.calledOnce);
    assert.strictEqual(this.requests, 0);
    assert.dom(button).hasAttribute("data-phase", "pending");
    this.closeConfirmation();
    await settled();
    assert.strictEqual(this.requests, 0);
    assert.strictEqual(this.currentUser.all_unread_notifications_count, 3);
    assert.dom(button).hasAttribute("data-phase", "idle");
  });

  test("confirmation submits once and completion follows the request result", async function (assert) {
    this.currentUser.set("unread_high_priority_notifications", 2);
    await renderNotifications();
    await hold();
    this.confirmation.dismissNotifications();
    this.closeConfirmation();
    await settled();
    assert.strictEqual(this.requests, 1);
    assert.strictEqual(this.currentUser.unread_high_priority_notifications, 0);
    assert.dom(button).hasAttribute("data-phase", "done");
  });

  test("request failure resets the button, preserves counts and offers a retry", async function (assert) {
    pretender.put("/notifications/mark-read", () => {
      this.requests++;
      return response(this.requests === 1 ? 500 : 200, {
        success: this.requests > 1,
      });
    });
    await renderNotifications();
    await hold();
    assert.strictEqual(this.currentUser.all_unread_notifications_count, 3);
    assert.dom(button).hasAttribute("data-phase", "idle");
    assert.dom('.isbf-notifications__status[role="alert"] button').exists();
    await click('.isbf-notifications__status[role="alert"] button');
    assert.strictEqual(this.requests, 2);
    assert.strictEqual(this.currentUser.all_unread_notifications_count, 0);
    assert.dom('.isbf-notifications__status[role="alert"]').doesNotExist();
  });

  test("a newer notification during the request keeps its unread count", async function (assert) {
    pretender.put("/notifications/mark-read", () => {
      this.notifications.version++;
      this.currentUser.setProperties({
        unread_notifications: 4,
        all_unread_notifications_count: 4,
      });
      return response({ success: true });
    });
    await renderNotifications();
    await hold();
    assert.strictEqual(this.currentUser.all_unread_notifications_count, 4);
    assert.strictEqual(this.currentUser.unread_notifications, 4);
    assert.dom(button).hasAttribute("data-phase", "done");
  });
});
