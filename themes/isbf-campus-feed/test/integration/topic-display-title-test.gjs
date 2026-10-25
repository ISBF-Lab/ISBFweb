import { get } from "@ember/object";
import { fillIn, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import PostListItemDetails from "discourse/components/post-list/item/details";
import SearchMenuTopic from "discourse/components/search-menu/results/type/topic";
import SearchResultEntry from "discourse/components/search-result-entry";
import TopicLink from "discourse/components/topic-list/topic-link";
import BufferedProxy from "discourse/lib/buffered-proxy";
import { fancyTitle } from "discourse/lib/topic-fancy-title";
import topicTitleToken from "discourse/lib/topic-title-token";
import Bookmark from "discourse/models/bookmark";
import Post from "discourse/models/post";
import Topic from "discourse/models/topic";
import UserAction from "discourse/models/user-action";
import UserDraft from "discourse/models/user-draft";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import stubIntersectionObserver from "discourse/tests/helpers/stub-intersection-observer";
import dTopicLink from "discourse/ui-kit/helpers/d-topic-link";
import ISBFOptionalTopicTitleEditor from "../../discourse/components/isbf-optional-topic-title-editor";
import { invalidateCookedPost } from "../../discourse/lib/feed-post-loader";

const TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";

module("ISBF | Integration | topic display title", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.topic = Topic.create({
      id: 980001,
      title: TITLE,
      fancy_title: TITLE,
      slug: "campus",
      excerpt: "<p>Campus body.</p>",
      archetype: "regular",
      category_id: this.site.categories[0].id,
    });
  });

  test("native topic links retain the unread target and escape preview text", async function (assert) {
    this.topic.setProperties({
      excerpt: "<p>&lt;svg onload=alert(1)&gt; &amp; body</p>",
      last_read_post_number: 2,
      highest_post_number: 5,
    });
    await render(<template><TopicLink @topic={{this.topic}} /></template>);
    assert.dom("a.title").hasAttribute("href", this.topic.lastUnreadUrl);
    assert
      .dom(".isbf-topic-title-preview")
      .hasText("<svg onload=alert(1)> & body");
    assert.dom("a.title svg").doesNotExist();
    assert.strictEqual(
      this.topic.title,
      TITLE,
      "presentation never rewrites the stored title"
    );
    assert.strictEqual(
      topicTitleToken(this.topic, {
        topic_page_title_includes_category: false,
      }),
      "<svg onload=alert(1)> & body"
    );
  });

  test("localized topic links and browser titles retain the selected language without fetching the body", async function (assert) {
    const observations = stubIntersectionObserver();
    this.topic.setProperties({
      fancy_title: "<b>Translated &amp; title</b>",
      fancy_title_localized: true,
      excerpt: undefined,
    });
    await render(<template><TopicLink @topic={{this.topic}} /></template>);
    assert.dom("a.title").hasText("Translated & title");
    assert.dom("a.title b").exists("localized title formatting is preserved");
    assert.dom(".isbf-topic-title-preview").doesNotExist();
    assert.strictEqual(
      observations.length,
      0,
      "translations need no body request"
    );
    assert.strictEqual(
      topicTitleToken(this.topic, {
        topic_page_title_includes_category: false,
      }),
      "Translated & title"
    );
    assert.strictEqual(
      this.topic.displayTitle,
      "Translated & title",
      "plain-text consumers use the selected language too"
    );
    this.topic.setProperties({
      fancy_title: TITLE,
      fancy_title_localized: false,
      excerpt: "<p>Original-language body.</p>",
    });
    await settled();
    assert.dom(".isbf-topic-title-preview").hasText("Original-language body.");
    this.topic.setProperties({
      fancy_title: "Translated again",
      fancy_title_localized: true,
    });
    await settled();
    assert.dom("a.title").hasText("Translated again");
    assert.strictEqual(this.topic.displayTitle, "Translated again");
    assert.strictEqual(
      this.topic.title,
      TITLE,
      "the persisted title remains unchanged"
    );
  });

  test("bookmarked localized titles retain their flag and exact post target", async function (assert) {
    this.bookmark = Bookmark.create({
      id: 980602,
      topic_id: 980001,
      title: TITLE,
      fancy_title: "Translated bookmark",
      fancy_title_localized: true,
      excerpt: "<p>Original-language bookmark body.</p>",
      bookmarkable_type: "Post",
      linked_post_number: 7,
    });
    await render(
      <template>{{dTopicLink this.bookmark.topicForList}}</template>
    );
    assert
      .dom("a.title")
      .hasText("Translated bookmark")
      .hasAttribute("href", "/t/topic/980001/7");
    assert.true(this.bookmark.topicForList.fancy_title_localized);
  });

  test("cached sharing and activity labels update when a translation arrives", function (assert) {
    const sharing = this.owner
      .factoryFor("component:share-panel")
      .create({ panel: { model: { topic: this.topic } } });
    const activity = UserAction.create({
      title: TITLE,
      excerpt: "<p>Original activity body.</p>",
    });
    try {
      assert.true(get(sharing, "shareTitle").includes("Campus body."));
      assert.strictEqual(activity.titleHtml, "Original activity body.");
      this.topic.setProperties({
        fancy_title: "Translated sharing title",
        fancy_title_localized: true,
      });
      activity.setProperties({
        fancy_title: "Translated activity title",
        fancy_title_localized: true,
      });
      assert.true(
        get(sharing, "shareTitle").includes("Translated sharing title")
      );
      assert.strictEqual(activity.titleHtml, "Translated activity title");
    } finally {
      sharing.destroy();
      activity.destroy();
    }
  });

  test("localized search titles precede original-language highlighted headlines and blurbs", async function (assert) {
    this.siteSettings.use_pg_headlines_for_excerpt = true;
    this.siteSettings.support_mixed_text_direction = false;
    this.topic.setProperties({
      fancy_title: "Translated search title",
      fancy_title_localized: true,
    });
    this.searchPost = Post.create({
      id: 980603,
      topic_id: this.topic.id,
      topic: this.topic,
      post_number: 1,
      username: "eviltrout",
      created_at: "2026-10-24T00:00:00Z",
      topic_title_headline: TITLE.replace("校园动态", "<b>校园动态</b>"),
      blurb: "Original-language search body",
    });
    await render(
      <template>
        <SearchResultEntry @post={{this.searchPost}} />
        <div class="search-menu-test"><SearchMenuTopic
            @result={{this.searchPost}}
          /></div>
      </template>
    );
    assert.dom(".fps-result .topic-title").hasText("Translated search title");
    assert
      .dom(".search-menu-test .topic-title")
      .hasText("Translated search title");
  });

  test("a visible public title can load its missing first post", async function (assert) {
    const observations = stubIntersectionObserver();
    this.topic.set("excerpt", undefined);
    invalidateCookedPost(980101, false);
    let requests = 0;
    pretender.get("/posts/by_number/980001/1.json", () => {
      requests++;
      return response({ id: 980101, cooked: "<p>Loaded campus body.</p>" });
    });
    pretender.get("/posts/980101/cooked", () => {
      requests++;
      return response({ cooked: "<p>Loaded campus body.</p>" });
    });
    await render(<template><TopicLink @topic={{this.topic}} /></template>);
    assert.strictEqual(requests, 0, "offscreen titles make no requests");
    assert.dom(".isbf-topic-title-preview").hasText("View post");
    await observations
      .find(({ element }) =>
        element.classList.contains("isbf-topic-title-preview")
      )
      .trigger();
    assert.dom(".isbf-topic-title-preview").hasText("Loaded campus body.");
    assert.strictEqual(requests, 1);
  });

  test("private, hidden, and deleted titles never enter the public loader", async function (assert) {
    const observations = stubIntersectionObserver();
    this.topic.setProperties({
      excerpt: undefined,
      archetype: "private_message",
    });
    await render(<template><TopicLink @topic={{this.topic}} /></template>);
    assert.strictEqual(observations.length, 0);
    this.topic.setProperties({
      archetype: "regular",
      hidden: true,
      excerpt: "<p>Hidden body.</p>",
    });
    await settled();
    assert.dom(".isbf-topic-title-preview").hasText("View post");
    assert.strictEqual(observations.length, 0);
    this.topic.setProperties({ hidden: false, deleted_at: "2026-10-24" });
    await settled();
    assert.dom(".isbf-topic-title-preview").hasText("View post");
    assert.strictEqual(observations.length, 0);
  });

  test("a failed preview request keeps a clean title and original link", async function (assert) {
    const observations = stubIntersectionObserver();
    this.topic.setProperties({ id: 980404, excerpt: undefined });
    pretender.get("/posts/by_number/980404/1.json", () =>
      response(503, { errors: ["Unavailable"] })
    );
    await render(<template><TopicLink @topic={{this.topic}} /></template>);
    await observations
      .find(({ element }) =>
        element.classList.contains("isbf-topic-title-preview")
      )
      .trigger();
    assert.dom(".isbf-topic-title-preview").hasText("View post");
    assert.dom("a.title").hasAttribute("href", this.topic.lastUnreadUrl);
  });

  test("search headlines cannot reintroduce highlighted internal titles", function (assert) {
    const post = Post.create({
      topic: this.topic,
      topic_title_headline: TITLE.replace("校园动态", "<b>校园动态</b>"),
      blurb: "<p>Matched body.</p>",
    });
    assert.strictEqual(post.topicTitleHeadline, "Matched body.");
    assert.strictEqual(
      fancyTitle("<b>Real title</b>", false, { title: "Real title" }),
      "<b>Real title</b>"
    );
  });

  test("both search interfaces use the matched body without headline mode", async function (assert) {
    this.siteSettings.use_pg_headlines_for_excerpt = false;
    this.searchPost = Post.create({
      id: 980501,
      topic_id: this.topic.id,
      post_number: 1,
      topic: this.topic,
      username: "eviltrout",
      created_at: "2026-10-24T00:00:00Z",
      blurb: "<p>Matched search body.</p>",
    });
    await render(
      <template>
        <SearchResultEntry @post={{this.searchPost}} />
        <div class="search-menu-test"><SearchMenuTopic
            @result={{this.searchPost}}
          /></div>
      </template>
    );
    assert.dom(".fps-result .topic-title").hasText("Matched search body.");
    assert
      .dom(".search-menu-test .topic-title")
      .hasText("Matched search body.");
  });

  test("bookmarked replies retain their exact post and local excerpt", async function (assert) {
    this.bookmark = Bookmark.create({
      id: 980202,
      topic_id: 980001,
      title: TITLE,
      fancy_title: TITLE,
      excerpt: "<p>A bookmarked reply.</p>",
      bookmarkable_type: "Post",
      linked_post_number: 7,
    });
    await render(
      <template>{{dTopicLink this.bookmark.topicForList}}</template>
    );
    assert
      .dom("a.title")
      .hasText("A bookmarked reply.")
      .hasAttribute("href", "/t/topic/980001/7");
    assert.strictEqual(this.bookmark.title, TITLE);
  });

  test("draft rows display their own body while keeping resumable raw data", async function (assert) {
    this.draft = UserDraft.create({
      title: TITLE,
      excerpt: "<p>An unfinished thought.</p>",
      data: { title: TITLE },
      draft_key: "new_topic",
      created_at: "2026-10-24T00:00:00Z",
    });
    await render(
      <template>
        <PostListItemDetails @isDraft={{true}} @post={{this.draft}} />
      </template>
    );
    assert.dom(".draft-title").hasText("An unfinished thought.");
    assert.strictEqual(this.draft.data.title, TITLE);
    assert.strictEqual(this.draft.title, TITLE);
  });

  test("editing an untitled topic shows an empty field and preserves its marker", async function (assert) {
    this.buffered = BufferedProxy.create({ content: this.topic });
    this.outletArgs = { model: this.topic, buffered: this.buffered };
    await render(
      <template>
        <ISBFOptionalTopicTitleEditor @outletArgs={{this.outletArgs}} />
      </template>
    );
    assert.dom("#edit-title").hasValue("");
    await fillIn("#edit-title", "A real new title");
    assert.strictEqual(this.buffered.get("title"), "A real new title");
    await fillIn("#edit-title", "");
    assert.strictEqual(this.buffered.get("title"), TITLE);
    assert.strictEqual(this.topic.title, TITLE);
  });
});
