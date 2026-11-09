import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";

module("Unit | Route | admin-badges.show", function (hooks) {
  setupTest(hooks);

  test("new badges have no automatic trigger when server trigger order changes", async function (assert) {
    pretender.get("/admin/badges.json", () =>
      response({
        admin_badges: {
          triggers: { post_revision: 2, user_change: 8, none: 0 },
        },
        badge_types: [{ id: 3, name: "Bronze" }],
        badge_groupings: [{ id: 5, name: "Other", position: 0 }],
        badges: [],
      })
    );

    const route = this.owner.lookup("route:admin-badges.show");
    const badge = await route.model({ badge_id: "new" });

    assert.strictEqual(
      badge.trigger,
      0,
      "starts as a manually grantable badge"
    );
    assert.true(badge.enabled, "the new badge is enabled");
  });
});
