import {
  click,
  fillIn,
  find,
  findAll,
  render,
  waitFor,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFV2Calendar from "../../discourse/components/isbf-v2-calendar";

const ADD_BUTTON = ".isbf-v2-calendar__heading .isbf-v2-calendar__primary";
const EDITOR = ".isbf-v2-calendar__editor";
const TITLE_INPUT = `${EDITOR} input[type=text]`;
const SAVE_BUTTON = `${EDITOR} button[type=submit]`;
const CANCEL_BUTTON = `${EDITOR} .isbf-v2-calendar__form-actions button[type=button]`;

module(
  "ISBF Campus Feed | Integration | Component | ISBFV2Calendar",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      pretender.get("/isbf/api/entries.json", () => response({ entries: [] }));
      pretender.get("/discourse-post-event/events.json", () =>
        response({ events: [] })
      );
    });

    test("disables saving while a request is pending", async function (assert) {
      let resolveSave;
      let requests = 0;
      pretender.post("/isbf/api/entries.json", async () => {
        requests++;
        await new Promise((resolve) => (resolveSave = resolve));
        return response({});
      });

      await render(<template><ISBFV2Calendar /></template>);
      await click(ADD_BUTTON);
      await fillIn(TITLE_INPUT, "Campus meeting");
      const saving = click(SAVE_BUTTON);
      await waitUntil(() => Boolean(resolveSave));

      assert
        .dom(SAVE_BUTTON)
        .isDisabled("a second save is disabled while the first is pending");
      resolveSave();
      await saving;

      assert.strictEqual(requests, 1, "one entry is submitted");
      assert.dom(EDITOR).doesNotExist("the successful save closes its editor");
    });

    test("keeps a new editor open when an earlier save completes", async function (assert) {
      let resolveSave;
      pretender.post("/isbf/api/entries.json", async () => {
        await new Promise((resolve) => (resolveSave = resolve));
        return response({});
      });

      await render(<template><ISBFV2Calendar /></template>);
      await click(ADD_BUTTON);
      await fillIn(TITLE_INPUT, "First meeting");
      const saving = click(SAVE_BUTTON);
      await waitUntil(() => Boolean(resolveSave));

      const cancelling = click(CANCEL_BUTTON);
      await waitUntil(() => !find(EDITOR));
      const reopening = click(ADD_BUTTON);
      await waitFor(TITLE_INPUT);
      const typing = fillIn(TITLE_INPUT, "Second meeting");
      await waitUntil(() => find(TITLE_INPUT)?.value === "Second meeting");

      resolveSave();
      await Promise.all([saving, cancelling, reopening, typing]);

      assert
        .dom(TITLE_INPUT)
        .hasValue("Second meeting", "the new draft remains open and intact");
      assert
        .dom(SAVE_BUTTON)
        .isEnabled(
          "the new draft can be saved after the earlier request finishes"
        );
    });

    test("orders events by time across timestamp offsets", async function (assert) {
      const today = new Date();
      const earlier = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate(),
        8
      );
      const later = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate(),
        9
      );
      const offsetStart = new Date(earlier.getTime() + 8 * 3600000)
        .toISOString()
        .replace("Z", "+08:00");
      pretender.get("/isbf/api/entries.json", () =>
        response({
          entries: [
            {
              id: 1,
              title: "Later meeting",
              starts_at: later.toISOString(),
              ends_at: new Date(later.getTime() + 3600000).toISOString(),
              all_day: false,
            },
            {
              id: 2,
              title: "Earlier meeting",
              starts_at: offsetStart,
              ends_at: new Date(earlier.getTime() + 3600000).toISOString(),
              all_day: false,
            },
          ],
        })
      );

      await render(<template><ISBFV2Calendar /></template>);

      const titles = findAll(".isbf-v2-calendar__item h3");
      assert
        .dom(titles[0])
        .hasText("Earlier meeting", "the earlier timestamp appears first");
      assert
        .dom(titles[1])
        .hasText("Later meeting", "the later timestamp appears second");
    });
  }
);
