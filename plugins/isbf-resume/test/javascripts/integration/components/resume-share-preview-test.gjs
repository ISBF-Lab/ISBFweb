import { click, render, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ResumeSharePreview from "discourse/plugins/isbf-resume/discourse/components/resume-share-preview";

module("Integration | Component | ResumeSharePreview", function (hooks) {
  setupRenderingTest(hooks);

  test("loads one page, navigates within bounds and offers retry after a preview error", async function (assert) {
    const urls = [
      "/isbf-resume/shares/42/previews/1",
      "/isbf-resume/shares/42/previews/2",
    ];
    await render(<template><ResumeSharePreview @urls={{urls}} /></template>);

    assert
      .dom("img")
      .exists({ count: 1 }, "only the selected page is requested");
    assert.dom("img").hasAttribute("src", urls[0], "starts on the first page");
    await triggerEvent("img", "load");
    assert
      .dom(".isbf-resume-share-preview__controls button:first-child")
      .isDisabled("cannot go before the first page");
    await click(".isbf-resume-share-preview__controls button:last-child");
    assert
      .dom("img")
      .hasAttribute(
        "src",
        urls[1],
        "the next page has its own protected request"
      );
    await triggerEvent("img", "error", { bubbles: false });
    assert
      .dom(".isbf-resume-share-preview > button")
      .exists("a failed preview can be retried");
    assert
      .dom(".isbf-resume-share-preview__controls button:last-child")
      .isDisabled("cannot go beyond the final page");
    await click(".isbf-resume-share-preview > button");
    assert
      .dom("img")
      .hasAttribute(
        "src",
        `${urls[1]}?retry=1`,
        "retry requests the same page again"
      );
    await triggerEvent("img", "load");
    assert
      .dom(".isbf-resume-share-preview > button")
      .doesNotExist("the retry message clears after success");
    await click(".isbf-resume-share-preview__controls button:first-child");
    assert
      .dom("img")
      .hasAttribute(
        "src",
        `${urls[0]}?retry=1`,
        "the previous page remains accessible"
      );
  });
});
