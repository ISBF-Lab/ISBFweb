import { click, findAll, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";
import ResumeShareList from "discourse/plugins/isbf-resume/discourse/components/resume-share-list";

module("Integration | Component | ResumeShareList", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.model = {
      shares: [
        {
          id: 1,
          title: "Finance analyst resume",
          description: "Banking role, three years of experience",
          status: "approved",
        },
      ],
      can_submit: true,
      can_review: false,
      can_load_more: false,
      page: 1,
    };
  });

  test("shows file titles and descriptions with the upload link in the header", async function (assert) {
    await render(
      <template>
        <ResumeShareList @list="published" @model={{this.model}} />
      </template>
    );

    assert
      .dom(".isbf-resume-share-list__file h2 a")
      .hasText(this.model.shares[0].title, "the file title opens its details");
    assert
      .dom(".isbf-resume-share-list__file h2 a")
      .hasAttribute(
        "href",
        "/isbf/workbench/resume/shares/1",
        "details have their own route"
      );
    assert
      .dom(".isbf-resume-share-list__description")
      .hasText(
        this.model.shares[0].description,
        "the reviewed summary is visible in the file list"
      );
    assert
      .dom(".isbf-resume-sharing-header .isbf-resume-share-list__upload")
      .hasAttribute(
        "href",
        "/isbf/workbench/resume/shares/new",
        "the header exposes personal sharing"
      );
    assert
      .dom(".isbf-resume-share-list__navigation")
      .doesNotExist("public sharing has no duplicate tabs or review entry");
    assert
      .dom(".isbf-resume-share-list__status")
      .doesNotExist("published files need no approval label");
    assert
      .dom(".isbf-resume__intro")
      .doesNotExist("the public list has no promotional explanation");
    assert
      .dom(".isbf-resume-share-list__actions .btn-primary")
      .exists(
        { count: 2 },
        "my submissions and upload use matching primary actions"
      );
  });

  test("loads the next page and appends it without duplicating the first page", async function (assert) {
    this.model.can_load_more = true;
    let parameters;
    pretender.get("/isbf-resume/shares.json", (request) => {
      parameters = request.queryParams;
      return response({
        shares: [
          {
            id: 2,
            title: "Engineering resume",
            description: "Engineering summary",
            status: "approved",
          },
        ],
        can_load_more: false,
        page: 2,
      });
    });
    await render(
      <template>
        <ResumeShareList @list="published" @model={{this.model}} />
      </template>
    );

    await click(
      findAll("button").find(
        (button) =>
          button.textContent.trim() === i18n("isbf_resume.sharing.load_more")
      )
    );

    assert.strictEqual(parameters.page, "2", "requests the next page");
    assert.strictEqual(
      parameters.list,
      "published",
      "keeps the public-list filter"
    );
    assert
      .dom(".isbf-resume-share-list__file")
      .exists({ count: 2 }, "renders each page once");
    assert
      .dom('h2 a[href="/isbf/workbench/resume/shares/1"]')
      .exists({ count: 1 }, "retains the first result exactly once");
    assert
      .dom('h2 a[href="/isbf/workbench/resume/shares/2"]')
      .hasText("Engineering resume", "appends the next result");
    assert
      .dom("button")
      .doesNotExist("removes the loader when the server has no more results");
  });
});
