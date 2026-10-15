import { find, render, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import ResumeShareUpload from "discourse/plugins/isbf-resume/discourse/components/resume-share-upload";

async function selectFile(file) {
  const transfer = new DataTransfer();
  transfer.items.add(file);
  find('input[type="file"]').files = transfer.files;
  await triggerEvent('input[type="file"]', "change");
}

module("Integration | Component | ResumeShareUpload", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  test("sends the PDF binary and blank optional details after explicit free-sharing consent", async function (assert) {
    const contents = "%PDF-1.7\nclient upload bytes\n%%EOF";
    const file = new File([contents], "My resume.pdf", {
      type: "application/pdf",
    });
    let body;
    let destination;
    this.owner.lookup("service:router").transitionTo = (...args) => {
      destination = args;
    };
    pretender.post("/isbf-resume/shares.json", (request) => {
      body = request.requestBody;
      return response(201, { id: 42, status: "pending" });
    });
    await render(<template><ResumeShareUpload /></template>);

    assert
      .dom('input[type="file"]')
      .hasAttribute(
        "accept",
        "application/pdf,.pdf",
        "the picker offers PDF files"
      );
    await selectFile(file);
    await formKit().field("consent").toggle();
    await formKit().submit();

    assert.true(body instanceof FormData, "submits multipart form data");
    assert.deepEqual(
      destination,
      ["isbfResumeShares.show", 42],
      "opens the submitted resume after upload"
    );
    const submittedFile = body.get("shared_resume[file]");
    assert.true(
      submittedFile instanceof File,
      "preserves the uploaded PDF as a binary file"
    );
    assert.strictEqual(
      submittedFile.name,
      file.name,
      "preserves the original filename"
    );
    assert.strictEqual(
      await submittedFile.text(),
      contents,
      "transports the actual file bytes"
    );
    assert.strictEqual(
      body.get("shared_resume[consent]"),
      "true",
      "records explicit sharing consent"
    );
    for (const field of [
      "title",
      "industry",
      "position",
      "salary",
      "experience",
      "description",
    ]) {
      assert.strictEqual(
        body.get(`shared_resume[${field}]`),
        "",
        `${field} remains optional and submits as blank`
      );
      assert
        .form()
        .field(field)
        .hasNoErrors(`${field} does not block the upload`);
    }
  });

  test("requires PDF selection and consent while keeping descriptive fields optional", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/shares.json", () => {
      requests++;
      return response({ id: 42 });
    });
    await render(<template><ResumeShareUpload /></template>);

    await formKit().submit();

    assert.strictEqual(
      requests,
      0,
      "does not upload without a file and consent"
    );
    assert
      .form()
      .field("file")
      .hasError(i18n("form_kit.errors.required"), "a PDF is required");
    assert
      .form()
      .field("consent")
      .hasError(
        i18n("form_kit.errors.not_accepted"),
        "free public sharing requires consent"
      );
    const describedBy = find('input[type="file"]')
      .getAttribute("aria-describedby")
      .split(" ");
    assert.true(
      describedBy.includes("isbf-resume-sharing-pdf-help"),
      "the file control retains its format and size instructions"
    );
    assert.true(
      describedBy.includes(find('[data-name="file"] .form-kit__errors').id),
      "the missing-PDF error is associated with the file control"
    );
    assert.form().field("salary").hasNoErrors("salary remains optional");
    assert
      .form()
      .field("description")
      .hasNoErrors("uploader description remains optional");
  });

  test("rejects non-PDF, empty and oversized files before a request", async function (assert) {
    let requests = 0;
    pretender.post("/isbf-resume/shares.json", () => {
      requests++;
      return response({ id: 42 });
    });
    await render(<template><ResumeShareUpload /></template>);
    await formKit().field("consent").toggle();
    const invalidFiles = [
      new File(["document"], "resume.docx"),
      new File([], "empty.pdf", { type: "application/pdf" }),
      new File([new Uint8Array(10 * 1024 * 1024 + 1)], "large.pdf", {
        type: "application/pdf",
      }),
    ];

    for (const file of invalidFiles) {
      await selectFile(file);
      assert
        .dom(".isbf-resume-share-upload")
        .includesText(
          i18n(
            file.size > 10 * 1024 * 1024
              ? "isbf_resume.sharing.pdf_too_large"
              : "isbf_resume.sharing.invalid_pdf"
          ),
          `${file.name} has an explanatory error`
        );
      assert
        .dom('input[type="file"]')
        .hasValue("", `${file.name} is cleared from the picker`);
      await formKit().submit();
    }

    assert.strictEqual(
      requests,
      0,
      "invalid selections never create a submission"
    );
  });
});
