import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import Composer from "discourse/models/composer";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { logIn } from "discourse/tests/helpers/qunit-helpers";
import { OFFICIAL_CALENDAR_FIELD } from "../../discourse/lib/official-calendar";

module("ISBF | Unit | Model | composer-official-calendar", function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.site = this.owner.lookup("service:site");
    this.originalConfig = this.site.isbf_calendar;
    this.categoryId = this.site.categories[0].id;
    this.site.set("isbf_calendar", { official_category_id: this.categoryId });
    this.user = logIn(this.owner);
    this.store = this.owner.lookup("service:store");
    this.composer = this.store.createRecord("composer", {
      user: this.user,
      action: Composer.CREATE_TOPIC,
      categoryId: this.categoryId,
      draftKey: "new_topic",
      draftSequence: 0,
    });
    this.items = [
      {
        id: 8,
        revision: 2,
        title: "Deadline",
        schedule_kind: "deadline",
        starts_at: "2026-10-20T01:00:00Z",
        ends_at: "2026-10-20T01:00:00Z",
        all_day: false,
      },
    ];
  });

  hooks.afterEach(function () {
    this.site.set("isbf_calendar", this.originalConfig);
  });

  test("items remain isolated and clearing preserves existing extensions", function (assert) {
    this.composer.set(OFFICIAL_CALENDAR_FIELD, this.items);
    const another = this.store.createRecord("composer", { user: this.user });
    assert.strictEqual(
      another[OFFICIAL_CALENDAR_FIELD],
      null,
      "another composer starts without shared items"
    );
    this.composer.set("isbf_official_campuses", ["north"]);
    this.composer.clearState();
    assert.strictEqual(
      this.composer[OFFICIAL_CALENDAR_FIELD],
      null,
      "calendar state is cleared"
    );
    assert.strictEqual(
      this.composer.isbf_official_campuses,
      null,
      "the official selection reset still runs"
    );
  });

  test("draft serialization and reopening retain structured items", async function (assert) {
    this.composer.set(OFFICIAL_CALENDAR_FIELD, this.items);
    const draft = this.composer.serializeDraftData();
    assert.deepEqual(
      draft[OFFICIAL_CALENDAR_FIELD],
      this.items,
      "draft items remain arrays"
    );
    this.composer.clearState();
    await this.composer.open({
      ...draft,
      draftKey: "new_topic",
      draftSequence: 0,
    });
    assert.deepEqual(
      this.composer[OFFICIAL_CALENDAR_FIELD],
      this.items,
      "draft items are restored"
    );
    assert.deepEqual(
      JSON.parse(this.composer.isbfOfficialCalendarPayload),
      this.items,
      "post payloads remain JSON strings"
    );
  });

  test("editing the first post restores source IDs and versions", async function (assert) {
    const topic = this.store.createRecord("topic", {
      id: 280,
      title: "Announcement",
      category_id: this.categoryId,
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
        raw: "An official announcement",
        [OFFICIAL_CALENDAR_FIELD]: this.items,
      })
    );
    await this.composer.open({
      action: Composer.EDIT,
      post,
      topic,
      categoryId: this.categoryId,
      draftKey: "topic_280",
      draftSequence: 0,
    });
    assert.deepEqual(
      this.composer[OFFICIAL_CALENDAR_FIELD],
      this.items,
      "the loaded post supplies stable source IDs and revisions"
    );
  });

  test("ordinary posts, replies and private messages omit time metadata", function (assert) {
    this.composer.set(OFFICIAL_CALENDAR_FIELD, this.items);
    this.composer.set("categoryId", this.site.categories[1].id);
    assert.strictEqual(
      this.composer.isbfOfficialCalendarPayload,
      undefined,
      "ordinary categories omit calendar metadata"
    );
    this.composer.setProperties({
      categoryId: this.categoryId,
      action: Composer.REPLY,
    });
    assert.strictEqual(
      this.composer.isbfOfficialCalendarPayload,
      undefined,
      "replies omit calendar metadata"
    );
    this.composer.setProperties({
      action: Composer.PRIVATE_MESSAGE,
      archetypeId: "private_message",
    });
    assert.strictEqual(
      this.composer.isbfOfficialCalendarPayload,
      undefined,
      "private messages omit calendar metadata"
    );
  });
});
