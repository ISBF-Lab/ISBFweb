import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import formKit from "discourse/tests/helpers/form-kit-helper";
import ISBFOfficialCalendarEditor from "../../discourse/components/isbf-official-calendar-editor";

module(
  "ISBF | Integration | Component | ISBFOfficialCalendarEditor",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.saved = null;
      this.close = () => {};
      this.model = {
        items: [],
        onSave: (items) => {
          this.saved = items;
        },
      };
    });

    test("a publisher can add a date-only deadline", async function (assert) {
      await render(
        <template>
          <ModalContainer />
          <ISBFOfficialCalendarEditor
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      await click(".isbf-official-calendar-editor__add");
      await formKit().field("items.0.title").fillIn("Application deadline");
      await formKit().field("items.0.schedule_kind").select("deadline");
      await formKit().field("items.0.all_day").toggle();
      await fillIn('[data-name="items.0.start"] input', "2026-10-20");
      assert
        .dom('[data-name="items.0.end"]')
        .doesNotExist("deadlines have one date or time");
      await click(
        ".isbf-official-calendar-editor .form-kit__button[type=submit]"
      );
      assert.strictEqual(
        this.saved?.[0].starts_at,
        "2026-10-19T16:00:00.000Z",
        "saving uses Beijing midnight"
      );
      assert.strictEqual(
        this.saved?.[0].ends_at,
        "2026-10-20T16:00:00.000Z",
        "the date remains a whole-day marker"
      );
    });

    test("changing precision retains the date and removing a row preserves other IDs", async function (assert) {
      const item = {
        id: 8,
        revision: 2,
        title: "Briefing",
        schedule_kind: "event",
        starts_at: "2026-10-20T01:00:00Z",
        ends_at: "2026-10-20T02:00:00Z",
        all_day: false,
      };
      this.model.items = [item];
      await render(
        <template>
          <ModalContainer />
          <ISBFOfficialCalendarEditor
            @closeModal={{this.close}}
            @model={{this.model}}
          />
        </template>
      );
      await formKit().field("items.0.all_day").toggle();
      assert
        .dom('[data-name="items.0.start"] input')
        .hasValue("2026-10-20", "date-only mode keeps the Beijing day");
      await click(".isbf-official-calendar-editor__add");
      await click(".isbf-official-calendar-editor__item:last-child .btn");
      assert
        .dom(".isbf-official-calendar-editor__item")
        .exists({ count: 1 }, "only the new row is removed");
      await click(
        ".isbf-official-calendar-editor .form-kit__button[type=submit]"
      );
      assert.strictEqual(
        this.saved?.[0].id,
        8,
        "the remaining item keeps its stable identity"
      );
      assert.strictEqual(
        this.saved?.[0].revision,
        2,
        "the displayed source version is submitted"
      );
    });
  }
);
