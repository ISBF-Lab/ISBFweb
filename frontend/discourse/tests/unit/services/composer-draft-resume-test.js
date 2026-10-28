import Evented from "@ember/object/evented";
import Service from "@ember/service";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";
import { USER_OPTION_COMPOSITION_MODES } from "discourse/lib/constants";
import Composer from "discourse/models/composer";
import Draft from "discourse/models/draft";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

class DraftResumeRouter extends Service.extend(Evented) {
  currentRouteName = "userActivity.drafts";
  currentURL = "/u/eviltrout/activity/drafts";
  destinations = [];

  async transitionTo(url) {
    this.trigger("routeWillChange");
    this.destinations.push(url);
    this.currentURL = url;
    this.currentRouteName = "topic.fromParamsNear";
  }
}

module("Unit | Service | composer draft resume", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.owner.unregister("service:router");
    this.owner.register("service:router", DraftResumeRouter);
    const user = logIn(this.owner);
    user.set(
      "user_option.composition_mode",
      USER_OPTION_COMPOSITION_MODES.markdown
    );
    this.store = this.owner.lookup("service:store");
    this.composer = this.owner.lookup("service:composer");
    this.router = this.owner.lookup("service:router");
    this.topic = this.store.createRecord("topic", {
      id: 280,
      slug: "published-topic",
      title: "Published topic",
      category_id: 1,
      tags: [],
      draft_key: "topic_280",
      details: { can_edit: true, can_create_post: true },
    });
    Object.defineProperty(this.composer, "topicController", {
      value: { model: this.topic },
    });
    this.item = this.store.createRecord("user-draft", {
      draft_key: "topic_280",
      topic_id: 280,
      slug: "published-topic",
      sequence: 1,
      data: { reply: "Stale list excerpt", action: Composer.REPLY },
    });
    this.postData = {
      id: 8098,
      topic_id: 280,
      topic_slug: "published-topic",
      post_number: 3,
      raw: "Published body",
      username: "eviltrout",
      can_edit: true,
      reply_to_post_number: 2,
    };
    pretender.get("/posts/8098", () => response(this.postData));
    this.savedDraft = {
      reply: "Latest saved draft body",
      action: Composer.REPLY,
      categoryId: 1,
      postId: 8098,
      whisper: false,
      reply_to_post_number: null,
      reply_to_user: null,
    };
    pretender.get("/drafts/topic_280.json", () =>
      response({ draft: JSON.stringify(this.savedDraft), draft_sequence: 7 })
    );
  });

  hooks.afterEach(function () {
    this.composer.close();
    sinon.restore();
  });

  for (const postNumber of [1, 3]) {
    test(`restores an edit to published post ${postNumber} using its real position`, async function (assert) {
      this.postData.post_number = postNumber;
      Object.assign(this.savedDraft, {
        action: Composer.EDIT,
        title: "Unsaved title change",
        original_text: "Original body at the time of editing",
        original_title: "Original title at the time of editing",
        original_tags: ["original-tag"],
        tags: ["edited-tag"],
      });

      await this.composer.resumeDraft(this.item);

      const model = this.composer.model;
      assert.deepEqual(this.router.destinations, [
        `/t/published-topic/280${postNumber === 1 ? "" : "/3"}`,
      ]);
      assert.true(model.viewOpen);
      assert.strictEqual(model.action, Composer.EDIT);
      assert.strictEqual(model.post.id, 8098);
      assert.strictEqual(model.topic.id, 280);
      assert.strictEqual(model.reply, this.savedDraft.reply);
      assert.strictEqual(model.title, this.savedDraft.title);
      assert.deepEqual(model.tags, this.savedDraft.tags);
      assert.strictEqual(model.originalText, this.savedDraft.original_text);
      assert.strictEqual(model.originalTitle, this.savedDraft.original_title);
      assert.deepEqual(model.originalTags, this.savedDraft.original_tags);
      assert.strictEqual(model.reply_to_post_number, null);
      assert.strictEqual(model.reply_to_user, null);
      assert.strictEqual(model.draftSequence, 7);
      assert.false(this.composer.isResumingDraft);
    });
  }

  test("restores an unsent reply with its target and latest saved body", async function (assert) {
    await this.composer.resumeDraft(this.item);

    const model = this.composer.model;
    assert.deepEqual(this.router.destinations, ["/t/published-topic/280/3"]);
    assert.strictEqual(model.action, Composer.REPLY);
    assert.strictEqual(model.post.post_number, 3);
    assert.strictEqual(model.post.topic.id, 280);
    assert.strictEqual(model.reply, this.savedDraft.reply);
    assert.false(model.whisper);
    assert.strictEqual(model.draftSequence, 7);
  });

  test("opens a topic-level reply even when the loaded page has no draft", async function (assert) {
    delete this.savedDraft.postId;
    this.topic.set("draft", null);
    const transitionTo = this.router.transitionTo.bind(this.router);
    sinon.stub(this.router, "transitionTo").callsFake((url) => {
      assert.strictEqual(this.composer.resumingDraftTopicId, 280);
      return transitionTo(url);
    });

    await this.composer.resumeDraft(this.item);

    assert.deepEqual(this.router.destinations, ["/t/published-topic/280"]);
    assert.strictEqual(this.composer.model.action, Composer.REPLY);
    assert.strictEqual(this.composer.model.topic.id, 280);
    assert.strictEqual(this.composer.model.reply, this.savedDraft.reply);
    assert.strictEqual(this.composer.model.post, null);
    assert.strictEqual(this.composer.resumingDraftTopicId, null);
  });

  test("restores a new topic without leaving the drafts page", async function (assert) {
    pretender.get("/drafts/new_topic.json", () =>
      response({
        draft: JSON.stringify({
          action: Composer.CREATE_TOPIC,
          title: "Unpublished topic title",
          reply: "Unpublished body",
          categoryId: 1,
        }),
        draft_sequence: 8,
      })
    );

    await this.composer.resumeDraft({ draft_key: "new_topic" });

    assert.deepEqual(this.router.destinations, []);
    assert.strictEqual(this.composer.model.action, Composer.CREATE_TOPIC);
    assert.strictEqual(this.composer.model.title, "Unpublished topic title");
    assert.strictEqual(this.composer.model.reply, "Unpublished body");
    assert.strictEqual(this.composer.model.draftSequence, 8);
  });

  test("restores a new personal message with its recipient", async function (assert) {
    pretender.get("/drafts/new_private_message.json", () =>
      response({
        draft: JSON.stringify({
          action: Composer.PRIVATE_MESSAGE,
          title: "Unsent message",
          reply: "Private draft body",
          recipients: "alice",
        }),
        draft_sequence: 2,
      })
    );

    await this.composer.resumeDraft({ draft_key: "new_private_message" });

    assert.deepEqual(this.router.destinations, []);
    assert.strictEqual(this.composer.model.action, Composer.PRIVATE_MESSAGE);
    assert.strictEqual(this.composer.model.targetRecipients, "alice");
    assert.strictEqual(this.composer.model.reply, "Private draft body");
  });

  test("keeps in-memory edits when reopening the same draft", async function (assert) {
    await this.composer.open({
      action: Composer.REPLY,
      draftKey: this.item.draft_key,
      draftSequence: 9,
      topic: this.topic,
      reply: "Newer in-memory text",
    });
    const model = this.composer.model;
    model.set("composeState", Composer.DRAFT);

    await this.composer.resumeDraft(this.item);

    assert.strictEqual(this.composer.model, model);
    assert.true(model.viewOpen);
    assert.strictEqual(model.reply, "Newer in-memory text");
    assert.strictEqual(model.draftSequence, 9);
  });

  test("keeps the current draft when switching is cancelled", async function (assert) {
    await this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: "new_topic",
      draftSequence: 0,
      reply: "Keep this unsaved text",
    });
    const model = this.composer.model;
    sinon
      .stub(this.composer.modal, "show")
      .callsFake((_component, options) => options.model.onCancelDiscard());

    await this.composer.resumeDraft(this.item);

    assert.strictEqual(this.composer.model, model);
    assert.strictEqual(model.reply, "Keep this unsaved text");
    assert.deepEqual(this.router.destinations, []);
    assert.false(this.composer.isResumingDraft);
  });

  test("ignores duplicate clicks while the draft is loading", async function (assert) {
    let resolveDraft;
    const request = sinon.stub(Draft, "get").returns(
      new Promise((resolve) => {
        resolveDraft = resolve;
      })
    );
    const pending = this.composer.resumeDraft(this.item);

    await this.composer.resumeDraft(this.item);
    resolveDraft({
      draft: JSON.stringify(this.savedDraft),
      draft_sequence: 7,
    });
    await pending;

    assert.strictEqual(request.callCount, 1);
    assert.strictEqual(this.router.destinations.length, 1);
    assert.strictEqual(this.composer.model.reply, this.savedDraft.reply);
  });

  test("stops restoring after the user leaves while the request is pending", async function (assert) {
    let resolveDraft;
    sinon.stub(Draft, "get").returns(
      new Promise((resolve) => {
        resolveDraft = resolve;
      })
    );
    const pending = this.composer.resumeDraft(this.item);
    this.router.trigger("routeWillChange");
    resolveDraft({
      draft: JSON.stringify(this.savedDraft),
      draft_sequence: 7,
    });
    await pending;

    assert.strictEqual(this.composer.model, undefined);
    assert.deepEqual(this.router.destinations, []);
    assert.false(this.composer.isResumingDraft);
    assert.false(this.router.has("routeWillChange"));
  });

  test("refreshes a deleted draft without restoring stale list data", async function (assert) {
    pretender.get("/drafts/topic_280.json", () =>
      response({ draft: null, draft_sequence: 8 })
    );
    const alert = sinon.stub(this.composer.dialog, "alert").resolves();
    let removedKey;
    this.composer.appEvents.on("draft:destroyed", (key) => {
      removedKey = key;
    });

    await this.composer.resumeDraft(this.item);

    assert.strictEqual(removedKey, this.item.draft_key);
    assert.strictEqual(alert.firstCall.args[0], i18n("drafts.not_found"));
    assert.strictEqual(this.composer.model, undefined);
    assert.deepEqual(this.router.destinations, []);
  });

  test("preserves the current composer when the target is unavailable", async function (assert) {
    await this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: "new_topic",
      draftSequence: 0,
      reply: "Keep current work",
    });
    const model = this.composer.model;
    pretender.get("/posts/8098", () =>
      response(404, { errors: ["The post is unavailable"] })
    );
    const alert = sinon.stub(this.composer.dialog, "alert").resolves();

    await this.composer.resumeDraft(this.item);

    assert.strictEqual(this.composer.model, model);
    assert.strictEqual(model.reply, "Keep current work");
    assert.true(alert.calledOnce);
    assert.deepEqual(this.router.destinations, []);
    assert.false(this.composer.isResumingDraft);
  });

  test("keeps an unreadable draft for recovery instead of deleting it", async function (assert) {
    pretender.get("/drafts/topic_280.json", () =>
      response({ draft: "{invalid JSON", draft_sequence: 7 })
    );
    let cleared = false;
    pretender.delete("/drafts/topic_280.json", () => {
      cleared = true;
      return response({ success: true });
    });
    sinon.stub(console, "error");
    const alert = sinon.stub(this.composer.dialog, "alert").resolves();

    await this.composer.resumeDraft(this.item);

    assert.false(cleared);
    assert.true(alert.calledOnce);
    assert.strictEqual(this.composer.model, undefined);
    assert.deepEqual(this.router.destinations, []);
    assert.false(this.composer.isResumingDraft);
  });
});
