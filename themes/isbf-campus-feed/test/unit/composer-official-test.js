import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import sinon from "sinon";
import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import { setOptionalTopicTitle } from "../../discourse/lib/optional-topic-title";

module("ISBF | Unit | Model | composer-official", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.site = this.owner.lookup("service:site");
    this.originalConfig = this.site.isbf_official;
    this.config = {
      category_id: this.site.categories[0].id,
      campuses: [
        { id: "north", label: "North campus" },
        { id: "south", label: "South campus" },
      ],
      types: [
        { id: "notice", label: "Notice" },
        { id: "event", label: "Event" },
      ],
    };
    this.site.set("isbf_official", this.config);
    this.user = logIn(this.owner);
    this.user.set("user_option.composition_mode", 0);
    this.store = this.owner.lookup("service:store");
    this.composer = this.store.createRecord("composer", {
      user: this.user,
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: "new_topic",
      draftSequence: 0,
      title: "An official campus update",
      reply: "A campus update with enough text to publish.",
    });
  });

  hooks.afterEach(function () {
    this.site.set("isbf_official", this.originalConfig);
  });

  test("official fields default to null on each composer", function (assert) {
    this.composer.set("isbf_official_campuses", ["north"]);
    const another = this.store.createRecord("composer", { user: this.user });

    assert.strictEqual(
      another.isbf_official_campuses,
      null,
      "campuses are not shared between composers"
    );
    assert.strictEqual(
      another.isbf_official_types,
      null,
      "types default to null"
    );
  });

  test("clearing repeatedly resets official selections, optional title and core state", function (assert) {
    for (let attempt = 0; attempt < 2; attempt++) {
      this.composer.setProperties({
        isbf_official_campuses: ["north"],
        isbf_official_types: ["notice"],
        reply: "A campus update body",
      });
      setOptionalTopicTitle(this.composer, "Campus update");

      assert.strictEqual(
        this.composer.clearState(),
        undefined,
        "the core return value is preserved"
      );
      assert.strictEqual(
        this.composer.title,
        null,
        "the core title is cleared"
      );
      assert.strictEqual(
        this.composer.reply,
        null,
        "the core reply is cleared"
      );
      assert.strictEqual(
        this.composer.isbf_optional_title,
        null,
        "the existing optional title extension still runs"
      );
      assert.strictEqual(
        this.composer.isbf_official_campuses,
        null,
        "campuses are cleared"
      );
      assert.strictEqual(
        this.composer.isbf_official_types,
        null,
        "types are cleared"
      );
    }
  });

  test("opening a new official topic initializes empty selections", async function (assert) {
    await this.composer.open({
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: "new_topic",
      draftSequence: 0,
    });

    assert.deepEqual(
      this.composer.isbf_official_campuses,
      [],
      "new topics have no preselected campuses"
    );
    assert.deepEqual(
      this.composer.isbf_official_types,
      [],
      "new topics have no preselected types"
    );
    assert.false(this.composer.loading, "the core open operation completes");
  });

  test("official selections survive draft serialization and restoration", async function (assert) {
    this.composer.setProperties({
      isbf_official_campuses: ["north", "south"],
      isbf_official_types: ["event"],
    });
    const draft = this.composer.serializeDraftData();

    assert.deepEqual(
      draft.isbf_official_campuses,
      ["north", "south"],
      "draft campuses remain arrays"
    );
    assert.deepEqual(
      draft.isbf_official_types,
      ["event"],
      "draft types remain arrays"
    );

    this.composer.clearState();
    await this.composer.open({
      ...draft,
      draftKey: "new_topic",
      draftSequence: 0,
    });

    assert.deepEqual(
      this.composer.isbf_official_campuses,
      ["north", "south"],
      "draft campuses are restored"
    );
    assert.deepEqual(
      this.composer.isbf_official_types,
      ["event"],
      "draft types are restored"
    );
  });

  test("editing the first post restores selections from the loaded post", async function (assert) {
    const topic = this.store.createRecord("topic", {
      id: 280,
      title: "Campus update",
      category_id: this.config.category_id,
      details: { can_edit: true },
    });
    const post = this.store.createRecord("post", {
      id: 123,
      post_number: 1,
      topic,
    });
    pretender.get("/posts/123", () =>
      response({
        id: 123,
        topic_id: 280,
        post_number: 1,
        raw: "An existing campus update",
        isbf_official_campuses: ["south"],
        isbf_official_types: ["notice"],
      })
    );

    this.composer.clearState();
    await this.composer.open({
      action: Composer.EDIT,
      post,
      topic,
      categoryId: this.config.category_id,
      draftKey: "topic_280",
      draftSequence: 0,
    });

    assert.deepEqual(
      this.composer.isbf_official_campuses,
      ["south"],
      "campuses come from the loaded first post"
    );
    assert.deepEqual(
      this.composer.isbf_official_types,
      ["notice"],
      "types come from the loaded first post"
    );
  });

  test("open preserves another extension's arguments and result", async function (assert) {
    const options = { draftKey: "custom_draft", draftSequence: 4 };
    const result = { opened: true };
    withPluginApi((api) => {
      api.registerBehaviorTransformer("composer-open", ({ context }) => {
        assert.strictEqual(context.opts, options, "the options reach core");
        return Promise.resolve(result);
      });
    });

    assert.strictEqual(
      await this.composer.open(options),
      result,
      "the original promise result is preserved"
    );
  });

  test("open preserves promise rejections", async function (assert) {
    const error = new Error("Unable to open the composer");
    withPluginApi((api) => {
      api.registerBehaviorTransformer("composer-open", () =>
        Promise.reject(error)
      );
    });

    await assert.rejects(
      this.composer.open({}),
      (rejection) => rejection === error,
      "the original rejection reaches the caller"
    );
  });

  test("payload getters track and filter official selections", function (assert) {
    this.composer.setProperties({
      isbf_official_campuses: ["north", "north", "unknown"],
      isbf_official_types: ["event"],
    });

    assert.strictEqual(
      this.composer.isbfOfficialCampusesPayload,
      '["north"]',
      "campuses retain the existing JSON format and filter invalid values"
    );
    this.composer.set("isbf_official_campuses", ["south"]);
    assert.strictEqual(
      this.composer.isbfOfficialCampusesPayload,
      '["south"]',
      "the getter reflects the new selection"
    );
    assert.strictEqual(
      this.composer.isbfOfficialTypesPayload,
      '["event"]',
      "types retain the existing JSON format"
    );
  });

  for (const missingField of [
    "isbf_official_campuses",
    "isbf_official_types",
  ]) {
    test(`save requires ${missingField} before creating a post`, async function (assert) {
      this.composer.setProperties({
        isbf_official_campuses: ["north"],
        isbf_official_types: ["notice"],
      });
      this.composer.set(missingField, []);
      const alert = sinon.stub(this.composer.dialog, "alert");
      let posted = false;
      pretender.post("/posts", () => {
        posted = true;
        return response({});
      });

      await this.composer.save({});

      assert.true(alert.calledOnce, "the existing validation dialog is shown");
      assert.false(posted, "no post is submitted with incomplete selections");
    });
  }

  test("saving a complete official topic preserves payloads and result", async function (assert) {
    this.composer.setProperties({
      isbf_official_campuses: ["north", "south"],
      isbf_official_types: ["notice"],
    });
    let payload;
    pretender.post("/posts", (request) => {
      payload = parsePostData(request.requestBody);
      return response({
        success: true,
        action: "create_post",
        post: {
          id: 12345,
          topic_id: 280,
          topic_slug: "internationalization-localization",
        },
      });
    });

    assert.false(
      this.composer.cantSubmitPost,
      "the official topic satisfies core submission requirements"
    );
    const result = await this.composer.save({});

    assert.strictEqual(
      payload.isbf_official_campuses,
      '["north","south"]',
      "new posts send campuses as JSON"
    );
    assert.strictEqual(
      payload.isbf_official_types,
      '["notice"]',
      "new posts send types as JSON"
    );
    assert.strictEqual(
      result.responseJson.post.id,
      12345,
      "the core save result reaches the caller"
    );
    assert.strictEqual(
      this.composer.isbf_official_campuses,
      null,
      "successful saves clear the selections"
    );
  });

  test("editing the first post preserves update serialization and options", async function (assert) {
    this.composer.setProperties({
      action: Composer.EDIT,
      topic: this.store.createRecord("topic", {
        id: 280,
        category_id: this.config.category_id,
        title: "An official campus update",
        details: { can_edit: true },
      }),
      post: this.store.createRecord("post", { id: 123, post_number: 1 }),
      isbf_official_campuses: ["south"],
      isbf_official_types: ["event"],
    });
    pretender.put("/t/topic/280", () =>
      response({ basic_topic: { title: "An official campus update" } })
    );
    let payload;
    pretender.put("/posts/123", (request) => {
      payload = parsePostData(request.requestBody).post;
      return response({
        post: {
          id: 123,
          post_number: 1,
          topic_id: 280,
          cooked: "Updated body",
        },
      });
    });

    assert.false(
      this.composer.cantSubmitPost,
      "the edit satisfies core submission requirements"
    );
    await this.composer.save({ editReason: "Campus correction" });

    assert.strictEqual(
      payload.isbf_official_campuses,
      '["south"]',
      "updates send campuses as JSON"
    );
    assert.strictEqual(
      payload.isbf_official_types,
      '["event"]',
      "updates send types as JSON"
    );
    assert.strictEqual(
      payload.edit_reason,
      "Campus correction",
      "save options reach the original method"
    );
  });

  test("ordinary topics save without official selections", async function (assert) {
    this.composer.set("categoryId", this.site.categories[1].id);
    let payload;
    pretender.post("/posts", (request) => {
      payload = parsePostData(request.requestBody);
      return response({
        success: true,
        action: "create_post",
        post: {
          id: 12345,
          topic_id: 280,
          topic_slug: "internationalization-localization",
        },
      });
    });

    assert.false(
      this.composer.cantSubmitPost,
      "the ordinary topic satisfies core submission requirements"
    );
    await this.composer.save({});

    assert.strictEqual(
      payload.isbf_official_campuses,
      undefined,
      "ordinary posts omit official campuses"
    );
    assert.strictEqual(
      payload.isbf_official_types,
      undefined,
      "ordinary posts omit official types"
    );
  });

  test("replies and private messages omit official payloads", function (assert) {
    this.composer.setProperties({
      action: Composer.REPLY,
      isbf_official_campuses: ["north"],
      isbf_official_types: ["notice"],
    });
    assert.strictEqual(
      this.composer.isbfOfficialCampusesPayload,
      undefined,
      "replies do not include campuses"
    );
    this.composer.setProperties({
      action: Composer.PRIVATE_MESSAGE,
      archetypeId: "private_message",
    });
    assert.strictEqual(
      this.composer.isbfOfficialTypesPayload,
      undefined,
      "private messages do not include official types"
    );
  });
});
