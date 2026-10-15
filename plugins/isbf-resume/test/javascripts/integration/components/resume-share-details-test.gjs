import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ResumeShareDetails from "discourse/plugins/isbf-resume/discourse/components/resume-share-details";

module("Integration | Component | ResumeShareDetails", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.share = {
      id: 42,
      title: "Finance analyst resume",
      description: "Reviewed summary",
      status: "approved",
      pdf_url: "/isbf-resume/shares/42/pdf",
      preview_urls: [
        "/isbf-resume/shares/42/previews/1",
        "/isbf-resume/shares/42/previews/2",
      ],
    };
  });

  test("shows the reviewed description with image previews and PDF download for a forum member", async function (assert) {
    await render(
      <template><ResumeShareDetails @share={{this.share}} /></template>
    );

    assert
      .dom(".isbf-resume-sharing-header h1")
      .hasText(this.share.title, "uses the resume title");
    assert
      .dom(".isbf-resume-share-details__description")
      .hasText(this.share.description, "uses the approved summary");
    assert
      .dom('.isbf-resume-sharing-header a[href="/isbf-resume/shares/42/pdf"]')
      .exists("offers the PDF download")
      .hasAttribute(
        "data-auto-route",
        "false",
        "downloads the PDF without routing it through the SPA"
      );
    assert
      .dom(".isbf-resume-share-details__preview img")
      .exists({ count: 1 }, "loads one preview page at a time");
    assert
      .dom('img[src="/isbf-resume/shares/42/previews/1"]')
      .hasAttribute(
        "loading",
        "lazy",
        "loads the preview through the authorized endpoint"
      );
    assert
      .dom(".isbf-resume-share-review-form")
      .doesNotExist("ordinary members have no review form");
    assert
      .dom(".isbf-resume-share-details__reviews")
      .doesNotExist("ordinary payloads expose no private review history");
  });

  test("keeps moderation in the review center when an authorized payload includes audit history", async function (assert) {
    this.share.reviews = [
      {
        id: 1,
        reviewer_name: "Reviewer's recorded name",
        reviewer_username: "recorded_reviewer",
        decision: "approve",
        created_at: "2026-10-14T12:00:00Z",
        original_description: "Original uploader text",
        description: "Edited reviewer text",
      },
    ];
    await render(
      <template><ResumeShareDetails @share={{this.share}} /></template>
    );

    assert
      .dom(".isbf-resume-share-details__reviews")
      .doesNotExist(
        "review history stays in the review center even for a reviewer"
      );
    assert
      .dom(".isbf-resume-share-review-form")
      .doesNotExist("the shared file page contains no review controls");
    assert
      .dom(".isbf-resume-share-details__status")
      .doesNotExist("approved files do not repeat their approval status");
  });
});
