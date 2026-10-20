import { settled } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import { createViewTracker } from "../../discourse/lib/view-tracker";

module("ISBF | Unit | Lib | view-tracker", function (hooks) {
  setupTest(hooks);

  test("settling flushes batched impressions and cached counts avoid another request", async function (assert) {
    const requests = [];
    pretender.post("/isbf/views/post-impressions", (request) => {
      requests.push(parsePostData(request.requestBody));
      return response({ counts: { 970991: 4, 970992: 0 } });
    });
    const track = createViewTracker("/isbf/views/post-impressions", "post_ids");
    const first = track(970991, 19);
    const second = track(970992, 19);

    await settled();

    assert.deepEqual(
      requests,
      [{ "post_ids[]": ["970991", "970992"] }],
      "settling includes the delayed impression request"
    );
    assert.deepEqual(
      await Promise.all([first, second]),
      [4, 0],
      "each caller receives its count, including zero"
    );
    assert.strictEqual(await track(970991, 19), 4, "the count is cached");
    assert.strictEqual(requests.length, 1, "a cached count adds no request");
  });
});
