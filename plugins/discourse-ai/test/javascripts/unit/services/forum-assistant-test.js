import { getOwner } from "@ember/owner";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import User from "discourse/models/user";
import pretender, { response } from "discourse/tests/helpers/create-pretender";

const READY = {
  enabled: true,
  configured: true,
  restricted: true,
  can_ask: true,
  remaining_today: 20,
  daily_limit: 20,
  resets_at: "2026-11-18T00:00:00+08:00",
  agent: { id: -1, username: "forum_bot" },
};

module("Unit | Service | forum-assistant", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    const owner = getOwner(this);
    owner.unregister("service:current-user");
    owner.register(
      "service:current-user",
      User.create({ id: 42, admin: false, forum_assistant: { ...READY } }),
      { instantiate: false }
    );
    this.service = owner.lookup("service:forum-assistant");
  });

  test("refreshes server quota and fails closed after a status failure", async function (assert) {
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response({ ...READY, remaining_today: 0, can_ask: false })
    );
    await this.service.refresh();
    assert.strictEqual(this.service.status.remaining_today, 0);
    assert.false(this.service.status.can_ask);

    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response(503, { errors: ["Unavailable"] })
    );
    await this.service.refresh();
    assert.false(this.service.status.can_ask);
    assert.false(this.service.status.configured);
    assert.true(
      this.service.restricted,
      "a network failure never removes the member restriction"
    );
  });

  test("cancels the current account's request without accepting another account ID", async function (assert) {
    let cancelled = 0;
    pretender.post(
      "/discourse-ai/ai-bot/forum-assistant/cancel.json",
      (request) => {
        cancelled++;
        assert.strictEqual(
          new URLSearchParams(request.requestBody).get("user_id"),
          null
        );
        return response(204);
      }
    );
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response(READY)
    );
    await this.service.cancel();
    assert.strictEqual(cancelled, 1);
    assert.true(this.service.status.can_ask);
  });

  test("member restriction survives missing status while administrator selections remain separate", function (assert) {
    const owner = getOwner(this);
    const user = owner.lookup("service:current-user");
    const settings = owner.lookup("service:site-settings");
    user.setProperties({ admin: false, forum_assistant: null });
    settings.ai_forum_assistant_enabled = true;
    assert.true(this.service.restricted);

    user.setProperties({
      admin: true,
      forum_assistant: { ...READY, restricted: false },
    });
    assert.true(this.service.isSelected(-1));
    assert.false(this.service.isSelected(3));
  });

  test("accepts a short forum question and blocks file or exhausted-quota submissions", async function (assert) {
    const owner = getOwner(this);
    const submit = owner.lookup("service:ai-bot-docked-submit");
    const settings = owner.lookup("service:site-settings");
    settings.min_personal_message_post_length = 10;
    settings.ai_forum_assistant_max_question_chars = 4000;
    let sent = 0;
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response(READY)
    );
    pretender.post("/posts.json", (request) => {
      sent++;
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("raw"),
        "怎么发帖"
      );
      return response({ id: 700, topic_id: 42 });
    });
    const result = await submit.submitReply({
      topicId: 42,
      raw: "怎么发帖",
      uploads: [],
      inProgressUploadsCount: 0,
    });
    assert.strictEqual(result.id, 700);
    assert.strictEqual(
      await submit.submitReply({
        topicId: 42,
        raw: "怎么发帖",
        uploads: [{ original_filename: "test.pdf" }],
        inProgressUploadsCount: 0,
      }),
      null
    );
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response({ ...READY, remaining_today: 0, can_ask: false })
    );
    assert.strictEqual(
      await submit.submitReply({
        topicId: 42,
        raw: "怎么发帖",
        uploads: [],
        inProgressUploadsCount: 0,
      }),
      null
    );
    assert.strictEqual(sent, 1);
  });
});
