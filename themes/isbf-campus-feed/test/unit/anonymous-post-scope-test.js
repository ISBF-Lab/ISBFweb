import { module, test } from "qunit";
import { canPublishAnonymously } from "../../discourse/lib/anonymous-post-scope";

module("ISBF Campus Feed | Unit | Lib | anonymous-post-scope", function () {
  const user = { can_post_anonymously: true };
  const siteSettings = { academy_official_category: 0 };

  test("hides anonymous publishing for unlisted topic replies", function (assert) {
    for (const visible of [false, "false"]) {
      assert.false(
        canPublishAnonymously(
          { action: "reply", topic: { visible } },
          user,
          siteSettings
        ),
        `an unlisted topic with visibility ${JSON.stringify(visible)} is excluded`
      );
    }
  });

  test("hides anonymous publishing when creating an unlisted topic", function (assert) {
    assert.false(
      canPublishAnonymously(
        { action: "createTopic", visible: false },
        user,
        siteSettings
      ),
      "an explicitly unlisted draft is excluded"
    );
  });

  test("allows a public draft without an explicit visibility field", function (assert) {
    assert.true(
      canPublishAnonymously({ action: "createTopic" }, user, siteSettings),
      "ordinary public drafts remain eligible"
    );
  });
});
