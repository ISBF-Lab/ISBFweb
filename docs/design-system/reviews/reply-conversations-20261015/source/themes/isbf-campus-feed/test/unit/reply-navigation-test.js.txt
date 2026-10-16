import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";
import DiscourseURL from "discourse/lib/url";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ReplyNavigation from "../../discourse/lib/reply-navigation";

module("ISBF | Unit | Lib | reply-navigation", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.topic = {
      id: 77101,
      slug: "conversations",
      url: "/t/conversations/77101",
      reply_navigation: { root_count: 21, root_index: 1, reply_count: 121 },
      postStream: { posts: [] },
    };
    this.navigation = new ReplyNavigation(
      this.topic,
      this.owner.lookup("service:app-events")
    );
    this.route = sinon.stub(DiscourseURL, "routeTo");
  });

  hooks.afterEach(function () {
    this.navigation.destroy();
    sinon.restore();
  });

  test("group indexes resolve through the server before using canonical floor links", async function (assert) {
    pretender.get("/n/conversations/77101/navigation.json", (request) => {
      assert.strictEqual(request.queryParams.root_index, "21");
      return response({ root_index: 21, root_count: 21, root_post_number: 49 });
    });
    await this.navigation.jumpToIndex(21);
    assert.true(this.route.calledOnceWithExactly("/t/conversations/77101/49"));
  });

  test("a destroyed navigation cannot route after an outstanding resolution", async function (assert) {
    pretender.get("/n/conversations/77101/navigation.json", () =>
      response({ root_index: 21, root_post_number: 49 })
    );
    const pending = this.navigation.jumpToIndex(21);
    this.navigation.destroy();
    await pending;
    assert.false(this.route.called);
  });

  test("new reply totals update without changing group identity", function (assert) {
    this.topic.reply_navigation = { root_count: 22, reply_count: 124 };
    assert.strictEqual(this.navigation.total, 22);
    this.navigation.notify(21);
    assert.strictEqual(this.navigation.currentIndex, 21);
    this.navigation.jumpToPostNumber(103);
    assert.true(this.route.calledOnceWithExactly("/t/conversations/77101/103"));
  });
});
