import { settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import sinon from "sinon";
import { register } from "discourse/lib/push-notifications";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Push notification navigation", function (needs) {
  needs.user();

  needs.hooks.beforeEach(function () {
    this.worker = new EventTarget();
    this.worker.controller = { state: "activated" };
    this.worker.ready = Promise.resolve({
      pushManager: { getSubscription: async () => null },
    });
    this.worker.getRegistrations = async () => [];
    this.worker.register = async () => this.worker.ready;
    sinon.stub(navigator, "serviceWorker").value(this.worker);
    sinon.stub(Notification, "permission").value("granted");
  });

  test("opens the reply named by a notification in an existing forum window", async function (assert) {
    await visit("/latest");
    const appEvents = this.owner.lookup("service:app-events");
    register(
      this.owner.lookup("service:current-user"),
      this.owner.lookup("service:router"),
      appEvents
    );
    const onHighlight = (postNumber) => assert.step(String(postNumber));
    appEvents.on("post:highlight", onHighlight);

    this.worker.dispatchEvent(
      new MessageEvent("message", {
        data: { url: "/t/internationalization-localization/280/2" },
      })
    );
    await settled();

    assert.verifySteps(
      ["2"],
      "positions the notification's exact reply number"
    );
    assert.dom("#post_2").exists("renders the target reply");
    appEvents.off("post:highlight", onHighlight);
  });

  test("reopens the reply when the forum URL already matches the notification", async function (assert) {
    const url = "/t/internationalization-localization/280/2";
    await visit(url);
    const appEvents = this.owner.lookup("service:app-events");
    register(
      this.owner.lookup("service:current-user"),
      this.owner.lookup("service:router"),
      appEvents
    );
    const onHighlight = (postNumber) => assert.step(String(postNumber));
    appEvents.on("post:highlight", onHighlight);

    this.worker.dispatchEvent(new MessageEvent("message", { data: { url } }));
    await settled();

    assert.verifySteps(
      ["2"],
      "repeats navigation to the reply instead of only focusing the window"
    );
    assert.dom("#post_2").exists("keeps the target reply rendered");
    appEvents.off("post:highlight", onHighlight);
  });
});
