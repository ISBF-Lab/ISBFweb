import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFV2AnonymousPosts from "../../discourse/components/isbf-v2-anonymous-posts";

module(
  "ISBF Campus Feed | Integration | Component | ISBFV2AnonymousPosts",
  function (hooks) {
    setupRenderingTest(hooks);

    test("retries a failed initial request", async function (assert) {
      pretender.get("/isbf-anonymous/api/posts", () => response(500, {}));

      await render(<template><ISBFV2AnonymousPosts /></template>);

      assert.dom("[role=alert]").exists("the initial request error is visible");
      assert
        .dom(".isbf-v2-anonymous-posts__more")
        .isEnabled("the failed request can be retried");

      pretender.get("/isbf-anonymous/api/posts", () =>
        response({
          posts: [
            {
              id: 1,
              title: "Recovered post",
              excerpt: "Recovered content",
              url: "/t/1",
            },
          ],
          next_before_id: null,
        })
      );
      await click(".isbf-v2-anonymous-posts__more");

      assert
        .dom(".isbf-v2-anonymous-posts__item a")
        .hasText("Recovered post", "the retry renders posts");
      assert.dom("[role=alert]").doesNotExist("the previous error is cleared");
      assert
        .dom(".isbf-v2-anonymous-posts__more")
        .doesNotExist("pagination stops at the final page");
    });
  }
);
