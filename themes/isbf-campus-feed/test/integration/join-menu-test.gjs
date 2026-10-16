import { click, findAll, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { themePrefix } from "virtual:theme";
import DiscourseURL from "discourse/lib/url";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ISBFV2UtilityActions from "../../discourse/components/isbf-v2-utility-actions";

module(
  "ISBF | Integration | Component | ISBFV2UtilityActions | Join",
  function (hooks) {
    setupRenderingTest(hooks, { anonymous: true, stubRouter: true });

    hooks.beforeEach(function () {
      this.redirect = sinon.stub(DiscourseURL, "redirectTo");
      this.menu = { close: sinon.stub().resolves() };
    });

    hooks.afterEach(function () {
      this.redirect.restore();
    });

    test("the existing fourth action closes the menu and opens the public join page", async function (assert) {
      await render(
        <template><ISBFV2UtilityActions @menu={{this.menu}} /></template>
      );

      assert
        .dom(".isbf-v2-more-menu__item")
        .exists({ count: 4 }, "all four existing menu items remain");
      assert.deepEqual(
        findAll(".isbf-v2-more-menu__item").map((button) =>
          button.textContent.trim()
        ),
        ["sidebar_settings", "appearance", "feedback", "join_us"].map((key) =>
          i18n(themePrefix(`isbf_v2.${key}`))
        ),
        "the menu labels retain their original order"
      );

      await click(".dropdown-menu__item:nth-child(4) button");

      assert.true(this.menu.close.calledOnce, "the menu is dismissed");
      assert.true(
        this.redirect.calledOnceWithExactly("/join/"),
        "anonymous visitors receive a full-page redirect"
      );
      assert.true(
        this.redirect.calledAfter(this.menu.close),
        "navigation follows menu dismissal"
      );
    });
  }
);
