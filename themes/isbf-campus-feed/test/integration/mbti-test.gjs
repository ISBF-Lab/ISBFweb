import { clearRender, click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DialogHolder from "discourse/dialog-holder/components/dialog-holder";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFMbti from "../../discourse/components/isbf-mbti";
import { MBTI_DRAFT_KEY } from "../../discourse/lib/mbti";

const questionnaires = [
  { variant: "28", question_count: 28, version: "isbf-1" },
  { variant: "40", question_count: 2, version: "isbf-1" },
  { variant: "93", question_count: 93, version: "isbf-1" },
];
const questionnaire = {
  variant: "40",
  question_count: 2,
  version: "isbf-1",
  questions: [
    {
      id: 1,
      question: "Which setting restores your energy?",
      options: ["Conversation", "Quiet reflection"],
    },
    {
      id: 2,
      question: "How do you prefer to plan?",
      options: ["A settled plan", "Flexible options"],
    },
  ],
};
const result = {
  id: 123,
  type: "INFP",
  variant: "40",
  version: "isbf-1",
  created_at: "2026-10-28T01:00:00Z",
  dimensions: ["EI", "SN", "TF", "JP"].map((key) => ({
    key,
    first: key[0],
    second: key[1],
    first_percent: 50,
    second_percent: 50,
    tied: true,
  })),
};

module("ISBF | Integration | Component | ISBFMbti", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.previousConfig = this.site.isbf_mbti;
    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    this.keyValueStore = this.owner.lookup("service:key-value-store");
    this.keyValueStore.remove(MBTI_DRAFT_KEY);
    pretender.get("/isbf/api/mbti/questionnaires.json", () =>
      response({ questionnaires })
    );
    pretender.get("/isbf/api/mbti/questionnaires/40.json", () =>
      response({ questionnaire })
    );
    pretender.get("/isbf/api/mbti/results.json", () =>
      response({ results: [result], page: 0, has_more: false })
    );
    pretender.get("/isbf/api/mbti/results/123.json", () =>
      response({ result })
    );
  });

  hooks.afterEach(function () {
    this.site.set("isbf_mbti", this.previousConfig);
    this.keyValueStore.remove(MBTI_DRAFT_KEY);
  });

  test("40 is the default and choices require manual navigation with previous answers retained", async function (assert) {
    await render(<template><ISBFMbti /></template>);
    assert
      .dom('[data-test-mbti-version="40"]')
      .hasAttribute(
        "aria-pressed",
        "true",
        "40 questions are recommended by default"
      );
    await click("[data-test-mbti-start]");
    assert
      .dom("[data-test-mbti-question]")
      .hasAttribute("data-question-id", "1", "the first question appears");
    assert
      .dom("[data-test-mbti-next]")
      .isDisabled("an unanswered question cannot advance");
    await click('[data-test-mbti-choice="2"]');
    assert
      .dom("[data-test-mbti-question]")
      .hasAttribute(
        "data-question-id",
        "1",
        "selecting an answer does not auto-advance"
      );
    await click("[data-test-mbti-next]");
    assert
      .dom("[data-test-mbti-question]")
      .hasAttribute("data-question-id", "2", "next advances one question");
    await click("[data-test-mbti-previous]");
    assert
      .dom('[data-test-mbti-choice="2"]')
      .isChecked("the previous answer remains selected");
  });

  test("leaving and returning resumes this device's same version and question", async function (assert) {
    await render(<template><ISBFMbti /></template>);
    await click("[data-test-mbti-start]");
    await click('[data-test-mbti-choice="1"]');
    await click("[data-test-mbti-next]");
    await clearRender();
    await render(<template><ISBFMbti /></template>);
    assert
      .dom("[data-test-mbti-resume]")
      .exists("unfinished progress has a resume action");
    await click("[data-test-mbti-resume]");
    assert
      .dom("[data-test-mbti-question]")
      .hasAttribute("data-question-id", "2", "the saved question is restored");
    await click("[data-test-mbti-previous]");
    assert
      .dom('[data-test-mbti-choice="1"]')
      .isChecked("answers survive the remount");
  });

  test("failed submission retains answers and attempt id until the saved result is returned", async function (assert) {
    const submissions = [];
    pretender.post("/isbf/api/mbti/results.json", (request) => {
      submissions.push(JSON.parse(request.requestBody));
      return submissions.length === 1
        ? [
            503,
            { "Content-Type": "application/json" },
            JSON.stringify({ errors: ["Temporary save failure"] }),
          ]
        : response({ result });
    });
    await render(<template><ISBFMbti /></template>);
    await click("[data-test-mbti-start]");
    await click('[data-test-mbti-choice="1"]');
    await click("[data-test-mbti-next]");
    await click('[data-test-mbti-choice="2"]');
    await click("[data-test-mbti-submit]");
    assert
      .dom('[data-test-mbti-choice="2"]')
      .isChecked("the failed submission retains its answers");
    assert
      .dom("[role=alert]")
      .includesText("Temporary save failure", "the save error is visible");
    await click("[data-test-mbti-submit]");
    assert.strictEqual(
      submissions[0].attempt_id,
      submissions[1].attempt_id,
      "retry uses the same idempotency key"
    );
    assert.deepEqual(
      submissions[1].answers,
      [
        { id: 1, choice: 1 },
        { id: 2, choice: 2 },
      ],
      "the complete unchanged answers reach the server"
    );
    assert
      .dom("[data-test-mbti-result]")
      .includesText(
        "INFP",
        "only the successful response switches to the result"
      );
    assert
      .dom(".isbf-mbti-result__dimensions > li")
      .exists({ count: 4 }, "all four dimensions are displayed");
    assert.strictEqual(
      this.keyValueStore.getObject(MBTI_DRAFT_KEY),
      undefined,
      "success clears the local answers"
    );
  });

  test("private history opens server result details without exposing an answer sheet", async function (assert) {
    await render(<template><ISBFMbti /></template>);
    await click("[data-test-mbti-history]");
    assert
      .dom("[data-test-mbti-history-item]")
      .exists({ count: 1 }, "the current user's history is rendered");
    await click("[data-test-mbti-history-item]");
    assert
      .dom("[data-test-mbti-result]")
      .includesText("INFP", "the selected result opens");
    assert
      .dom("[data-test-mbti-question]")
      .doesNotExist("private history does not restore raw answers");
  });

  test("a confirmation from the previous account cannot start another account's quiz", async function (assert) {
    const owner = this.currentUser.id;
    try {
      await render(<template><DialogHolder /><ISBFMbti /></template>);
      await click("[data-test-mbti-start]");
      await click('[data-test-mbti-choice="1"]');
      await click(".isbf-mbti__header > a");
      await click("[data-test-mbti-start]");
      assert.dom(".dialog-content").exists("restarting asks for confirmation");
      this.currentUser.set("id", owner + 1000);
      await settled();
      await click(".dialog-footer .btn-primary");
      assert
        .dom("[data-test-mbti-question]")
        .doesNotExist("the old confirmation cannot start a new owner's quiz");
      assert
        .dom("[data-test-mbti-intro]")
        .exists("the new account stays on its clean intro");
    } finally {
      await clearRender();
      this.currentUser.set("id", owner);
    }
  });

  test("a failed history page retries that page without duplicating already loaded results", async function (assert) {
    let secondPageAttempts = 0;
    pretender.get("/isbf/api/mbti/results.json", (request) => {
      if (request.queryParams.page === "1") {
        return ++secondPageAttempts === 1
          ? response(503, { errors: ["Temporary history failure"] })
          : response({
              results: [{ ...result, id: 124 }],
              page: 1,
              has_more: false,
            });
      }
      return response({ results: [result], page: 0, has_more: true });
    });
    await render(<template><ISBFMbti /></template>);
    await click("[data-test-mbti-history]");
    await click("[data-test-mbti-load-more]");
    assert
      .dom("[data-test-mbti-history-item]")
      .exists({ count: 1 }, "failure retains the loaded first page");
    await click("[data-test-mbti-retry]");
    assert.strictEqual(
      secondPageAttempts,
      2,
      "retry requests the failed second page"
    );
    assert
      .dom("[data-test-mbti-history-item]")
      .exists({ count: 2 }, "the new page is appended once");
    assert
      .dom('[data-result-id="123"]')
      .exists({ count: 1 }, "the first page is not duplicated");
  });

  test("failed draft cleanup is visible after a successful server save", async function (assert) {
    pretender.post("/isbf/api/mbti/results.json", () => response({ result }));
    await render(<template><ISBFMbti /></template>);
    await click("[data-test-mbti-start]");
    await click('[data-test-mbti-choice="1"]');
    await click("[data-test-mbti-next]");
    await click('[data-test-mbti-choice="2"]');
    const removal = sinon
      .stub(this.keyValueStore, "remove")
      .throws(new Error("Storage blocked"));
    try {
      await click("[data-test-mbti-submit]");
      assert
        .dom("[data-test-mbti-result]")
        .exists("the saved server result remains available");
      assert
        .dom("[data-test-mbti-storage-warning]")
        .exists("the browser cleanup failure is disclosed");
    } finally {
      removal.restore();
    }
  });
});
