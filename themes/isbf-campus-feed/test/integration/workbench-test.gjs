import { getOwner } from "@ember/owner";
import { findAll, render, settled, waitFor } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { settings } from "virtual:theme";
import { addExtraSpriteSymbols } from "discourse/lib/svg-sprite-loader";
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
    this.previousWorkbenchEntries = settings.workbench_entries;
    settings.workbench_entries = [];
    this.previousGuidesEnabled = this.siteSettings.isbf_guides_enabled;
    this.previousAssistant = getOwner(this).lookup(
      "service:current-user"
    ).forum_assistant;
    getOwner(this).lookup("service:current-user").set("forum_assistant", null);
    this.site.setProperties(configuration);
    this.siteSettings.isbf_resume_enabled = true;
    this.siteSettings.isbf_guides_enabled = false;
  });

  hooks.afterEach(function () {
    this.contextStub.restore();
    this.site.setProperties(this.previousConfiguration);
    this.siteSettings.isbf_resume_enabled = this.previousResumeEnabled;
    settings.workbench_entries = this.previousWorkbenchEntries;
    this.siteSettings.isbf_guides_enabled = this.previousGuidesEnabled;
    getOwner(this)
      .lookup("service:current-user")
      .set("forum_assistant", this.previousAssistant);
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

  test("Guides remains last when MBTI is available and respects its feature flag", async function (assert) {
    this.siteSettings.isbf_guides_enabled = true;
    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    await render(<template><ISBFV2Workbench /></template>);

    const cards = findAll("[data-workbench-key]");
    assert.strictEqual(cards.at(-1).dataset.workbenchKey, "guides");
    assert.dom('[data-workbench-key="guides"]').hasAttribute("href", "/guides");
    assert
      .dom('[data-workbench-key="mbti"]')
      .hasAttribute("href", "/isbf/mbti");

    this.siteSettings.isbf_guides_enabled = false;
    await settled();
    assert.dom('[data-workbench-key="guides"]').doesNotExist();
    assert.strictEqual(
      findAll("[data-workbench-key]").at(-1).dataset.workbenchKey,
      "mbti"
    );
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

  test("the configured forum assistant opens the existing conversation page before guides", async function (assert) {
    const user = getOwner(this).lookup("service:current-user");
    user.set("forum_assistant", {
      enabled: true,
      configured: true,
      can_ask: false,
    });
    this.siteSettings.isbf_guides_enabled = true;
    await render(<template><ISBFV2Workbench /></template>);
    assert
      .dom('[data-workbench-key="ai_assistant"]')
      .hasAttribute("href", "/discourse-ai/ai-bot/conversations");
    assert
      .dom(".isbf-workbench-grid__item:last-child")
      .hasAttribute("data-workbench-key", "guides");
    assert
      .dom(".isbf-workbench-grid__item:nth-last-child(2)")
      .hasAttribute("data-workbench-key", "ai_assistant");
  });

  test("an unconfigured assistant has no workbench entry", async function (assert) {
    getOwner(this)
      .lookup("service:current-user")
      .set("forum_assistant", { enabled: true, configured: false });
    await render(<template><ISBFV2Workbench /></template>);
    assert.dom('[data-workbench-key="ai_assistant"]').doesNotExist();
  });

  test("saved order, icons, palettes and real links remain attached to their keys", async function (assert) {
    settings.workbench_entries = [
      { key: "resume", icon: "heart", tone: "mint" },
      { key: "library", icon: "not-an-icon", tone: "amber" },
      { key: "resume", icon: "star", tone: "violet" },
      { key: "unknown" },
    ];
    await render(<template><ISBFV2Workbench /></template>);
    assert.deepEqual(
      findAll("[data-workbench-key]")
        .slice(0, 3)
        .map((item) => item.dataset.workbenchKey),
      ["resume", "library", "learning_resources"]
    );
    assert
      .dom('[data-workbench-key="resume"]')
      .hasAttribute("href", "/isbf/workbench/resume");
    assert
      .dom('[data-workbench-key="resume"]')
      .hasAttribute("data-workbench-palette", "mint");
    assert
      .dom('[data-workbench-key="resume"] .isbf-workbench-grid__glyph use')
      .hasAttribute("href", "#heart");
    assert
      .dom(
        '[data-workbench-key="resume"] .isbf-workbench-grid__mobile-icon use'
      )
      .hasAttribute("href", "#heart");
    assert
      .dom('[data-workbench-key="library"]')
      .hasAttribute("href", "/isbf/library");
    assert
      .dom('[data-workbench-key="library"]')
      .hasAttribute("data-workbench-palette", "amber");
    assert
      .dom(
        '[data-workbench-key="library"] .isbf-workbench-grid__mobile-icon use'
      )
      .hasAttribute("href", "#database");
    assert.dom('[data-workbench-key="unknown"]').doesNotExist();
  });

  test("capabilities are checked after merging so re-enabled entries return to their configured positions", async function (assert) {
    settings.workbench_entries = [
      { key: "library" },
      { key: "mbti", icon: "heart", tone: "violet" },
      { key: "guides" },
    ];
    this.siteSettings.isbf_guides_enabled = true;
    await render(<template><ISBFV2Workbench /></template>);
    assert.dom('[data-workbench-key="mbti"]').doesNotExist();
    assert.deepEqual(
      findAll("[data-workbench-key]")
        .slice(0, 2)
        .map((item) => item.dataset.workbenchKey),
      ["library", "guides"]
    );
    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    await settled();
    assert.deepEqual(
      findAll("[data-workbench-key]")
        .slice(0, 3)
        .map((item) => item.dataset.workbenchKey),
      ["library", "mbti", "guides"]
    );
    assert
      .dom('[data-workbench-key="mbti"]')
      .hasAttribute("data-workbench-palette", "violet");
    assert
      .dom('[data-workbench-key="mbti"] .isbf-workbench-grid__glyph use')
      .hasAttribute("href", "#heart");
    this.site.set("isbf_mbti", null);
    await settled();
    this.site.set("isbf_mbti", { enabled: true, path: "/isbf/mbti" });
    await settled();
    assert
      .dom(".isbf-workbench-grid__item:nth-child(2)")
      .hasAttribute("data-workbench-key", "mbti");
  });

  test("a saved icon replaces the fallback as soon as the sprite arrives", async function (assert) {
    const icon = "isbf-test-late-workbench-icon";
    const card = '[data-workbench-key="resume"]';
    const mobileIcon = `${card} .isbf-workbench-grid__mobile-icon use`;
    const glyph = `${card} .isbf-workbench-grid__glyph use`;
    settings.workbench_entries = [{ key: "resume", icon }];

    await render(<template><ISBFV2Workbench /></template>);
    assert.dom(mobileIcon).hasAttribute("href", "#file-lines");

    addExtraSpriteSymbols([{ id: icon, symbol: `<symbol id="${icon}" />` }]);
    try {
      await waitFor(`${glyph}[href="#${icon}"]`);
      assert.dom(glyph).hasAttribute("href", `#${icon}`);
      assert.dom(mobileIcon).hasAttribute("href", `#${icon}`);
      assert.dom(card).hasAttribute("href", "/isbf/workbench/resume");
    } finally {
      document.getElementById(icon)?.remove();
    }
  });
});
