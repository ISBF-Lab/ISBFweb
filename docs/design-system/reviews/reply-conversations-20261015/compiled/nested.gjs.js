import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { helper } from "@ember/component/helper";
import { array, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { cancel, next, schedule } from "@ember/runloop";
import { service } from "@ember/service";
import MoreTopics from "discourse/components/more-topics";
import PluginOutlet from "discourse/components/plugin-outlet";
import lazyHash from "discourse/helpers/lazy-hash";
import { flatRepliesEnabled } from "discourse/lib/flat-replies";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import DiscourseURL from "discourse/lib/url";
import PostStreamViewportTracker from "discourse/modifiers/post-stream-viewport-tracker";
import { and, gt, includes, not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DLoadMore from "discourse/ui-kit/d-load-more";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import NestedFloatingActions from "./nested/floating-actions";
import NestedHeader from "./nested/header";
import NestedOp from "./nested/op";
import NestedPost from "./nested/post";
import NestedSortSelector from "./nested/sort-selector";
import NestedTopicActions from "./nested/topic-actions";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
const postExcerpt = helper(([post]) => {
  const element = document.createElement("div");
  element.innerHTML = post.cooked ?? "";
  return element.textContent?.replace(/\s+/g, " ").trim();
});
// Depth is zero-based; depth 3 matches the server's root preload depth.
const MOBILE_ROOT_VIEW_COLLAPSE_DEPTH = 3;
const STORED_SCROLL_ANCHORS = Object.create(null);
// Exported so system specs can wait out the full restoration window.
export const SCROLL_RESTORE_WINDOW_MS = 1250;
export default class Nested extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "header", [service]);
  }
  #header = (i(this, "header"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "screenTrack", [service]);
  }
  #screenTrack = (i(this, "screenTrack"), void 0);
  static {
    g(this.prototype, "site", [service]);
  }
  #site = (i(this, "site"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  static {
    g(this.prototype, "cloakAbove", [tracked], function () {
      return 0;
    });
  }
  #cloakAbove = (i(this, "cloakAbove"), void 0);
  static {
    g(this.prototype, "cloakBelow", [tracked], function () {
      return 0;
    });
  }
  #cloakBelow = (i(this, "cloakBelow"), void 0);
  static {
    g(this.prototype, "focusDirection", [tracked], function () {
      return "forward";
    });
  }
  #focusDirection = (i(this, "focusDirection"), void 0);
  static {
    g(this.prototype, "focusedPath", [tracked], function () {
      return [];
    });
  }
  #focusedPath = (i(this, "focusedPath"), void 0);
  static {
    g(this.prototype, "mobileReturnAnchor", [tracked], function () {
      return null;
    });
  }
  #mobileReturnAnchor = (i(this, "mobileReturnAnchor"), void 0);
  viewportTracker = new PostStreamViewportTracker();
  #initialFocusedPathKey = null;
  #focusedPathsByPostNumber = new Map();
  #scrollAttempts = 0;
  #maxScrollAttempts = 20;
  #nextTimer = null;
  #retryTimer = null;
  #highlightTimer = null;
  #lastScrollKey = null;
  #lastRestoredScrollY = null;
  #activeScrollAnchorKey = null;
  #cancelledScrollAnchorKey = null;
  #restoringStoredScroll = false;
  #scrollRestoreCompletionTimer = null;
  #scrollRestoreTimers = [];
  #onPopstate = () => {
    this.#restoringStoredScroll = true;
    next(this, this.syncFocusFromURL);
  };
  #onScroll = () => this.#handleScroll();
  #onUserScrollIntent = () => this.#cancelUserScrollRestoration();
  #onUserScrollKey = event => {
    if (["ArrowDown", "ArrowUp", "End", "Home", "PageDown", "PageUp", " "].includes(event.key)) {
      this.#cancelUserScrollRestoration();
    }
  };
  #onPageHide = () => this.persistScrollAnchor();
  constructor() {
    super(...arguments);
    this.#restoringStoredScroll = Boolean(this.args.scrollAnchor || this.#loadStoredScrollAnchor());
    this.applyInitialFocusedPath();
    window.addEventListener("popstate", this.#onPopstate);
    window.addEventListener("scroll", this.#onScroll, {
      passive: true
    });
    window.addEventListener("touchmove", this.#onUserScrollIntent, {
      passive: true
    });
    window.addEventListener("wheel", this.#onUserScrollIntent, {
      passive: true
    });
    window.addEventListener("keydown", this.#onUserScrollKey);
    document.addEventListener("scroll", this.#onScroll, {
      passive: true
    });
    document.addEventListener("touchmove", this.#onUserScrollIntent, {
      passive: true
    });
    document.addEventListener("wheel", this.#onUserScrollIntent, {
      passive: true
    });
    window.addEventListener("pagehide", this.#onPageHide);
    this.router.on("routeWillChange", this.persistScrollAnchor);
    this.appEvents.on("keyboard:move-selection", this, this.maybeLoadMoreRoots);
    this.appEvents.on("nested:scroll-to-target", this, this.forceScheduleTargetScroll);
    this.appEvents.on("nested-replies:scroll-restored", this, this.clearMobileReturnAnchor);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("keyboard:move-selection", this, this.maybeLoadMoreRoots);
    this.appEvents.off("nested:scroll-to-target", this, this.forceScheduleTargetScroll);
    this.appEvents.off("nested-replies:scroll-restored", this, this.clearMobileReturnAnchor);
    cancel(this.#nextTimer);
    cancel(this.#retryTimer);
    this.#cancelScrollRestoration();
    clearTimeout(this.#highlightTimer);
    this.persistScrollAnchor();
    window.removeEventListener("popstate", this.#onPopstate);
    window.removeEventListener("scroll", this.#onScroll);
    window.removeEventListener("touchmove", this.#onUserScrollIntent);
    window.removeEventListener("wheel", this.#onUserScrollIntent);
    window.removeEventListener("keydown", this.#onUserScrollKey);
    document.removeEventListener("scroll", this.#onScroll);
    document.removeEventListener("touchmove", this.#onUserScrollIntent);
    document.removeEventListener("wheel", this.#onUserScrollIntent);
    window.removeEventListener("pagehide", this.#onPageHide);
    this.router.off("routeWillChange", this.persistScrollAnchor);
    this.viewportTracker.destroy();
  }
  get emptyPath() {
    return [];
  }
  get isMobileFocused() {
    return !flatRepliesEnabled(this.siteSettings) && this.site.mobileView && this.focusedPath.length > 0;
  }
  get viewClass() {
    return ["nested-view", this.args.contextMode ? "nested-context-view" : null, this.isMobileFocused ? "-mobile-focused" : null].filter(Boolean).join(" ");
  }
  get showContextBanner() {
    return this.args.contextMode && !this.site.mobileView;
  }
  get showParentContextLink() {
    return this.args.contextNoAncestors || this.args.ancestorsTruncated;
  }
  get mobileFocusClass() {
    return `nested-view__mobile-focus --${this.focusDirection}`;
  }
  get collapseFromDepth() {
    if (this.args.collapseReplies) {
      if (this.args.contextMode) {
        return this.args.rootNodes?.[0]?.post?.post_number === this.args.targetPostNumber ? 1 : null;
      }
      if (this.isMobileFocused) {
        return this.focusedPath.length > 1 ? null : 1;
      }
      return 0;
    }
    if (this.site.mobileView) {
      return MOBILE_ROOT_VIEW_COLLAPSE_DEPTH;
    }
    return null;
  }
  get rootScrollAnchor() {
    return this.mobileReturnAnchor || this.args.scrollAnchor;
  }
  get rootPostScrollAnchor() {
    return this.postLevelScrollAnchor(this.rootScrollAnchor);
  }
  get focusedPostScrollAnchor() {
    return this.postLevelScrollAnchor(this.args.scrollAnchor);
  }
  get focusedNode() {
    return this.focusedPath.at(-1);
  }
  get focusedNodes() {
    return this.focusedNode ? [this.focusedNode] : [];
  }
  get ancestorPath() {
    return this.focusedPath.slice(0, -1);
  }
  get initialFocusedPathKey() {
    return this.#focusedPathKey(this.args.initialFocusedPath);
  }
  get targetScrollKey() {
    return `${this.args.targetPostNumber}:${this.args.rootNodes?.[0]?._renderKey}`;
  }
  get #storedScrollAnchors() {
    return STORED_SCROLL_ANCHORS;
  }
  maybeLoadMoreRoots({
    selectedArticle,
    articles
  }) {
    if (!this.args.hasMoreRoots || this.args.loadingMore) {
      return;
    }
    if (selectedArticle === articles[articles.length - 1]) {
      this.args.loadMoreRoots?.();
    }
  }
  static {
    n(this.prototype, "maybeLoadMoreRoots", [action]);
  }
  postLevelScrollAnchor(anchor) {
    return Number.isFinite(anchor?.scrollY) ? null : anchor;
  }
  setCloakingBoundaries(above, below) {
    this.cloakAbove = above;
    this.cloakBelow = below;
  }
  static {
    n(this.prototype, "setCloakingBoundaries", [action]);
  }
  focusPath(path, returnAnchor) {
    if (!this.site.mobileView) {
      return;
    }
    if (!this.isMobileFocused) {
      this.mobileReturnAnchor = returnAnchor || this.findScrollAnchor() || this.scrollAnchorForPath(path);
      this.args.saveScrollPosition?.(this.mobileReturnAnchor);
      this.#saveStoredScrollAnchor(this.mobileReturnAnchor, null);
    }
    this.focusDirection = path.length >= this.focusedPath.length ? "forward" : "back";
    this.focusedPath = path;
    this.#registerFocusedPath(path);
    this.#pushURLForFocusedPath(path);
  }
  static {
    n(this.prototype, "focusPath", [action]);
  }
  returnToAncestor(index) {
    this.focusPath(this.focusedPath.slice(0, index + 1));
  }
  static {
    n(this.prototype, "returnToAncestor", [action]);
  }
  clearFocus() {
    if (this.args.contextMode) {
      this.args.viewFullThread?.();
      return;
    }
    this.focusDirection = "back";
    this.mobileReturnAnchor ??= this.scrollAnchorForPath(this.focusedPath);
    this.focusedPath = [];
    this.#replaceURLForFocusedPath([]);
  }
  static {
    n(this.prototype, "clearFocus", [action]);
  }
  clearMobileReturnAnchor() {
    this.mobileReturnAnchor = null;
    this.args.clearScrollAnchor?.();
  }
  static {
    n(this.prototype, "clearMobileReturnAnchor", [action]);
  }
  captureScrollAnchor() {
    return this.findScrollAnchor();
  }
  static {
    n(this.prototype, "captureScrollAnchor", [action]);
  }
  persistScrollAnchor() {
    if (this.isDestroying || this.#restoringStoredScroll) {
      return;
    }
    const anchor = this.findScrollAnchor();
    if (anchor) {
      this.args.saveScrollPosition?.(anchor);
      this.#saveStoredScrollAnchor(anchor, this.isMobileFocused ? null : this.args.postNumber);
    }
  }
  static {
    n(this.prototype, "persistScrollAnchor", [action]);
  }
  restoreStoredScrollAnchor() {
    const anchor = this.args.scrollAnchor || this.#loadStoredScrollAnchor();
    if (!anchor) {
      return;
    }
    this.#cancelledScrollAnchorKey = null;
    this.#restoreScrollAnchorAfterRender(anchor);
  }
  static {
    n(this.prototype, "restoreStoredScrollAnchor", [action]);
  }
  restoreUpdatedScrollAnchor() {
    if (!this.args.scrollAnchor) {
      return;
    }
    const anchorKey = this.#scrollAnchorRestoreKey(this.args.scrollAnchor);
    if (anchorKey && anchorKey === this.#cancelledScrollAnchorKey) {
      return;
    }
    this.#restoreScrollAnchorAfterRender(this.args.scrollAnchor);
  }
  static {
    n(this.prototype, "restoreUpdatedScrollAnchor", [action]);
  }
  findScrollAnchor() {
    const articles = document.querySelectorAll(".nested-view__roots .nested-post [data-post-number]");
    let best = null;
    let bestDistance = Infinity;
    for (const article of articles) {
      const postElement = article.closest(".nested-post") || article;
      const rect = postElement.getBoundingClientRect();
      const distance = Math.abs(rect.top);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = {
          postNumber: Number(article.dataset.postNumber),
          offsetFromTop: rect.top,
          scrollY: window.scrollY
        };
      }
    }
    return best;
  }
  scrollAnchorForPath(path) {
    const rootNode = path?.[0];
    const postNumber = rootNode?.post?.post_number;
    if (!postNumber) {
      return null;
    }
    const postElement = document.querySelector(`.nested-view [data-post-number="${postNumber}"]`);
    const element = postElement?.closest(".nested-post") || postElement;
    if (!element) {
      return {
        postNumber,
        offsetFromTop: this.header.headerOffset
      };
    }
    return {
      postNumber,
      offsetFromTop: element.getBoundingClientRect().top,
      scrollY: window.scrollY
    };
  }
  scrollMobileFocusIntoContext(element) {
    if (!this.isMobileFocused || this.isDestroying) {
      return;
    }
    const ancestorRows = element.querySelectorAll(".nested-view__mobile-ancestor");
    const target = ancestorRows[ancestorRows.length - 1] || element.querySelector(".nested-view__mobile-focus-back");
    if (!target) {
      return;
    }
    const rect = target.getBoundingClientRect();
    window.scrollTo({
      top: window.scrollY + rect.top - this.#stickyHeaderBottom(),
      behavior: "auto"
    });
  }
  static {
    n(this.prototype, "scrollMobileFocusIntoContext", [action]);
  }
  applyInitialFocusedPath() {
    if (!this.site.mobileView) {
      return;
    }
    const key = this.initialFocusedPathKey;
    if (!this.args.initialFocusedPath?.length) {
      this.#initialFocusedPathKey = key;
      if (this.focusedPath.length > 0) {
        this.focusDirection = "back";
        this.focusedPath = [];
      }
      return;
    }
    if (key === this.#initialFocusedPathKey) {
      return;
    }
    this.#initialFocusedPathKey = key;
    this.focusDirection = "forward";
    this.focusedPath = this.args.initialFocusedPath;
    this.#registerFocusedPath(this.focusedPath);
  }
  static {
    n(this.prototype, "applyInitialFocusedPath", [action]);
  }
  syncFocusFromURL() {
    if (this.isDestroying || !this.site.mobileView) {
      return;
    }
    const postNumber = this.#postNumberFromCurrentURL();
    if (postNumber === undefined) {
      return;
    }
    if (!postNumber) {
      const storedAnchor = this.#loadStoredScrollAnchor();
      const anchor = this.mobileReturnAnchor || storedAnchor || (this.focusedPath.length > 0 ? this.scrollAnchorForPath(this.focusedPath) : null);
      this.args.setFocusedPostNumber?.(null, []);
      if (this.focusedPath.length > 0) {
        this.focusDirection = "back";
      }
      this.mobileReturnAnchor = anchor;
      this.focusedPath = [];
      if (anchor) {
        this.#restoreScrollAnchorAfterRender(anchor);
      } else {
        this.#restoringStoredScroll = false;
      }
      return;
    }
    const path = this.#focusedPathsByPostNumber.get(postNumber);
    if (!path) {
      this.#restoringStoredScroll = false;
      return;
    }
    this.args.setFocusedPostNumber?.(postNumber, path);
    this.focusDirection = path.length >= this.focusedPath.length ? "forward" : "back";
    this.focusedPath = path;
    this.#restoringStoredScroll = false;
  }
  static {
    n(this.prototype, "syncFocusFromURL", [action]);
  }
  scheduleTargetScroll() {
    this.#scheduleTargetScroll();
  }
  static {
    n(this.prototype, "scheduleTargetScroll", [action]);
  }
  forceScheduleTargetScroll() {
    this.#scheduleTargetScroll({
      force: true
    });
  }
  static {
    n(this.prototype, "forceScheduleTargetScroll", [action]);
  }
  #handleScroll() {
    if (!this.#restoringStoredScroll) {
      this.persistScrollAnchor();
      return;
    }
    if (this.#isRestoredScrollEcho()) {
      return;
    }
    this.#cancelledScrollAnchorKey = this.#activeScrollAnchorKey || this.#scrollAnchorRestoreKey(this.args.scrollAnchor);
    this.#cancelScrollRestoration({
      clearAnchor: true
    });
    this.persistScrollAnchor();
  }
  #isRestoredScrollEcho() {
    return this.#lastRestoredScrollY != null && Math.abs(window.scrollY - this.#lastRestoredScrollY) <= 2;
  }
  #cancelUserScrollRestoration() {
    if (!this.#restoringStoredScroll && !this.args.scrollAnchor) {
      return;
    }
    this.#cancelledScrollAnchorKey = this.#activeScrollAnchorKey || this.#scrollAnchorRestoreKey(this.args.scrollAnchor);
    this.#cancelScrollRestoration({
      clearAnchor: true
    });
    this.persistScrollAnchor();
  }
  #cancelScrollRestoration({
    clearAnchor = false
  } = {}) {
    for (const timer of this.#scrollRestoreTimers) {
      clearTimeout(timer);
    }
    this.#scrollRestoreTimers = [];
    clearTimeout(this.#scrollRestoreCompletionTimer);
    this.#scrollRestoreCompletionTimer = null;
    if (clearAnchor) {
      this.args.clearScrollAnchor?.();
    }
    this.#activeScrollAnchorKey = null;
    this.#lastRestoredScrollY = null;
    this.#restoringStoredScroll = false;
  }
  #restoreScrollAnchorAfterRender(anchor) {
    this.#cancelScrollRestoration();
    this.#activeScrollAnchorKey = this.#scrollAnchorRestoreKey(anchor);
    this.#restoringStoredScroll = true;
    const initialScrollY = window.scrollY;
    schedule("afterRender", () => {
      if (!this.#restoringStoredScroll) {
        return;
      }
      if (Math.abs(window.scrollY - initialScrollY) > 2) {
        this.#cancelScrollRestoration({
          clearAnchor: true
        });
        return;
      }
      this.#restoreScrollAnchor(anchor);
      for (const delay of [50, 150, 300, 600, 1000]) {
        const timer = setTimeout(() => {
          if (this.#restoringStoredScroll) {
            this.#restoreScrollAnchor(anchor);
          }
        }, delay);
        this.#scrollRestoreTimers.push(timer);
      }
      this.#scrollRestoreCompletionTimer = setTimeout(() => {
        this.#cancelScrollRestoration({
          clearAnchor: true
        });
      }, SCROLL_RESTORE_WINDOW_MS);
    });
  }
  #restoreScrollAnchor(anchor) {
    if (Number.isFinite(anchor.scrollY)) {
      window.scrollTo(0, anchor.scrollY);
      this.#lastRestoredScrollY = window.scrollY;
      return;
    }
    const article = document.querySelector(`.nested-post [data-post-number="${anchor.postNumber}"]`);
    const element = article?.closest(".nested-post") || article;
    if (element) {
      const rect = element.getBoundingClientRect();
      window.scrollTo(0, window.scrollY + rect.top - anchor.offsetFromTop);
      this.#lastRestoredScrollY = window.scrollY;
    }
  }
  #scrollAnchorRestoreKey(anchor) {
    if (!anchor) {
      return null;
    }
    return [anchor.postNumber, anchor.scrollY ?? "", anchor.offsetFromTop ?? ""].join(":");
  }
  #saveStoredScrollAnchor(anchor, postNumber = this.args.postNumber) {
    const key = this.#scrollAnchorKey(postNumber);
    this.#storedScrollAnchors[key] = anchor;
    try {
      sessionStorage.setItem(key, JSON.stringify(anchor));
    } catch {
      // Ignore storage failures; module-level in-memory cache still works.
    }
  }
  #loadStoredScrollAnchor(postNumber = this.args.postNumber) {
    const key = this.#scrollAnchorKey(postNumber);
    const cached = this.#storedScrollAnchors[key];
    if (cached) {
      return cached;
    }
    try {
      const value = sessionStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    } catch {
      return null;
    }
  }
  #scrollAnchorKey(postNumber = this.args.postNumber) {
    const parts = [this.args.topic.id];
    if (this.args.sort) {
      parts.push(`s=${this.args.sort}`);
    }
    if (postNumber) {
      parts.push(`p=${postNumber}`);
    }
    if (this.args.contextNoAncestors) {
      parts.push("c=0");
    }
    return `nested-view-scroll:${parts.join(":")}`;
  }
  #stickyHeaderBottom() {
    const headerWrap = document.querySelector(".d-header-wrap");
    return Math.max(0, headerWrap?.getBoundingClientRect().bottom || 0);
  }
  #focusedPathKey(path) {
    return (path || []).map(node => `${node._renderKey || node.post?.id}:${node.post?.id}`).join(":");
  }
  #pushURLForFocusedPath(path) {
    const postNumber = path.at(-1)?.post?.post_number || null;
    this.args.setFocusedPostNumber?.(postNumber, path);
    const url = this.#nestedURL(postNumber);
    if (this.#currentURLMatches(url)) {
      return;
    }
    DiscourseURL.pushState(url);
  }
  #replaceURLForFocusedPath(path) {
    const postNumber = path.at(-1)?.post?.post_number || null;
    this.args.setFocusedPostNumber?.(postNumber, path);
    const url = this.#nestedURL(postNumber);
    if (this.#currentURLMatches(url)) {
      return;
    }
    DiscourseURL.replaceState(url);
  }
  #registerFocusedPath(path) {
    path.forEach((node, index) => {
      const postNumber = node.post?.post_number;
      if (postNumber) {
        this.#focusedPathsByPostNumber.set(postNumber, path.slice(0, index + 1));
      }
    });
  }
  #postNumberFromCurrentURL() {
    const path = withoutPrefix(window.location.pathname);
    const match = /^\/t\/[^/]+\/(\d+)(?:\/(\d+))?/.exec(path);
    if (!match || String(match[1]) !== String(this.args.topic.id)) {
      return undefined;
    }
    return match[2] ? Number(match[2]) : null;
  }
  #currentURLMatches(url) {
    const current = withoutPrefix(`${window.location.pathname}${window.location.search}`);
    const target = withoutPrefix(url);
    return current === target;
  }
  #scheduleTargetScroll({
    force = false
  } = {}) {
    if (!this.args.targetPostNumber || this.isMobileFocused) {
      return;
    }
    const scrollKey = this.targetScrollKey;
    if (!force && scrollKey === this.#lastScrollKey) {
      return;
    }
    this.#lastScrollKey = scrollKey;
    cancel(this.#nextTimer);
    cancel(this.#retryTimer);
    clearTimeout(this.#highlightTimer);
    this.#scrollAttempts = 0;
    this.#nextTimer = next(this, this.#scrollToTarget);
  }
  #scrollToTarget() {
    if (this.isDestroying) {
      return;
    }
    const postNumber = this.args.targetPostNumber;
    const target = document.querySelector(`.nested-view [data-post-number="${postNumber}"]`);
    if (target) {
      const postEl = target.closest(".nested-post");
      if (postEl) {
        postEl.classList.add("nested-post--highlighted");
        this.#highlightTimer = setTimeout(() => postEl.classList.remove("nested-post--highlighted"), 2000);
      }
      const controls = document.querySelector(".nested-view:not(.nested-context-view) > .nested-view__controls");
      const banner = document.querySelector(".nested-context-view > .nested-context-view__banner");
      const rect = target.getBoundingClientRect();
      window.scrollTo({
        top: window.scrollY + rect.top - (this.header.headerOffset || 0) - (controls?.offsetHeight || 0) - (banner?.offsetHeight || 0),
        behavior: "smooth"
      });
    } else if (this.#scrollAttempts < this.#maxScrollAttempts) {
      this.#scrollAttempts++;
      this.#retryTimer = schedule("afterRender", this, this.#scrollToTarget);
    }
  }
  #nestedURL(postNumber = null) {
    let path = `/t/${this.args.topic.slug}/${this.args.topic.id}`;
    if (postNumber) {
      path += `/${postNumber}`;
    }
    const params = new URLSearchParams();
    const defaultSort = this.siteSettings.nested_replies_default_sort || "top";
    if (this.args.sort && this.args.sort !== defaultSort) {
      params.set("sort", this.args.sort);
    }
    if (this.args.collapseReplies) {
      params.set("collapse_replies", "true");
    }
    const query = params.toString();
    return getURL(query ? `${path}?${query}` : path);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{this.viewClass}}
      data-topic-id={{@topic.id}}
      id="topic"
      {{didInsert this.scheduleTargetScroll}}
      {{didInsert this.restoreStoredScrollAnchor}}
      {{didUpdate this.scheduleTargetScroll @targetPostNumber @rootNodes}}
      {{didUpdate this.restoreUpdatedScrollAnchor @scrollAnchor}}
      {{didUpdate this.restoreUpdatedScrollAnchor @rootNodes}}
      {{didUpdate this.applyInitialFocusedPath @initialFocusedPath}}
      {{this.viewportTracker.setup
        eyeline=false
        headerOffset=this.header.headerOffset
        screenTrack=this.screenTrack
        setCloakingBoundaries=this.setCloakingBoundaries
        topicId=@topic.id
      }}
    >
      {{#each (array @topic) key="@identity" as |topic|}}
        <PluginOutlet
          @name="nested-topic-navigation"
          @outletArgs={{lazyHash topic=topic}}
        />
      {{/each}}
      <NestedHeader
        @buffered={{@buffered}}
        @cancelEditingTopic={{@cancelEditingTopic}}
        @canEditTags={{@canEditTags}}
        @editingTopic={{@editingTopic}}
        @finishedEditingTopic={{@finishedEditingTopic}}
        @minimumRequiredTags={{@minimumRequiredTags}}
        @showCategoryChooser={{@showCategoryChooser}}
        @startEditingTopic={{@startEditingTopic}}
        @topic={{@topic}}
        @topicCategoryChanged={{@topicCategoryChanged}}
        @topicTagsChanged={{@topicTagsChanged}}
      />
    
      <PluginOutlet
        @connectorTagName="div"
        @name="topic-above-post-stream"
        @outletArgs={{lazyHash model=@topic}}
      />
    
      {{#if this.isMobileFocused}}
        <div
          class={{this.mobileFocusClass}}
          {{didInsert this.scrollMobileFocusIntoContext}}
          {{didUpdate this.scrollMobileFocusIntoContext this.focusedPath}}
        >
          <button
            class="nested-view__mobile-focus-back"
            type="button"
            {{on "click" this.clearFocus}}
          >
            {{dIcon "chevron-left"}}
            <span>{{i18n "nested_replies.all_replies"}}</span>
          </button>
    
          {{#if this.ancestorPath.length}}
            <nav
              aria-label={{i18n "nested_replies.focused_path"}}
              class="nested-view__mobile-ancestors"
            >
              {{#each this.ancestorPath as |ancestorNode index|}}
                <button
                  aria-label={{i18n
                    "nested_replies.return_to_branch"
                    username=ancestorNode.post.username
                  }}
                  class="nested-view__mobile-ancestor"
                  data-test-nested-mobile-ancestor={{ancestorNode.post.post_number}}
                  type="button"
                  {{on "click" (fn this.returnToAncestor index)}}
                >
                  {{dIcon "chevron-left"}}
                  <span
                    aria-hidden="true"
                    class="nested-view__mobile-ancestor-avatar"
                  >
                    {{! PostAvatar renders a user link; keep this avatar non-interactive inside the ancestor button. }}
                    {{dAvatar
                      ancestorNode.post
                      imageSize="small"
                      hideTitle=true
                    }}
                  </span>
                  <span class="nested-view__mobile-ancestor-meta">
                    <span
                      class="nested-view__mobile-ancestor-username"
                    >{{ancestorNode.post.username}}</span>
                    <span class="nested-view__mobile-ancestor-excerpt">
                      {{postExcerpt ancestorNode.post}}
                    </span>
                  </span>
                </button>
              {{/each}}
            </nav>
          {{/if}}
    
          {{#each this.focusedNodes key="post.id" as |focusedNode|}}
            <div class="nested-view__mobile-focused-branch">
              <NestedPost
                @captureScrollAnchor={{this.captureScrollAnchor}}
                @changeNotice={{@changeNotice}}
                @changePostOwner={{@changePostOwner}}
                @children={{focusedNode.children}}
                @cloakAbove={{this.cloakAbove}}
                @cloakBelow={{this.cloakBelow}}
                @collapseFromDepth={{this.collapseFromDepth}}
                @deletePost={{@deletePost}}
                @depth={{0}}
                @editPost={{@editPost}}
                @expansionState={{@expansionState}}
                @fetchedChildrenCache={{@fetchedChildrenCache}}
                @focusPost={{this.focusPath}}
                @forceExpanded={{true}}
                @getCloakingData={{this.viewportTracker.getCloakingData}}
                @grantBadge={{@grantBadge}}
                @lockPost={{@lockPost}}
                @multiSelect={{@multiSelect}}
                @path={{this.ancestorPath}}
                @permanentlyDeletePost={{@permanentlyDeletePost}}
                @post={{focusedNode.post}}
                @postSelected={{@postSelected}}
                @rebakePost={{@rebakePost}}
                @recoverPost={{@recoverPost}}
                @registerPost={{this.viewportTracker.registerPost}}
                @replyToPost={{@replyToPost}}
                @scrollAnchor={{this.focusedPostScrollAnchor}}
                @selectBelow={{@selectBelow}}
                @selectReplies={{@selectReplies}}
                @showFlags={{@showFlags}}
                @showHistory={{@showHistory}}
                @showPagePublish={{@showPagePublish}}
                @sort={{@effectiveSort}}
                @togglePostSelection={{@togglePostSelection}}
                @togglePostType={{@togglePostType}}
                @toggleWiki={{@toggleWiki}}
                @topic={{@topic}}
                @unhidePost={{@unhidePost}}
                @unlockPost={{@unlockPost}}
              />
            </div>
          {{/each}}
        </div>
      {{else}}
        <NestedOp
          @changeNotice={{@changeNotice}}
          @changePostOwner={{@changePostOwner}}
          @deletePost={{@deletePost}}
          @editPost={{@editPost}}
          @grantBadge={{@grantBadge}}
          @lockPost={{@lockPost}}
          @multiSelect={{@multiSelect}}
          @permanentlyDeletePost={{@permanentlyDeletePost}}
          @post={{@opPost}}
          @postSelected={{@postSelected}}
          @rebakePost={{@rebakePost}}
          @recoverPost={{@recoverPost}}
          @registerPost={{this.viewportTracker.registerPost}}
          @replyToPost={{@replyToPost}}
          @selectBelow={{@selectBelow}}
          @selectReplies={{@selectReplies}}
          @showFlags={{@showFlags}}
          @showHistory={{@showHistory}}
          @showPagePublish={{@showPagePublish}}
          @showPostMenu={{true}}
          @togglePostSelection={{@togglePostSelection}}
          @togglePostType={{@togglePostType}}
          @toggleWiki={{@toggleWiki}}
          @topic={{@topic}}
          @unhidePost={{@unhidePost}}
          @unlockPost={{@unlockPost}}
        />
    
        {{#if this.currentUser}}
          <NestedTopicActions @topic={{@topic}} />
        {{/if}}
    
        <div class="nested-view__controls">
          <div class="nested-view__controls-left">
            <NestedSortSelector @current={{@sort}} @onChange={{@changeSort}} />
          </div>
    
          <div class="nested-view__controls-right">
            {{#if @topic.has_activity_log}}
              <DButton
                class="btn-flat nested-view__activity-link"
                @action={{@showActivityLog}}
                @label="nested_replies.activity_log.link"
              />
            {{/if}}
          </div>
        </div>
    
        {{#if this.showContextBanner}}
          <div class="nested-context-view__banner">
            <span class="nested-context-view__banner-icon">{{dIcon
                "nested-thread"
              }}</span>
            <span class="nested-context-view__banner-text">{{i18n
                "nested_replies.context.banner"
              }}</span>
            <div class="nested-context-view__nav">
              <DButton
                class="btn-default btn-small nested-context-view__full-thread"
                @action={{@viewFullThread}}
                @icon="arrow-left"
                @translatedLabel={{i18n
                  "nested_replies.context.view_full_topic"
                }}
              />
              {{#if this.showParentContextLink}}
                <DButton
                  class="btn-default btn-small nested-context-view__parent-context"
                  @action={{@viewParentContext}}
                  @icon="arrow-up"
                  @translatedLabel={{i18n
                    "nested_replies.context.view_parent_context"
                  }}
                />
              {{/if}}
            </div>
          </div>
        {{/if}}
    
        {{#if (gt @newRootPostCount 0)}}
          <div class="nested-view__new-replies">
            <DButton
              class="btn-primary nested-view__new-replies-btn"
              @action={{@loadNewRoots}}
              @translatedLabel={{i18n
                "nested_replies.new_replies"
                count=@newRootPostCount
              }}
            />
          </div>
        {{/if}}
    
        <div class="nested-view__roots">
          {{#if @firstRootPage}}
            <DButton
              class="btn-flat nested-view__previous-roots"
              @action={{@loadPreviousRoots}}
              @disabled={{@loadingPreviousRoots}}
              @label="nested_replies.load_previous_discussions"
            />
          {{/if}}
          {{#each @rootNodes key="_renderKey" as |node index|}}
            <NestedPost
              @captureScrollAnchor={{this.captureScrollAnchor}}
              @changeNotice={{@changeNotice}}
              @changePostOwner={{@changePostOwner}}
              @children={{node.children}}
              @cloakAbove={{this.cloakAbove}}
              @cloakBelow={{this.cloakBelow}}
              @collapseFromDepth={{this.collapseFromDepth}}
              @deletePost={{@deletePost}}
              @depth={{0}}
              @editPost={{@editPost}}
              @expansionState={{@expansionState}}
              @fetchedChildrenCache={{@fetchedChildrenCache}}
              @focusPost={{this.focusPath}}
              @getCloakingData={{this.viewportTracker.getCloakingData}}
              @grantBadge={{@grantBadge}}
              @isPinned={{includes @pinnedPostIds node.post.id}}
              @lockPost={{@lockPost}}
              @multiSelect={{@multiSelect}}
              @path={{this.emptyPath}}
              @permanentlyDeletePost={{@permanentlyDeletePost}}
              @post={{node.post}}
              @postSelected={{@postSelected}}
              @rebakePost={{@rebakePost}}
              @recoverPost={{@recoverPost}}
              @registerPost={{this.viewportTracker.registerPost}}
              @replyToPost={{@replyToPost}}
              @scrollAnchor={{this.rootPostScrollAnchor}}
              @selectBelow={{@selectBelow}}
              @selectReplies={{@selectReplies}}
              @showFlags={{@showFlags}}
              @showHistory={{@showHistory}}
              @showPagePublish={{@showPagePublish}}
              @sort={{@effectiveSort}}
              @togglePostSelection={{@togglePostSelection}}
              @togglePostType={{@togglePostType}}
              @toggleWiki={{@toggleWiki}}
              @topic={{@topic}}
              @unhidePost={{@unhidePost}}
              @unlockPost={{@unlockPost}}
            />
            <PluginOutlet
              @name="nested-roots-between"
              @outletArgs={{lazyHash topic=@topic index=index}}
            />
          {{else}}
            <div class="nested-view__empty">
              {{i18n "nested_replies.no_replies"}}
            </div>
          {{/each}}
        </div>
    
        <DConditionalLoadingSpinner @condition={{@loadingMore}} />
    
        <DLoadMore
          @action={{@loadMoreRoots}}
          @enabled={{@hasMoreRoots}}
          @isLoading={{@loadingMore}}
        />
      {{/if}}
    
      <PluginOutlet
        @connectorTagName="div"
        @name="topic-above-footer-buttons"
        @outletArgs={{lazyHash model=@topic}}
      />
    
      <PluginOutlet
        @connectorTagName="div"
        @name="topic-area-bottom"
        @outletArgs={{lazyHash model=@topic}}
      />
    
      {{#unless this.isMobileFocused}}
        <NestedFloatingActions
          @replyAction={{fn @replyToPost @opPost 0}}
          @topic={{@topic}}
        />
      {{/unless}}
    
      {{#if (and (not this.isMobileFocused) (not @hasMoreRoots))}}
        <PluginOutlet
          @connectorTagName="div"
          @name="topic-above-suggested"
          @outletArgs={{lazyHash model=@topic}}
        />
    
        <MoreTopics @topic={{@topic}} />
    
        <PluginOutlet
          @connectorTagName="div"
          @name="topic-below-suggested"
          @outletArgs={{lazyHash model=@topic}}
        />
      {{/if}}
    
      <PluginOutlet
        @connectorTagName="div"
        @name="topic-navigation-bottom"
        @outletArgs={{lazyHash model=@topic}}
      />
    
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[30,0,[\"viewClass\"]]],[16,\"data-topic-id\",[30,1,[\"id\"]]],[24,1,\"topic\"],[4,[32,0],[[30,0,[\"scheduleTargetScroll\"]]],null],[4,[32,0],[[30,0,[\"restoreStoredScrollAnchor\"]]],null],[4,[32,1],[[30,0,[\"scheduleTargetScroll\"]],[30,2],[30,3]],null],[4,[32,1],[[30,0,[\"restoreUpdatedScrollAnchor\"]],[30,4]],null],[4,[32,1],[[30,0,[\"restoreUpdatedScrollAnchor\"]],[30,3]],null],[4,[32,1],[[30,0,[\"applyInitialFocusedPath\"]],[30,5]],null],[4,[30,0,[\"viewportTracker\",\"setup\"]],null,[[\"eyeline\",\"headerOffset\",\"screenTrack\",\"setCloakingBoundaries\",\"topicId\"],[false,[30,0,[\"header\",\"headerOffset\"]],[30,0,[\"screenTrack\"]],[30,0,[\"setCloakingBoundaries\"]],[30,1,[\"id\"]]]]],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[28,[32,2],[[30,1]],null]],null]],null],\"@identity\",[[[1,\"    \"],[8,[32,3],null,[[\"@name\",\"@outletArgs\"],[\"nested-topic-navigation\",[28,[32,4],null,[[\"topic\"],[[30,6]]]]]],null],[1,\"\\n\"]],[6]],null],[1,\"  \"],[8,[32,5],null,[[\"@buffered\",\"@cancelEditingTopic\",\"@canEditTags\",\"@editingTopic\",\"@finishedEditingTopic\",\"@minimumRequiredTags\",\"@showCategoryChooser\",\"@startEditingTopic\",\"@topic\",\"@topicCategoryChanged\",\"@topicTagsChanged\"],[[30,7],[30,8],[30,9],[30,10],[30,11],[30,12],[30,13],[30,14],[30,1],[30,15],[30,16]]],null],[1,\"\\n\\n  \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-post-stream\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\\n\"],[41,[30,0,[\"isMobileFocused\"]],[[[1,\"    \"],[11,0],[16,0,[30,0,[\"mobileFocusClass\"]]],[4,[32,0],[[30,0,[\"scrollMobileFocusIntoContext\"]]],null],[4,[32,1],[[30,0,[\"scrollMobileFocusIntoContext\"]],[30,0,[\"focusedPath\"]]],null],[12],[1,\"\\n      \"],[11,\"button\"],[24,0,\"nested-view__mobile-focus-back\"],[24,4,\"button\"],[4,[32,6],[\"click\",[30,0,[\"clearFocus\"]]],null],[12],[1,\"\\n        \"],[1,[28,[32,7],[\"chevron-left\"],null]],[1,\"\\n        \"],[10,1],[12],[1,[28,[32,8],[\"nested_replies.all_replies\"],null]],[13],[1,\"\\n      \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"ancestorPath\",\"length\"]],[[[1,\"        \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,8],[\"nested_replies.focused_path\"],null]],[14,0,\"nested-view__mobile-ancestors\"],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"ancestorPath\"]]],null]],null],null,[[[1,\"            \"],[11,\"button\"],[16,\"aria-label\",[28,[32,8],[\"nested_replies.return_to_branch\"],[[\"username\"],[[30,17,[\"post\",\"username\"]]]]]],[24,0,\"nested-view__mobile-ancestor\"],[16,\"data-test-nested-mobile-ancestor\",[30,17,[\"post\",\"post_number\"]]],[24,4,\"button\"],[4,[32,6],[\"click\",[28,[32,9],[[30,0,[\"returnToAncestor\"]],[30,18]],null]],null],[12],[1,\"\\n              \"],[1,[28,[32,7],[\"chevron-left\"],null]],[1,\"\\n              \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"nested-view__mobile-ancestor-avatar\"],[12],[1,\"\\n\"],[1,\"                \"],[1,[28,[32,10],[[30,17,[\"post\"]]],[[\"imageSize\",\"hideTitle\"],[\"small\",true]]]],[1,\"\\n              \"],[13],[1,\"\\n              \"],[10,1],[14,0,\"nested-view__mobile-ancestor-meta\"],[12],[1,\"\\n                \"],[10,1],[14,0,\"nested-view__mobile-ancestor-username\"],[12],[1,[30,17,[\"post\",\"username\"]]],[13],[1,\"\\n                \"],[10,1],[14,0,\"nested-view__mobile-ancestor-excerpt\"],[12],[1,\"\\n                  \"],[1,[28,[32,11],[[30,17,[\"post\"]]],null]],[1,\"\\n                \"],[13],[1,\"\\n              \"],[13],[1,\"\\n            \"],[13],[1,\"\\n\"]],[17,18]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"focusedNodes\"]]],null]],null],\"post.id\",[[[1,\"        \"],[10,0],[14,0,\"nested-view__mobile-focused-branch\"],[12],[1,\"\\n          \"],[8,[32,12],null,[[\"@captureScrollAnchor\",\"@changeNotice\",\"@changePostOwner\",\"@children\",\"@cloakAbove\",\"@cloakBelow\",\"@collapseFromDepth\",\"@deletePost\",\"@depth\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@forceExpanded\",\"@getCloakingData\",\"@grantBadge\",\"@lockPost\",\"@multiSelect\",\"@path\",\"@permanentlyDeletePost\",\"@post\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@sort\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@unhidePost\",\"@unlockPost\"],[[30,0,[\"captureScrollAnchor\"]],[30,20],[30,21],[30,19,[\"children\"]],[30,0,[\"cloakAbove\"]],[30,0,[\"cloakBelow\"]],[30,0,[\"collapseFromDepth\"]],[30,22],0,[30,23],[30,24],[30,25],[30,0,[\"focusPath\"]],true,[30,0,[\"viewportTracker\",\"getCloakingData\"]],[30,26],[30,27],[30,28],[30,0,[\"ancestorPath\"]],[30,29],[30,19,[\"post\"]],[30,30],[30,31],[30,32],[30,0,[\"viewportTracker\",\"registerPost\"]],[30,33],[30,0,[\"focusedPostScrollAnchor\"]],[30,34],[30,35],[30,36],[30,37],[30,38],[30,39],[30,40],[30,41],[30,42],[30,1],[30,43],[30,44]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[19]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[8,[32,13],null,[[\"@changeNotice\",\"@changePostOwner\",\"@deletePost\",\"@editPost\",\"@grantBadge\",\"@lockPost\",\"@multiSelect\",\"@permanentlyDeletePost\",\"@post\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@showPostMenu\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@unhidePost\",\"@unlockPost\"],[[30,20],[30,21],[30,22],[30,23],[30,26],[30,27],[30,28],[30,29],[30,45],[30,30],[30,31],[30,32],[30,0,[\"viewportTracker\",\"registerPost\"]],[30,33],[30,34],[30,35],[30,36],[30,37],[30,38],true,[30,40],[30,41],[30,42],[30,1],[30,43],[30,44]]],null],[1,\"\\n\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"      \"],[8,[32,14],null,[[\"@topic\"],[[30,1]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"nested-view__controls\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"nested-view__controls-left\"],[12],[1,\"\\n        \"],[8,[32,15],null,[[\"@current\",\"@onChange\"],[[30,46],[30,47]]],null],[1,\"\\n      \"],[13],[1,\"\\n\\n      \"],[10,0],[14,0,\"nested-view__controls-right\"],[12],[1,\"\\n\"],[41,[30,1,[\"has_activity_log\"]],[[[1,\"          \"],[8,[32,16],[[24,0,\"btn-flat nested-view__activity-link\"]],[[\"@action\",\"@label\"],[[30,48],\"nested_replies.activity_log.link\"]],null],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"showContextBanner\"]],[[[1,\"      \"],[10,0],[14,0,\"nested-context-view__banner\"],[12],[1,\"\\n        \"],[10,1],[14,0,\"nested-context-view__banner-icon\"],[12],[1,[28,[32,7],[\"nested-thread\"],null]],[13],[1,\"\\n        \"],[10,1],[14,0,\"nested-context-view__banner-text\"],[12],[1,[28,[32,8],[\"nested_replies.context.banner\"],null]],[13],[1,\"\\n        \"],[10,0],[14,0,\"nested-context-view__nav\"],[12],[1,\"\\n          \"],[8,[32,16],[[24,0,\"btn-default btn-small nested-context-view__full-thread\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[30,49],\"arrow-left\",[28,[32,8],[\"nested_replies.context.view_full_topic\"],null]]],null],[1,\"\\n\"],[41,[30,0,[\"showParentContextLink\"]],[[[1,\"            \"],[8,[32,16],[[24,0,\"btn-default btn-small nested-context-view__parent-context\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[30,50],\"arrow-up\",[28,[32,8],[\"nested_replies.context.view_parent_context\"],null]]],null],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,17],[[30,51],0],null],[[[1,\"      \"],[10,0],[14,0,\"nested-view__new-replies\"],[12],[1,\"\\n        \"],[8,[32,16],[[24,0,\"btn-primary nested-view__new-replies-btn\"]],[[\"@action\",\"@translatedLabel\"],[[30,52],[28,[32,8],[\"nested_replies.new_replies\"],[[\"count\"],[[30,51]]]]]],null],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"nested-view__roots\"],[12],[1,\"\\n\"],[41,[30,53],[[[1,\"        \"],[8,[32,16],[[24,0,\"btn-flat nested-view__previous-roots\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,54],[30,55],\"nested_replies.load_previous_discussions\"]],null],[1,\"\\n\"]],[]],null],[42,[28,[31,1],[[28,[31,1],[[30,3]],null]],null],\"_renderKey\",[[[1,\"        \"],[8,[32,12],null,[[\"@captureScrollAnchor\",\"@changeNotice\",\"@changePostOwner\",\"@children\",\"@cloakAbove\",\"@cloakBelow\",\"@collapseFromDepth\",\"@deletePost\",\"@depth\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@getCloakingData\",\"@grantBadge\",\"@isPinned\",\"@lockPost\",\"@multiSelect\",\"@path\",\"@permanentlyDeletePost\",\"@post\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@sort\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@unhidePost\",\"@unlockPost\"],[[30,0,[\"captureScrollAnchor\"]],[30,20],[30,21],[30,56,[\"children\"]],[30,0,[\"cloakAbove\"]],[30,0,[\"cloakBelow\"]],[30,0,[\"collapseFromDepth\"]],[30,22],0,[30,23],[30,24],[30,25],[30,0,[\"focusPath\"]],[30,0,[\"viewportTracker\",\"getCloakingData\"]],[30,26],[28,[32,18],[[30,58],[30,56,[\"post\",\"id\"]]],null],[30,27],[30,28],[30,0,[\"emptyPath\"]],[30,29],[30,56,[\"post\"]],[30,30],[30,31],[30,32],[30,0,[\"viewportTracker\",\"registerPost\"]],[30,33],[30,0,[\"rootPostScrollAnchor\"]],[30,34],[30,35],[30,36],[30,37],[30,38],[30,39],[30,40],[30,41],[30,42],[30,1],[30,43],[30,44]]],null],[1,\"\\n        \"],[8,[32,3],null,[[\"@name\",\"@outletArgs\"],[\"nested-roots-between\",[28,[32,4],null,[[\"topic\",\"index\"],[[30,1],[30,57]]]]]],null],[1,\"\\n\"]],[56,57]],[[[1,\"        \"],[10,0],[14,0,\"nested-view__empty\"],[12],[1,\"\\n          \"],[1,[28,[32,8],[\"nested_replies.no_replies\"],null]],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]]],[1,\"    \"],[13],[1,\"\\n\\n    \"],[8,[32,19],null,[[\"@condition\"],[[30,59]]],null],[1,\"\\n\\n    \"],[8,[32,20],null,[[\"@action\",\"@enabled\",\"@isLoading\"],[[30,60],[30,61],[30,59]]],null],[1,\"\\n\"]],[]]],[1,\"\\n  \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-footer-buttons\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\\n  \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-area-bottom\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\\n\"],[41,[51,[30,0,[\"isMobileFocused\"]]],[[[1,\"    \"],[8,[32,21],null,[[\"@replyAction\",\"@topic\"],[[28,[32,9],[[30,33],[30,45],0],null],[30,1]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,22],[[28,[32,23],[[30,0,[\"isMobileFocused\"]]],null],[28,[32,23],[[30,61]],null]],null],[[[1,\"    \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-suggested\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\\n    \"],[8,[32,24],null,[[\"@topic\"],[[30,1]]],null],[1,\"\\n\\n    \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-below-suggested\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n  \"],[8,[32,3],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-navigation-bottom\",[28,[32,4],null,[[\"model\"],[[30,1]]]]]],null],[1,\"\\n\\n\"],[13]],[\"@topic\",\"@targetPostNumber\",\"@rootNodes\",\"@scrollAnchor\",\"@initialFocusedPath\",\"topic\",\"@buffered\",\"@cancelEditingTopic\",\"@canEditTags\",\"@editingTopic\",\"@finishedEditingTopic\",\"@minimumRequiredTags\",\"@showCategoryChooser\",\"@startEditingTopic\",\"@topicCategoryChanged\",\"@topicTagsChanged\",\"ancestorNode\",\"index\",\"focusedNode\",\"@changeNotice\",\"@changePostOwner\",\"@deletePost\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@grantBadge\",\"@lockPost\",\"@multiSelect\",\"@permanentlyDeletePost\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@replyToPost\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@effectiveSort\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@unhidePost\",\"@unlockPost\",\"@opPost\",\"@sort\",\"@changeSort\",\"@showActivityLog\",\"@viewFullThread\",\"@viewParentContext\",\"@newRootPostCount\",\"@loadNewRoots\",\"@firstRootPage\",\"@loadPreviousRoots\",\"@loadingPreviousRoots\",\"node\",\"index\",\"@pinnedPostIds\",\"@loadingMore\",\"@loadMoreRoots\",\"@hasMoreRoots\"],[\"each\",\"-track-array\",\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        didUpdate,
        array,
        PluginOutlet,
        lazyHash,
        NestedHeader,
        on,
        dIcon,
        i18n,
        fn,
        dAvatar,
        postExcerpt,
        NestedPost,
        NestedOp,
        NestedTopicActions,
        NestedSortSelector,
        DButton,
        gt,
        includes,
        DConditionalLoadingSpinner,
        DLoadMore,
        NestedFloatingActions,
        and,
        not,
        MoreTopics
      }),
      "isStrictMode": true
    }), this);
  }
}