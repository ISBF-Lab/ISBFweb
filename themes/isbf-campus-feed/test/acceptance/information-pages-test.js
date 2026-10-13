import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import staticFixtures from "discourse/tests/fixtures/static-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("ISBF | Information pages", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    for (const page of [
      "guidelines",
      "faq",
      "tos",
      "privacy",
      "rules",
      "conduct",
    ]) {
      server.get(`/${page}.html`, () => [
        200,
        { "Content-Type": "text/html" },
        staticFixtures["faq.html"],
      ]);
    }
    server.post("/isbf/views/impressions", () => helper.response({}));
  });

  for (const page of [
    "guidelines",
    "faq",
    "about",
    "tos",
    "privacy",
    "rules",
    "conduct",
  ]) {
    test(`/${page} keeps its content in the V2 shell`, async function (assert) {
      await visit(`/${page}`);

      assert
        .dom(".isbf-v2-shell--information")
        .exists("the information page uses the V2 shell");
      assert.dom(".isbf-v2-side").exists("the shared navigation is present");
      assert
        .dom(".isbf-v2-page-header > span")
        .hasText(
          i18n(page === "about" ? "about.simple_title" : page),
          "the page header uses the existing translated title"
        );
      assert.dom(".body-page").exists("Core still renders the page content");
      assert
        .dom(".body-page .nav-pills")
        .exists("the existing page navigation remains available");
      assert
        .dom(".isbf-v2-page-header__back")
        .hasAttribute("href", "/latest", "the page has a shared return link");
      assert
        .dom(".isbf-v2-compose")
        .doesNotExist("the feed composer does not cover the information page");
    });
  }

  test("guidelines links and the return button keep the shared navigation", async function (assert) {
    await visit("/latest");
    await visit("/guidelines");
    await click('.body-page .nav-pills a[href="/tos"]');

    assert
      .dom(".isbf-v2-page-header > span")
      .hasText(i18n("tos"), "the terms page retains the V2 header");
    assert
      .dom(".body-page")
      .exists("the terms content remains accessible after navigation");

    await click(".isbf-v2-page-header__back");

    assert
      .dom(".isbf-v2-shell--feed")
      .exists("the return button opens the V2 feed");
    assert
      .dom(".isbf-v2-shell--information")
      .doesNotExist("the information page state is cleared");
  });

  test("guidelines with a query, fragment, or trailing slash retain the shell", async function (assert) {
    for (const path of [
      "/guidelines?from=home",
      "/guidelines#be-civil",
      "/guidelines/",
    ]) {
      await visit(path);

      assert
        .dom(".isbf-v2-shell--information")
        .exists(`${path} keeps the information page shell`);
      assert
        .dom(".isbf-v2-page-header > span")
        .hasText(i18n("guidelines"), `${path} keeps the guidelines title`);
      assert
        .dom(".body-page #be-civil")
        .exists(`${path} retains the original content anchors`);
    }
  });

  test("guidelines remain local when FAQ has an external URL", async function (assert) {
    this.siteSettings.faq_url = "https://example.com/faq";
    await visit("/guidelines");

    assert
      .dom(".isbf-v2-shell--information")
      .exists("guidelines still use the local information page shell");
    assert.dom(".body-page").exists("the local guidelines content remains");
  });
});

acceptance("ISBF | Information pages | Login required", function (needs) {
  needs.settings({ login_required: true });

  test("login retains its existing interface", async function (assert) {
    await visit("/login");

    assert.dom(".login-fullpage").exists("the login form remains available");
    assert
      .dom(".isbf-v2-shell")
      .doesNotExist("the information page shell does not replace login");
  });
});
