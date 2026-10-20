import { click, render, settled, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { themePrefix } from "virtual:theme";
import UserStream from "discourse/components/user-stream";
import UserSummaryTopic from "discourse/components/user-summary-topic";
import UserAction from "discourse/models/user-action";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";
import ISBFActivityPreview from "../../discourse/components/isbf-activity-preview";
import ISBFPostPreview from "../../discourse/components/isbf-post-preview";

const TITLE = "校园动态 [isbf-untitled:0ebf0f60-4f19-4cb0-a820-e10d4ac5c501]";
const COOKED =
  '<p>Campus photos.</p><a class="lightbox"><img src="/images/d-logo-sketch-small.png?preview=a" alt="2488243601b3ff3b12a9ad5fad7462c7"></a><img src="/images/d-logo-sketch-small.png?preview=b">';
let nextPreviewId = 780000;

module("ISBF | Integration | Component | ISBFPostPreview", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.postId = nextPreviewId;
    nextPreviewId += 10;
    this.topicId = this.postId + 1;
    this.href = `/t/campus/${this.topicId}`;
    this.requests = 0;
    this.observers = [];
    const observers = this.observers;
    this.observerStub = sinon
      .stub(window, "IntersectionObserver")
      .callsFake(function (callback) {
        observers.push(callback);
        return { observe() {}, disconnect() {} };
      });
    pretender.get("/posts/:id/cooked", () => {
      this.requests++;
      return response({ cooked: COOKED });
    });
    pretender.get("/posts/by_number/:topicId/:postNumber.json", (request) => {
      this.requests++;
      const number = Number.parseInt(request.params["postNumber.json"], 10);
      return response({
        id: this.postId + number - 1,
        cooked: number === 1 ? COOKED : "<p>This is the popular reply.</p>",
      });
    });
    this.owner
      .lookup("service:router")
      .set("currentURL", "/u/eviltrout/activity");
    this.item = UserAction.create({
      action_type: 4,
      post_id: this.postId,
      post_number: 1,
      topic_id: this.topicId,
      slug: "campus",
      title: TITLE,
      user_id: this.currentUser.id,
      username: this.currentUser.username,
      avatar_template: "/letter_avatar_proxy/v4/letter/e/00ccdd/{size}.png",
      created_at: new Date().toISOString(),
      category_id: this.site.categories[0].id,
      excerpt:
        '<p>Campus photos.</p><a class="lightbox">[2488243601b3ff3b12a9ad5fad7462c7]</a>',
      truncated: true,
    });
    this.outletArgs = { item: this.item };
  });

  hooks.afterEach(function () {
    this.observerStub.restore();
  });

  test("untitled activity loads image previews only after becoming visible", async function (assert) {
    await render(
      <template>
        <ISBFActivityPreview @outletArgs={{this.outletArgs}} />
      </template>
    );
    assert
      .dom(".isbf-activity-preview__title")
      .doesNotExist("the internal title is omitted");
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus photos.", "the initial excerpt omits filenames");
    assert.strictEqual(this.requests, 0, "offscreen content is not requested");
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    assert
      .dom(".isbf-post-preview__image")
      .exists({ count: 2 }, "both image thumbnails are displayed");
    assert
      .dom(".isbf-post-preview__image")
      .hasAttribute(
        "alt",
        i18n(themePrefix("isbf_v2.preview_image")),
        "the filename is not an image label"
      );
    assert
      .dom(".isbf-activity-preview__metadata .badge-category.--style-square")
      .exists("the native square category badge is used");
  });

  test("the real activity stream previews a historical topic without a post ID", async function (assert) {
    this.item.set("post_id", null);
    this.stream = {
      content: [this.item],
      loading: false,
      canLoadMore: false,
      findItems: async () => [],
    };
    await render(<template><UserStream @stream={{this.stream}} /></template>);
    assert
      .dom(".user-stream-item")
      .hasClass(
        "isbf-activity-item",
        "the native row and outlet agree that the historical topic is eligible"
      );
    assert
      .dom(".isbf-activity-preview__title")
      .doesNotExist(
        "the internal title is omitted through the real stream outlet"
      );
    assert
      .dom(".isbf-post-preview__text")
      .hasText(
        "Campus photos.",
        "the initial preview omits the image filename"
      );
    this.observers.forEach((callback) => callback([{ isIntersecting: true }]));
    await settled();
    assert
      .dom(".isbf-post-preview__image")
      .exists(
        { count: 2 },
        "a record without a post ID still loads both thumbnails"
      );
  });

  test("the native summary topic link uses the body for an untitled topic", async function (assert) {
    this.summaryTopic = { id: this.topicId, title: TITLE, fancyTitle: TITLE };
    await render(
      <template>
        <UserSummaryTopic
          @createdAt={{this.item.created_at}}
          @likes={{4}}
          @postNumber={{1}}
          @topic={{this.summaryTopic}}
          @url={{this.href}}
        />
      </template>
    );
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    assert
      .dom(".isbf-post-preview.--summary")
      .hasText(
        "Campus photos.",
        "the topic's first post replaces its internal title"
      );
    assert.dom(".like-count").hasText("4", "the original like count remains");
    assert
      .dom(".isbf-post-preview__image")
      .doesNotExist("the summary remains a compact text list");
  });

  test("an untitled popular reply previews its own post number", async function (assert) {
    this.summaryTopic = { id: this.topicId, title: TITLE, fancyTitle: TITLE };
    this.replyHref = `${this.href}/7`;
    await render(
      <template>
        <UserSummaryTopic
          @createdAt={{this.item.created_at}}
          @postNumber={{7}}
          @topic={{this.summaryTopic}}
          @url={{this.replyHref}}
        />
      </template>
    );
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    assert
      .dom(".isbf-post-preview__text")
      .hasText(
        "This is the popular reply.",
        "the reply body is used instead of the topic's first post"
      );
    assert
      .dom(".isbf-post-preview")
      .hasAttribute(
        "href",
        this.replyHref,
        "the original reply target is preserved"
      );
  });

  test("an explicitly titled recent discussion needs no body request", async function (assert) {
    await render(
      <template>
        <ISBFPostPreview
          @href={{this.href}}
          @postId={{this.postId}}
          @title="Campus news"
          @variant="rail"
        />
      </template>
    );
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus news", "the explicit title remains");
    assert.strictEqual(
      this.observers.length,
      0,
      "a titled row needs no observer"
    );
    assert.strictEqual(this.requests, 0, "a titled row needs no body request");
  });

  test("a recent untitled discussion retains the production text-only rail", async function (assert) {
    this.title = TITLE;
    await render(
      <template>
        <ISBFPostPreview
          @href={{this.href}}
          @postId={{this.postId}}
          @title={{this.title}}
          @variant="rail"
        />
      </template>
    );
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus photos.", "the body replaces the internal title");
    assert
      .dom(".isbf-post-preview__image")
      .doesNotExist("the production rail does not show thumbnails");
    assert
      .dom(".isbf-post-preview")
      .hasAttribute("href", this.href, "the post link remains usable");
  });

  test("failed activity images are removed while the post link remains usable", async function (assert) {
    await render(
      <template>
        <ISBFActivityPreview @outletArgs={{this.outletArgs}} />
      </template>
    );
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    await triggerEvent(".isbf-post-preview__image", "error", {
      bubbles: false,
    });
    assert
      .dom(".isbf-post-preview__image")
      .hasAttribute(
        "src",
        new URL(
          "/images/d-logo-sketch-small.png?preview=b",
          window.location.href
        ).href,
        "the remaining thumbnail survives the failed image"
      );
    await triggerEvent(".isbf-post-preview__image", "error", {
      bubbles: false,
    });
    assert
      .dom(".isbf-post-preview__image")
      .doesNotExist("a failed image is removed");
    assert
      .dom(".isbf-post-preview")
      .hasAttribute("href", this.item.postUrl, "the post link remains usable");
  });

  test("a failed request retains a clean excerpt and post link", async function (assert) {
    pretender.get("/posts/:id/cooked", () =>
      response(503, { errors: ["Unavailable"] })
    );
    await render(
      <template>
        <ISBFActivityPreview @outletArgs={{this.outletArgs}} />
      </template>
    );
    this.observers[0]([{ isIntersecting: true }]);
    await settled();
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus photos.", "the clean initial text remains");
    assert
      .dom(".isbf-post-preview")
      .hasAttribute(
        "href",
        this.item.postUrl,
        "the link survives the failed request"
      );
  });

  test("hidden activity does not display or request its body", async function (assert) {
    this.item.set("hidden", true);
    await render(
      <template>
        <ISBFActivityPreview @outletArgs={{this.outletArgs}} />
      </template>
    );
    assert
      .dom(".isbf-post-preview__text")
      .hasText("View update", "hidden content uses a neutral link");
    assert.strictEqual(
      this.observers.length,
      0,
      "hidden content has no observer"
    );
    assert.strictEqual(this.requests, 0, "hidden content is not fetched");
  });

  test("the native expand control still displays and folds the full body", async function (assert) {
    pretender.get(`/posts/by_number/${this.topicId}/1.json`, () =>
      response({ cooked: "<p>Full campus post.</p>" })
    );
    await render(
      <template>
        <ISBFActivityPreview @outletArgs={{this.outletArgs}} />
      </template>
    );
    await click(".isbf-activity-preview .expand-item");
    assert
      .dom(".isbf-activity-preview__body")
      .hasText(
        "Full campus post.",
        "native expansion displays the cooked post"
      );
    await click(".isbf-activity-preview .collapse-item");
    assert
      .dom(".isbf-activity-preview__body")
      .doesNotExist("native collapse returns to the preview");
    assert
      .dom(".isbf-post-preview__text")
      .hasText("Campus photos.", "the preview is restored");
  });
});
