import { waitUntil } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import {
  invalidateCookedPost,
  loadCookedPost,
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
});
