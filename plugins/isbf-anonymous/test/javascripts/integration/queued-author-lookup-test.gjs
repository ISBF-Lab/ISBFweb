import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import ReviewableQueuedPost from "discourse/components/reviewable/queued-post";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";

const reviewable = {
  id: 90,
  type: "ReviewableQueuedPost",
  isbf_per_post_anonymous: true,
  cooked: "<p>Anonymous content awaiting approval.</p>",
  payload: { tags: [] },
  target_created_by: { id: 77, username: "anon_pool_0001" },
};

module("Integration | Component | Reviewable | QueuedPost", function (hooks) {
  setupRenderingTest(hooks);

  test("looks up a queued anonymous author only after clicking", async function (assert) {
    this.currentUser.set("admin", true);
    let requests = 0;
    pretender.get("/isbf-anonymous/api/queued-posts/90/author.json", () => {
      requests++;
      return response({
        author: {
          id: 1,
          username: "eviltrout",
          avatar_template: "/letter_avatar_proxy/v4/letter/e/aeaffb/{size}.png",
        },
      });
    });

    await render(
      <template>
        <ReviewableQueuedPost @reviewable={{reviewable}} /><ModalContainer />
      </template>
    );
    assert
      .dom(".isbf-anonymous-author-lookup")
      .hasText(
        i18n("isbf_anonymous.author_lookup.button"),
        "the queued item offers the same lookup"
      );
    assert.strictEqual(
      requests,
      0,
      "rendering the review item does not fetch its owner"
    );

    await click(".isbf-anonymous-author-lookup");

    assert.strictEqual(
      requests,
      1,
      "lookup uses the queued-post endpoint and reviewable ID"
    );
    assert
      .dom(".isbf-anonymous-author__username")
      .hasText("eviltrout", "the shared dialog displays the queued author");
    await click(".isbf-anonymous-author .modal-close");
    assert
      .dom(".isbf-anonymous-author")
      .doesNotExist("closing clears the queued author's dialog");
  });

  test("moderators have no queued lookup entry", async function (assert) {
    this.currentUser.setProperties({ admin: false, moderator: true });
    await render(
      <template><ReviewableQueuedPost @reviewable={{reviewable}} /></template>
    );
    assert
      .dom(".isbf-anonymous-author-lookup")
      .doesNotExist("moderator access is insufficient");
  });

  test("members have no queued lookup entry", async function (assert) {
    await render(
      <template><ReviewableQueuedPost @reviewable={{reviewable}} /></template>
    );
    assert
      .dom(".isbf-anonymous-author-lookup")
      .doesNotExist("members cannot look up the real author");
  });

  test("ordinary queued content has no lookup entry", async function (assert) {
    this.currentUser.set("admin", true);
    const ordinaryReviewable = {
      ...reviewable,
      isbf_per_post_anonymous: false,
    };

    await render(
      <template>
        <ReviewableQueuedPost @reviewable={{ordinaryReviewable}} />
      </template>
    );

    assert
      .dom(".isbf-anonymous-author-lookup")
      .doesNotExist("ordinary content does not offer anonymous-author lookup");
  });
});

module(
  "Integration | Guest | Component | Reviewable | QueuedPost",
  function (hooks) {
    setupRenderingTest(hooks, { anonymous: true });

    test("guests have no queued lookup entry", async function (assert) {
      await render(
        <template><ReviewableQueuedPost @reviewable={{reviewable}} /></template>
      );

      assert
        .dom(".isbf-anonymous-author-lookup")
        .doesNotExist("guests cannot request the real author");
    });
  }
);
