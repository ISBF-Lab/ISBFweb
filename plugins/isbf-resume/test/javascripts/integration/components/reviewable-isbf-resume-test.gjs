import { click, find, render, waitUntil } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ReviewableIsbfResume from "discourse/plugins/isbf-resume/discourse/components/reviewable-isbf-resume";

module("Integration | Component | ReviewableIsbfResume", function (hooks) {
  setupRenderingTest(hooks);

  test("shows the PDF and recorded review snapshots inside the review center", async function (assert) {
    this.reviewable = {
      can_edit: false,
      can_edit_resume: true,
      payload: { description: "Reviewed summary" },
      shared_resume: {
        id: 42,
        status: "approved",
        title: "Shared PDF resume",
        submitted_description: "Uploader's original description",
        pdf_url: "/isbf-resume/shares/42/pdf",
        preview_urls: ["/isbf-resume/shares/42/previews/1"],
        reviews: [
          {
            id: 1,
            reviewer_name: "Recorded reviewer name",
            reviewer_username: "reviewer",
            created_at: "2026-10-15T00:00:00Z",
            original_description: "Uploader's original description",
            description: "Reviewed summary",
          },
        ],
      },
    };
    await render(
      <template>
        <ReviewableIsbfResume @reviewable={{this.reviewable}} />
      </template>
    );
    assert
      .dom(".isbf-resume-review")
      .includesText(
        this.reviewable.shared_resume.title,
        "the queue identifies the submission"
      );
    assert
      .dom(".isbf-resume-review")
      .includesText(
        this.reviewable.shared_resume.submitted_description,
        "the original description remains available to reviewers"
      );
    assert
      .dom(".isbf-resume-review")
      .includesText(
        this.reviewable.payload.description,
        "the published description is shown"
      );
    assert
      .dom(".isbf-resume-review")
      .includesText(
        this.reviewable.shared_resume.reviews[0].reviewer_name,
        "the recorded reviewer name is visible"
      );
    assert
      .dom(".isbf-resume-review time")
      .hasAttribute(
        "datetime",
        this.reviewable.shared_resume.reviews[0].created_at,
        "the review time is preserved"
      );
    assert
      .dom('.isbf-resume-review a[href="/isbf-resume/shares/42/pdf"]')
      .hasAttribute(
        "data-auto-route",
        "false",
        "PDF download bypasses application routing"
      );
    assert
      .dom(".isbf-resume-review > button")
      .hasText(
        i18n("isbf_resume.sharing.edit_details"),
        "approved entries expose editing to reviewers"
      );
    assert
      .dom(".isbf-resume-review details img")
      .doesNotExist("a collapsed review does not request a preview");
    await click(".isbf-resume-review details summary");
    await waitUntil(() => find(".isbf-resume-review details img"));
    assert
      .dom(".isbf-resume-review details img")
      .hasAttribute(
        "src",
        this.reviewable.shared_resume.preview_urls[0],
        "reviewers can expand the protected PDF preview"
      );
    await click(".isbf-resume-review details summary");
    await waitUntil(() => !find(".isbf-resume-review details img"));
    assert
      .dom(".isbf-resume-review details img")
      .doesNotExist("closing the preview removes its image");
  });
});
