import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import {
  emptyResume,
  exportPayload,
  fieldPath,
} from "discourse/plugins/isbf-resume/discourse/lib/resume-data";

module("Unit | Lib | resume-data", function (hooks) {
  setupTest(hooks);

  test("export preserves entered content and excludes editing metadata", function (assert) {
    const draft = emptyResume();
    const details = "  完成 20% 增长\n第二行保留空格  ";
    draft.basic = {
      name: "张三",
      phone: "+86 12345",
      email: "user@example.com",
    };
    draft.experience = {
      entry_alpha: {
        company: "示例公司",
        details,
        localNote: "private UI state",
      },
    };
    draft.localNote = "private UI state";

    const payload = exportPayload(draft);

    assert.strictEqual(
      payload.experience[0].details,
      details,
      "does not rewrite or trim user content"
    );
    assert.deepEqual(
      Object.keys(payload.experience[0]).sort(),
      ["company", "details"],
      "only document fields reach the generator"
    );
    assert.false(
      "localNote" in payload,
      "omits editor-only metadata at the top level"
    );
    assert.strictEqual(
      draft.experience.entry_alpha.details,
      details,
      "leaves the draft intact"
    );
  });

  test("removing an earlier row preserves the remaining row and error association", function (assert) {
    const draft = emptyResume();
    draft.education = {
      entry_first: { school: "第一所学校" },
      entry_second: { school: "第二所学校", major: "计算机" },
      entry_third: { school: "第三所学校" },
    };
    delete draft.education.entry_first;

    assert.deepEqual(
      exportPayload(draft).education.map((entry) => entry.school),
      ["第二所学校", "第三所学校"],
      "retains the entered order after a deletion"
    );
    assert.strictEqual(
      fieldPath("education.0.major", draft),
      "education.entry_second.major",
      "maps the server array index to the surviving stable row"
    );
    assert.strictEqual(
      fieldPath("education.1.school", draft),
      "education.entry_third.school",
      "keeps the next error attached to its own row"
    );
  });

  test("switching the document color keeps all entered fields unchanged", function (assert) {
    const draft = emptyResume();
    draft.basic = { name: "张三", email: "user@example.com" };
    draft.projects = {
      entry_project: { name: "作品集", details: "按原文输出" },
    };
    const gold = exportPayload(draft);
    draft.template = "blue-gray";
    const gray = exportPayload(draft);

    assert.strictEqual(
      gray.template,
      "blue-gray",
      "selects the second palette"
    );
    assert.deepEqual(
      { ...gray, template: gold.template },
      gold,
      "the palette is the only export difference"
    );
  });
});
