import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { isDestroying, registerDestructor } from "@ember/destroyable";
import { array } from "@ember/helper";
import { service } from "@ember/service";
import { modifier as modifierFn } from "ember-modifier";
import { bind } from "discourse/lib/decorators";
import EmbedMode from "discourse/lib/embed-mode";
import discourseLater from "discourse/lib/later";
import { headerOffset } from "discourse/lib/offset-calculator";
import SwipeEvents, { getMaxAnimationTimeMs, shouldCloseMenu } from "discourse/lib/swipe-events";
import TrackedMediaQuery from "discourse/lib/tracked-media-query";
import { applyValueTransformer } from "discourse/lib/transformer";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dCloseOnClickOutside from "discourse/ui-kit/modifiers/d-close-on-click-outside";
import JumpToPost from "./modal/jump-to-post";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
const MIN_WIDTH_TIMELINE = 925;
const MIN_HEIGHT_TIMELINE = 325;
// State shared with the yielded block (the timeline / progress bar). Derived
// values read through injected fetchers rather than a back-reference to the
// component, so tracking is preserved without coupling.
class TopicNavigationInfo {
  static {
    g(this.prototype, "topicProgressExpanded", [tracked], function () {
      return false;
    });
  }
  #topicProgressExpanded = (i(this, "topicProgressExpanded"), void 0);
  static {
    g(this.prototype, "prevEvent", [tracked], function () {
      return null;
    });
  }
  #prevEvent = (i(this, "prevEvent"), void 0);
  #postCountFetcher;
  #renderTimelineFetcher;
  constructor(postCountFetcher, renderTimelineFetcher) {
    this.#postCountFetcher = postCountFetcher;
    this.#renderTimelineFetcher = renderTimelineFetcher;
  }
  get renderTimeline() {
    return this.#renderTimelineFetcher();
  }
  get withTopicProgress() {
    return !this.renderTimeline && this.#postCountFetcher() > 1;
  }
}
export default class TopicNavigation extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "composer", [service]);
  }
  #composer = (i(this, "composer"), void 0);
  static {
    g(this.prototype, "modal", [service]);
  }
  #modal = (i(this, "modal"), void 0);
  static {
    g(this.prototype, "site", [service]);
  }
  #site = (i(this, "site"), void 0);
  static {
    g(this.prototype, "composerHeight", [tracked], function () {
      return 0;
    });
  }
  #composerHeight = (i(this, "composerHeight"), void 0);
  info = new TopicNavigationInfo(() => this.args.topic.posts_count, () => this.renderTimeline);
  widthQuery = this.setupWidthQuery();
  movingElement = null;
  pxClosed = 0;
  setupSwipe = modifierFn(element => {
    if (!this.site.mobileView) {
      return;
    }
    const swipeEvents = new SwipeEvents(element);
    swipeEvents.addTouchListeners();
    element.addEventListener("swipestart", this.onSwipeStart);
    element.addEventListener("swipeend", this.onSwipeEnd);
    element.addEventListener("swipecancel", this.onSwipeCancel);
    element.addEventListener("swipe", this.onSwipe);
    return () => {
      element.removeEventListener("swipestart", this.onSwipeStart);
      element.removeEventListener("swipeend", this.onSwipeEnd);
      element.removeEventListener("swipecancel", this.onSwipeCancel);
      element.removeEventListener("swipe", this.onSwipe);
      swipeEvents.removeTouchListeners();
    };
  });
  #heightQuery = null;
  constructor() {
    super(...arguments);
    this.setupAppEvents();
    this.updateComposerHeight();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#heightQuery?.teardown();
  }
  get renderTimeline() {
    // Expanded == mobile fullscreen mode; always render.
    if (this.info.topicProgressExpanded) {
      return true;
    }
    return applyValueTransformer("topic-navigation-render-timeline", this.#fitsTimeline, {
      topic: this.args.topic
    });
  }
  get #fitsTimeline() {
    if (this.site.mobileView || EmbedMode.enabled) {
      return false;
    }
    if (!this.widthQuery.matches) {
      return false;
    }
    // If composer is open, check we have enough vertical space.
    if (this.composer.isPreviewActive) {
      return this.heightQuery?.matches ?? false;
    }
    return true;
  }
  get heightQuery() {
    const threshold = this.composer.isPreviewActive ? MIN_HEIGHT_TIMELINE + this.composerHeight + headerOffset() : null;
    return this.#buildHeightQuery(threshold);
  }
  static {
    n(this.prototype, "heightQuery", [cached]);
  }
  setupAppEvents() {
    this.appEvents.on("topic:current-post-scrolled", this.topicScrolled).on("topic:jump-to-post", this.collapseFullscreen).on("topic:keyboard-trigger", this.keyboardTrigger).on("topic:toggle-progress-expansion", this.toggleProgressExpansion).on("composer:resized", this.updateComposerHeight);
    registerDestructor(this, () => {
      this.appEvents.off("topic:current-post-scrolled", this.topicScrolled).off("topic:jump-to-post", this.collapseFullscreen).off("topic:keyboard-trigger", this.keyboardTrigger).off("topic:toggle-progress-expansion", this.toggleProgressExpansion).off("composer:resized", this.updateComposerHeight);
    });
  }
  setupWidthQuery() {
    const query = new TrackedMediaQuery(`(min-width: ${MIN_WIDTH_TIMELINE}px)`);
    registerDestructor(this, () => query.teardown());
    return query;
  }
  updateComposerHeight() {
    this.composerHeight = document.querySelector("#reply-control")?.offsetHeight || 0;
  }
  static {
    n(this.prototype, "updateComposerHeight", [bind]);
  }
  topicScrolled(event) {
    this.info.prevEvent = event;
  }
  static {
    n(this.prototype, "topicScrolled", [bind]);
  }
  toggleProgressExpansion() {
    this.info.topicProgressExpanded = !this.info.topicProgressExpanded;
  }
  static {
    n(this.prototype, "toggleProgressExpansion", [bind]);
  }
  closeOnClickOutside() {
    if (this.info.topicProgressExpanded) {
      this.collapseFullscreen();
    }
  }
  static {
    n(this.prototype, "closeOnClickOutside", [bind]);
  }
  collapseFullscreen(postId, delay = 500) {
    if (!this.info.topicProgressExpanded) {
      return;
    }
    document.querySelectorAll(".timeline-fullscreen").forEach(el => el.classList.remove("show"));
    discourseLater(() => {
      if (isDestroying(this)) {
        return;
      }
      this.info.topicProgressExpanded = false;
    }, delay);
  }
  static {
    n(this.prototype, "collapseFullscreen", [bind]);
  }
  keyboardTrigger(e) {
    if (e.type === "jump") {
      this.modal.show(JumpToPost, {
        model: {
          topic: this.args.topic,
          postCount: this.args.postCount,
          jumpToIndex: this.args.jumpToIndex,
          jumpToDate: this.args.jumpToDate
        }
      });
    }
  }
  static {
    n(this.prototype, "keyboardTrigger", [bind]);
  }
  onSwipeStart(event) {
    const e = event.detail;
    const target = e.originalEvent.target;
    if (target.classList.contains("docked") || !target.closest(".timeline-container")) {
      event.preventDefault();
      return;
    }
    e.originalEvent.preventDefault();
    const centeredElement = document.elementFromPoint(e.center.x, e.center.y);
    if (centeredElement.closest(".timeline-scrollarea-wrapper")) {
      event.preventDefault();
    } else if (e.direction === "up" || e.direction === "down") {
      this.movingElement = document.querySelector(".timeline-container");
    }
  }
  static {
    n(this.prototype, "onSwipeStart", [bind]);
  }
  onSwipeCancel() {
    const durationMs = getMaxAnimationTimeMs();
    const timelineContainer = document.querySelector(".timeline-container");
    timelineContainer.animate([{
      transform: `translate3d(0, 0, 0)`
    }], {
      duration: durationMs,
      fill: "forwards",
      easing: "ease-out"
    });
  }
  static {
    n(this.prototype, "onSwipeCancel", [bind]);
  }
  onSwipeEnd(event) {
    const e = event.detail;
    const timelineContainer = document.querySelector(".timeline-container");
    const maxOffset = timelineContainer.offsetHeight;
    let durationMs;
    if (shouldCloseMenu(e, "bottom")) {
      const distancePx = maxOffset - this.pxClosed;
      durationMs = getMaxAnimationTimeMs(distancePx / Math.abs(e.velocityY));
      timelineContainer.animate([{
        transform: `translate3d(0, ${maxOffset}px, 0)`
      }], {
        duration: durationMs,
        fill: "forwards"
      }).finished.then(() => this.collapseFullscreen(null, 0));
    } else {
      const distancePx = this.pxClosed;
      durationMs = getMaxAnimationTimeMs(distancePx / Math.abs(e.velocityY));
      timelineContainer.animate([{
        transform: `translate3d(0, 0, 0)`
      }], {
        duration: durationMs,
        fill: "forwards",
        easing: "ease-out"
      });
    }
  }
  static {
    n(this.prototype, "onSwipeEnd", [bind]);
  }
  onSwipe(event) {
    const e = event.detail;
    e.originalEvent.preventDefault();
    this.pxClosed = Math.max(0, e.deltaY);
    this.movingElement.animate([{
      transform: `translate3d(0, ${this.pxClosed}px, 0)`
    }], {
      fill: "forwards"
    });
  }
  static {
    n(this.prototype, "onSwipe", [bind]);
  }
  #buildHeightQuery(threshold) {
    this.#heightQuery?.teardown();
    this.#heightQuery = threshold === null ? null : new TrackedMediaQuery(`(min-height: ${threshold}px)`);
    return this.#heightQuery;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{dConcatClass
        (if this.info.topicProgressExpanded "topic-progress-expanded")
        (if this.info.renderTimeline "with-timeline")
        (if this.info.withTopicProgress "with-topic-progress")
      }}
      ...attributes
      {{this.setupSwipe}}
      {{dCloseOnClickOutside this.closeOnClickOutside}}
    >
      {{! Fully rerender when topic changes (see 4f328089d6f). }}
      {{#each (array @topic) key="id"}}
        {{yield this.info this.toggleProgressExpansion}}
      {{/each}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[28,[32,0],[[52,[30,0,[\"info\",\"topicProgressExpanded\"]],\"topic-progress-expanded\"],[52,[30,0,[\"info\",\"renderTimeline\"]],\"with-timeline\"],[52,[30,0,[\"info\",\"withTopicProgress\"]],\"with-topic-progress\"]],null]],[17,1],[4,[30,0,[\"setupSwipe\"]],null,null],[4,[32,1],[[30,0,[\"closeOnClickOutside\"]]],null],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[28,[32,2],[[30,2]],null]],null]],null],\"id\",[[[1,\"    \"],[18,3,[[30,0,[\"info\"]],[30,0,[\"toggleProgressExpansion\"]]]],[1,\"\\n\"]],[]],null],[13]],[\"&attrs\",\"@topic\",\"&default\"],[\"if\",\"each\",\"-track-array\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        dCloseOnClickOutside,
        array
      }),
      "isStrictMode": true
    }), this);
  }
}