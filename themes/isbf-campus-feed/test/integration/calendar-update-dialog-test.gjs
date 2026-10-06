import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import ISBFCalendarUpdateDialog from "../../discourse/components/isbf-calendar-update-dialog";

module(
  "ISBF | Integration | Component | ISBFCalendarUpdateDialog",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.entry = {
        id: 99,
        source_item_id: 8,
        title: "Saved briefing",
        note: "Private note",
        starts_at: "2026-10-20T01:00:00Z",
        ends_at: "2026-10-20T02:00:00Z",
        all_day: false,
        schedule_kind: "event",
        needs_update: true,
        latest_source: {
          id: 8,
          revision: 2,
          title: "New briefing",
          starts_at: "2026-11-20T01:00:00Z",
          ends_at: "2026-11-20T02:00:00Z",
          all_day: false,
          schedule_kind: "event",
        },
      };
      this.closed = false;
      this.changed = null;
      this.accepted = false;
      this.close = () => {
        this.closed = true;
      };
      this.model = {
        entry: this.entry,
        onChanged: (entry, accepted) => {
          this.changed = entry;
          this.accepted = accepted;
        },
      };
    });

    test("accept sends the reviewed version and preserves the private note", async function (assert) {
      let payload;
      pretender.post("/isbf/api/entries/99/accept-update.json", (request) => {
        payload = parsePostData(request.requestBody);
        return response({
          entry: {
            ...this.entry,
            ...this.entry.latest_source,
            id: 99,
            needs_update: false,
          },
        });
      });
      await render(
        <template>
          <ModalContainer />
          <ISBFCalendarUpdateDialog
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      assert
        .dom(".isbf-calendar-update-dialog__snapshot")
        .includesText("Saved briefing", "the saved snapshot is displayed");
      assert
        .dom(".isbf-calendar-update-dialog__latest")
        .includesText(
          "New briefing",
          "the new information is shown for review"
        );
      await click(".isbf-calendar-update-dialog__accept");
      assert.strictEqual(
        Number(payload.revision),
        2,
        "confirmation uses the displayed revision"
      );
      assert.strictEqual(
        this.changed.note,
        "Private note",
        "the private note survives the response"
      );
      assert.true(
        this.accepted,
        "the calendar can navigate to the accepted date"
      );
      assert.true(this.closed, "confirmation closes the dialog");
    });

    test("keeping old information dismisses only the displayed revision", async function (assert) {
      let payload;
      pretender.post("/isbf/api/entries/99/dismiss-update.json", (request) => {
        payload = parsePostData(request.requestBody);
        return response(204, null);
      });
      await render(
        <template>
          <ModalContainer />
          <ISBFCalendarUpdateDialog
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      await click(".isbf-calendar-update-dialog__dismiss");
      assert.strictEqual(
        Number(payload.revision),
        2,
        "only the reviewed revision is dismissed"
      );
      assert.strictEqual(
        this.changed.title,
        "Saved briefing",
        "keeping information leaves the saved snapshot intact"
      );
      assert.false(this.accepted, "dismissal does not navigate to a new date");
    });

    test("a concurrent change refreshes the dialog without confirming it", async function (assert) {
      pretender.post("/isbf/api/entries/99/accept-update.json", () =>
        response(409, {})
      );
      pretender.get("/isbf/api/entries/99.json", () =>
        response({
          entry: {
            ...this.entry,
            latest_source: {
              ...this.entry.latest_source,
              revision: 3,
              title: "Changed again",
            },
          },
        })
      );
      await render(
        <template>
          <ModalContainer />
          <ISBFCalendarUpdateDialog
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      await click(".isbf-calendar-update-dialog__accept");
      assert
        .dom(".isbf-calendar-update-dialog__latest")
        .includesText("Changed again", "the new revision is shown");
      assert.dom('[role="status"]').exists("the user is asked to review again");
      assert.false(this.closed, "a conflicting version remains unconfirmed");
    });

    test("cancelled sources retain the record and offer removal", async function (assert) {
      this.model.entry = {
        ...this.entry,
        cancelled: true,
        latest_source: { id: 8, revision: 2, cancelled: true },
      };
      await render(
        <template>
          <ModalContainer />
          <ISBFCalendarUpdateDialog
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      assert
        .dom(".isbf-calendar-update-dialog__accept")
        .doesNotExist("a cancelled source cannot update the saved schedule");
      assert
        .dom(".isbf-calendar-update-dialog__dismiss")
        .exists("the user may keep the record");
      assert
        .dom(".isbf-calendar-update-dialog__remove")
        .exists("the user may choose to remove it");
      assert
        .dom(".isbf-calendar-update-dialog__snapshot")
        .includesText("Private note", "the note remains visible");
    });
  }
);
