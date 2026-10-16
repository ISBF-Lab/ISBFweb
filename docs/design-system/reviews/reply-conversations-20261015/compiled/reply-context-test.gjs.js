import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFReplyContext from "../../discourse/components/isbf-reply-context";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
module("ISBF | Integration | Component | ISBFReplyContext", function (hooks) {
  setupRenderingTest(hooks);
  hooks.beforeEach(function () {
    const store = this.owner.lookup("service:store");
    this.topic = store.createRecord("topic", {
      id: 71101,
      slug: "reply-context"
    });
    this.post = store.createRecord("post", {
      id: 71103,
      post_number: 3,
      topic: this.topic,
      reply_to_post_number: 2,
      reply_to_user: {
        username: "parent",
        name: "Parent name"
      }
    });
  });
  test("loads original content only on demand and links to its exact floor", async function (assert) {
    let requests = 0;
    pretender.get("/posts/by_number/71101/2.json", () => {
      requests++;
      return response({
        id: 71102,
        topic_id: 71101,
        post_number: 2,
        cooked: "<p>Original reply</p>"
      });
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFReplyContext @post={{this.post}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@post\"],[[32,1,[\"post\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFReplyContext,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.strictEqual(requests, 0);
    assert.dom(".isbf-reply-context__toggle").includesText("#2");
    await click(".isbf-reply-context__toggle");
    assert.dom(".isbf-reply-context__preview .cooked").hasText("Original reply");
    assert.dom(".isbf-reply-context__link").hasAttribute("href", "/t/reply-context/71101/2");
    await click(".isbf-reply-context__toggle");
    assert.dom(".isbf-reply-context__preview").doesNotExist();
    await click(".isbf-reply-context__toggle");
    assert.strictEqual(requests, 1, "reopening uses the loaded original");
  });
  test("unavailable originals can be retried without exposing hidden content", async function (assert) {
    const hidden = "<p>Hidden original</p>";
    let available = false;
    pretender.get("/posts/by_number/71101/2.json", () => response({
      id: 71102,
      topic_id: 71101,
      post_number: 2,
      cooked: hidden,
      cooked_hidden: !available
    }));
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFReplyContext @post={{this.post}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@post\"],[[32,1,[\"post\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFReplyContext,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    await click(".isbf-reply-context__toggle");
    assert.dom(".isbf-reply-context__preview .cooked").doesNotExist();
    available = true;
    await click(".isbf-reply-context__preview button");
    assert.dom(".isbf-reply-context__preview .cooked").hasText("Hidden original");
  });
});