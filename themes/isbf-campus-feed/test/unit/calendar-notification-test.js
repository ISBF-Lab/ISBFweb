import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import { getRenderDirector } from "discourse/lib/notification-types-manager";

module("ISBF | Unit | Lib | calendar-notification", function (hooks) {
  setupTest(hooks);

  test("calendar changes link to the private entry", function (assert) {
    const director = getRenderDirector(
      "custom",
      {
        data: {
          message: "isbf_calendar.changed",
          entry_id: 99,
          topic_title: "Briefing",
        },
      },
      null,
      {},
      this.owner.lookup("service:site")
    );
    assert.strictEqual(
      director.linkHref,
      "/isbf/calendar?entry_id=99",
      "the notification opens the corresponding calendar record"
    );
    assert.strictEqual(
      director.icon,
      "calendar-days",
      "calendar changes have a calendar icon"
    );
    assert.strictEqual(director.label, null, "no unrelated actor is shown");
  });

  test("other custom notifications retain core rendering", function (assert) {
    const director = getRenderDirector(
      "custom",
      {
        topic_id: 280,
        post_number: 1,
        slug: "briefing",
        data: { message: "another_plugin", username: "sam" },
      },
      null,
      {},
      this.owner.lookup("service:site")
    );
    assert.strictEqual(
      director.linkHref,
      "/t/briefing/280",
      "existing custom topic links remain available"
    );
    assert.strictEqual(
      director.icon,
      "notification.another_plugin",
      "existing custom icons remain available"
    );
  });
});
