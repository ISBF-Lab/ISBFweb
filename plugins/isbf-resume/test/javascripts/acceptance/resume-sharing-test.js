import {
  click,
  currentURL,
  fillIn,
  find,
  triggerEvent,
  visit,
} from "@ember/test-helpers";
import { test } from "qunit";
import getURL from "discourse/lib/get-url";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Resume sharing route", function (needs) {
  needs.user({ admin: true, moderator: false });
  needs.settings({ isbf_resume_enabled: true });
  needs.pretender((server, helper) => {
    server.get("/isbf-resume/collection.json", () =>
      helper.response({
        can_submit: true,
        collection_url: "https://f.wps.cn/g/yhH9i8lN/",
      })
    );
    const uploadedShare = {
      id: 43,
      title: "Uploaded PDF resume",
      status: "pending",
      submitted_description: "",
      description: "",
      pdf_url: "/isbf-resume/shares/43/pdf",
      preview_urls: [],
      can_review: false,
    };
    server.post("/isbf-resume/shares.json", () =>
      helper.response(201, uploadedShare)
    );
    server.get("/isbf-resume/shares/43.json", () =>
      helper.response(uploadedShare)
    );
    server.get("/isbf-resume/shares.json", () =>
      helper.response({
        shares: [
          {
            id: 42,
            title: "Published PDF resume",
            description: "Description from the published route model",
          },
        ],
        can_load_more: false,
        can_submit: true,
        can_review: false,
        page: 1,
      })
    );
  });

  test("starts with public sharing and switches to generation", async function (assert) {
    await visit("/isbf/workbench/resume");
    assert
      .dom('.isbf-resume-workspace__navigation a[aria-current="page"]')
      .hasText(
        i18n("isbf_resume.sharing.share_navigation"),
        "sharing is the default section"
      );
    assert
      .dom(".isbf-resume-share-list__navigation")
      .doesNotExist("review and redundant sharing tabs are absent");
    await click(
      '.isbf-resume-workspace__navigation a[href="/isbf/workbench/resume/generate"]'
    );
    assert.strictEqual(
      currentURL(),
      "/isbf/workbench/resume/generate",
      "the sidebar enters generation"
    );
    assert
      .dom('.isbf-resume-workspace__navigation a[aria-current="page"]')
      .hasText(
        i18n("isbf_resume.sharing.generate_navigation"),
        "generation is selected"
      );
    assert
      .dom(".isbf-resume-workspace__content .isbf-resume__form")
      .exists("the existing editor is mounted");
  });

  test("loads the shared resume route model and displays the header upload link", async function (assert) {
    await visit("/isbf/workbench/resume/shares");

    assert.strictEqual(
      currentURL(),
      "/isbf/workbench/resume/shares",
      "the member reaches the published sharing route"
    );
    assert
      .dom(".isbf-resume-share-list__file h2 a")
      .hasText(
        "Published PDF resume",
        "the route model supplies the file title"
      );
    assert
      .dom(".isbf-resume-share-list__description")
      .hasText(
        "Description from the published route model",
        "the route model supplies the public description"
      );
    assert
      .dom(".isbf-resume-sharing-header .isbf-resume-share-list__upload")
      .hasAttribute(
        "href",
        getURL("/isbf/workbench/resume/shares/new"),
        "the header exposes the upload route when the server allows submission"
      );
    assert
      .dom(".isbf-resume-sharing-header .isbf-resume-share-list__upload")
      .hasText(
        i18n("isbf_resume.sharing.upload"),
        "the upload link is translated"
      );
  });

  test("opens uploaded resume details after submitting without an unsaved changes dialog", async function (assert) {
    await visit("/isbf/workbench/resume/shares/new");
    const transfer = new DataTransfer();
    transfer.items.add(
      new File(["%PDF-1.7\nclient upload bytes\n%%EOF"], "shared-resume.pdf", {
        type: "application/pdf",
      })
    );
    find('input[type="file"]').files = transfer.files;
    await triggerEvent('input[type="file"]', "change");
    await fillIn(
      '[data-name="download_url"] input',
      "https://365.kdocs.cn/l/document"
    );
    await formKit().field("consent").toggle();
    await formKit().submit();

    assert.strictEqual(
      currentURL(),
      "/isbf/workbench/resume/shares/43",
      "successful submission enters the new resume's details route"
    );
    assert
      .dom(".isbf-resume-share-details .isbf-resume-sharing-header h1")
      .hasText(
        "Uploaded PDF resume",
        "the submitted resume details are loaded"
      );
    assert
      .dom(".isbf-resume-share-details__status")
      .hasText(
        i18n("isbf_resume.sharing.statuses.pending"),
        "the new upload remains pending review"
      );
    assert
      .dom(".dialog-container")
      .isNotVisible(
        "successful submission does not prompt to discard saved data"
      );
  });
});
