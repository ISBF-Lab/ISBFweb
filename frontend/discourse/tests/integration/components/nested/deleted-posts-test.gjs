import { getOwner } from "@ember/owner";
import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import NestedDeletedPosts from "discourse/components/nested/deleted-posts";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module("Integration | Component | Nested | Deleted posts", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner = getOwner(this);
    this.posts = [2, 3, 4].map((number) => ({
      id: number,
      post_number: number,
      deleted_post_placeholder: true,
    }));
    this.target = null;
  });

  test("starts with one collapsed summary and expands compact placeholders", async function (assert) {
    await render(
      <template><NestedDeletedPosts @posts={{this.posts}} /></template>
    );
    assert
      .dom(".nested-deleted-posts__summary")
      .hasAttribute("aria-expanded", "false");
    assert.dom(".nested-deleted-posts__entry").doesNotExist();
    await click(".nested-deleted-posts__summary");
    assert.dom(".nested-deleted-posts__entry").exists({ count: 3 });
    assert
      .dom(".nested-deleted-posts__summary")
      .hasAttribute("aria-expanded", "true");
    await click(".nested-deleted-posts__summary");
    assert.dom(".nested-deleted-posts__entry").doesNotExist();
  });

  test("a direct floor target expands its group and can subsequently collapse", async function (assert) {
    this.target = 3;
    await render(
      <template>
        <NestedDeletedPosts
          @posts={{this.posts}}
          @targetPostNumber={{this.target}}
        />
      </template>
    );
    assert.dom('[data-post-number="3"]').exists();
    await click(".nested-deleted-posts__summary");
    assert.dom(".nested-deleted-posts__entry").doesNotExist();
    this.set("target", 4);
    await settled();
    assert.dom('[data-post-number="4"]').exists();
  });

  test("a single deleted reply has no empty expand or collapse button", async function (assert) {
    this.posts = [this.posts[0]];
    await render(
      <template><NestedDeletedPosts @posts={{this.posts}} /></template>
    );
    assert.dom(".nested-deleted-posts__summary").doesNotExist();
    assert.dom(".nested-deleted-posts__entry").exists({ count: 1 });
    assert.dom(".nested-post-children__collapse").doesNotExist();
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
    await render(
      <template><NestedDeletedPosts @posts={{this.posts}} /></template>
    );
    assert.dom(".nested-deleted-posts__more").doesNotExist();
    assert.dom(".nested-post__placeholder-reveal").doesNotExist();
    assert.dom(".nested-deleted-posts").doesNotIncludeText("hidden content");
  });
});
