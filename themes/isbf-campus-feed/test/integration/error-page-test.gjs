import {
  clearRender,
  click,
  find,
  render,
  settled,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { themePrefix } from "virtual:theme";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ISBFErrorPage from "../../discourse/components/isbf-error-page";
import ErrorConnector from "../../discourse/connectors/exception-wrapper/isbf-error-page";

async function renderError(context) {
  const { controller } = context;
  await render(
    <template><ISBFErrorPage @controller={{controller}} /></template>
  );
}

module("ISBF | Integration | Error page", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.controller = this.owner.lookup("controller:exception");
    this.exception = this.owner.lookup("service:exception");
    this.exception.thrown = {
      status: 403,
      requestedUrl: "/admin/users/1.json",
    };
    this.retry = sinon.spy();
    this.exception.lastTransition = { retry: this.retry };
  });

  test("permission errors hide the failed request until details are expanded", async function (assert) {
    await renderError(this);

    assert.dom(".isbf-error-page").hasAttribute("data-error-status", "403");
    assert
      .dom(".isbf-error-page__title")
      .hasText(i18n("errors.reasons.forbidden"));
    assert.dom(".isbf-error-page__details").doesNotExist();
    assert.dom(".isbf-error-page .btn-primary").exists({ count: 1 });
    assert
      .dom(".isbf-error-page__details-toggle")
      .hasAttribute("aria-expanded", "false");

    await click(".isbf-error-page__details-toggle");
    const toggle = find(".isbf-error-page__details-toggle");
    assert
      .dom(".isbf-error-page__details")
      .hasAttribute("id", toggle.getAttribute("aria-controls"));
    assert.dom(".isbf-error-page__details code").hasText("/admin/users/1.json");
    assert.dom(toggle).hasAttribute("aria-expanded", "true");

    await click(".isbf-error-page__details-toggle");
    assert.dom(".isbf-error-page__details").doesNotExist();
  });

  test("server errors display their actual status and a useful recovery message", async function (assert) {
    this.exception.thrown = { status: 503 };
    await renderError(this);

    assert.dom(".isbf-error-page").hasAttribute("data-error-status", "503");
    assert
      .dom(".isbf-error-page__description")
      .hasText(i18n(themePrefix("error_page.server_description")));

    this.exception.thrown = {
      status: 500,
      desc: "The report is being rebuilt.",
    };
    await settled();
    assert.dom(".isbf-error-page").hasAttribute("data-error-status", "500");
    assert
      .dom(".isbf-error-page__description")
      .hasText("The report is being rebuilt.");
  });

  test("offline, timeout and unknown errors use text instead of a fabricated status", async function (assert) {
    this.exception.thrown = { status: 0, readyState: 0 };
    await renderError(this);
    assert
      .dom(".isbf-error-page__fallback")
      .hasText(i18n(themePrefix("error_page.offline")));

    this.exception.thrown = { jqTextStatus: "timeout" };
    await settled();
    assert
      .dom(".isbf-error-page__fallback")
      .hasText(i18n(themePrefix("error_page.offline")));

    this.exception.thrown = new Error("Failed to load");
    await settled();
    assert
      .dom(".isbf-error-page__fallback")
      .hasText(i18n(themePrefix("error_page.unknown")));
  });

  test("details escape request text and reset for the next error", async function (assert) {
    this.exception.thrown = {
      status: 403,
      requestedUrl: "<img src=x onerror=alert(1)>",
    };
    await renderError(this);
    await click(".isbf-error-page__details-toggle");
    assert
      .dom(".isbf-error-page__details code")
      .hasText("<img src=x onerror=alert(1)>");
    assert.dom(".isbf-error-page__details img").doesNotExist();

    this.exception.thrown = { status: 503 };
    await settled();
    assert.dom(".isbf-error-page__details").doesNotExist();
  });

  test("retry uses the original transition", async function (assert) {
    await renderError(this);
    await click(".isbf-error-page__primary");
    assert.true(this.retry.calledOnce);
    assert.false(this.controller.loading);
  });

  test("leaving the error page releases its full-screen state and animation", async function (assert) {
    await renderError(this);
    await waitUntil(() =>
      find(".isbf-error-page__stage").classList.contains("--enhanced")
    );
    const stage = find(".isbf-error-page__stage");
    assert.true(document.body.classList.contains("isbf-error-page-active"));

    await clearRender();
    assert.false(document.body.classList.contains("isbf-error-page-active"));
    assert.false(stage.classList.contains("--enhanced"));
  });

  test("special permission content and existing 404 pages keep their original outlet", async function (assert) {
    const errorContext = { controller: this.controller };
    this.exception.thrown = {
      status: 403,
      responseJSON: { extras: { html: "group permission content" } },
    };
    await render(
      <template>
        <ErrorConnector @outletArgs={{errorContext}}><p
            class="original-error"
          >Original permission content</p></ErrorConnector>
      </template>
    );
    assert.dom(".original-error").exists();
    assert.dom(".isbf-error-page").doesNotExist();

    this.exception.thrown = { status: 404 };
    await settled();
    assert.dom(".original-error").exists();

    this.exception.thrown = { status: 403 };
    await settled();
    assert.dom(".original-error").doesNotExist();
    assert.dom(".isbf-error-page").exists();
  });
});
