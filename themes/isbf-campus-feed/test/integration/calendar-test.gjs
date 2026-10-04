import { click, render, triggerKeyEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import DialogHolder from "discourse/dialog-holder/components/dialog-holder";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFV2Calendar from "../../discourse/components/isbf-v2-calendar";

module("ISBF | Integration | Component | ISBFV2Calendar", function (hooks) {
  setupRenderingTest(hooks);

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
});
