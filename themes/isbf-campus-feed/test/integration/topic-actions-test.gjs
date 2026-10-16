import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { ISBFTopicReply } from "../../discourse/components/isbf-topic-actions";

module("ISBF | Integration | Component | ISBFTopicReply", function (hooks) {
  setupRenderingTest(hooks);

  test("shows the reply count without displaying the accessibility instruction", async function (assert) {
    const store = this.owner.lookup("service:store");
    const topic = store.createRecord("topic", {
      id: 71101,
      archetype: "regular",
      is_nested_view: true,
    });
    this.post = store.createRecord("post", {
      id: 71102,
      post_number: 2,
      reply_count: 7,
      topic,
      username: "parent",
    });
    this.actions = { replyToPost() {} };
    this.state = { currentUser: this.currentUser, canCreatePost: true };

    await render(
      <template>
        <ISBFTopicReply
          @buttonActions={{this.actions}}
          @post={{this.post}}
          @state={{this.state}}
        />
      </template>
    );

    assert
      .dom(".isbf-topic-card__reply")
      .hasText("7", "matches the feed's compact reply count");
    assert
      .dom(".isbf-topic-card__reply")
      .hasAttribute(
        "aria-label",
        /parent/,
        "keeps the reply target accessible"
      );
  });
});
