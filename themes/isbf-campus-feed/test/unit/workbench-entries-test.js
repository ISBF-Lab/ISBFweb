import { module, test } from "qunit";
import {
  mergeWorkbenchEntries,
  WORKBENCH_ENTRIES,
} from "../../discourse/lib/workbench-entries";

const DEFAULT_KEYS = [
  "learning_resources",
  "library",
  "courses",
  "careers",
  "resume",
  "campus_services",
  "student_identity",
  "alumni",
  "marketplace",
  "teamup",
  "mbti",
  "ai_assistant",
  "guides",
];
const keys = (entries) => entries.map((entry) => entry.key);

module("ISBF | Unit | workbench entries", function () {
  test("old, empty, and invalid settings retain the original entries and appearance", function (assert) {
    for (const value of [undefined, null, [], "[]", {}, false, 12]) {
      const entries = mergeWorkbenchEntries(value);
      assert.deepEqual(keys(entries), DEFAULT_KEYS);
      assert.deepEqual(
        entries,
        WORKBENCH_ENTRIES.map((entry) => ({ ...entry, paletteTone: "" }))
      );
      assert.true(entries.every((entry) => entry.paletteTone === ""));
    }
    assert.strictEqual(mergeWorkbenchEntries().at(-1).key, "guides");
  });

  test("saved order is applied and omitted entries are appended in their original order", function (assert) {
    const entries = mergeWorkbenchEntries([
      { key: "guides" },
      { key: "resume" },
      { key: "library" },
    ]);
    assert.deepEqual(keys(entries), [
      "guides",
      "resume",
      "library",
      ...DEFAULT_KEYS.filter(
        (key) => !["guides", "resume", "library"].includes(key)
      ),
    ]);
  });

  test("the first duplicate wins and unknown or malformed entries are ignored", function (assert) {
    const entries = mergeWorkbenchEntries([
      null,
      false,
      12,
      "library",
      {},
      { key: "unknown", icon: "heart", tone: "amber" },
      { key: "library", icon: "missing", tone: "invalid" },
      { key: "library", icon: "heart", tone: "amber" },
      { key: "guides" },
    ]);
    assert.deepEqual(keys(entries), [
      "library",
      "guides",
      ...DEFAULT_KEYS.filter((key) => !["library", "guides"].includes(key)),
    ]);
    assert.strictEqual(entries[0].icon, "isbf-workbench-database");
    assert.strictEqual(entries[0].tone, "indigo");
    assert.strictEqual(entries[0].paletteTone, "");
  });

  test("a known icon replaces both original icon variants", function (assert) {
    const entries = mergeWorkbenchEntries(
      [{ key: "library", icon: " heart " }],
      (id) => id === "heart"
    );
    assert.strictEqual(entries[0].icon, "heart");
    assert.strictEqual(entries[0].mobileIcon, "heart");
  });

  test("cleared, unavailable, and invalid icons restore each entry's original variants", function (assert) {
    for (const icon of [undefined, null, "", " ", "missing", 12, {}]) {
      const [entry] = mergeWorkbenchEntries([{ key: "library", icon }]);
      assert.strictEqual(entry.icon, "isbf-workbench-database");
      assert.strictEqual(entry.mobileIcon, "database");
    }
    const [guide] = mergeWorkbenchEntries([{ key: "guides", icon: null }]);
    assert.strictEqual(guide.icon, "isbf-workbench-guides");
    assert.strictEqual(guide.mobileIcon, "isbf-workbench-guides");
  });

  test("supported palettes are explicit while default and invalid tones retain original colors", function (assert) {
    for (const tone of ["theme", "mint", "amber", "violet"]) {
      const [entry] = mergeWorkbenchEntries([{ key: "library", tone }]);
      assert.strictEqual(entry.paletteTone, tone);
      assert.strictEqual(entry.tone, tone);
    }
    for (const tone of [undefined, null, "", "default", "invalid", {}, 12]) {
      const [entry] = mergeWorkbenchEntries([{ key: "library", tone }]);
      assert.strictEqual(entry.paletteTone, "");
      assert.strictEqual(entry.tone, "indigo");
    }
  });

  test("visibility filtering preserves a disabled feature's configured position and appearance", function (assert) {
    const configuration = [
      { key: "library" },
      { key: "mbti", icon: "heart", tone: "mint" },
      { key: "guides" },
    ];
    const allEntries = mergeWorkbenchEntries(
      configuration,
      (id) => id === "heart"
    );
    const visible = allEntries.filter((entry) => entry.key !== "mbti");
    assert.deepEqual(keys(visible).slice(0, 2), ["library", "guides"]);

    const restored = mergeWorkbenchEntries(
      configuration,
      (id) => id === "heart"
    );
    assert.deepEqual(keys(restored).slice(0, 3), ["library", "mbti", "guides"]);
    assert.strictEqual(restored[1].icon, "heart");
    assert.strictEqual(restored[1].mobileIcon, "heart");
    assert.strictEqual(restored[1].paletteTone, "mint");
  });

  test("merging does not mutate saved settings or share mutable returned objects", function (assert) {
    const configured = Object.freeze({ key: "library", tone: "mint" });
    const configuration = Object.freeze([configured]);
    const entries = mergeWorkbenchEntries(configuration);
    entries[0].icon = "changed";
    entries.at(-1).tone = "changed";

    assert.deepEqual(configuration, [{ key: "library", tone: "mint" }]);
    assert.strictEqual(
      mergeWorkbenchEntries(configuration)[0].icon,
      "isbf-workbench-database"
    );
    assert.strictEqual(mergeWorkbenchEntries().at(-1).tone, "blue");
  });
});
