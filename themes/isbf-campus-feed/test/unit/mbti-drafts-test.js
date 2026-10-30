import { module, test } from "qunit";
import KeyValueStore from "discourse/lib/key-value-store";
import {
  clearForeignMbtiDrafts,
  MBTI_DRAFT_KEY,
  readMbtiDrafts,
  saveMbtiDrafts,
} from "../../discourse/lib/mbti";

const meta = [{ variant: "40", version: "isbf-1", question_count: 40 }];
const draft = {
  variant: "40",
  version: "isbf-1",
  attempt_id: "6e7de90b-57de-4170-9ee0-3707f51b643c",
  index: 1,
  answers: { 1: 2 },
};

module("ISBF | Unit | MBTI drafts", function (hooks) {
  let store;
  hooks.beforeEach(function () {
    store = new KeyValueStore("mbti-unit_");
    store.abandonLocal();
  });
  hooks.afterEach(function () {
    store.abandonLocal();
  });

  test("resumes a matching account and questionnaire and clears foreign account data", function (assert) {
    saveMbtiDrafts(store, 12, { 40: draft });
    assert.deepEqual(
      readMbtiDrafts(store, 12, meta).drafts[40],
      draft,
      "matching progress is restored"
    );
    clearForeignMbtiDrafts(store, 13);
    assert.strictEqual(
      store.getObject(MBTI_DRAFT_KEY),
      undefined,
      "account switch removes the old owner's answers"
    );
    assert.deepEqual(
      readMbtiDrafts(store, 13, meta).drafts,
      {},
      "another account cannot restore the draft"
    );
  });

  test("rejects stale banks, invalid answer values and invalid attempt ids", function (assert) {
    for (const change of [
      { version: "old-bank" },
      { answers: { 1: 3 } },
      { index: 40 },
      { attempt_id: "not-an-attempt" },
    ]) {
      saveMbtiDrafts(store, 12, { 40: { ...draft, ...change } });
      const restored = readMbtiDrafts(store, 12, meta);
      assert.deepEqual(restored.drafts, {}, "invalid progress is not resumed");
      assert.true(restored.stale, "the UI can explain why it must restart");
    }
  });

  test("storage failure allows in-memory answering and logout clears the saved entry", function (assert) {
    const unavailable = {
      set() {
        return false;
      },
    };
    assert.false(
      saveMbtiDrafts(unavailable, 12, { 40: draft }),
      "unavailable storage is reported without throwing"
    );
    saveMbtiDrafts(store, 12, { 40: draft });
    store.abandonLocal();
    assert.deepEqual(
      readMbtiDrafts(store, 12, meta).drafts,
      {},
      "the native logout cleanup removes progress"
    );
  });
});
