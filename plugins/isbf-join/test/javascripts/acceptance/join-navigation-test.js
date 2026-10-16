import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import sinon from "sinon";
import DiscourseURL from "discourse/lib/url";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("ISBF join | Standalone navigation", function (needs) {
  needs.mobileView();
  needs.settings({ login_required: true });

  needs.hooks.beforeEach(function () {
    this.redirect = sinon.stub(DiscourseURL, "redirectTo");
  });

  needs.hooks.afterEach(function () {
    this.redirect.restore();
  });

  test("anonymous mobile client navigation loads the public document for both entry URLs", async function (assert) {
    await visit("/login");

    for (const path of ["/join", "/join/"]) {
      await visit(path).catch((error) => {
        if (error.message !== "TransitionAborted") {
          throw error;
        }
      });

      assert.true(
        this.redirect.calledOnceWithExactly("/join/"),
        `${path} loads the standalone document instead of a forum error page`
      );
      this.redirect.resetHistory();
    }
  });
});
