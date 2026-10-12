import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFOfficialCalendarItems from "../../discourse/components/isbf-official-calendar-items";

module(
  "ISBF | Integration | Component | ISBFOfficialCalendarItems",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.item = {
        id: 8,
        revision: 1,
        title: "Campus briefing",
        schedule_kind: "event",
        starts_at: "2026-10-20T01:00:00Z",
        ends_at: "2026-10-20T02:00:00Z",
        all_day: false,
      };
      this.items = [this.item];
      this.outletArgs = {
        post: {
          id: 123,
          post_number: 1,
          isbf_official_calendar_items: this.items,
        },
      };
      this.addCount = 0;
      pretender.post("/isbf/api/official-items/8/add.json", () => {
        this.addCount++;
        return response({ entry: { ...this.item, id: 99, source_item_id: 8 } });
      });
    });

    test("the feed summary has no add control", async function (assert) {
      await render(
        <template>
          <ISBFOfficialCalendarItems @items={{this.items}} @readOnly={{true}} />
        </template>
      );
      assert
        .dom(".isbf-official-calendar-items strong")
        .hasText("Campus briefing", "the activity summary is displayed");
      assert
        .dom(".isbf-official-calendar-items .btn")
        .doesNotExist("adding is reserved for the detail page");
    });

    test("one click adds the item and prevents another request", async function (assert) {
      await render(
        <template>
          <ISBFOfficialCalendarItems @outletArgs={{this.outletArgs}} />
        </template>
      );
      await click(".isbf-official-calendar-items .btn");
      assert.strictEqual(this.addCount, 1, "one request adds the item");
      assert
        .dom(".isbf-official-calendar-items .btn")
        .isDisabled("the added state prevents another click");
    });

    test("a failed request can be retried", async function (assert) {
      pretender.post("/isbf/api/official-items/8/add.json", () =>
        response(500, {})
      );
      await render(
        <template>
          <ISBFOfficialCalendarItems @outletArgs={{this.outletArgs}} />
        </template>
      );
      await click(".isbf-official-calendar-items .btn");
      assert
        .dom(".isbf-official-calendar-items__error")
        .exists("a failed request explains the error");
      assert
        .dom(".isbf-official-calendar-items .btn")
        .isNotDisabled("the user can retry");
    });

    test("a version conflict refreshes the official information", async function (assert) {
      pretender.post("/isbf/api/official-items/8/add.json", () =>
        response(409, {})
      );
      pretender.get("/posts/123.json", () =>
        response({
          isbf_official_calendar_items: [
            { ...this.item, revision: 2, title: "Rescheduled briefing" },
          ],
        })
      );
      await render(
        <template>
          <ISBFOfficialCalendarItems @outletArgs={{this.outletArgs}} />
        </template>
      );
      await click(".isbf-official-calendar-items .btn");
      assert
        .dom(".isbf-official-calendar-items strong")
        .hasText(
          "Rescheduled briefing",
          "the stale display is refreshed before another click"
        );
    });
  }
);
