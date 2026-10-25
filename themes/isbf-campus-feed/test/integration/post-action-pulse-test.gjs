import { hash } from "@ember/helper";
import EmberObject from "@ember/object";
import {
  clearRender,
  click,
  find,
  render,
  settled,
  triggerEvent,
  waitFor,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import PostMenuLikeButton from "discourse/components/post/menu/buttons/like";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import DButton from "discourse/ui-kit/d-button";
import ISBFPostActionCount from "../../discourse/components/isbf-post-action-count";
import {
  ISBFTopicBookmark,
  ISBFTopicLike,
  ISBFTopicReply,
} from "../../discourse/components/isbf-topic-actions";
import PostActionPulse from "../../discourse/lib/post-action-pulse";
import postActionPulse from "../../discourse/modifiers/post-action-pulse";

const toggle = ".toggle-like";
const rolling = "[data-isbf-count-rolling]";
const running = "[data-isbf-pulse-running]";

async function pointerClick(selector) {
  await triggerEvent(selector, "pointerdown", { button: 0, isPrimary: true });
  await triggerEvent(selector, "pointerup", { button: 0 });
  await triggerEvent(selector, "click", { button: 0, detail: 1 });
}

function deferred() {
  let resolve;
  const promise = new Promise((done) => (resolve = done));
  return { promise, resolve };
}

module("ISBF | Integration | Post action pulse", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.post = EmberObject.create({
      id: 990080,
      post_number: 2,
      username: "pulse_user",
      showLike: true,
      canToggleLike: true,
      liked: false,
      likeCount: 8,
      topic: { id: 990081, archived: false },
    });
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)");
    this.reduced = sinon.stub(this.motion, "matches").get(() => false);
    const nativeMatchMedia = window.matchMedia.bind(window);
    sinon
      .stub(window, "matchMedia")
      .callsFake((query) =>
        query === "(prefers-reduced-motion: reduce)"
          ? this.motion
          : nativeMatchMedia(query)
      );
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  test("the optional native hooks keep the default animation and numeric count", async function (assert) {
    this.toggleLike = sinon.spy();
    await render(
      <template>
        <PostMenuLikeButton
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
          @showLabel={{false}}
        />
      </template>
    );
    assert.dom(".like-count").hasText("8");
    find(toggle).click();
    await waitFor(".heart-animation");
    assert.false(
      this.toggleLike.called,
      "the default still has its native delay"
    );
    await waitUntil(() => this.toggleLike.calledOnce);
    assert.dom(".heart-animation").doesNotExist();
  });

  test("the count block preserves the owner's icon and native users menu", async function (assert) {
    this.post.setProperties({ yours: true, showLike: false });
    const menu = this.owner.lookup("service:menu");
    const show = sinon.spy();
    sinon.stub(menu, "show").value(show);
    await render(
      <template>
        <PostMenuLikeButton @post={{this.post}} @showLabel={{false}}>
          <:count as |count|><strong
              class="custom-count"
            >{{count}}</strong></:count>
        </PostMenuLikeButton>
      </template>
    );
    assert.dom(".my-likes .d-icon").exists();
    assert.dom(".custom-count").hasText("8");
    await click(".like-count");
    assert.true(show.calledOnce, "the original count action opens its menu");
    assert.strictEqual(show.firstCall.args[1].data.post, this.post);
  });

  test("a pointer press pulses immediately while a slow like keeps the real count", async function (assert) {
    const request = deferred();
    this.toggleLike = sinon.spy(async () => {
      await request.promise;
      this.post.setProperties({ likeCount: 9, liked: true });
    });
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await pointerClick(toggle);
    assert.true(
      this.toggleLike.calledOnce,
      "the request starts without the old delay"
    );
    assert.dom(running).exists();
    assert.dom(".heart-animation").doesNotExist();
    assert.dom(".isbf-post-action-count__value").hasText("8");
    await waitUntil(() => !find(running));
    request.resolve();
    await waitFor(rolling);
    assert.dom(".isbf-post-action-count__value").hasText("9");
    assert.dom(".isbf-post-action-count__slot").exists({ count: 1 });
    assert.dom(".isbf-post-action-count__roll").hasText("89");
    await waitUntil(() => !find(rolling));
    assert.dom(".isbf-post-action-count__motion").hasText("");
  });

  test("decrements and multi-digit changes roll in the proper direction", async function (assert) {
    this.post.setProperties({ likeCount: 10, liked: true });
    this.toggleLike = () =>
      this.post.setProperties({ likeCount: 9, liked: false });
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await pointerClick(toggle);
    await waitFor(rolling);
    assert.dom(".isbf-post-action-count__roll > span:first-child").hasText("9");
    assert.dom(".isbf-post-action-count__roll > span:last-child").hasText("10");
    assert.true(
      find(".isbf-post-action-count").clientWidth >=
        find(".isbf-post-action-count__slot").scrollWidth,
      "the previous multi-digit count stays visible throughout the roll"
    );
    await waitUntil(() => !find(rolling));
    assert.dom(".isbf-post-action-count__value").hasText("9");
  });

  test("keyboard and external count updates are immediate", async function (assert) {
    this.toggleLike = () =>
      this.post.setProperties({ likeCount: 9, liked: true });
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await click(toggle);
    assert.dom(running).doesNotExist();
    assert.dom(rolling).doesNotExist();
    assert.dom(".isbf-post-action-count__value").hasText("9");
    this.post.set("likeCount", 15);
    await settled();
    assert.dom(rolling).doesNotExist();
    assert.dom(".isbf-post-action-count__value").hasText("15");
  });

  test("a failed request leaves no stale local transition for later updates", async function (assert) {
    this.toggleLike = sinon.spy(async () => {});
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await pointerClick(toggle);
    await waitUntil(() => !find(running));
    this.post.set("likeCount", 12);
    await settled();
    assert.dom(rolling).doesNotExist();
    assert.dom(".isbf-post-action-count__value").hasText("12");
  });

  test("zero counts keep the native entry rules and count clicks do not pulse", async function (assert) {
    this.post.set("likeCount", 0);
    this.toggleLike = () =>
      this.post.setProperties({ likeCount: 1, liked: true });
    const menu = this.owner.lookup("service:menu");
    sinon.stub(menu, "show");
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    assert.dom(".like-count").doesNotExist();
    await pointerClick(toggle);
    assert.dom(".isbf-post-action-count__value").hasText("1");
    await waitUntil(() => !find(running));
    await pointerClick(".like-count");
    assert.dom(running).doesNotExist();
    assert.dom(rolling).doesNotExist();
    this.post.setProperties({ likeCount: 0, liked: false });
    await settled();
    assert.dom(".like-count").doesNotExist();
  });

  test("disabled controls never start a run", async function (assert) {
    this.post.set("canToggleLike", false);
    this.toggleLike = sinon.spy();
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    find(toggle).dispatchEvent(
      new PointerEvent("pointerdown", { bubbles: true, button: 0 })
    );
    await settled();
    assert.dom("[data-isbf-pulse-pressed]").doesNotExist();
    assert.dom(running).doesNotExist();
    assert.false(this.toggleLike.called);
  });

  test("canceled touches release the pressed style without a run", async function (assert) {
    this.toggleLike = sinon.spy();
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await triggerEvent(toggle, "pointerdown", { button: 0 });
    assert.dom("[data-isbf-pulse-pressed]").exists();
    await triggerEvent(toggle, "pointercancel", { button: 0 });
    assert.dom("[data-isbf-pulse-pressed]").doesNotExist();
    assert.strictEqual(find(toggle).style.transform, "");
    assert.false(this.toggleLike.called);
  });

  test("reduced motion and a live preference change release all transforms", async function (assert) {
    this.toggleLike = () =>
      this.post.setProperties({ likeCount: 9, liked: true });
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await pointerClick(toggle);
    await waitFor(rolling);
    this.reduced.get(() => true);
    this.motion.dispatchEvent(new Event("change"));
    assert.dom(running).doesNotExist();
    assert.dom(rolling).doesNotExist();
    assert.strictEqual(find(toggle).style.transform, "");
    await pointerClick(toggle);
    assert.dom(running).doesNotExist();
    assert.dom(rolling).doesNotExist();
  });

  test("reply opens its native action without incrementing or selecting", async function (assert) {
    this.post.set("reply_count", 3);
    this.reply = sinon.spy();
    await render(
      <template>
        <ISBFTopicReply
          @buttonActions={{hash replyToPost=this.reply}}
          @post={{this.post}}
          @state={{hash currentUser=true canCreatePost=true}}
        />
      </template>
    );
    await pointerClick(".reply");
    assert.true(this.reply.calledOnce);
    assert.dom(running).exists();
    assert.dom(".isbf-post-action-count__value").hasText("3");
    assert.dom(".reply").doesNotHaveAttribute("aria-pressed");
  });

  test("the first-post bookmark tracks its model and uses the existing PUT routes", async function (assert) {
    const topic = EmberObject.create({ id: 990081, bookmarked: false });
    this.post.setProperties({ post_number: 1, topic, canBookmark: true });
    const requests = [];
    pretender.put("/t/990081/bookmark", () => {
      requests.push("create");
      return response({});
    });
    pretender.put("/t/990081/remove_bookmarks", () => {
      requests.push("remove");
      return response({});
    });
    await render(
      <template><ISBFTopicBookmark @post={{this.post}} /></template>
    );
    const button = ".isbf-topic-card__bookmark button";
    assert.dom(button).hasAttribute("aria-pressed", "false");
    await click(button);
    assert.true(topic.bookmarked);
    assert.dom(".isbf-topic-card__bookmark").hasClass("bookmarked");
    assert.dom(button).hasAttribute("aria-pressed", "true");
    await click(button);
    assert.false(topic.bookmarked);
    assert.dom(".isbf-topic-card__bookmark").doesNotHaveClass("bookmarked");
    assert.dom(button).hasAttribute("aria-pressed", "false");
    assert.deepEqual(requests, ["create", "remove"]);
  });

  test("compact counts retain their format and unchanged glyphs do not roll", async function (assert) {
    this.pulse = new PostActionPulse();
    this.set("value", 1201);
    this.change = () => {
      this.set("value", 1202);
      this.pulse.settle("like");
    };
    await render(
      <template>
        <DButton
          data-isbf-action-count={{this.value}}
          data-isbf-post-action="like"
          @action={{this.change}}
          @icon="heart"
          {{postActionPulse this.pulse}}
        ><ISBFPostActionCount
            @kind="like"
            @pulse={{this.pulse}}
            @value={{this.value}}
          /></DButton>
      </template>
    );
    const text = find(".isbf-post-action-count__value").textContent;
    await pointerClick("button");
    assert.dom(".isbf-post-action-count__value").hasText(text);
    assert.dom(rolling).doesNotExist();
  });

  test("a repeated press replaces the animation and destruction cancels it", async function (assert) {
    this.toggleLike = () => this.post.set("likeCount", this.post.likeCount + 1);
    await render(
      <template>
        <ISBFTopicLike
          @buttonActions={{hash toggleLike=this.toggleLike}}
          @post={{this.post}}
        />
      </template>
    );
    await pointerClick(toggle);
    await pointerClick(toggle);
    assert.dom(running).exists({ count: 1 });
    assert.dom(".isbf-post-action-count__value").hasText("10");
    const button = find(toggle);
    const count = find(".isbf-post-action-count");
    await clearRender();
    assert.strictEqual(button.style.transform, "");
    assert.false(button.hasAttribute("data-isbf-pulse-running"));
    assert.false(count.hasAttribute("data-isbf-count-rolling"));
    assert.strictEqual(count.getAnimations({ subtree: true }).length, 0);
  });
});
