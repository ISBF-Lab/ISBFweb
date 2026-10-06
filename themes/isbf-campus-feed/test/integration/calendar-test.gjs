import { click, render, triggerKeyEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import DialogHolder from "discourse/dialog-holder/components/dialog-holder";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, {
  parsePostData,
  response,
} from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import ISBFV2Calendar from "../../discourse/components/isbf-v2-calendar";

module("ISBF | Integration | Component | ISBFV2Calendar", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    const today = new Date();
    const day = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
    const startsAt = `${day}T00:00:00.000Z`;
    this.entries = [
      {
        id: 123,
        title: "Personal calendar entry",
        starts_at: startsAt,
        ends_at: new Date(
          new Date(startsAt).getTime() + 86400000
        ).toISOString(),
        all_day: true,
      },
    ];
    this.deleteCount = 0;
    pretender.get("/isbf/api/entry-updates.json", () =>
      response({ entries: [] })
    );
    pretender.get("/isbf/api/entries.json", () =>
      response({ entries: this.entries })
    );
    pretender.get("/discourse-post-event/events.json", () =>
      response({ events: [] })
    );
    pretender.delete("/isbf/api/entries/123.json", () => {
      this.deleteCount++;
      this.entries = [];
      return response({});
    });
  });

  test("deleting an entry requires confirmation", async function (assert) {
    await render(<template><ISBFV2Calendar /><DialogHolder /></template>);
    await click(".isbf-v2-calendar__item-actions button:last-child");
    assert
      .dom(".dialog-body")
      .exists("the Discourse confirmation dialog opens");

    await click(".dialog-footer .btn-default");
    assert.strictEqual(
      this.deleteCount,
      0,
      "cancelling does not delete the entry"
    );
    assert
      .dom(".isbf-v2-calendar__item h3")
      .hasText(
        "Personal calendar entry",
        "the entry remains after cancellation"
      );

    await click(".isbf-v2-calendar__item-actions button:last-child");
    await click(".dialog-footer .btn-primary");
    assert.strictEqual(
      this.deleteCount,
      1,
      "confirmation deletes the entry once"
    );
    assert
      .dom(".isbf-v2-calendar__item")
      .doesNotExist("the agenda refreshes after deletion");
  });

  test("the entry editor focuses the title and closes with Escape", async function (assert) {
    await render(<template><ISBFV2Calendar /></template>);
    await click(".isbf-v2-calendar__heading .isbf-v2-calendar__primary");

    assert
      .dom('.isbf-v2-calendar__editor input[type="text"]')
      .isFocused("the title receives keyboard focus");
    assert
      .dom(".isbf-v2-calendar__editor-backdrop")
      .hasAttribute("tabindex", "-1", "the dialog can receive focus");

    await triggerKeyEvent(
      '.isbf-v2-calendar__editor input[type="text"]',
      "keydown",
      "Escape"
    );
    assert
      .dom(".isbf-v2-calendar__editor-backdrop")
      .doesNotExist("Escape closes the editor");
  });

  test("pending changes appear outside the displayed month", async function (assert) {
    pretender.get("/isbf/api/entry-updates.json", () =>
      response({
        entries: [{ id: 999, title: "Future briefing", cancelled: false }],
      })
    );
    await render(<template><ISBFV2Calendar /></template>);
    assert
      .dom(".isbf-calendar-updates__item")
      .includesText(
        "Future briefing",
        "changes are loaded independently of the visible month"
      );
  });

  test("a notification opens the accepted entry on its Beijing date", async function (assert) {
    this.entries = [
      {
        id: 99,
        source_item_id: 8,
        title: "Midnight briefing",
        starts_at: "2027-05-14T16:30:00Z",
        ends_at: "2027-05-14T16:30:00Z",
        all_day: false,
        schedule_kind: "event",
      },
    ];
    this.owner.lookup("service:router").currentURL =
      "/isbf/calendar?entry_id=99";
    pretender.get("/isbf/api/entries/99.json", () =>
      response({ entry: this.entries[0] })
    );
    await render(<template><ISBFV2Calendar /></template>);
    assert
      .dom('[aria-label="2027-05-15"]')
      .hasAttribute(
        "aria-pressed",
        "true",
        "the notification navigates across months to the Beijing day"
      );
    assert
      .dom(".isbf-v2-calendar__item h3")
      .hasText("Midnight briefing", "a point event appears in the agenda");
    assert
      .dom(".isbf-v2-calendar__item.is-focused")
      .isFocused("the imported entry receives focus");
  });

  test("imported entries expose only a private note editor", async function (assert) {
    this.entries = [
      {
        id: 99,
        source_item_id: 8,
        title: "Official briefing",
        note: "Old note",
        starts_at: "2027-05-14T16:30:00Z",
        ends_at: "2027-05-14T16:30:00Z",
        all_day: false,
        schedule_kind: "event",
      },
    ];
    this.owner.lookup("service:router").currentURL =
      "/isbf/calendar?entry_id=99";
    pretender.get("/isbf/api/entries/99.json", () =>
      response({ entry: this.entries[0] })
    );
    let payload;
    pretender.patch("/isbf/api/entries/99.json", (request) => {
      payload = parsePostData(request.requestBody).entry;
      this.entries = [{ ...this.entries[0], note: payload.note }];
      return response({ entry: this.entries[0] });
    });
    await render(<template><ISBFV2Calendar /><ModalContainer /></template>);
    await click(".isbf-v2-calendar__item-actions button:first-child");
    assert
      .dom('.isbf-calendar-note-editor [data-name="title"]')
      .doesNotExist("official fields have no editable controls");
    await formKit().field("note").fillIn("Bring student ID");
    await click(".isbf-calendar-note-editor .form-kit__button[type=submit]");
    assert.deepEqual(
      payload,
      { note: "Bring student ID" },
      "only the note is written"
    );
  });
});
