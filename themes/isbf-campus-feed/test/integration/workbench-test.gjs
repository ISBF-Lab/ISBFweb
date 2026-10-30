import { findAll, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFV2Workbench from "../../discourse/components/isbf-v2-workbench";

module("ISBF | Integration | Component | ISBFV2Workbench", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  let geometryStyle;
  hooks.before(function () {
    // Theme QUnit omits theme CSS; retain the canvas's normal out-of-flow layout.
    geometryStyle = document.createElement("style");
    geometryStyle.textContent =
      ".isbf-workbench-grid__items { position: relative; } .isbf-workbench-grid__canvas { position: absolute; }";
    document.head.append(geometryStyle);
  });
  hooks.after(function () {
    geometryStyle.remove();
  });

  hooks.beforeEach(function () {
    const getContext = HTMLCanvasElement.prototype.getContext;
    this.contextStub = sinon
      .stub(HTMLCanvasElement.prototype, "getContext")
      .callsFake(function (type, ...args) {
        return type === "webgl2" ? null : getContext.call(this, type, ...args);
      });
    const configuration = {
      isbf_learning: { category_id: 1, grades: [] },
      isbf_library: {
        category_id: 2,
        link_sharing: true,
        catalog_requests: true,
      },
      isbf_careers: { category_id: 3, enabled: true, version: 1 },
      isbf_marketplace: { category_id: 4, private_images: true, version: 1 },
      isbf_teamup: { category_id: 5, enabled: true, version: 1 },
      isbf_alumni: { enabled: true, countries: [] },
      isbf_mbti: null,
    };
    this.previousConfiguration = Object.fromEntries(
      Object.keys(configuration).map((name) => [name, this.site[name]])
    );
    this.previousResumeEnabled = this.siteSettings.isbf_resume_enabled;
    this.site.setProperties(configuration);
    this.siteSettings.isbf_resume_enabled = true;
  });

  hooks.afterEach(function () {
    this.contextStub.restore();
    this.site.setProperties(this.previousConfiguration);
    this.siteSettings.isbf_resume_enabled = this.previousResumeEnabled;
  });

  test("the new presentation preserves real links and non-interactive placeholders", async function (assert) {
    await render(<template><ISBFV2Workbench /></template>);
    assert.dom(".isbf-workbench-grid__item").exists({ count: 10 });
    for (const [key, href] of Object.entries({
      learning_resources: "/isbf/learning",
      library: "/isbf/library",
      careers: "/isbf/careers",
      resume: "/isbf/workbench/resume",
      alumni: "/isbf/alumni",
      marketplace: "/isbf/marketplace",
      teamup: "/isbf/teamup",
    })) {
      assert.dom(`[data-workbench-key="${key}"]`).hasAttribute("href", href);
    }
    for (const key of ["courses", "campus_services", "student_identity"]) {
      assert.dom(`[data-workbench-key="${key}"]`).hasTagName("div");
      assert
        .dom(`[data-workbench-key="${key}"]`)
        .doesNotHaveAttribute("tabindex");
    }
    assert.dom(".isbf-workbench-grid.has-webgl").doesNotExist();
    assert
      .dom(
        '[data-workbench-key="learning_resources"] .isbf-workbench-grid__label'
      )
      .hasStyle({ opacity: "1" });
  });

  test("MBTI is appended only when its plugin capability is enabled", async function (assert) {
    await render(<template><ISBFV2Workbench /></template>);
    assert
      .dom('[data-workbench-key="mbti"]')
      .doesNotExist("a missing capability creates no dead link");

    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    await settled();
    const cards = findAll("[data-workbench-key]");
    assert.strictEqual(
      cards.at(-1).dataset.workbenchKey,
      "mbti",
      "the existing entry order is retained when the capability arrives"
    );
    assert
      .dom('[data-workbench-key="mbti"]')
      .hasAttribute("href", "/isbf/mbti", "the new card opens its real route");

    this.site.set("isbf_mbti", { enabled: false, path: "/isbf/mbti" });
    await settled();
    assert
      .dom('[data-workbench-key="mbti"]')
      .doesNotExist("disabling the capability removes its existing card");

    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    await settled();
    assert
      .dom('[data-workbench-key="mbti"]')
      .exists({ count: 1 }, "re-enabling restores exactly one card");

    this.site.set("isbf_mbti", null);
    await settled();
    assert
      .dom('[data-workbench-key="mbti"]')
      .doesNotExist("removing the capability removes its existing card");
  });

  test("disabled services keep their existing visibility and placeholder rules", async function (assert) {
    this.site.setProperties({
      isbf_alumni: null,
      isbf_learning: null,
      isbf_library: null,
      isbf_careers: null,
      isbf_marketplace: null,
      isbf_teamup: null,
    });
    this.siteSettings.isbf_resume_enabled = false;
    await render(<template><ISBFV2Workbench /></template>);
    assert.dom(".isbf-workbench-grid__item").exists({ count: 9 });
    assert.dom('[data-workbench-key="alumni"]').doesNotExist();
    assert.dom("a.isbf-workbench-grid__item").doesNotExist();
  });

  test("entry names belong to the glass face and decorative copy is removed", async function (assert) {
    await render(<template><ISBFV2Workbench /></template>);
    assert
      .dom(".isbf-workbench-grid__face > .isbf-workbench-grid__label")
      .exists({ count: 10 });
    assert.dom(".isbf-workbench-grid__face[aria-hidden]").doesNotExist();
    assert
      .dom(".isbf-workbench-grid__mobile-icon[aria-hidden=true]")
      .exists({ count: 10 });
    assert
      .dom(
        ".isbf-v2-workbench__heading-dot, .isbf-v2-workbench__signature, .isbf-v2-workbench__caption, .isbf-v2-workbench__heading p, .isbf-v2-workbench__mobile-brand"
      )
      .doesNotExist();
  });
});
