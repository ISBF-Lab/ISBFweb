import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import {
  calendarEditorItems,
  calendarItemFromEditor,
  canonicalCalendarItems,
  officialDateKey,
  officialOccursOn,
} from "../../discourse/lib/official-calendar";

module("ISBF | Unit | Lib | official-calendar", function (hooks) {
  setupTest(hooks);

  test("a date-only deadline is a Beijing day with an exclusive end", function (assert) {
    const item = calendarItemFromEditor({
      title: "Application",
      schedule_kind: "deadline",
      all_day: true,
      start: "2026-10-20",
      end: "",
    });
    assert.strictEqual(
      item.starts_at,
      "2026-10-19T16:00:00.000Z",
      "the day begins at Beijing midnight"
    );
    assert.strictEqual(
      item.ends_at,
      "2026-10-20T16:00:00.000Z",
      "no deadline time is inferred"
    );
    assert.true(
      officialOccursOn(item, "2026-10-20"),
      "it belongs to the stated Beijing date"
    );
    assert.false(
      officialOccursOn(item, "2026-10-19"),
      "it does not use the UTC date"
    );
    assert.false(
      officialOccursOn(item, "2026-10-21"),
      "the exclusive end is excluded"
    );
  });

  test("a precise deadline or activity without an end occupies one day", function (assert) {
    for (const schedule_kind of ["event", "deadline"]) {
      const item = calendarItemFromEditor({
        title: "Briefing",
        schedule_kind,
        all_day: false,
        start: "2026-10-20T00:30",
        end: "",
      });
      assert.strictEqual(
        item.starts_at,
        item.ends_at,
        "a missing end stays a point in time"
      );
      assert.true(
        officialOccursOn(item, "2026-10-20"),
        "the point is visible on its Beijing day"
      );
      assert.false(
        officialOccursOn(item, "2026-10-19"),
        "the UTC day does not move the point"
      );
    }
  });

  test("editor round trips preserve source identity and Beijing times", function (assert) {
    const item = {
      id: 8,
      revision: 4,
      title: "Activity",
      schedule_kind: "event",
      all_day: false,
      starts_at: "2026-10-19T16:30:00.000Z",
      ends_at: "2026-10-19T18:00:00.000Z",
      personal_entry_id: 99,
    };
    const draft = calendarEditorItems([item])[0];
    assert.strictEqual(
      draft.start,
      "2026-10-20T00:30",
      "editing uses Beijing wall time"
    );
    assert.strictEqual(
      officialDateKey(item.starts_at),
      "2026-10-20",
      "day selection uses Beijing time"
    );
    assert.deepEqual(
      calendarItemFromEditor(draft),
      canonicalCalendarItems([item])[0],
      "saving retains identity without sending personal state"
    );
  });

  test("impossible dates and reversed ranges cannot be saved", function (assert) {
    const draft = {
      title: "Deadline",
      schedule_kind: "event",
      all_day: false,
      start: "2026-02-30T09:00",
      end: "",
    };
    assert.throws(
      () => calendarItemFromEditor(draft),
      RangeError,
      "an impossible date is rejected"
    );
    assert.throws(
      () =>
        calendarItemFromEditor({
          ...draft,
          start: "2026-10-20T10:00",
          end: "2026-10-20T09:00",
        }),
      RangeError,
      "the end cannot precede the start"
    );
  });
});
