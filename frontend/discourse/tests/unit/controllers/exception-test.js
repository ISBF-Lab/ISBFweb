import { settled } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";

module("Unit | Controller | exception", function (hooks) {
  setupTest(hooks);

  test("retries the original transition and releases the loading state", async function (assert) {
    const controller = this.owner.lookup("controller:exception");
    const exception = this.owner.lookup("service:exception");
    const retry = sinon.spy();
    exception.thrown = { status: 503 };
    exception.lastTransition = { retry };

    controller.tryLoading();
    await settled();

    assert.true(retry.calledOnce);
    assert.strictEqual(exception.thrown, null);
    assert.strictEqual(exception.lastTransition, null);
    assert.false(controller.loading);
  });
});
