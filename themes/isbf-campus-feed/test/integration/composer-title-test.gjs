import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import Composer from "discourse/models/composer";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ISBFV2ComposerTitle from "../../discourse/components/isbf-v2-composer-title";
import { setOptionalTopicTitle } from "../../discourse/lib/optional-topic-title";

module(
  "ISBF | Integration | Component | ISBFV2ComposerTitle",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.siteSettings.min_topic_title_length = 6;
      this.siteSettings.min_first_post_length = 8;
      this.model = this.owner.lookup("service:store").createRecord("composer", {
        user: this.currentUser,
        action: Composer.CREATE_TOPIC,
        categoryId: this.site.categories[0].id,
        reply: "A complete announcement body.",
      });
      this.composer = this.owner.lookup("service:composer");
      this.composer.set("model", this.model);
      this.outletArgs = { model: this.model };
    });

    test("publishing a short title shows the required length and correcting it clears the error", async function (assert) {
      setOptionalTopicTitle(this.model, "校园新公告");
      await render(
        <template>
          <div class="isbf-v2-shell">
            <ISBFV2ComposerTitle @outletArgs={{this.outletArgs}} />
            <DButton
              class="publish-announcement"
              @action={{this.composer.saveAction}}
              @label="composer.create_topic"
            />
          </div>
        </template>
      );

      assert
        .dom(".isbf-v2-composer-title .popup-tip")
        .isNotVisible("the error is hidden before publishing");
      await click(".publish-announcement");
      assert
        .dom(".isbf-v2-composer-title .popup-tip")
        .isVisible("publishing reveals the title error")
        .hasAttribute("role", "alert", "the error is accessible")
        .hasText(
          i18n("composer.error.title_too_short", { count: 6 }),
          "the error explains the required title length"
        );

      await fillIn("#isbf-optional-title", "校园活动公告");
      assert
        .dom(".isbf-v2-composer-title .popup-tip")
        .isNotVisible("a valid title clears the error");
    });

    test("leaving an optional title empty clears a previous length error", async function (assert) {
      setOptionalTopicTitle(this.model, "校园新公告");
      await render(
        <template>
          <div class="isbf-v2-shell">
            <ISBFV2ComposerTitle @outletArgs={{this.outletArgs}} />
            <DButton
              class="publish-announcement"
              @action={{this.composer.saveAction}}
              @label="composer.create_topic"
            />
          </div>
        </template>
      );
      await click(".publish-announcement");
      await fillIn("#isbf-optional-title", "");

      assert
        .dom(".isbf-v2-composer-title .popup-tip")
        .isNotVisible("an empty optional title has no length error");
      assert.true(
        this.model.titleLengthValid,
        "the generated internal title still satisfies publishing validation"
      );
    });
  }
);
