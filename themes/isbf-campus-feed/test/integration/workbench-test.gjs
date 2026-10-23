import {
  clearRender,
  find,
  findAll,
  render,
  triggerEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ISBFV2Workbench from "../../discourse/components/isbf-v2-workbench";

module("ISBF | Integration | Component | ISBFV2Workbench", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.site.setProperties({
      isbf_learning: null,
      isbf_library: null,
      isbf_careers: null,
      isbf_teamup: null,
      isbf_marketplace: null,
      isbf_alumni: null,
    });
    this.siteSettings.isbf_resume_enabled = false;
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  test("unavailable services stay noninteractive and alumni follows its configuration", async function (assert) {
    await render(<template><ISBFV2Workbench /></template>);

    assert
      .dom(".isbf-v2-workbench__card")
      .exists({ count: 9 }, "only the configured alumni entry is omitted");
    assert
      .dom("a.isbf-v2-workbench__card")
      .doesNotExist(
        "unavailable services have no navigation or extra focus target"
      );
    assert
      .dom('[data-service="teamup"] .isbf-v2-workbench__name')
      .doesNotIncludeText(
        "translation missing",
        "the new entry has a translated name"
      );
  });

  test("available services keep their order and real destinations", async function (assert) {
    this.site.setProperties({
      isbf_learning: { category_id: 7, grades: [{ id: 1, label: "Grade 1" }] },
      isbf_library: {
        category_id: 10,
        link_sharing: true,
        catalog_requests: true,
      },
      isbf_careers: { category_id: 11, enabled: true, version: 1 },
      isbf_teamup: { category_id: 9, enabled: true, version: 1 },
      isbf_marketplace: { category_id: 8, private_images: true, version: 1 },
      isbf_alumni: { enabled: true, countries: [] },
    });
    this.siteSettings.isbf_resume_enabled = true;

    await render(<template><ISBFV2Workbench /></template>);

    assert.deepEqual(
      findAll(".isbf-v2-workbench__card").map((card) => card.dataset.service),
      [
        "learning_resources",
        "library",
        "courses",
        "careers",
        "resume",
        "campus_services",
        "student_identity",
        "alumni",
        "marketplace",
        "teamup",
      ],
      "the original ten-entry order is retained"
    );
    assert.deepEqual(
      findAll("a.isbf-v2-workbench__card").map((card) =>
        card.getAttribute("href")
      ),
      [
        "/isbf/learning",
        "/isbf/library",
        "/isbf/careers",
        "/isbf/workbench/resume",
        "/isbf/alumni",
        "/isbf/marketplace",
        "/isbf/teamup",
      ],
      "the seven available services retain native links"
    );
    assert
      .dom('[data-service="courses"]')
      .doesNotHaveAttribute("href", "future services remain placeholders");
  });

  test("hover feedback stops for reduced motion and after unmounting", async function (assert) {
    this.site.isbf_learning = { category_id: 7, grades: [] };
    const matchMedia = window.matchMedia.bind(window);
    const media = matchMedia("(prefers-reduced-motion: reduce)");
    let reduced = false;
    sinon.stub(media, "matches").get(() => reduced);
    sinon
      .stub(window, "matchMedia")
      .callsFake((query) =>
        query === "(prefers-reduced-motion: reduce)" ? media : matchMedia(query)
      );
    const cancel = sinon.spy();
    const animate = sinon
      .stub(Element.prototype, "animate")
      .returns({ cancel });

    await render(<template><ISBFV2Workbench /></template>);
    const card = find('[data-service="learning_resources"]');
    await triggerEvent(card, "pointerover", { pointerType: "mouse" });
    assert.true(
      animate.calledOnce,
      "a mouse entering an available card starts feedback"
    );

    reduced = true;
    media.dispatchEvent(new Event("change"));
    assert.true(
      cancel.calledOnce,
      "enabling reduced motion cancels active feedback"
    );
    await triggerEvent(card, "pointerover", { pointerType: "mouse" });
    assert.true(
      animate.calledOnce,
      "reduced motion prevents another animation"
    );

    reduced = false;
    await triggerEvent(card, "pointerover", { pointerType: "mouse" });
    await clearRender();
    assert.strictEqual(
      cancel.callCount,
      2,
      "unmounting cancels remaining feedback"
    );
    await triggerEvent(card, "pointerover", { pointerType: "mouse" });
    assert.true(
      animate.calledTwice,
      "the detached card no longer has a listener"
    );
  });
});
