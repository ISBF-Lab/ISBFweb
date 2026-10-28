import EmberObject from "@ember/object";
import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DMenus from "discourse/float-kit/components/d-menus";
import Topic from "discourse/models/topic";
import User from "discourse/models/user";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import select from "discourse/tests/helpers/d-select";
import stubIntersectionObserver from "discourse/tests/helpers/stub-intersection-observer";
import { enableLoadMoreObserver } from "discourse/ui-kit/d-load-more";
import ISBFTopTopics from "../../discourse/components/isbf-top-topics";

const UNTITLED =
  "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";

module("ISBF | Integration | Top topics", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    enableLoadMoreObserver();
    this.observations = stubIntersectionObserver();
    this.site.set("periods", [
      "all",
      "yearly",
      "quarterly",
      "monthly",
      "weekly",
      "daily",
    ]);
    this.topic = Topic.create({
      id: 981001,
      title: "Campus discussion",
      fancy_title: "Campus discussion",
      slug: "campus",
      archetype: "regular",
      category_id: this.site.categories[0].id,
      excerpt: "<p>A short campus update.</p>",
      views: 1200,
      posts_count: 3,
      like_count: 0,
      bumped_at: "2026-10-27T10:00:00Z",
      last_read_post_number: 1,
      highest_post_number: 3,
      unread_posts: 2,
      posters: [{ user: User.create({ id: 982001, username: "student" }) }],
    });
    this.model = EmberObject.create({
      topics: [this.topic],
      for_period: "monthly",
      canLoadMore: false,
      loadingMore: false,
    });
    this.changePeriod = sinon.spy();
  });

  hooks.afterEach(function () {
    enableLoadMoreObserver();
    sinon.restore();
  });

  test("ranks use the returned order and retain real counts and native targets", async function (assert) {
    await render(<template><ISBFTopTopics @model={{this.model}} /></template>);
    assert.dom(".isbf-top-topics__rank").hasText("1");
    assert
      .dom(".isbf-top-topics__title")
      .hasText("Campus discussion")
      .hasAttribute("href", this.topic.lastUnreadUrl);
    assert.dom(".isbf-top-topics__summary").hasText("A short campus update.");
    assert
      .dom('[data-stat="replies"]')
      .hasAttribute("href", this.topic.firstPostUrl);
    assert.dom('[data-stat="replies"] .number').hasText("2");
    assert.dom('[data-stat="likes"] .number').hasText("0");
    assert.dom(".isbf-top-topics__unread").exists();
    assert.dom(".isbf-top-topics__author").hasText("student");
    assert.dom(".isbf-top-topics__list.topic-list").exists();
    assert.dom(".topic-list-header").doesNotExist();
  });

  test("untitled topics show escaped body text once and image-only posts retain a link", async function (assert) {
    this.topic.setProperties({
      title: UNTITLED,
      fancy_title: UNTITLED,
      excerpt: "<p>&lt;script&gt; Campus &amp; friends.</p>",
    });
    await render(<template><ISBFTopTopics @model={{this.model}} /></template>);
    assert.dom(".isbf-top-topics__title").hasText("<script> Campus & friends.");
    assert.dom(".isbf-top-topics__summary").doesNotExist();
    assert.dom(".isbf-top-topics script").doesNotExist();
    assert.dom(".isbf-top-topics").doesNotContainText("isbf-untitled");

    this.topic.set("excerpt", '<p><img src="/image.png"></p>');
    await settled();
    assert.dom(".isbf-top-topics__title").hasAttribute("href");
    assert.dom(".isbf-top-topics__title").matchesText(/\S/);
    assert.dom(".isbf-top-topics img").doesNotExist();
    assert.strictEqual(this.topic.title, UNTITLED);
  });

  test("hidden content is not reused as an excerpt", async function (assert) {
    this.topic.set("hidden", true);
    await render(<template><ISBFTopTopics @model={{this.model}} /></template>);
    assert.dom(".isbf-top-topics__summary").doesNotExist();
    assert.dom(".isbf-top-topics").doesNotContainText("A short campus update.");
  });

  test("the shared selector exposes configured periods and an empty period remains selectable", async function (assert) {
    this.model.set("topics", []);
    await render(
      <template>
        <DMenus />
        <ISBFTopTopics
          @model={{this.model}}
          @onPeriodChange={{this.changePeriod}}
        />
      </template>
    );
    assert.dom(".isbf-top-topics__empty").exists();
    assert.dom(".isbf-top-topics__list").doesNotExist();
    assert.dom(".isbf-top-topics__select").hasTagName("button");
    assert.dom(".d-select__native option").exists({ count: 6 });
    await select(".isbf-top-topics__select", "weekly");
    assert.true(this.changePeriod.calledOnceWithExactly("weekly"));
  });

  test("failed pagination preserves topics and can retry without duplicate ranks", async function (assert) {
    const model = this.model;
    model.set("canLoadMore", true);
    model.loadMore = sinon.stub();
    model.loadMore.onFirstCall().callsFake(() => {
      model.set("loadingMore", true);
      return Promise.reject(new Error("Test pagination failure"));
    });
    model.loadMore.onSecondCall().callsFake(() => {
      model.setProperties({
        topics: [
          this.topic,
          Topic.create({
            id: 981002,
            title: "Another discussion",
            fancy_title: "Another discussion",
            posts_count: 1,
            views: 0,
            like_count: 0,
            category_id: this.topic.category_id,
          }),
        ],
        loadingMore: false,
        canLoadMore: false,
      });
      return Promise.resolve();
    });

    await render(<template><ISBFTopTopics @model={{this.model}} /></template>);
    await this.observations
      .find((entry) => entry.element.matches(".load-more-sentinel"))
      .trigger();
    assert.dom(".isbf-top-topics__retry").exists();
    assert.dom(".isbf-top-topics__item").exists({ count: 1 });
    assert.false(model.loadingMore);
    await click(".isbf-top-topics__retry");
    assert.dom(".isbf-top-topics__retry").doesNotExist();
    assert.dom(".isbf-top-topics__item").exists({ count: 2 });
    assert
      .dom(".isbf-top-topics__item:last-child .isbf-top-topics__rank")
      .hasText("2");
    assert.true(model.loadMore.calledTwice);
  });
});
