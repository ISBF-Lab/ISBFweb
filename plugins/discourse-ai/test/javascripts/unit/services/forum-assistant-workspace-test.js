import { getOwner } from "@ember/owner";
import { settled, waitUntil } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import User from "discourse/models/user";
import pretender, { response } from "discourse/tests/helpers/create-pretender";

const BASE = "/discourse-ai/ai-bot/forum-assistant/conversations";
const READY = {
  enabled: true,
  configured: true,
  can_ask: true,
  remaining_today: 20,
  daily_limit: 20,
};

module("Unit | Service | forum-assistant-workspace", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    const owner = getOwner(this);
    owner.unregister("service:current-user");
    owner.register(
      "service:current-user",
      User.create({ id: 42, forum_assistant: READY }),
      { instantiate: false }
    );
    this.service = owner.lookup("service:forum-assistant-workspace");
    this.callbacks = new Map();
    const bus = owner.lookup("service:message-bus");
    bus.subscribe = (channel, callback) =>
      this.callbacks.set(channel, callback);
    bus.unsubscribe = (channel) => this.callbacks.delete(channel);
    this.routes = [];
    owner.lookup("service:router").replaceWith = (name, options) =>
      this.routes.push({ name, ...options });
    this.status = { ...READY };
    this.details = new Map(
      [1, 2].map((id) => [
        id,
        {
          conversation: { id, title: `Question ${id}`, read_only: false },
          messages: [
            {
              id: id * 10,
              post_number: 1,
              role: "user",
              raw: `Question ${id}`,
            },
          ],
          request: { id, status: "completed" },
          has_more: false,
        },
      ])
    );
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response(this.status)
    );
    pretender.get(`${BASE}.json`, () =>
      response({
        conversations: [...this.details.values()].map(
          (item) => item.conversation
        ),
        has_more: false,
      })
    );
    for (const id of [1, 2]) {
      pretender.get(`${BASE}/${id}.json`, () => response(this.details.get(id)));
    }
    pretender.get(`${BASE}/3.json`, () =>
      response(404, { errors: ["Unavailable"] })
    );
  });

  hooks.afterEach(function () {
    this.service.stop();
  });

  test("submits through the dedicated endpoint and stays in the assistant workspace", async function (assert) {
    let submissions = 0;
    pretender.post(`${BASE}.json`, (request) => {
      submissions++;
      assert.deepEqual(
        [...new URLSearchParams(request.requestBody).keys()],
        ["raw"]
      );
      return response({
        conversation_id: 1,
        message: this.details.get(1).messages[0],
        request: { status: "queued" },
      });
    });
    await this.service.start(null);
    this.service.setDraft("Find forum rules");
    assert.true(await this.service.send("Find forum rules"));
    assert.strictEqual(submissions, 1);
    assert.strictEqual(this.service.selectedId, 1);
    assert.deepEqual(this.routes, [
      {
        name: "discourse-ai-bot-conversations",
        queryParams: { conversation: 1 },
      },
    ]);
    assert.strictEqual(this.service.draft, "");
    await this.service.select(null);
    assert.strictEqual(
      this.service.draft,
      "",
      "the starting draft is cleared after acceptance"
    );
  });

  test("keeps drafts separate while switching conversations", async function (assert) {
    await this.service.start(1);
    this.service.setDraft("Follow-up for the first question");
    await this.service.select(2);
    assert.strictEqual(this.service.draft, "");
    this.service.setDraft("Follow-up for the second question");
    await this.service.select(1);
    assert.strictEqual(this.service.draft, "Follow-up for the first question");
    await this.service.select(2);
    assert.strictEqual(this.service.draft, "Follow-up for the second question");
  });

  test("keeps the draft after a failed send and does not automatically resubmit", async function (assert) {
    let submissions = 0;
    pretender.post(`${BASE}/1/messages.json`, () => {
      submissions++;
      return response(503, { errors: ["Please try later"] });
    });
    await this.service.start(1);
    this.service.setDraft("A question to retain");
    assert.false(await this.service.send(this.service.draft));
    assert.strictEqual(submissions, 1);
    assert.strictEqual(this.service.draft, "A question to retain");
    assert.true(this.service.error.includes("Please try later"));
  });

  test("streams safely and ignores a delayed chunk from a previous conversation", async function (assert) {
    this.details.get(1).request = {
      id: 1,
      status: "running",
      reply_post_id: 11,
    };
    await this.service.start(1);
    const oldCallback = this.callbacks.get("discourse-ai/ai-bot/topic/1");
    oldCallback({
      post_id: 11,
      post_number: 2,
      raw: "A forum answer <script>alert(1)</script>",
    });
    await waitUntil(() => this.service.messages.length === 2, {
      timeout: 5000,
    });
    assert.false(this.service.messages[1].cooked.includes("<script>"));
    await this.service.select(2);
    oldCallback({ post_id: 11, post_number: 2, raw: "An obsolete update" });
    await settled();
    assert.deepEqual(
      this.service.messages.map((message) => message.id),
      [20]
    );
  });

  test("loads fixed replies on completion events and clears the generating state", async function (assert) {
    this.details.get(1).request = {
      id: 1,
      status: "running",
      reply_post_id: null,
    };
    await this.service.start(1);
    assert.true(this.service.generating);
    this.details.get(1).request = {
      id: 1,
      status: "refused",
      reply_post_id: 11,
    };
    this.details.get(1).messages.push({
      id: 11,
      post_number: 2,
      role: "assistant",
      raw: "Forum questions only",
      cooked: "<p>Forum questions only</p>",
    });
    this.callbacks.get("/discourse-ai/forum-assistant/user/42")({
      conversation_id: 1,
    });
    await settled();
    assert.false(this.service.generating);
    assert.strictEqual(this.service.messages[1].id, 11);
  });

  test("fails closed for missing conversations and for exhausted or read-only state", async function (assert) {
    await this.service.start(1);
    this.details.get(2).conversation.read_only = true;
    await this.service.select(2);
    assert.true(this.service.disabled);
    assert.false(await this.service.send("Do not submit"));
    await this.service.select(3);
    assert.deepEqual(this.service.messages, []);
    assert.true(this.service.disabled);
    assert.strictEqual(typeof this.service.error, "string");
    await this.service.select(null);
    this.status.can_ask = false;
    await getOwner(this).lookup("service:forum-assistant").refresh();
    assert.true(this.service.disabled);
    assert.false(await this.service.send("Do not submit"));
  });

  test("stops only the selected request and cleans up every subscription on exit", async function (assert) {
    this.details.get(1).request = { id: 1, status: "queued" };
    pretender.post(
      "/discourse-ai/ai-bot/forum-assistant/cancel.json",
      (request) => {
        assert.strictEqual(
          new URLSearchParams(request.requestBody).get("conversation_id"),
          "1"
        );
        this.details.get(1).request.status = "cancelled";
        return response(204);
      }
    );
    await this.service.start(1);
    await this.service.cancel();
    assert.false(this.service.generating);
    this.service.stop();
    assert.strictEqual(this.callbacks.size, 0);
  });

  test("clears previously visible messages after access is revoked", async function (assert) {
    await this.service.start(1);
    assert.strictEqual(this.service.messages.length, 1);
    pretender.get(`${BASE}/1.json`, () =>
      response(404, { errors: ["Unavailable"] })
    );
    await this.service.refresh();
    assert.deepEqual(this.service.messages, []);
    assert.true(this.service.disabled);
    assert.false(this.callbacks.has("discourse-ai/ai-bot/topic/1"));
  });

  test("reconciles a completion event arriving during a history refresh", async function (assert) {
    this.details.get(1).request.status = "running";
    await this.service.start(1);
    pretender.get(`${BASE}/1.json`, () => response(this.details.get(1)), 20);
    const refresh = this.service.refresh();
    this.details.get(1).request.status = "refused";
    this.callbacks.get("/discourse-ai/forum-assistant/user/42")({
      conversation_id: 1,
    });
    await refresh;
    assert.strictEqual(this.service.request.status, "refused");
    assert.false(this.service.generating);
  });
});
