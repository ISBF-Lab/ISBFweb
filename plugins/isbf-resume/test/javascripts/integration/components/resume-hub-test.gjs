import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ResumeHub from "discourse/plugins/isbf-resume/discourse/components/resume-hub";

module("Integration | Component | ResumeHub", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  test("opens the existing generator by default inside the two-section workspace", async function (assert) {
    await render(<template><ResumeHub /></template>);

    assert
      .dom(".isbf-resume-workspace__back")
      .hasText(
        i18n("isbf_resume.sharing.hub_title"),
        "the arrow and area title return to the workbench"
      );
    assert
      .dom(".isbf-resume-workspace__back")
      .hasAttribute(
        "href",
        "/isbf/workbench",
        "the area has one workbench back link"
      );
    assert
      .dom(".isbf-resume-workspace__navigation a")
      .exists({ count: 2 }, "the sidebar offers generation and sharing");
    assert
      .dom('.isbf-resume-workspace__navigation a[aria-current="page"]')
      .hasText(
        i18n("isbf_resume.sharing.generate_navigation"),
        "generation is selected initially"
      );
    assert
      .dom(
        '.isbf-resume-workspace__navigation a[href="/isbf/workbench/resume/shares"]'
      )
      .hasText(
        i18n("isbf_resume.sharing.share_navigation"),
        "sharing opens the public list"
      );
    assert
      .dom(".isbf-resume-workspace__content .isbf-resume__form")
      .exists("the original editor is immediately usable");
  });
});
