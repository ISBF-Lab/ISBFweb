import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ISBFAlumni from "../../discourse/components/isbf-alumni";
import ISBFLearning from "../../discourse/components/isbf-learning";
import ISBFMarketplace from "../../discourse/components/isbf-marketplace";
import { initialize } from "../../discourse/initializers/isbf-back-navigation";

module("ISBF | Integration | Service | isbf-back-navigation", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.owner.unregister("service:isbf-back-navigation");
    this.stateStub = sinon.stub(window.history, "state").get(() => ({
      uuid: "current-page",
    }));
    this.backStub = sinon.stub(window.history, "back");
    this.owner.lookup("service:session-store").setObject({
      key: "isbfBackNavigation",
      value: {
        entries: [
          { uuid: "source-page", url: "/search?q=campus" },
          { uuid: "current-page", url: "/isbf/marketplace" },
        ],
      },
    });
  });

  hooks.afterEach(function () {
    this.backStub.restore();
    this.stateStub.restore();
    this.owner.lookup("service:session-store").remove("isbfBackNavigation");
  });

  test("the marketplace arrow returns to its source through browser history", async function (assert) {
    initialize(this.owner.__container__, this.owner);
    await render(<template><ISBFMarketplace /></template>);
    assert
      .dom(".isbf-marketplace__header a")
      .hasAttribute(
        "href",
        "/search?q=campus",
        "the source is the return link"
      );
    assert
      .dom(".isbf-marketplace__header a")
      .hasAttribute(
        "aria-label",
        i18n("back_button"),
        "the label describes back"
      );
    await click(".isbf-marketplace__header a");
    assert.true(
      this.backStub.calledOnce,
      "the click traverses browser history"
    );
  });

  test("directly opened functional pages retain their workbench fallback", async function (assert) {
    this.owner.lookup("service:session-store").remove("isbfBackNavigation");
    initialize(this.owner.__container__, this.owner);
    await render(<template><ISBFMarketplace /></template>);
    assert
      .dom(".isbf-marketplace__header a")
      .hasAttribute(
        "href",
        "/isbf/workbench",
        "marketplace falls back to workbench"
      );
    await render(<template><ISBFLearning /></template>);
    assert
      .dom(".isbf-learning__back")
      .hasAttribute(
        "href",
        "/isbf/workbench",
        "learning falls back to workbench"
      );
    await render(<template><ISBFAlumni /></template>);
    assert
      .dom(".isbf-alumni__back")
      .hasAttribute(
        "href",
        "/isbf/workbench",
        "alumni falls back to workbench"
      );
    const navigation = this.owner.lookup("service:isbf-back-navigation");
    assert.strictEqual(
      navigation.href("/latest"),
      "/latest",
      "page headers fall back to home"
    );
  });

  test("modified clicks retain ordinary link behavior", function (assert) {
    initialize(this.owner.__container__, this.owner);
    const navigation = this.owner.lookup("service:isbf-back-navigation");
    const preventDefault = sinon.spy();
    for (const modifier of ["ctrlKey", "metaKey", "shiftKey", "altKey"]) {
      navigation.back({ [modifier]: true, preventDefault });
    }
    navigation.back({ button: 1, preventDefault });
    assert.false(
      this.backStub.called,
      "modified clicks do not move this tab's history"
    );
    assert.false(
      preventDefault.called,
      "the link's default behavior is retained"
    );
  });
});
