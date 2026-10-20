import { waitUntil } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import {
  invalidateCookedPost,
  loadCookedPost,
  loadPostPolls,
} from "../../discourse/lib/feed-post-loader";

let nextId = 700000;

module("ISBF | Unit | Lib | feed-post-loader", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.firstId = nextId;
    nextId += 1000;
    this.requests = [];
    pretender.get("/posts/:id/cooked", (request) => {
      this.requests.push(request);
      return response({ cooked: `Post ${request.params.id}` });
    });
  });

  test("concurrent requests for the same numeric ID share a request and cache", async function (assert) {
    const [first, second] = await Promise.all([
      loadCookedPost(this.firstId),
      loadCookedPost(String(this.firstId)),
    ]);
    assert.strictEqual(first, second, "both callers receive the same content");
    await loadCookedPost(this.firstId);
    assert.strictEqual(
      this.requests.length,
      1,
      "concurrent and cached callers use one request"
    );
  });

  test("only four requests start before a queued request can proceed", async function (assert) {
    pretender.get(
      "/posts/:id/cooked",
      (request) => {
        this.requests.push(request);
        return response({ cooked: `Post ${request.params.id}` });
      },
      true
    );
    const pending = Array.from({ length: 5 }, (_, index) =>
      loadCookedPost(this.firstId + index)
    );
    await waitUntil(() => this.requests.length === 4);
    assert.strictEqual(this.requests.length, 4, "the fifth request waits");
    pretender.resolve(this.requests[0]);
    await pending[0];
    await waitUntil(() => this.requests.length === 5);
    this.requests.slice(1).forEach((request) => pretender.resolve(request));
    await Promise.all(pending);
    assert.strictEqual(
      this.requests.length,
      5,
      "the queue resumes after a request completes"
    );
  });

  test("a hidden post cannot be repopulated by a response already in flight", async function (assert) {
    pretender.get(
      "/posts/:id/cooked",
      (request) => {
        this.requests.push(request);
        return response({ cooked: "Previously visible content" });
      },
      true
    );
    const pending = loadCookedPost(this.firstId);
    await waitUntil(() => this.requests.length === 1);
    invalidateCookedPost(this.firstId);
    pretender.resolve(this.requests[0]);
    assert.strictEqual(await pending, "", "the stale response is discarded");
    assert.strictEqual(
      await loadCookedPost(this.firstId),
      "",
      "hidden content is not requested again"
    );
    assert.strictEqual(
      this.requests.length,
      1,
      "only the original request was issued"
    );
  });

  test("the least recently used content is evicted after fifty posts", async function (assert) {
    for (let index = 0; index < 50; index++) {
      await loadCookedPost(this.firstId + index);
    }
    await loadCookedPost(this.firstId);
    await loadCookedPost(this.firstId + 50);
    await loadCookedPost(this.firstId);
    assert.strictEqual(
      this.requests.length,
      51,
      "recently used content stays cached"
    );
    await loadCookedPost(this.firstId + 1);
    assert.strictEqual(
      this.requests.length,
      52,
      "the older entry is fetched again"
    );
  });

  test("a post number resolves once and shares the canonical post cache", async function (assert) {
    pretender.get("/posts/by_number/:topicId/:postNumber.json", (request) => {
      this.requests.push(request);
      return response({ id: this.firstId, cooked: "Historical topic body" });
    });
    const target = { topicId: this.firstId, postNumber: 1 };
    const [first, second] = await Promise.all([
      loadCookedPost(null, target),
      loadCookedPost(null, target),
    ]);
    assert.strictEqual(first, "Historical topic body", "the body is resolved");
    assert.strictEqual(
      second,
      first,
      "concurrent number lookups share a request"
    );
    assert.strictEqual(
      await loadCookedPost(this.firstId),
      first,
      "a caller with the resolved ID shares the same body"
    );
    assert.strictEqual(
      await loadCookedPost(null, target),
      first,
      "subsequent number lookups use the resolved post cache"
    );
    assert.strictEqual(
      this.requests.length,
      1,
      "only one HTTP request is needed"
    );
  });

  test("a hidden number lookup cannot restore an in-flight body", async function (assert) {
    pretender.get(
      "/posts/by_number/:topicId/:postNumber.json",
      (request) => {
        this.requests.push(request);
        return response({
          id: this.firstId,
          cooked: "Previously visible body",
        });
      },
      true
    );
    const target = { topicId: this.firstId, postNumber: 2 };
    const pending = loadCookedPost(null, target);
    await waitUntil(() => this.requests.length === 1);
    invalidateCookedPost(this.firstId);
    pretender.resolve(this.requests[0]);
    assert.strictEqual(
      await pending,
      "",
      "the stale number response is discarded"
    );
    assert.strictEqual(
      await loadCookedPost(null, target),
      "",
      "a resolved hidden alias does not expose its cached body"
    );
    assert.strictEqual(
      this.requests.length,
      1,
      "the hidden alias is not fetched again"
    );
  });

  test("an edit invalidates a pending number lookup before its ID is known", async function (assert) {
    pretender.get(
      "/posts/by_number/:topicId/:postNumber.json",
      (request) => {
        this.requests.push(request);
        return response({
          id: this.firstId,
          cooked: "Body from before the edit",
        });
      },
      true
    );
    const target = { topicId: this.firstId, postNumber: 3 };
    const pending = loadCookedPost(null, target);
    await waitUntil(() => this.requests.length === 1);
    invalidateCookedPost(this.firstId, false);
    pretender.resolve(this.requests[0]);
    assert.strictEqual(await pending, "", "the pre-edit body is not cached");
    assert.strictEqual(
      await loadCookedPost(null, target),
      `Post ${this.firstId}`,
      "the known ID is fetched again after the edit"
    );
    assert.strictEqual(
      this.requests.length,
      2,
      "the edited post has one new request"
    );
  });

  test("different replies in one topic keep separate bodies", async function (assert) {
    pretender.get("/posts/by_number/:topicId/:postNumber.json", (request) => {
      this.requests.push(request);
      const number = Number(request.params.postNumber);
      return response({ id: this.firstId + number, cooked: `Reply ${number}` });
    });
    assert.strictEqual(
      await loadCookedPost(null, { topicId: this.firstId, postNumber: 2 }),
      "Reply 2",
      "the first requested reply is used"
    );
    assert.strictEqual(
      await loadCookedPost(null, { topicId: this.firstId, postNumber: 3 }),
      "Reply 3",
      "a different reply does not reuse the first reply's text"
    );
  });

  test("poll state stays separate from cooked bodies and other users", async function (assert) {
    pretender.get("/posts/:id.json", (request) => {
      this.requests.push(request);
      return response({ id: this.firstId, polls: [{ name: "poll" }] });
    });
    const first = await loadPostPolls(this.firstId, 101);
    assert.deepEqual(
      first.polls,
      [{ name: "poll" }],
      "the original poll response remains available"
    );
    await loadPostPolls(this.firstId, 101);
    assert.strictEqual(
      this.requests.length,
      1,
      "the same user reuses poll state"
    );
    await loadPostPolls(this.firstId, 102);
    assert.strictEqual(
      this.requests.length,
      2,
      "another user gets separate poll state"
    );
    assert.strictEqual(
      await loadCookedPost(this.firstId),
      `Post ${this.firstId}`,
      "a body lookup cannot return a poll payload"
    );
  });
});
