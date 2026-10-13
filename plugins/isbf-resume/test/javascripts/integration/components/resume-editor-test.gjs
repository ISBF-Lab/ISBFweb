import {
  click,
  fillIn,
  find,
  findAll,
  focus,
  render,
  triggerKeyEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import {
  disableClearA11yAnnouncementsInTests,
  enableClearA11yAnnouncementsInTests,
} from "discourse/services/a11y";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import ResumeEditor from "discourse/plugins/isbf-resume/discourse/components/resume-editor";

function stage(key) {
  return findAll('[role="tab"]').find(
    (tab) => tab.textContent.trim() === i18n(`isbf_resume.${key}`)
  );
}

function educationModule() {
  return findAll("summary")
    .find(
      (summary) =>
        summary.textContent.trim() ===
        i18n("isbf_resume.sections.education.label")
    )
    .closest("details");
}

async function confirmGeneration() {
  await click(".isbf-resume-confirmation .btn-primary");
}

async function fillRequired() {
  await formKit().field("basic.name").fillIn("张三");
  await fillIn('[data-name="basic.phone"] input', "+86 13800138000");
  await fillIn('[data-name="basic.email"] input', "user@example.com");
}

module("Integration | Component | ResumeEditor", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    disableClearA11yAnnouncementsInTests();
  });

  hooks.afterEach(function () {
    enableClearA11yAnnouncementsInTests();
  });

  test("typing and switching stages preview the current form values without submitting", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/exports.json", () => {
      requests++;
      return response({});
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    await formKit()
      .field("basic.highest_education")
      .fillIn("示例大学 · 软件工程 · 本科");
    await click(stage("preview"));

    assert
      .dom(".isbf-resume-draft")
      .includesText("张三", "renders the entered name on the preview stage");
    assert
      .dom(".isbf-resume-draft")
      .includesText("user@example.com", "renders the entered contact detail");
    assert
      .dom(".isbf-resume-draft")
      .includesText(
        "示例大学 · 软件工程 · 本科",
        "renders optional information"
      );
    assert.strictEqual(
      requests,
      0,
      "previewing does not submit a generation request"
    );
    await click(stage("content"));
    await formKit().field("basic.name").fillIn("李四");
    await fillIn('[data-name="basic.highest_education"] input', "");
    await click(stage("preview"));

    assert
      .dom(".isbf-resume-draft")
      .includesText("李四", "updates after an edit");
    assert
      .dom(".isbf-resume-draft")
      .doesNotIncludeText("张三", "does not retain the old name");
    assert
      .dom(".isbf-resume-draft")
      .doesNotIncludeText("示例大学", "removes cleared optional information");
    assert.strictEqual(
      requests,
      0,
      "changes remain local until confirmed generation"
    );
  });

  test("submission from another stage reveals missing required contact fields", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/exports.json", () => {
      requests++;
      return response({});
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await click(stage("preview"));
    await formKit().submit();

    assert.strictEqual(requests, 0, "does not send an incomplete resume");
    assert
      .dom(".isbf-resume-confirmation")
      .doesNotExist("validates before showing a confirmation");
    assert
      .dom(".isbf-resume")
      .hasAttribute(
        "data-stage",
        "content",
        "returns to the fields that need attention"
      );
    for (const name of ["name", "phone", "email"]) {
      assert
        .dom(`[data-name="basic.${name}"]`)
        .hasClass("has-error", `${name} has a nearby validation error`);
    }
  });

  test("invalid contact formats return to editing before either generation confirmation", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/exports.json", () => {
      requests++;
      return response({});
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    await fillIn('[data-name="basic.phone"] input', "invalid12345");
    await fillIn('[data-name="basic.email"] input', "name@example");
    await click(stage("templates"));
    await click(".isbf-resume__generate-english");

    assert.strictEqual(
      requests,
      0,
      "does not request generation for invalid contact details"
    );
    assert
      .dom(".isbf-resume-confirmation")
      .doesNotExist("does not skip contact checks for English generation");
    assert
      .dom(".isbf-resume")
      .hasAttribute("data-stage", "content", "reveals the fields to correct");
    assert
      .dom('[data-name="basic.phone"]')
      .hasClass("has-error", "flags the phone format");
    assert
      .dom('[data-name="basic.email"]')
      .hasClass("has-error", "flags the email format");
  });

  test("returning from the content warning preserves the draft and sends no generation request", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/exports.json", () => {
      requests++;
      return response({});
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    const trigger = find('.form-kit__actions button[type="submit"]');
    await focus(trigger);
    await formKit().submit();

    assert
      .dom(".isbf-resume-confirmation")
      .includesText(
        i18n("isbf_resume.generation_notice"),
        "explains the content review responsibility"
      );
    assert
      .dom(".isbf-resume-confirmation")
      .includesText(
        i18n("isbf_resume.frequency_notice"),
        "retains the requested short-period warning"
      );
    assert.strictEqual(
      requests,
      0,
      "waits for explicit confirmation before making the request"
    );
    await click(".isbf-resume-confirmation .btn-default");

    assert.strictEqual(requests, 0, "cancelling does not generate a file");
    assert
      .dom(trigger)
      .isFocused("returns keyboard focus to the generation control");
    assert
      .dom(".isbf-resume")
      .hasAttribute("data-stage", "content", "returns to editing");
    assert
      .dom('[data-name="basic.name"] input')
      .hasValue("张三", "preserves the entered name");
  });

  test("Escape closes the warning and returns keyboard focus without generating", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/exports.json", () => {
      requests++;
      return response({});
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    await focus(".isbf-resume__generate-english");
    await click(".isbf-resume__generate-english");
    await triggerKeyEvent(
      ".isbf-resume-confirmation .btn-primary",
      "keydown",
      "Escape"
    );

    assert.dom(".isbf-resume-confirmation").doesNotExist("closes the warning");
    assert.strictEqual(requests, 0, "Escape does not request a new file");
    assert
      .dom(".isbf-resume__generate-english")
      .isFocused("restores focus after the dialog closes");
    assert
      .dom('[data-name="basic.name"] input')
      .hasValue("张三", "keeps the draft after keyboard cancellation");
  });

  test("English generation allows returning to edit and preserves the submitted wording", async function (assert) {
    let submitted;
    pretender.post("/isbf-resume/exports.json", (request) => {
      submitted = JSON.parse(request.requestBody).resume;
      return response(201, {
        id: "english",
        pages: 1,
        docx_url: "/isbf-resume/exports/english/docx",
        pdf_url: "/isbf-resume/exports/english/pdf",
      });
    });
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    await focus(".isbf-resume__generate-english");
    await click(".isbf-resume__generate-english");

    assert
      .dom(".isbf-resume-confirmation")
      .includesText(
        i18n("isbf_resume.english_notice"),
        "warns that English content is not translated"
      );
    await click(".isbf-resume-confirmation .btn-default");
    assert.strictEqual(
      submitted,
      undefined,
      "returning to edit sends no request"
    );
    assert
      .dom(".isbf-resume__generate-english")
      .isFocused("returns keyboard focus to the English generation control");
    await click(".isbf-resume__generate-english");
    await confirmGeneration();

    assert.strictEqual(
      submitted.language,
      "en",
      "requests English document headings"
    );
    assert.strictEqual(
      submitted.basic.name,
      "张三",
      "does not translate the supplied text"
    );
    assert
      .dom(".isbf-resume")
      .hasAttribute("data-stage", "preview", "opens the actual preview stage");
    assert
      .dom(".isbf-resume__page-advice")
      .hasText(
        i18n("isbf_resume.page_advice"),
        "reminds the user about length and blank space"
      );
    assert
      .dom('a[href="/isbf-resume/exports/english/docx"]')
      .exists("offers the English document after generation");
  });

  test("removing the first education record keeps the second input and stable identity", async function (assert) {
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    const moduleElement = educationModule();
    await click(moduleElement.querySelector("summary"));
    await click(moduleElement.querySelector("button"));
    const firstInput = moduleElement.querySelector(
      '[data-name$=".school"] input'
    );
    await fillIn(firstInput, "第一所学校");
    await click([...moduleElement.querySelectorAll("button")].at(-1));
    const inputs = [
      ...moduleElement.querySelectorAll('[data-name$=".school"] input'),
    ];
    const remainingInputId = inputs[1].id;
    await fillIn(inputs[1], "第二所学校");
    await click(moduleElement.querySelector(".isbf-resume__entry button"));

    assert
      .dom(`[id="${remainingInputId}"]`)
      .hasValue(
        "第二所学校",
        "retains the surviving row's own value and input ID"
      );
    assert
      .dom(".isbf-resume__entry")
      .exists({ count: 1 }, "removes only the requested record");
  });

  test("the selected template reaches generation and later edits invalidate its downloads", async function (assert) {
    assert.timeout(120_000);
    let submitted;
    let pendingRequest;
    pretender.post(
      "/isbf-resume/exports.json",
      (request) => {
        pendingRequest = request;
        submitted = JSON.parse(request.requestBody).resume;
        return response(201, {
          id: "example",
          pages: 1,
          docx_url: "/isbf-resume/exports/example/docx",
          pdf_url: "/isbf-resume/exports/example/pdf",
        });
      },
      true
    );
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    await click(stage("templates"));
    await formKit().field("template").select("blue-gray");
    assert
      .dom(".isbf-resume")
      .hasAttribute(
        "data-stage",
        "templates",
        "selects the color in the template stage"
      );
    await formKit().submit();
    const generation = confirmGeneration();
    try {
      await waitUntil(
        () => pendingRequest && find('.isbf-resume__preview[aria-busy="true"]'),
        { timeout: 30_000 }
      );
      assert
        .dom(".isbf-resume")
        .hasAttribute(
          "data-stage",
          "preview",
          "opens preview while generation is running"
        );
      assert
        .dom(".isbf-resume__preview")
        .includesText(
          i18n("isbf_resume.generating_preview"),
          "explains that the actual preview is being generated"
        );
      assert
        .dom(".isbf-resume__paper")
        .doesNotExist(
          "does not display a template sample as the pending result"
        );
      assert
        .dom(".isbf-resume__downloads a[href]")
        .doesNotExist("withholds files while generation is running");
    } finally {
      if (pendingRequest) {
        pretender.resolve(pendingRequest);
      }
      await generation;
    }

    assert
      .dom(".isbf-resume")
      .hasAttribute(
        "data-stage",
        "preview",
        "shows the generated preview before editing again"
      );
    assert.strictEqual(
      submitted.template,
      "blue-gray",
      "submits the user's color choice"
    );
    assert.strictEqual(
      submitted.basic.name,
      "张三",
      "retains content while switching stages"
    );
    assert.strictEqual(
      submitted.language,
      "zh_CN",
      "the regular button generates Chinese headings"
    );
    assert
      .dom('a[href="/isbf-resume/exports/example/docx"]')
      .exists("offers the generated DOCX");
    await click(stage("content"));
    assert
      .dom(".isbf-resume")
      .hasAttribute("data-stage", "content", "returns to the editing stage");
    await formKit().field("basic.name").fillIn("张三四");
    await waitUntil(
      () =>
        find(".isbf-resume__form .form-kit__actions")?.textContent.includes(
          i18n("isbf_resume.stale")
        ),
      { timeout: 10_000 }
    );

    assert
      .dom(".isbf-resume")
      .hasAttribute(
        "data-stage",
        "content",
        "keeps the editing stage after the draft changes"
      );
    assert
      .dom('a[href="/isbf-resume/exports/example/docx"]')
      .doesNotExist("withdraws a download after the draft changes");
    assert
      .dom(".isbf-resume__form .form-kit__actions")
      .isVisible("shows the export status beside the generation control");
    assert
      .dom(".isbf-resume__form .form-kit__actions")
      .includesText(
        i18n("isbf_resume.stale"),
        "explains that the export needs to be updated"
      );
  });

  test("server field errors retain the draft and reveal their module for correction", async function (assert) {
    // Two confirmations and failed submissions redraw the full form.
    assert.timeout(240_000);
    pretender.post("/isbf-resume/exports.json", () =>
      response(422, {
        errors: ["请补充学校名称"],
        field_errors: { "education.0.school": "请补充学校名称" },
      })
    );
    await render(<template><ResumeEditor /><ModalContainer /></template>);
    await fillRequired();
    const moduleElement = educationModule();
    await click(moduleElement.querySelector("summary"));
    await click(moduleElement.querySelector("button"));
    const major = moduleElement.querySelector('[data-name$=".major"] input');
    const stableName = major
      .closest("[data-name]")
      .dataset.name.replace(/\.major$/, ".school");
    await fillIn(major, "计算机科学");
    await click(stage("templates"));
    await formKit().submit();
    await confirmGeneration();

    assert
      .dom(".isbf-resume")
      .hasAttribute(
        "data-stage",
        "content",
        "returns to editing on a generation error"
      );
    assert
      .dom(`[data-name="${stableName}"]`)
      .hasClass(
        "has-error",
        "associates the server error with the stable education row"
      );
    assert
      .dom(".form-kit__errors-summary-list a")
      .hasText(
        i18n("isbf_resume.fields.education.school.label"),
        "names the field in human-readable error feedback"
      );
    assert
      .dom(`[data-name="${stableName.replace(/\.school$/, ".major")}"] input`)
      .hasValue("计算机科学", "preserves the entered details");
    assert
      .dom(educationModule())
      .hasAttribute("open", "", "reveals the module containing the error");

    await click(educationModule().querySelector("summary"));
    assert
      .dom(educationModule())
      .doesNotHaveAttribute("open", "allows the user to collapse the module");
    await formKit().submit();
    await confirmGeneration();
    assert
      .dom(educationModule())
      .hasAttribute(
        "open",
        "",
        "reveals the field again when a retry returns the same error"
      );
  });
});
