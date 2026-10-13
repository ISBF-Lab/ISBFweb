import { module, test } from "qunit";
import {
  calendarEditorItems,
  calendarItemsFromEditor,
  canonicalCalendarItems,
  isOfficialCalendarPath,
  officialCalendarGroups,
} from "../../discourse/lib/official-calendar";

module("ISBF | Unit | Lib | official-activities", function () {
  test("both official list paths use the layout while other feeds keep their summaries", function (assert) {
    const official = "/c/official/6/l/latest";
    for (const path of [
      "/c/official/6",
      official,
      "/c/official/6/l/top?period=monthly#topic",
    ]) {
      assert.true(isOfficialCalendarPath(path, official), path);
    }
    for (const path of [
      "/latest",
      "/c/official/60/l/latest",
      "/c/general/7",
      "/t/topic/6",
      undefined,
    ]) {
      assert.false(isOfficialCalendarPath(path, official), String(path));
    }
  });

  const activity = {
    id: 8,
    revision: 2,
    title: "Campus briefing",
    schedule_kind: "event",
    starts_at: "2026-10-20T01:00:00Z",
    ends_at: "2026-10-20T02:00:00Z",
    all_day: false,
    location: "Lecture hall",
    organizer: "Student office",
    registration_deadline_id: 9,
  };
  const deadline = {
    id: 9,
    revision: 3,
    title: "Briefing registration",
    schedule_kind: "deadline",
    starts_at: "2026-10-18T03:00:00Z",
    ends_at: "2026-10-18T03:00:00Z",
    all_day: false,
  };

  test("editing an activity keeps its registration identity and separate time precision", function (assert) {
    const editor = calendarEditorItems([deadline, activity]);
    assert.strictEqual(
      editor.length,
      1,
      "the registration cutoff is edited within its activity"
    );
    assert.strictEqual(
      editor[0].registration_deadline.id,
      9,
      "the cutoff keeps its source ID"
    );
    assert.strictEqual(
      editor[0].registration_deadline.start,
      "2026-10-18T11:00",
      "the cutoff uses Beijing time"
    );
    const saved = calendarItemsFromEditor(editor);
    assert.strictEqual(
      saved[0].registration_deadline_index,
      1,
      "the payload links to the reordered cutoff"
    );
    assert.strictEqual(
      saved[1].revision,
      3,
      "editing retains the cutoff version"
    );
    assert.strictEqual(
      saved[0].location,
      activity.location,
      "the activity location is retained"
    );
    assert.strictEqual(
      saved[0].organizer,
      activity.organizer,
      "the organizer is retained"
    );
  });

  test("multiple activities pair only with their own cutoffs and standalone deadlines remain visible", function (assert) {
    const another = {
      ...activity,
      id: 10,
      title: "Workshop",
      registration_deadline_id: 11,
    };
    const cutoff = { ...deadline, id: 11, title: "Workshop registration" };
    const independent = { ...deadline, id: 12, title: "Submit application" };
    const source = [cutoff, activity, independent, another, deadline];
    const groups = officialCalendarGroups(source);
    assert.deepEqual(
      groups.map((group) => group.item.id),
      [8, 12, 10],
      "linked cutoffs appear only within their activities"
    );
    assert.deepEqual(
      groups.map((group) => group.deadline?.id ?? null),
      [9, null, 11],
      "each activity keeps the correct cutoff"
    );
    const saved = calendarItemsFromEditor(calendarEditorItems(source));
    assert.strictEqual(
      saved[0].registration_deadline_index,
      1,
      "the first activity points to its cutoff"
    );
    assert.strictEqual(
      saved[3].registration_deadline_index,
      4,
      "the second activity points to its own cutoff"
    );
    assert.strictEqual(
      saved[2].id,
      12,
      "the independent deadline remains a separate row"
    );
  });

  test("a new optional registration cutoff creates a date-only deadline", function (assert) {
    const saved = calendarItemsFromEditor([
      {
        title: "Workshop",
        schedule_kind: "event",
        all_day: false,
        start: "2026-10-20T09:00",
        end: "",
        location: " Room 101 ",
        organizer: " Student office ",
        has_registration_deadline: true,
        registration_deadline: { all_day: true, start: "2026-10-18" },
      },
    ]);
    assert.strictEqual(
      saved.length,
      2,
      "the activity and cutoff remain separately importable time items"
    );
    assert.strictEqual(
      saved[1].starts_at,
      "2026-10-17T16:00:00.000Z",
      "date-only registration begins at Beijing midnight"
    );
    assert.strictEqual(
      saved[1].ends_at,
      "2026-10-18T16:00:00.000Z",
      "the cutoff preserves the full day"
    );
    assert.strictEqual(
      saved[0].location,
      "Room 101",
      "display metadata is trimmed"
    );
    assert.strictEqual(
      saved[0].registration_deadline_index,
      1,
      "the new activity links to the new cutoff"
    );
  });

  test("clearing registration omits its cutoff while keeping the activity ID", function (assert) {
    const editor = calendarEditorItems([activity, deadline]);
    editor[0].has_registration_deadline = false;
    const saved = calendarItemsFromEditor(editor);
    assert.strictEqual(
      saved.length,
      1,
      "the cutoff is omitted for cancellation"
    );
    assert.strictEqual(
      saved[0].registration_deadline_index,
      null,
      "the relation is explicitly cleared"
    );
    assert.strictEqual(
      saved[0].id,
      activity.id,
      "the activity keeps its source ID"
    );
  });

  test("legacy deadlines remain independent and cancelled cutoffs cannot be paired", function (assert) {
    const legacy = { ...activity, registration_deadline_id: null };
    assert.strictEqual(
      officialCalendarGroups([legacy, deadline]).length,
      2,
      "legacy records are not automatically paired"
    );
    const cancelled = { ...deadline, cancelled: true };
    const saved = canonicalCalendarItems([activity, cancelled]);
    assert.strictEqual(saved.length, 1, "cancelled cutoffs are omitted");
    assert.strictEqual(
      saved[0].registration_deadline_index,
      null,
      "the removed cutoff is not referenced"
    );
  });
});
