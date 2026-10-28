import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";

module("Unit | Route | topic draft opening", function (hooks) {
  setupTest(hooks);

  hooks.afterEach(function () {
    sinon.restore();
  });

  for (const nested of [false, true]) {
    for (const destinationId of [null, 280, "724"]) {
      test(`${nested ? "nested" : "flat"} topic restores its draft unless it is the explicit resume destination ${destinationId}`, function (assert) {
        const route = this.owner.lookup("route:topic.from-params");
        const composer = this.owner.lookup("service:composer");
        composer.isResumingDraft = true;
        composer.resumingDraftTopicId = destinationId;
        const open = sinon.stub(composer, "open");
        const topic = {
          id: 724,
          draft: JSON.stringify({ reply: "This topic's saved reply" }),
          draft_key: "topic_724",
          draft_sequence: 2,
          details: { set() {} },
          postStream: { closestPostForPostNumber() {} },
        };
        const topicController = {
          set(key, value) {
            this[key] = value;
          },
          setProperties(properties) {
            Object.assign(this, properties);
          },
          subscribe() {},
        };
        const nestedController = {
          setProperties(properties) {
            Object.assign(this, properties);
          },
          subscribe() {},
          unsubscribe() {},
        };
        sinon.stub(route, "controllerFor").callsFake((name) => {
          return name === "nested" ? nestedController : topicController;
        });
        sinon.stub(route, "modelFor").returns(topic);
        sinon.stub(route.screenTrack, "start");

        route.setupController(
          null,
          nested ? { _nested: { topic, contextMode: true } } : {},
          {}
        );

        assert.deepEqual(
          open.args.map(([options]) => ({
            topic: options.topic,
            draftKey: options.draftKey,
          })),
          destinationId === "724" ? [] : [{ topic, draftKey: "topic_724" }],
          "only the explicit destination defers opening to the resume action"
        );
      });
    }
  }
});
