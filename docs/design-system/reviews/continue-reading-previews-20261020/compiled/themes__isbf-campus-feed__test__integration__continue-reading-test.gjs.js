import EmberObject from "@ember/object";
import { click, focus, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { themePrefix } from "virtual:theme";
import MoreTopics, { registeredTabs } from "discourse/components/more-topics";
import { NotificationLevels } from "discourse/lib/notification-levels";
import { cloneJSON } from "discourse/lib/object";
import DiscourseURL from "discourse/lib/url";
import Topic from "discourse/models/topic";
import topicFixtures from "discourse/tests/fixtures/topic";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";
import continueReadingInitializer from "../../discourse/api-initializers/isbf-continue-reading";
import ISBFContinueReadingFooter from "../../discourse/components/isbf-continue-reading-footer";
import ISBFContinueReadingItem from "../../discourse/components/isbf-continue-reading-item";
import { invalidateCookedPost } from "../../discourse/lib/feed-post-loader";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
const fixture = cloneJSON(topicFixtures["/t/280/1.json"]);
const UNTITLED = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";
let nextPreviewId = 790900;
module("ISBF | Integration | Component | ContinueReadingItem", function (hooks) {
  setupRenderingTest(hooks);
  hooks.beforeEach(function () {
    this.topic = Topic.create({
      ...cloneJSON(fixture.suggested_topics[0]),
      posts_count: 1,
      highest_post_number: 1,
      last_read_post_number: 1,
      unseen: false,
      unread_posts: 0
    });
  });
  test("renders actual reply counts and native topic, date and category targets", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem
        @listContext="suggested"
        @topic={{this.topic}}
      /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@listContext\",\"@topic\"],[\"suggested\",[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading__replies").hasText(i18n(themePrefix("isbf_v2.continue_reading.replies"), {
      count: 0
    }), "zero replies have an explicit label");
    assert.dom(".isbf-continue-reading__title").hasAttribute("href", this.topic.lastUnreadUrl, "the title retains its reading target");
    assert.dom(".isbf-continue-reading__replies").hasAttribute("href", this.topic.firstPostUrl, "the reply count retains its original first-post target");
    assert.dom(".isbf-continue-reading__time").hasAttribute("href", this.topic.lastPostUrl, "activity still links to the latest post");
    assert.dom(".isbf-continue-reading__metadata .badge-category__wrapper").exists("the native category link is retained");
    this.topic.set("posts_count", 4);
    await settled();
    assert.dom(".isbf-continue-reading__replies").hasText(i18n(themePrefix("isbf_v2.continue_reading.replies"), {
      count: 3
    }), "the real reply count updates");
    assert.dom("a a").doesNotExist("the entries contain no nested anchors");
  });
  test("uses the creator avatar and a local fallback without inventing an author", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading__avatar").hasAttribute("data-user-card", this.topic.creator.username, "the avatar belongs to the original author");
    assert.dom(".isbf-continue-reading__avatar img").exists("the existing avatar helper renders an image");
    this.topic.set("posters", []);
    await settled();
    assert.dom(".isbf-continue-reading__avatar img").hasAttribute("src", "/images/avatar.png", "missing authors use the existing default image");
    assert.dom("a.isbf-continue-reading__avatar").doesNotExist("the fallback has no fabricated profile link");
  });
  test("keeps new, read and nested reply states distinct", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading__unread").doesNotExist("a read topic has no unread dot");
    this.topic.setProperties({
      unseen: true,
      last_read_post_number: null
    });
    await settled();
    assert.dom(".isbf-continue-reading__unread").doesNotExist("newness alone does not imply unread replies");
    this.topic.setProperties({
      unseen: false,
      unread_posts: 3,
      last_read_post_number: 1,
      highest_post_number: 4
    });
    await settled();
    assert.dom(".isbf-continue-reading__unread").exists("actual unread replies show a dot");
    this.topic.set("unread_posts", 2);
    await settled();
    assert.dom(".isbf-continue-reading__unread").hasAttribute("title", i18n("topic.unread_posts", {
      count: 2
    }), "the unread label follows tracking updates");
    this.topic.set("is_nested_view", true);
    await settled();
    assert.dom(".isbf-continue-reading__unread").doesNotExist("nested topics do not fall back to flat unread counts");
    this.topic.set("has_new_replies", true);
    await settled();
    assert.dom(".isbf-continue-reading__unread").exists("the native nested reply signal shows a dot");
    this.topic.set("has_new_replies", false);
    await settled();
    assert.dom(".isbf-continue-reading__unread").doesNotExist("reading the nested replies clears the dot");
  });
  test("retains lock state, keyboard focus and native click history", async function (assert) {
    this.topic.set("closed", true);
    const route = sinon.stub(DiscourseURL, "routeTo");
    const history = sinon.spy(this.owner.lookup("service:history-store"), "set");
    try {
      await render(setComponentTemplate(createTemplateFactory(
      /*
        <ul><ISBFContinueReadingItem
          @listContext="suggested"
          @topic={{this.topic}}
        /></ul>
      */
      {
        "id": null,
        "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@listContext\",\"@topic\"],[\"suggested\",[32,1,[\"topic\"]]]],null],[13]],[],[]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          ISBFContinueReadingItem,
          "this": this
        }),
        "isStrictMode": true
      }), templateOnly()));
      assert.dom(".topic-status.--closed").exists("the lock state remains identifiable");
      await focus(".isbf-continue-reading__title");
      assert.dom(".isbf-continue-reading__item").hasClass("selected", "native keyboard selection follows focus");
      await click(".isbf-continue-reading__title");
      assert.true(route.calledOnceWithExactly(new URL(this.topic.lastUnreadUrl, window.location.href).href), "title clicks keep the native reading route");
      assert.true(history.calledWithExactly("lastTopicIdViewed", this.topic.id), "clicks retain native list history");
    } finally {
      history.restore();
      route.restore();
    }
  });
});
module("ISBF | Integration | Component | ISBFContinueReadingItem", function (hooks) {
  setupRenderingTest(hooks);
  hooks.beforeEach(function () {
    this.topic = Topic.create({
      ...cloneJSON(fixture.suggested_topics[0]),
      id: ++nextPreviewId,
      title: UNTITLED,
      fancy_title: UNTITLED,
      excerpt: null,
      posts_count: 5,
      highest_post_number: 5,
      last_read_post_number: 2,
      unread_posts: 3
    });
    this.requests = [];
    this.cooked = '<p>Campus photos.</p><a class="lightbox"><img src="/images/avatar.png" alt="internal-filename"></a>';
    this.observers = [];
    const observers = this.observers;
    this.observerStub = sinon.stub(window, "IntersectionObserver").callsFake(function (callback) {
      observers.push(callback);
      return {
        observe() {},
        disconnect() {}
      };
    });
    invalidateCookedPost(this.topic.id, false);
    pretender.get("/posts/by_number/:topicId/:postNumber.json", request => {
      this.requests.push(request.url);
      return response({
        id: this.topic.id,
        cooked: this.cooked
      });
    });
  });
  hooks.afterEach(function () {
    this.observerStub.restore();
  });
  test("loads the first-post text lazily while retaining the unread target", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-post-preview__text").hasText(i18n(themePrefix("isbf_v2.preview_post")), "the internal title is absent even before the body loads");
    assert.strictEqual(this.requests.length, 0, "offscreen rows do not load");
    this.observers[0]([{
      isIntersecting: true
    }]);
    await settled();
    assert.deepEqual(this.requests, [`/posts/by_number/${this.topic.id}/1.json`], "the preview reads the first post rather than the unread reply");
    assert.dom(".isbf-post-preview__text").hasText("Campus photos.", "clean body text replaces the placeholder");
    assert.dom(".isbf-continue-reading__title").hasAttribute("href", this.topic.lastUnreadUrl, "the unread target remains");
    assert.dom(".isbf-post-preview__image").doesNotExist("the footer remains a text list");
    assert.dom("a a").doesNotExist("the preview contains no nested links");
  });
  test("a pure-image post has a readable label without a filename", async function (assert) {
    this.cooked = '<a class="lightbox"><img src="/images/avatar.png" alt="internal-filename"></a>';
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    this.observers[0]([{
      isIntersecting: true
    }]);
    await settled();
    assert.dom(".isbf-post-preview__text").hasText(i18n(themePrefix("isbf_v2.preview_picture")), "image-only content uses the existing label");
  });
  test("a missing body retains the neutral label and linked-post target", async function (assert) {
    this.topic.set("linked_post_number", 4);
    pretender.get("/posts/by_number/:topicId/:postNumber.json", () => response(404, {
      errors: ["Not found"]
    }));
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    this.observers[0]([{
      isIntersecting: true
    }]);
    await settled();
    assert.dom(".isbf-post-preview__text").hasText(i18n(themePrefix("isbf_v2.preview_post")), "failure does not restore the internal title");
    assert.dom(".isbf-continue-reading__title").hasAttribute("href", this.topic.urlForPostNumber(4), "the explicit post target survives");
  });
  test("hidden topics do not expose an excerpt or request their body", async function (assert) {
    this.topic.setProperties({
      hidden: true,
      excerpt: "Hidden text"
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-post-preview__text").hasText(i18n(themePrefix("isbf_v2.preview_post")), "hidden content uses a neutral label");
    assert.strictEqual(this.observers.length, 0, "hidden content is not observed");
    assert.strictEqual(this.requests.length, 0, "hidden content is not fetched");
  });
  test("untitled links retain read announcements, focus and native history", async function (assert) {
    this.topic.set("last_read_post_number", 5);
    const route = sinon.stub(DiscourseURL, "routeTo");
    const history = sinon.spy(this.owner.lookup("service:history-store"), "set");
    try {
      await render(setComponentTemplate(createTemplateFactory(
      /*
        <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
      */
      {
        "id": null,
        "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          ISBFContinueReadingItem,
          "this": this
        }),
        "isStrictMode": true
      }), templateOnly()));
      assert.dom(".isbf-continue-reading__title .sr-only").hasText(i18n("topic.sr_read"), "the native read announcement remains");
      await focus(".isbf-continue-reading__title");
      assert.dom(".isbf-continue-reading__item").hasClass("selected", "focus selects the row");
      await click(".isbf-continue-reading__title");
      assert.true(route.calledOnceWithExactly(new URL(this.topic.lastUnreadUrl, window.location.href).href), "clicks retain the native reading route");
      assert.true(history.calledWithExactly("lastTopicIdViewed", this.topic.id), "clicks retain list history");
    } finally {
      history.restore();
      route.restore();
    }
  });
  test("a real title keeps native formatting without a body request", async function (assert) {
    this.topic.setProperties({
      title: "Campus news",
      fancy_title: "Campus <em>news</em>"
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ul><ISBFContinueReadingItem @topic={{this.topic}} /></ul>
    */
    {
      "id": null,
      "block": "[[[10,\"ul\"],[12],[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null],[13]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingItem,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading__title em").hasText("news", "native title formatting remains");
    assert.strictEqual(this.observers.length, 0, "a titled row needs no preview observer");
    assert.strictEqual(this.requests.length, 0, "a titled row makes no body request");
  });
});
module("ISBF | Integration | Component | ContinueReadingFooter", function (hooks) {
  setupRenderingTest(hooks);
  hooks.beforeEach(function () {
    this.topic = EmberObject.create({
      category: null,
      isPrivateMessage: false
    });
    this.tracking = this.owner.lookup("service:topic-tracking-state");
    this.tracking.loadStates([{
      topic_id: 990101,
      category_id: fixture.category_id,
      last_read_post_number: 1,
      highest_post_number: 2,
      notification_level: NotificationLevels.TRACKING
    }, {
      topic_id: 990102,
      category_id: fixture.category_id,
      last_read_post_number: null,
      highest_post_number: 1,
      created_in_new_period: true,
      is_seen: false,
      notification_level: NotificationLevels.TRACKING
    }]);
  });
  test("retains both real count links and follows tracking updates", async function (assert) {
    this.siteSettings.enable_unified_new = true;
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFContinueReadingFooter @topic={{this.topic}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingFooter,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom("a[href='/new?subset=topics']").hasText(i18n(themePrefix("isbf_v2.continue_reading.remaining_new"), {
      count: 1
    }), "new topics use their actual count and unified route");
    assert.dom("a[href='/new?subset=replies']").exists("the unread entry is preserved alongside new topics");
    assert.dom(".isbf-continue-reading__browse-all").hasAttribute("href", "/latest", "uncategorized browsing retains the latest target");
    this.tracking.updateSeen(990101, 2);
    await settled();
    assert.dom("a[href='/new?subset=replies']").doesNotExist("reading a topic updates the compact footer");
    assert.dom("a[href='/new?subset=topics']").exists("the new-topic count remains separate");
  });
  test("retains separate new and unread routes when unified new is disabled", async function (assert) {
    this.siteSettings.enable_unified_new = false;
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFContinueReadingFooter @topic={{this.topic}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingFooter,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom("a[href='/new']").exists("new topics use the original separate route");
    assert.dom("a[href='/unread']").exists("unread topics use the original separate route");
  });
  test("zero counts preserve category browsing and the extra latest link", async function (assert) {
    this.tracking.updateSeen(990101, 2);
    this.tracking.updateSeen(990102, 1);
    const category = Topic.create(cloneJSON(fixture)).category;
    this.topic.set("category", category);
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ISBFContinueReadingFooter @topic={{this.topic}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFContinueReadingFooter,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading__remaining").doesNotExist("zero counts do not generate remaining-topic copy");
    assert.dom(".isbf-continue-reading__browse-all").hasAttribute("href", category.url, "browse all retains the current category target");
    assert.dom("a[href='/latest']").exists("the original extra latest entry is preserved");
    this.topic.set("category", null);
    await settled();
    assert.dom("a[href='/categories']").exists("without a category the original category directory remains available");
  });
});
module("ISBF | Integration | Component | ContinueReading", function (hooks) {
  setupRenderingTest(hooks, {
    stubRouter: true
  });
  hooks.beforeEach(function () {
    this.owner.lookup("service:router").currentURL = "/t/fixture/280";
    this.owner.lookup("service:key-value-store").set({
      key: "more-topics-preference-topic",
      value: "suggested-topics"
    });
    continueReadingInitializer.initialize(this.owner);
    this.originalTabs = [...registeredTabs];
    registeredTabs.splice(0, registeredTabs.length, {
      id: "suggested-topics",
      name: "New & unread",
      component: setComponentTemplate(createTemplateFactory(
      /*
        Original suggestions
      */
      {
        "id": null,
        "block": "[[[1,\"Original suggestions\"]],[],[]]",
        "moduleName": "(unknown template module)",
        "isStrictMode": true
      }), templateOnly()),
      condition: ({
        topic
      }) => topic.suggestedTopics?.length > 0
    }, {
      id: "related-topics",
      name: "Related topics",
      component: setComponentTemplate(createTemplateFactory(
      /*
        Original related topics
      */
      {
        "id": null,
        "block": "[[[1,\"Original related topics\"]],[],[]]",
        "moduleName": "(unknown template module)",
        "isStrictMode": true
      }), templateOnly()),
      condition: ({
        topic
      }) => topic.relatedTopics?.length > 0
    });
    this.topic = Topic.create(cloneJSON(fixture));
    this.topic.set("relatedTopics", [Topic.create({
      ...cloneJSON(fixture.suggested_topics[0]),
      id: 990201
    })]);
  });
  hooks.afterEach(function () {
    registeredTabs.splice(0, registeredTabs.length, ...this.originalTabs);
  });
  test("both sources share the list while retaining their order and persisted selection", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <MoreTopics @topic={{this.topic}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        MoreTopics,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading").hasAttribute("data-source", "suggested", "suggestions use the compact list");
    assert.dom(".isbf-continue-reading__item").exists({
      count: this.topic.suggestedTopics.length
    }, "the source list is not expanded or filtered");
    assert.dom(".isbf-continue-reading__item").hasAttribute("data-topic-id", `${this.topic.suggestedTopics[0].id}`, "the first source topic retains its position");
    await click(".isbf-continue-reading__tab:nth-of-type(2)");
    assert.dom(".isbf-continue-reading").hasAttribute("data-source", "related", "related topics share the same presentation");
    assert.dom(".isbf-continue-reading__source").hasText(i18n(themePrefix("isbf_v2.continue_reading.related")), "the caption matches the selected source");
    assert.dom(".isbf-continue-reading__item").hasAttribute("data-topic-id", "990201", "the related source supplies its own records");
    assert.strictEqual(this.owner.lookup("service:key-value-store").get("more-topics-preference-topic"), "related-topics", "the original preference service saves the selected source");
    assert.dom("table").doesNotExist("the two topic sources render semantic lists");
    assert.dom(".isbf-continue-reading__footer").exists({
      count: 1
    }, "the footer is rendered only once");
  });
  test("empty and private contexts retain their existing rendering", async function (assert) {
    this.topic.set("archetype", "private_message");
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <MoreTopics @topic={{this.topic}} />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@topic\"],[[32,1,[\"topic\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        MoreTopics,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-continue-reading").doesNotExist("private messages are outside the new presentation");
    assert.dom(".more-topics__lists").hasText("Original suggestions", "the wrapper yields to the native content");
    this.topic.setProperties({
      suggested_topics: [],
      relatedTopics: []
    });
    await settled();
    assert.dom(".isbf-continue-reading").doesNotExist("an empty source creates no placeholder panel");
    assert.dom(".more-topics__lists").doesNotExist("the original empty-list condition remains in control");
  });
});