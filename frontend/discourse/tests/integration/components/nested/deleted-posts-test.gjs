import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import NestedDeletedPosts from "discourse/components/nested/deleted-posts";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

function renderComponent(context) {
  return render(
    <template>
      <NestedDeletedPosts
        @posts={{context.posts}}
        @targetPostNumber={{context.target}}
      />
    </template>
  );
}

module("Integration | Component | Nested | DeletedPosts", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.posts = [2, 3, 4].map((number) => ({
      id: number,
      post_number: number,
      deleted_post_placeholder: true,
    }));
    this.target = null;
  });

  test("starts with one collapsed summary and expands compact placeholders", async function (assert) {
    await renderComponent(this);
    assert
      .dom(".nested-deleted-posts__summary")
      .hasAttribute("aria-expanded", "false", "the summary starts collapsed");
    assert
      .dom(".nested-deleted-posts__entry")
      .doesNotExist("collapsed groups hide individual entries");
    await click(".nested-deleted-posts__summary");
    assert
      .dom(".nested-deleted-posts__entry")
      .exists({ count: 3 }, "expanding reveals every loaded deleted reply");
    assert
      .dom(".nested-deleted-posts__summary")
      .hasAttribute("aria-expanded", "true", "the summary announces expansion");
    await click(".nested-deleted-posts__summary");
    assert
      .dom(".nested-deleted-posts__entry")
      .doesNotExist("the expanded group can collapse again");
  });

  test("a direct floor target expands its group and can subsequently collapse", async function (assert) {
    this.target = 3;
    await renderComponent(this);
    assert
      .dom('[data-post-number="3"]')
      .exists("the initial target is revealed");
    await click(".nested-deleted-posts__summary");
    assert
      .dom(".nested-deleted-posts__entry")
      .doesNotExist("a targeted group can still collapse");
    this.set("target", 4);
    await settled();
    assert
      .dom('[data-post-number="4"]')
      .exists("a new target reopens the group");
  });

  test("a single deleted reply has no empty expand or collapse button", async function (assert) {
    this.posts = [this.posts[0]];
    await renderComponent(this);
    assert
      .dom(".nested-deleted-posts__summary")
      .doesNotExist("a single deleted reply has no group control");
    assert
      .dom(".nested-deleted-posts__entry")
      .exists({ count: 1 }, "the single compact entry stays visible");
    assert
      .dom(".nested-post-children__collapse")
      .doesNotExist("there is no empty replies collapse control");
  });

  test("hidden body and unavailable recovery never create management actions", async function (assert) {
    this.posts = [
      {
        ...this.posts[0],
        cooked_hidden: true,
        cooked: "hidden content",
        can_recover: false,
      },
    ];
    await renderComponent(this);
    assert
      .dom(".nested-deleted-posts__more")
      .doesNotExist("unavailable actions do not create a menu");
    assert
      .dom(".nested-post__placeholder-reveal")
      .doesNotExist("hidden original content stays unrevealed");
    assert
      .dom(".nested-deleted-posts")
      .doesNotIncludeText(
        "hidden content",
        "hidden body text is never rendered"
      );
  });
});
