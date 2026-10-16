import { getOwner } from "@ember/owner";
import { click, render, settled } from "@ember/test-helpers";
import { modifier } from "ember-modifier";
import { module, test } from "qunit";
import sinon from "sinon";
import NestedPost from "discourse/components/nested/post";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";

const noop = () => {};
const registerPost = modifier(() => {});

function renderComponent(context) {
  const state = context.stateController || context;
  return render(
    <template>
      <NestedPost
        @changeNotice={{noop}}
        @changePostOwner={{noop}}
        @children={{context.children}}
        @collapseFromDepth={{context.collapseFromDepth}}
        @deletePost={{noop}}
        @depth={{context.depth}}
        @editPost={{noop}}
        @expansionState={{state.expansionState}}
        @fetchedChildrenCache={{state.fetchedChildrenCache}}
        @focusPost={{context.focusPost}}
        @grantBadge={{noop}}
        @lockPost={{noop}}
        @multiSelect={{context.multiSelect}}
        @path={{context.path}}
        @permanentlyDeletePost={{noop}}
        @post={{context.post}}
        @postSelected={{context.postSelected}}
        @rebakePost={{noop}}
        @recoverPost={{noop}}
        @registerPost={{registerPost}}
        @replyToPost={{noop}}
        @selectBelow={{context.selectBelow}}
        @selectReplies={{context.selectReplies}}
        @showFlags={{noop}}
        @showHistory={{noop}}
        @showPagePublish={{noop}}
        @sort="top"
        @togglePostSelection={{context.togglePostSelection}}
        @togglePostType={{noop}}
        @toggleWiki={{noop}}
        @topic={{context.topic}}
        @unhidePost={{noop}}
        @unlockPost={{noop}}
      />
    </template>
  );
}

module("Integration | Component | Nested | Post", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.nested_replies_max_depth = 6;
    this.store = getOwner(this).lookup("service:store");
    this.topic = this.store.createRecord("topic", {
      id: 1,
      slug: "nested-topic",
      user_id: 1,
    });
    this.path = [];
    this.children = [];
    this.depth = 0;
    this.collapseFromDepth = null;
    this.expansionState = new Map();
    this.fetchedChildrenCache = new Map();
    this.multiSelect = false;
    this.togglePostSelection = noop;
    this.selectReplies = noop;
    this.selectBelow = noop;
    this.postSelected = () => false;
    this.post = this.store.createRecord("post", {
      id: 2,
      post_number: 2,
      topic: this.topic,
      user_id: 2,
      username: "leaf-user",
      avatar_template: "/letter_avatar_proxy/v4/letter/l/25/48.png",
      cooked: "<p>Leaf post</p>",
      created_at: "2026-01-01T00:00:00.000Z",
      actions_summary: [],
      direct_reply_count: 0,
      total_descendant_count: 0,
    });
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  function flatChild(context, number) {
    const data = {
      id: 1000 + number,
      topic_id: context.topic.id,
      post_number: number,
      reply_to_post_number: number - 1,
      username: "reply-user",
      avatar_template: "/letter_avatar_proxy/v4/letter/r/25/{size}.png",
      cooked: `<p>Reply ${number}</p>`,
      created_at: "2026-01-01T00:00:00.000Z",
      actions_summary: [],
    };
    return {
      post: context.store.createRecord("post", {
        ...data,
        topic: context.topic,
      }),
      data,
      children: [],
    };
  }

  test("replacing route state keeps loaded replies in the active controller cache", async function (assert) {
    this.siteSettings.nested_replies_enabled = true;
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 1;
    this.stateController = this.owner.lookup("controller:nested");
    this.post.setProperties({
      direct_reply_count: 1,
      total_descendant_count: 6,
    });
    const nodes = Array.from({ length: 6 }, (_, index) =>
      flatChild(this, index + 3)
    );
    this.children = nodes.slice(0, 3);
    pretender.get("/n/nested-topic/1/children/2.json", () =>
      response({
        children: nodes.map((node) => node.data),
        page: 0,
        has_more: false,
      })
    );

    await renderComponent(this);
    const previous = this.stateController.fetchedChildrenCache;
    this.stateController.expansionState = new Map();
    this.stateController.fetchedChildrenCache = new Map();
    await settled();
    await click(".nested-post-children__expand");

    assert.strictEqual(
      this.stateController.fetchedChildrenCache.get("1:2").childNodes.length,
      6,
      "the controller can locate replies loaded beyond the preview"
    );
    assert.strictEqual(previous.get("1:2").childNodes.length, 3);
  });

  test("an own reply remains visible across expansion and a late first-page response", async function (assert) {
    this.siteSettings.nested_replies_enabled = true;
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 1;
    this.post.setProperties({
      direct_reply_count: 1,
      total_descendant_count: 100,
    });
    const nodes = Array.from({ length: 101 }, (_, index) =>
      flatChild(this, index + 3)
    );
    this.children = nodes.slice(0, 3);
    pretender.get("/n/nested-topic/1/children/2.json", () =>
      response({
        children: nodes.slice(0, 50).map((node) => node.data),
        page: 0,
        has_more: true,
      })
    );
    await renderComponent(this);
    this.owner
      .lookup("service:app-events")
      .trigger("nested-replies:child-created", {
        topicId: 1,
        post: nodes[100].post,
        parentPostNumber: 2,
        isOwnPost: true,
      });
    await settled();

    assert
      .dom(".nested-post__article[data-post-number='103']")
      .exists("shows the saved reply despite a missing middle page");
    assert
      .dom(".nested-post__article[data-post-number='52']")
      .exists("also merges the first server page");
    await click(".nested-post-children__collapse");
    await click(".nested-post-children__expand");
    assert
      .dom(".nested-post__article[data-post-number='103']")
      .exists("re-expanding keeps the saved reply");
    assert
      .dom(".nested-post-children__previous")
      .exists("the missing middle page remains loadable");
  });

  test("revealing an original in an expanded group preserves replies and can expand again", async function (assert) {
    this.siteSettings.nested_replies_enabled = true;
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 1;
    this.post.setProperties({
      direct_reply_count: 1,
      total_descendant_count: 6,
    });
    const nodes = Array.from({ length: 6 }, (_, index) =>
      flatChild(this, index + 3)
    );
    this.children = nodes.slice(0, 3);
    pretender.get("/n/nested-topic/1/children/2.json", () =>
      response({
        children: nodes.map((node) => node.data),
        page: 0,
        has_more: false,
      })
    );
    await renderComponent(this);
    await click(".nested-post-children__expand");
    this.owner
      .lookup("service:app-events")
      .trigger("nested-replies:reveal-root", { topicId: 1, rootPostNumber: 2 });
    await settled();
    assert
      .dom(".nested-post-children .nested-post")
      .exists({ count: 6 }, "keeps the expanded replies during target reveal");
    await click(".nested-post-children__collapse");
    await click(".nested-post-children__expand");
    assert
      .dom(".nested-post-children .nested-post")
      .exists({ count: 6 }, "restores every reply after collapsing again");
  });

  test("flat conversations preview three replies and expand in place on mobile", async function (assert) {
    this.siteSettings.nested_replies_enabled = true;
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 1;
    sinon.stub(getOwner(this).lookup("service:site"), "mobileView").value(true);
    this.focusPost = sinon.spy();
    this.post.setProperties({
      direct_reply_count: 1,
      total_descendant_count: 6,
    });
    const nodes = Array.from({ length: 6 }, (_, index) =>
      flatChild(this, index + 3)
    );
    this.children = nodes.slice(0, 3);
    pretender.get("/n/nested-topic/1/children/2.json", () =>
      response({
        children: nodes.map((node) => ({ ...node.data, children: [] })),
        page: 0,
        has_more: false,
      })
    );

    await renderComponent(this);
    assert.dom(".nested-post-children .nested-post").exists({ count: 3 });
    await click(".nested-post-children__expand");
    assert.dom(".nested-post-children .nested-post").exists({ count: 6 });
    assert.false(
      this.focusPost.called,
      "expands in place without entering mobile focus mode"
    );
    await click(".nested-post-children__collapse");
    assert.dom(".nested-post-children .nested-post").exists({ count: 3 });
    assert
      .dom(".nested-post__article[data-post-number='2']")
      .exists("the outer reply remains visible");
  });

  test("flat target pages expose a gap and merge earlier replies without duplicates", async function (assert) {
    this.collapseFromDepth = 0;
    this.siteSettings.nested_replies_enabled = true;
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 1;
    this.post.setProperties({
      direct_reply_count: 1,
      total_descendant_count: 100,
      target_post_number: 80,
      children_page: 1,
    });
    const nodes = Array.from({ length: 100 }, (_, index) =>
      flatChild(this, index + 3)
    );
    this.children = [...nodes.slice(0, 3), ...nodes.slice(50)];
    let attempts = 0;
    pretender.get("/n/nested-topic/1/children/2.json", (request) => {
      assert.strictEqual(
        request.queryParams.page,
        "0",
        "retries the missing earlier page"
      );
      if (attempts++ === 0) {
        return response(503, { errors: ["Unavailable"] });
      }
      return response({
        children: nodes
          .slice(0, 50)
          .map((node) => ({ ...node.data, children: [] })),
        page: 0,
        has_more: true,
      });
    });

    await renderComponent(this);
    assert.dom(".nested-post-children__previous").exists();
    assert.dom(".nested-post__article[data-post-number='80']").exists();
    await click(".nested-post-children__previous");
    assert.dom(".nested-post-children__error").exists();
    await click(".nested-post-children__error + button");
    assert.dom(".nested-post-children .nested-post").exists({ count: 100 });
    assert.dom(".nested-post-children__previous").doesNotExist();
  });

  test("uses nested replies affordance instead of flat post-menu replies button", async function (assert) {
    this.post.setProperties({
      reply_count: 2,
      direct_reply_count: 2,
      total_descendant_count: 2,
    });

    await renderComponent(this);

    assert
      .dom(".nested-post__menu .post-action-menu__show-replies")
      .doesNotExist(
        "does not render the flat replies button in nested post menus"
      );
    assert
      .dom(".nested-post__expand-replies")
      .exists("keeps the nested replies expansion button");
  });

  test("leaf posts can be collapsed from the depth line", async function (assert) {
    await renderComponent(this);

    assert
      .dom(".nested-post__depth-line")
      .exists("renders a depth-line for a post without replies");
    assert
      .dom(".nested-post__depth-line-icon")
      .exists("renders the collapse affordance");
    assert
      .dom(".nested-post__depth-line")
      .hasClass(
        "nested-post__depth-line--leaf",
        "uses the low-emphasis leaf depth-line"
      );
    assert
      .dom(".nested-post__depth-line")
      .doesNotHaveClass(
        "nested-post__depth-line--collapsed",
        "does not use the replies-hidden line state"
      );

    await click(".nested-post__depth-line");

    assert.dom(".nested-post__article").doesNotExist("collapses the post body");
    assert.dom(".nested-post__collapsed-bar").exists("shows the collapsed bar");
    assert
      .dom(".nested-post__collapsed-reply-count")
      .hasText(i18n("nested_replies.collapsed_post"));
    assert.deepEqual(
      this.expansionState.get(2),
      { expanded: false, collapsed: true },
      "stores the collapsed leaf state"
    );

    await click(".nested-post__collapsed-bar");

    assert.dom(".nested-post__article").exists("expands the post body again");
    assert
      .dom(".nested-post__depth-line")
      .exists("restores the depth-line affordance");
    assert.deepEqual(
      this.expansionState.get(2),
      { expanded: false, collapsed: false },
      "stores the expanded leaf state"
    );
  });

  test("mobile collapsed posts keep an avatar in the gutter", async function (assert) {
    const site = getOwner(this).lookup("service:site");
    sinon.stub(site, "mobileView").value(true);

    await renderComponent(this);
    await click(".nested-post__depth-line");

    assert.dom(".nested-post__article").doesNotExist("collapses the post body");
    assert
      .dom(".nested-post__gutter .topic-avatar")
      .exists("renders the post avatar area in the mobile gutter");
    assert
      .dom(".nested-post__collapsed-avatar")
      .doesNotExist("does not duplicate the avatar in the collapsed bar");
  });

  test("post registration can update post topic", async function (assert) {
    const appEvents = getOwner(this).lookup("service:app-events");
    const updatedTopic = this.store.createRecord("topic", {
      id: 99,
      slug: "updated-topic",
      user_id: 1,
    });
    let registered = false;
    const register = (post) => {
      post.topic = updatedTopic;
      registered = true;
    };

    appEvents.on("nested-replies:post-registered", this, register);

    try {
      await renderComponent(this);

      assert.true(registered, "registers the post");
      assert.strictEqual(this.post.topic, updatedTopic, "updates the topic");
    } finally {
      appEvents.off("nested-replies:post-registered", this, register);
    }
  });

  test("mobile focus waits for unloaded children before focusing", async function (assert) {
    const site = getOwner(this).lookup("service:site");
    sinon.stub(site, "mobileView").value(true);

    this.post.set("direct_reply_count", 1);
    this.post.set("total_descendant_count", 1);

    let focusedPath;
    let requestedChildren = false;
    this.focusPost = (path) => {
      focusedPath = path;
    };

    pretender.get("/n/nested-topic/1/children/2.json", (request) => {
      requestedChildren = true;
      assert.strictEqual(
        focusedPath,
        undefined,
        "does not enter focused mode before children are fetched"
      );
      assert.strictEqual(request.queryParams.sort, "top");
      assert.strictEqual(request.queryParams.depth, "1");

      return response({
        children: [
          {
            id: 3,
            post_number: 3,
            topic_id: 1,
            user_id: 3,
            username: "child-user",
            avatar_template: "/letter_avatar_proxy/v4/letter/c/25/48.png",
            cooked: "<p>Child post</p>",
            created_at: "2026-01-01T00:00:00.000Z",
            actions_summary: [],
            direct_reply_count: 0,
            total_descendant_count: 0,
            children: [],
          },
        ],
        has_more: false,
        page: 0,
      });
    });

    await renderComponent(this);
    await click(".nested-post__expand-replies");

    assert.true(requestedChildren, "fetches the missing children first");
    assert.strictEqual(focusedPath.length, 1, "focuses after the request");
    assert.strictEqual(
      focusedPath[0].children[0].post.post_number,
      3,
      "hydrates the focused path with the fetched child"
    );
    assert.strictEqual(
      this.fetchedChildrenCache.get("1:2").childNodes,
      focusedPath[0].children,
      "stores the fetched children in the shared cache"
    );
  });

  test("reply counts below the mobile depth cap do not preload missing children", async function (assert) {
    this.depth = 3;
    this.collapseFromDepth = 4;
    this.post.set("direct_reply_count", 1);
    this.post.set("total_descendant_count", 1);

    pretender.get("/n/nested-topic/1/children/2.json", () => {
      assert.step("requested children");

      return response({
        children: [],
        has_more: false,
        page: 0,
      });
    });

    await renderComponent(this);

    assert
      .dom(".nested-post__expand-replies")
      .exists("shows the explicit expansion affordance");
    assert
      .dom(".nested-post-children")
      .doesNotExist("does not mount the child loader");
    assert.verifySteps([], "does not request children while rendering");
  });

  test("renders server-flattened descendants once at the nesting depth cap", async function (assert) {
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 3;
    this.depth = 2;
    this.post.setProperties({
      direct_reply_count: 2,
      total_descendant_count: 4,
    });

    const child = (id, postNumber) => ({
      post: this.store.createRecord("post", {
        id,
        post_number: postNumber,
        topic: this.topic,
        user_id: 2,
        username: `user-${id}`,
        avatar_template: "/letter_avatar_proxy/v4/letter/u/25/48.png",
        cooked: `<p>Post ${postNumber}</p>`,
        created_at: "2026-01-01T00:00:00.000Z",
        actions_summary: [],
        direct_reply_count: 0,
        total_descendant_count: 0,
      }),
      children: [],
    });
    const grandchild56 = child(56, 56);
    const grandchild51 = child(51, 51);
    this.children = [child(48, 48), child(49, 49), grandchild56, grandchild51];

    await renderComponent(this);

    const appEvents = getOwner(this).lookup("service:app-events");
    appEvents.trigger("nested-replies:child-created", {
      topicId: this.topic.id,
      parentPostNumber: this.post.post_number,
      post: grandchild56.post,
    });

    assert
      .dom(".nested-post.--depth-3")
      .exists({ count: 4 }, "renders every descendant at the capped depth");
    assert
      .dom('[data-post-id="56"]')
      .exists({ count: 1 }, "renders a deep descendant exactly once");
    assert
      .dom('[data-post-id="51"]')
      .exists({ count: 1 }, "renders descendants from each branch");
    assert
      .dom(".nested-post-children__load-more")
      .doesNotExist("does not offer a fetch when every descendant is loaded");
  });

  test("recomputes capped descendant pagination when restoring child cache", async function (assert) {
    this.siteSettings.nested_replies_cap_nesting_depth = true;
    this.siteSettings.nested_replies_max_depth = 3;
    this.depth = 2;
    this.post.setProperties({
      direct_reply_count: 2,
      total_descendant_count: 3,
    });

    const cachedChild = this.store.createRecord("post", {
      id: 48,
      post_number: 48,
      topic: this.topic,
      user_id: 2,
      username: "cached-user",
      avatar_template: "/letter_avatar_proxy/v4/letter/c/25/48.png",
      cooked: "<p>Cached post</p>",
      created_at: "2026-01-01T00:00:00.000Z",
      actions_summary: [],
      direct_reply_count: 0,
      total_descendant_count: 0,
    });
    this.fetchedChildrenCache.set("1:2", {
      childNodes: [{ post: cachedChild, children: [] }],
      page: 0,
      hasMore: false,
      fetchedFromServer: false,
    });
    this.expansionState.set(this.post.post_number, {
      expanded: true,
      collapsed: false,
    });

    await renderComponent(this);

    assert.dom('[data-post-id="48"]').exists("restores the cached descendant");
    assert
      .dom(".nested-post-children__load-more")
      .exists("offers the missing descendants despite stale cached hasMore");
  });

  test("renders multi-select controls", async function (assert) {
    let selectedPost;
    this.multiSelect = true;
    this.postSelected = () => false;
    this.togglePostSelection = (post) => {
      selectedPost = post;
    };

    await renderComponent(this);

    assert
      .dom(".select-post")
      .hasText(i18n("topic.multi_select.select_post.label"));
    assert
      .dom(".select-below")
      .hasText(i18n("topic.multi_select.select_below.label"));

    await click(".select-post");

    assert.strictEqual(selectedPost, this.post, "passes the post to selection");
  });

  test("marks selected posts", async function (assert) {
    this.multiSelect = true;
    this.postSelected = (post) => post === this.post;

    await renderComponent(this);

    assert
      .dom(".nested-post")
      .hasClass("selected", "adds the selected state class");
    assert
      .dom(".select-post")
      .hasText(i18n("topic.multi_select.selected_post.label"));
  });
});
