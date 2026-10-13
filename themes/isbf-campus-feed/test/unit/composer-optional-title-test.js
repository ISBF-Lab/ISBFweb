import { settled } from "@ember/test-helpers";
import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import Composer from "discourse/models/composer";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import {
  isUntitledTopicTitle,
  prepareOptionalTopicTitle,
  setOptionalTopicTitle,
} from "../../discourse/lib/optional-topic-title";

module("ISBF | Unit | Model | composer-optional-title", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    const user = logIn(this.owner);
    this.composer = this.owner
      .lookup("service:store")
      .createRecord("composer", {
        user,
        action: Composer.CREATE_TOPIC,
        draftKey: "new_topic",
        draftSequence: 0,
      });
  });

  test("clearing a composer resets its optional title and core state", function (assert) {
    assert.strictEqual(
      this.composer.isbf_optional_title,
      null,
      "the field defaults to null"
    );
    setOptionalTopicTitle(this.composer, "Campus update");
    this.composer.set("reply", "A campus update body");

    assert.strictEqual(
      this.composer.clearState(),
      undefined,
      "the core return value is preserved"
    );
    assert.strictEqual(this.composer.title, null, "the core title is cleared");
    assert.strictEqual(this.composer.reply, null, "the core reply is cleared");
    assert.strictEqual(
      this.composer.isbf_optional_title,
      null,
      "the optional title is cleared"
    );

    this.composer.clearState();
    setOptionalTopicTitle(this.composer, "Another update");
    this.composer.clearState();
    assert.strictEqual(
      this.composer.isbf_optional_title,
      null,
      "repeated use does not retain a title"
    );
  });

  test("an untitled draft keeps its hidden title when restored", async function (assert) {
    prepareOptionalTopicTitle(this.composer);
    const hiddenTitle = this.composer.title;
    const draft = this.composer.serializeDraftData();

    assert.true(
      isUntitledTopicTitle(hiddenTitle),
      "an empty title receives the untitled marker"
    );
    assert.strictEqual(
      draft.isbf_optional_title,
      "",
      "the visible empty title is saved to the draft"
    );

    this.composer.clearState();
    await this.composer.open({
      ...draft,
      draftKey: "new_topic",
      draftSequence: 0,
    });
    prepareOptionalTopicTitle(this.composer);
    assert.strictEqual(
      this.composer.title,
      hiddenTitle,
      "restoration preserves the original marker"
    );
    assert.strictEqual(
      this.composer.isbf_optional_title,
      "",
      "the visible title remains empty"
    );
  });

  test("an explicit title survives draft restoration", async function (assert) {
    setOptionalTopicTitle(this.composer, "Campus update");
    const draft = this.composer.serializeDraftData();

    this.composer.clearState();
    await this.composer.open({
      ...draft,
      draftKey: "new_topic",
      draftSequence: 0,
    });
    prepareOptionalTopicTitle(this.composer);

    assert.strictEqual(
      this.composer.title,
      "Campus update",
      "the post title is restored"
    );
    assert.strictEqual(
      this.composer.isbf_optional_title,
      "Campus update",
      "the visible title is restored"
    );
  });

  test("saving and closing stores the title before clearing the composer", async function (assert) {
    let savedDraft;
    pretender.post("/drafts.json", (request) => {
      savedDraft = JSON.parse(parsePostData(request.requestBody).data);
      return response({ draft_sequence: 1 });
    });
    setOptionalTopicTitle(this.composer, "Saved update");
    this.composer.set("reply", "A campus update body");
    const service = this.owner.lookup("service:composer");
    service.set("model", this.composer);

    service.saveAndCloseComposer();
    await settled();

    assert.strictEqual(
      savedDraft.isbf_optional_title,
      "Saved update",
      "the saved draft contains the explicit title"
    );
    assert.strictEqual(
      this.composer.isbf_optional_title,
      null,
      "closing clears the optional title"
    );
    assert.strictEqual(service.model, null, "the composer service is closed");
  });

  test("cancelling an unchanged composer clears the optional title", async function (assert) {
    let clearedDraft = false;
    pretender.delete("/drafts/new_topic.json", () => {
      clearedDraft = true;
      return response({});
    });
    this.composer.setProperties({
      title: "Unchanged title",
      originalTitle: "Unchanged title",
      isbf_optional_title: "Unchanged title",
    });
    const service = this.owner.lookup("service:composer");
    service.set("model", this.composer);

    await service.cancelComposer();

    assert.true(clearedDraft, "cancelling deletes the saved draft");
    assert.strictEqual(
      this.composer.isbf_optional_title,
      null,
      "cancelling clears the optional title"
    );
    assert.strictEqual(service.model, null, "the composer service is closed");
  });
});
