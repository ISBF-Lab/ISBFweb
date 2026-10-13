import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFOfficialActivitySummary from "../../discourse/components/isbf-official-activity-summary";

module(
  "ISBF | Integration | Component | ISBFOfficialActivitySummary",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.activity = {
        id: 8,
        title: "Campus briefing",
        schedule_kind: "event",
        starts_at: "2026-10-20T01:00:00Z",
        ends_at: "2026-10-20T02:00:00Z",
        all_day: false,
        location: "Lecture hall",
        organizer: "Student office",
        registration_deadline_id: 9,
      };
      this.cutoff = {
        id: 9,
        title: "Briefing registration",
        schedule_kind: "deadline",
        starts_at: "2026-10-18T03:00:00Z",
        ends_at: "2026-10-18T03:00:00Z",
        all_day: false,
      };
      this.items = [this.activity, this.cutoff];
    });

    test("each activity shows four labelled fields and the cutoff appears once", async function (assert) {
      await render(
        <template>
          <ISBFOfficialActivitySummary @items={{this.items}} />
        </template>
      );
      assert
        .dom(".isbf-official-activity-summary__title")
        .hasText(this.activity.title, "the activity title labels its fields");
      assert
        .dom(".isbf-official-activity-summary__field")
        .exists({ count: 4 }, "the activity has four information fields");
      assert
        .dom(".isbf-official-activity-summary__field:nth-child(3) dd")
        .hasText(
          this.activity.location,
          "the third field contains the location"
        );
      assert
        .dom(".isbf-official-activity-summary__field:nth-child(4) dd")
        .hasText(
          this.activity.organizer,
          "the fourth field contains the organizer"
        );
      assert
        .dom(".isbf-official-activity-summary__deadline")
        .doesNotExist(
          "the linked cutoff is not repeated as a standalone deadline"
        );
      assert
        .dom("button")
        .doesNotExist("the summary remains a read-only part of the topic card");
    });

    test("legacy activities use placeholders and independent deadlines have a compact card", async function (assert) {
      this.items = [
        {
          ...this.activity,
          registration_deadline_id: null,
          location: "",
          organizer: "",
        },
        this.cutoff,
      ];
      await render(
        <template>
          <ISBFOfficialActivitySummary @items={{this.items}} />
        </template>
      );
      assert
        .dom(".isbf-official-activity-summary__field:nth-child(2) dd")
        .hasText("None", "an absent registration deadline is shown explicitly");
      assert
        .dom(".isbf-official-activity-summary__field:nth-child(3) dd")
        .hasText("Not provided", "an empty location has a placeholder");
      assert
        .dom(".isbf-official-activity-summary__deadline strong")
        .hasText(this.cutoff.title, "the independent deadline keeps its title");
    });

    test("multiple activities have separate groups and user text remains escaped", async function (assert) {
      const another = {
        ...this.activity,
        id: 10,
        title: "Workshop",
        registration_deadline_id: null,
        location: "<img src=x onerror=alert(1)>",
      };
      this.items = [...this.items, another];
      await render(
        <template>
          <ISBFOfficialActivitySummary @items={{this.items}} />
        </template>
      );
      assert
        .dom(".isbf-official-activity-summary__activity")
        .exists({ count: 2 }, "each activity has its own group");
      assert
        .dom(
          '[data-schedule-id="10"] .isbf-official-activity-summary__field:nth-child(3) dd'
        )
        .hasText(another.location, "the literal location is displayed");
      assert
        .dom('[data-schedule-id="10"] img')
        .doesNotExist("location text cannot create HTML elements");
    });

    test("ordinary announcements have no summary container", async function (assert) {
      this.items = [];
      await render(
        <template>
          <ISBFOfficialActivitySummary @items={{this.items}} />
        </template>
      );
      assert
        .dom(".isbf-official-activity-summary")
        .doesNotExist("an ordinary announcement adds no empty layout area");
    });
  }
);
