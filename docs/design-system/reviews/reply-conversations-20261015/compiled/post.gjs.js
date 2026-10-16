import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { cancel, scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import ShareTopicModal from "discourse/components/modal/share-topic";
import NestedRepliesExpandButton from "discourse/components/nested-replies-expand-button";
import PluginOutlet from "discourse/components/plugin-outlet";
import PostAvatar from "discourse/components/post/avatar";
import PostCookedHtml from "discourse/components/post/cooked-html";
import PostLinks from "discourse/components/post/links";
import PostMenu from "discourse/components/post/menu";
import PostMetaData from "discourse/components/post/meta-data";
import PostNotice from "discourse/components/post/notice";
import lazyHash from "discourse/helpers/lazy-hash";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { isTesting } from "discourse/lib/environment";
import { flatRepliesEnabled } from "discourse/lib/flat-replies";
import getURL, { getAbsoluteURL } from "discourse/lib/get-url";
import postActionFeedback from "discourse/lib/post-action-feedback";
import { nativeShare } from "discourse/lib/pwa-utils";
import { clipboardCopy } from "discourse/lib/utilities";
import { and, not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import nestedPostUrl from "../../lib/nested-post-url";
import processNode from "../../lib/process-node";
import NestedPostChildren from "./post-children";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class NestedPost extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "capabilities", [service]);
  }
  #capabilities = (i(this, "capabilities"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "modal", [service]);
  }
  #modal = (i(this, "modal"), void 0);
  static {
    g(this.prototype, "site", [service]);
  }
  #site = (i(this, "site"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  static {
    g(this.prototype, "store", [service]);
  }
  #store = (i(this, "store"), void 0);
  static {
    g(this.prototype, "expanded", [tracked]);
  }
  #expanded = (i(this, "expanded"), void 0);
  static {
    g(this.prototype, "lineHighlighted", [tracked], function () {
      return false;
    });
  }
  #lineHighlighted = (i(this, "lineHighlighted"), void 0);
  static {
    g(this.prototype, "collapsed", [tracked]);
  }
  #collapsed = (i(this, "collapsed"), void 0);
  static {
    g(this.prototype, "showDeletedContent", [tracked], function () {
      return false;
    });
  }
  #showDeletedContent = (i(this, "showDeletedContent"), void 0);
  static {
    g(this.prototype, "showIgnoredContent", [tracked], function () {
      return false;
    });
  }
  #showIgnoredContent = (i(this, "showIgnoredContent"), void 0);
  static {
    g(this.prototype, "loadingIgnoredContent", [tracked], function () {
      return false;
    });
  }
  #loadingIgnoredContent = (i(this, "loadingIgnoredContent"), void 0);
  static {
    g(this.prototype, "loadingReplies", [tracked], function () {
      return false;
    });
  }
  #loadingReplies = (i(this, "loadingReplies"), void 0);
  restoreScroll = modifier(element => {
    const anchor = this.args.scrollAnchor;
    if (anchor?.postNumber !== this.args.post.post_number) {
      return;
    }
    const anchorKey = [anchor.postNumber, anchor.scrollY ?? "", anchor.offsetFromTop ?? ""].join(":");
    if (anchorKey === this.#restoredScrollAnchorKey) {
      return;
    }
    this.#restoredScrollAnchorKey = anchorKey;
    if (Number.isFinite(anchor.scrollY)) {
      window.scrollTo(0, anchor.scrollY);
    } else {
      const rect = element.getBoundingClientRect();
      window.scrollTo(0, window.scrollY + rect.top - anchor.offsetFromTop);
    }
    // Defer the event to avoid backtracking re-render errors during the render phase
    Promise.resolve().then(() => {
      this.appEvents.trigger("nested-replies:scroll-restored");
    });
  });
  #restoredScrollAnchorKey = null;
  #postRegistered = false;
  #postRegistrationTimer;
  static {
    g(this.prototype, "_childWasCreated", [tracked], function () {
      return false;
    });
  }
  #_childWasCreated = (i(this, "_childWasCreated"), void 0);
  constructor() {
    super(...arguments);
    const cached = this.args.expansionState?.get(this.args.post.post_number);
    if (cached !== undefined) {
      this.expanded = cached.expanded;
      this.collapsed = cached.collapsed;
    } else {
      const wouldExpand = (this.flatReplies ? this.args.post.target_post_number > this.args.post.post_number : (this.args.children?.length ?? 0) > 0) || this.args.post.deleted_post_placeholder === true || this.args.post.ignored_post_placeholder === true;
      // collapseFromDepth is the URL-driven cutoff (set by the parent view —
      // 0 for root view, 1 for context view). At/below it, the post renders
      // but its children start hidden behind an "Expand X replies" button.
      if (!this.flatReplies && this.args.collapseFromDepth != null && this.args.depth >= this.args.collapseFromDepth) {
        this.expanded = false;
      } else {
        this.expanded = wouldExpand;
      }
      this.collapsed = false;
    }
    this.appEvents.on("nested-replies:child-created", this, this._onChildCreated);
    this.#postRegistrationTimer = scheduleOnce("afterRender", this, this.#registerPost);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this.#postRegistrationTimer);
    this.appEvents.off("nested-replies:child-created", this, this._onChildCreated);
    if (this.#postRegistered) {
      this.appEvents.trigger("nested-replies:post-unregistered", this.args.post);
    }
  }
  get isRoot() {
    return this.args.depth === 0;
  }
  get flatReplies() {
    return flatRepliesEnabled(this.siteSettings);
  }
  get renderChildren() {
    return !this.effectiveCollapsed && !this.atMaxDepth && (this.effectiveExpanded || this.flatReplies && this.hasReplies);
  }
  get previewChildren() {
    return this.flatReplies && !this.effectiveExpanded;
  }
  get cloakingData() {
    if (!this.isRoot || !this.args.getCloakingData) {
      return {
        active: false
      };
    }
    return this.args.getCloakingData(this.args.post, {
      above: this.args.cloakAbove,
      below: this.args.cloakBelow
    });
  }
  get depthClass() {
    return `--depth-${this.args.depth}`;
  }
  get isMobile() {
    return this.site.mobileView;
  }
  get canCreatePost() {
    return this.currentUser && this.args.topic?.details?.can_create_post;
  }
  get hasReplies() {
    return this._childWasCreated || (this.args.post.direct_reply_count || 0) > 0 || (this.args.children?.length ?? 0) > 0;
  }
  get replyCount() {
    const count = this.args.post.total_descendant_count || this.args.post.direct_reply_count || this.args.children?.length || 0;
    return this._childWasCreated ? Math.max(count, 1) : count;
  }
  get atMaxDepth() {
    return this.args.depth >= this.siteSettings.nested_replies_max_depth;
  }
  get isDeletedPlaceholder() {
    return this.args.post.deleted_post_placeholder === true;
  }
  get isIgnoredPlaceholder() {
    return this.args.post.ignored_post_placeholder === true;
  }
  get renderIgnoredPlaceholder() {
    return this.isIgnoredPlaceholder && !this.showIgnoredContent;
  }
  get showContinueThread() {
    return this.atMaxDepth && this.hasReplies && !this.siteSettings.nested_replies_cap_nesting_depth;
  }
  get showDepthLine() {
    return !this.flatReplies && (!this.hasReplies || !this.atMaxDepth || this.showContinueThread);
  }
  get depthLineCollapsed() {
    return this.hasReplies && !this.expanded;
  }
  get showDepthLineIcon() {
    return !this.hasReplies || this.expanded;
  }
  get showExpandRepliesButton() {
    return !this.flatReplies && this.hasReplies && !this.effectiveExpanded && !this.atMaxDepth;
  }
  get childPath() {
    return [...(this.args.path || []), {
      post: this.args.post,
      children: this.args.children || []
    }];
  }
  get mobileFocusEnabled() {
    return !this.flatReplies && this.site.mobileView && this.args.focusPost;
  }
  get childDepth() {
    return this.args.depth + 1;
  }
  get effectiveExpanded() {
    return this.args.forceExpanded || this.expanded;
  }
  get effectiveCollapsed() {
    return !this.args.forceExpanded && this.collapsed;
  }
  get isOP() {
    return this.args.post.user_id === this.args.topic?.user_id;
  }
  get selected() {
    return this.args.multiSelect && this.args.postSelected?.(this.args.post);
  }
  get contextUrl() {
    return getURL(`/t/${this.args.topic.slug}/${this.args.topic.id}/${this.args.post.post_number}?context=0`);
  }
  get expandLabel() {
    return i18n("nested_replies.collapsed_replies", {
      count: this.replyCount
    });
  }
  get collapsedBarLabel() {
    return this.hasReplies ? this.expandLabel : i18n("nested_replies.collapsed_post");
  }
  get depthLineLabel() {
    if (this.site.mobileView && !this.args.forceExpanded) {
      return i18n("nested_replies.collapse");
    }
    if (this.depthLineCollapsed) {
      return this.expandLabel;
    }
    return i18n("nested_replies.collapse");
  }
  get childCacheKey() {
    return `${this.args.topic?.id}:${this.args.post.post_number}`;
  }
  get nestedShareUrl() {
    return nestedPostUrl(this.args.topic, this.args.post.post_number);
  }
  childPathWithChildren(children) {
    return [...(this.args.path || []), {
      post: this.args.post,
      children: children || []
    }];
  }
  childPathWithNewChild(childPost) {
    const children = this.args.children || [];
    const hasChild = children.some(node => node.post?.id === childPost?.id || node.post?.post_number === childPost?.post_number);
    return [...(this.args.path || []), {
      post: this.args.post,
      children: hasChild ? children : [{
        post: childPost,
        children: []
      }, ...children]
    }];
  }
  toggleExpanded() {
    if (this.flatReplies) {
      this.expanded = !this.expanded;
      this.collapsed = false;
      this.args.expansionState?.set(this.args.post.post_number, {
        expanded: this.expanded,
        collapsed: false
      });
      return;
    }
    if (!this.hasReplies) {
      this.collapsed = !this.collapsed;
      this.lineHighlighted = false;
      this.args.expansionState?.set(this.args.post.post_number, {
        expanded: this.expanded,
        collapsed: this.collapsed
      });
      return;
    }
    if (this.expanded) {
      this.expanded = false;
      this.collapsed = true;
      this.lineHighlighted = false;
    } else {
      this.expanded = true;
      this.collapsed = false;
    }
    this.args.expansionState?.set(this.args.post.post_number, {
      expanded: this.expanded,
      collapsed: this.collapsed
    });
  }
  static {
    n(this.prototype, "toggleExpanded", [action]);
  }
  collapsePost() {
    if (this.hasReplies) {
      this.expanded = false;
    }
    this.collapsed = true;
    this.lineHighlighted = false;
    this.args.expansionState?.set(this.args.post.post_number, {
      expanded: this.expanded,
      collapsed: this.collapsed
    });
  }
  async childrenForMobileFocus() {
    const cacheKey = this.childCacheKey;
    const identityKey = [this.args.topic?.id, this.args.post.post_number, this.args.sort].join(":");
    const cached = this.args.fetchedChildrenCache?.get(cacheKey);
    if (cached) {
      return cached.childNodes;
    }
    if ((this.args.children?.length ?? 0) > 0 || !this.hasReplies) {
      return this.args.children || [];
    }
    this.loadingReplies = true;
    try {
      const query = new URLSearchParams({
        sort: this.args.sort || "top",
        depth: this.childDepth
      });
      const data = await ajax(`/n/${this.args.topic.slug}/${this.args.topic.id}/children/${this.args.post.post_number}.json?${query}`);
      if (this.isDestroying || this.childCacheKey !== cacheKey || [this.args.topic?.id, this.args.post.post_number, this.args.sort].join(":") !== identityKey) {
        return null;
      }
      const childNodes = (data.children || []).filter(child => child.topic_id != null && String(child.topic_id) === String(this.args.topic?.id)).map(child => processNode(this.store, this.args.topic, child));
      this.args.fetchedChildrenCache?.set(cacheKey, {
        childNodes,
        page: data.page,
        hasMore: data.has_more || false,
        fetchedFromServer: true
      });
      return childNodes;
    } catch (e) {
      if (!this.isDestroying) {
        popupAjaxError(e);
      }
      return null;
    } finally {
      if (!this.isDestroying) {
        this.loadingReplies = false;
      }
    }
  }
  async handleReplies() {
    if (this.loadingReplies) {
      return;
    }
    if (this.mobileFocusEnabled) {
      const returnAnchor = this.args.captureScrollAnchor?.();
      const children = await this.childrenForMobileFocus();
      if (children && !this.isDestroying) {
        this.args.focusPost(this.childPathWithChildren(children), returnAnchor);
      }
      return;
    }
    this.toggleExpanded();
  }
  static {
    n(this.prototype, "handleReplies", [action]);
  }
  handleDepthLine() {
    if (this.site.mobileView && !this.args.forceExpanded) {
      this.collapsePost();
      return;
    }
    this.toggleExpanded();
  }
  static {
    n(this.prototype, "handleDepthLine", [action]);
  }
  toggleDeletedContent() {
    this.showDeletedContent = !this.showDeletedContent;
  }
  static {
    n(this.prototype, "toggleDeletedContent", [action]);
  }
  async revealIgnoredContent() {
    if (this.showIgnoredContent || this.loadingIgnoredContent) {
      return;
    }
    const post = this.args.post;
    try {
      this.loadingIgnoredContent = true;
      const result = await ajax(`/posts/${post.id}/cooked.json`);
      post.set("cooked", result.cooked);
      this.showIgnoredContent = true;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loadingIgnoredContent = false;
    }
  }
  static {
    n(this.prototype, "revealIgnoredContent", [action]);
  }
  highlightLine() {
    if (!this.site.mobileView) {
      this.lineHighlighted = true;
    }
  }
  static {
    n(this.prototype, "highlightLine", [action]);
  }
  unhighlightLine() {
    this.lineHighlighted = false;
  }
  static {
    n(this.prototype, "unhighlightLine", [action]);
  }
  copyLink() {
    if (this.site.mobileView) {
      return this.share();
    }
    const post = this.args.post;
    const postId = post.id;
    let actionCallback = () => clipboardCopy(getAbsoluteURL(this.nestedShareUrl));
    if (isTesting()) {
      actionCallback = () => {};
    }
    postActionFeedback({
      postId,
      actionClass: "post-action-menu__copy-link",
      messageKey: "post.controls.link_copied",
      actionCallback,
      errorCallback: () => this.share()
    });
  }
  static {
    n(this.prototype, "copyLink", [action]);
  }
  async share() {
    const post = this.args.post;
    try {
      await nativeShare(this.capabilities, {
        url: getAbsoluteURL(this.nestedShareUrl)
      });
    } catch {
      const topic = this.args.topic;
      this.modal.show(ShareTopicModal, {
        model: {
          category: topic.category,
          topic,
          post
        }
      });
    }
  }
  static {
    n(this.prototype, "share", [action]);
  }
  async toggleLike() {
    const post = this.args.post;
    const likeAction = post.likeAction;
    if (likeAction?.canToggle) {
      try {
        await likeAction.togglePromise(post);
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }
  static {
    n(this.prototype, "toggleLike", [action]);
  }
  togglePostSelection() {
    return this.args.togglePostSelection?.(this.args.post);
  }
  static {
    n(this.prototype, "togglePostSelection", [action]);
  }
  selectReplies() {
    return this.args.selectReplies?.(this.args.post);
  }
  static {
    n(this.prototype, "selectReplies", [action]);
  }
  selectBelow() {
    return this.args.selectBelow?.(this.args.post);
  }
  static {
    n(this.prototype, "selectBelow", [action]);
  }
  showLogin() {
    getOwner(this).lookup("route:application").send("showLogin");
  }
  static {
    n(this.prototype, "showLogin", [action]);
  }
  #registerPost() {
    if (this.isDestroying) {
      return;
    }
    this.#postRegistered = true;
    this.appEvents.trigger("nested-replies:post-registered", this.args.post);
  }
  _onChildCreated({
    topicId,
    post: childPost,
    parentPostNumber,
    isOwnPost
  }) {
    if (String(topicId) !== String(this.args.topic?.id) || parentPostNumber !== this.args.post.post_number) {
      return;
    }
    const post = this.args.post;
    post.set("direct_reply_count", (post.direct_reply_count || 0) + 1);
    post.set("total_descendant_count", (post.total_descendant_count || 0) + 1);
    this._childWasCreated = true;
    if (!this.expanded && (!this.flatReplies || isOwnPost)) {
      this.expanded = true;
      this.collapsed = false;
      this.args.expansionState?.set(this.args.post.post_number, {
        expanded: true,
        collapsed: false
      });
    }
    if (isOwnPost && this.mobileFocusEnabled) {
      this.args.focusPost(this.childPathWithNewChild(childPost));
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{dConcatClass
        "nested-post"
        this.depthClass
        (if @parentLineHighlighted "--parent-line-highlighted")
        (if this.effectiveCollapsed "nested-post--collapsed")
        (if @isPinned "nested-post--pinned")
        (if @post.isWhisper "nested-post--whisper")
        (if
          (or @post.isModeratorAction (and @post.isWarning @post.firstPost))
          "post--moderator moderator"
        )
        (if @post.hidden "nested-post--hidden post--hidden post-hidden")
        (if (or @post.deleted @post.user_deleted) "nested-post--deleted")
        (if this.cloakingData.active "nested-post--cloaked")
        (if this.selected "selected")
      }}
      data-root-index={{if this.isRoot @post.root_index}}
      style={{this.cloakingData.style}}
      {{this.restoreScroll}}
      {{! At depth 0, register wrapper with cloaking observer (captures full subtree height).
          At deeper depths, register as trackOnly (viewport tracking only, no cloaking). }}
      {{@registerPost @post trackOnly=(not this.isRoot)}}
    >
      {{#unless this.cloakingData.active}}
        {{#if @collapseParent}}
          <button
            aria-label={{i18n "nested_replies.collapse_parent"}}
            class="nested-post__parent-line-btn"
            type="button"
            {{on "click" @collapseParent}}
            {{on "mouseenter" @highlightParentLine}}
            {{on "mouseleave" @unhighlightParentLine}}
          ></button>
        {{/if}}
        <div class="nested-post__gutter">
          {{#if this.isDeletedPlaceholder}}
            <div class="nested-post__placeholder-avatar">
              {{dIcon "trash-can"}}
            </div>
          {{else if this.renderIgnoredPlaceholder}}
            <button
              aria-label={{i18n "nested_replies.toggle_ignored_content"}}
              class="nested-post__placeholder-avatar nested-post__placeholder-avatar--reveal"
              data-post-number={{@post.post_number}}
              disabled={{this.loadingIgnoredContent}}
              type="button"
              {{on "click" this.revealIgnoredContent}}
            >
              {{#if this.loadingIgnoredContent}}
                {{dIcon "spinner" class="fa-spin"}}
              {{else}}
                {{dIcon "far-eye-slash"}}
              {{/if}}
            </button>
          {{else}}
            <PostAvatar @post={{@post}} @size="small" />
          {{/if}}
          {{#if (and this.showDepthLine (not this.effectiveCollapsed))}}
            <button
              aria-label={{this.depthLineLabel}}
              class={{dConcatClass
                "nested-post__depth-line"
                (if this.lineHighlighted "nested-post__depth-line--highlighted")
                (unless this.hasReplies "nested-post__depth-line--leaf")
                (if
                  this.depthLineCollapsed "nested-post__depth-line--collapsed"
                )
              }}
              type="button"
              {{on "click" this.handleDepthLine}}
              {{on "mouseenter" this.highlightLine}}
              {{on "mouseleave" this.unhighlightLine}}
            >
              {{#if this.showDepthLineIcon}}
                <span class="nested-post__depth-line-icon">
                  {{dIcon "discourse-circle-minus"}}
                </span>
              {{/if}}
            </button>
          {{/if}}
        </div>
        <div class="nested-post__main">
          {{#if this.effectiveCollapsed}}
            <button
              class="nested-post__collapsed-bar"
              data-post-number={{@post.post_number}}
              type="button"
              {{on "click" this.toggleExpanded}}
            >
              {{dIcon "discourse-circle-plus"}}
              {{#if this.isDeletedPlaceholder}}
                <span class="nested-post__collapsed-username">{{i18n
                    "nested_replies.deleted_post_placeholder"
                  }}</span>
              {{else if this.renderIgnoredPlaceholder}}
                <span class="nested-post__collapsed-username">{{i18n
                    "nested_replies.ignored_post_placeholder"
                  }}</span>
              {{else}}
                <span
                  class="nested-post__collapsed-username"
                >{{@post.username}}</span>
              {{/if}}
              <span
                aria-hidden="true"
                class="nested-post__collapsed-separator"
              >&middot;</span>
              <span
                class="nested-post__collapsed-reply-count"
              >{{this.collapsedBarLabel}}</span>
            </button>
          {{else if this.isDeletedPlaceholder}}
            <div
              class="nested-post__placeholder nested-post__placeholder--deleted"
              data-post-number={{@post.post_number}}
            >
              <div class="nested-post__placeholder-actions">
                <span class="nested-post__placeholder-label">{{i18n
                    "nested_replies.deleted_post_placeholder"
                  }}</span>
                {{#if this.currentUser.staff}}
                  <DButton
                    class="btn-flat toggle-deleted-content"
                    @action={{this.toggleDeletedContent}}
                    @ariaLabel="post.controls.view_deleted"
                    @icon={{if
                      this.showDeletedContent
                      "far-eye-slash"
                      "far-eye"
                    }}
                  />
                {{/if}}
                {{#if @post.can_recover}}
                  <DButton
                    class="btn-flat recover"
                    @action={{fn @recoverPost @post}}
                    @ariaLabel="post.controls.undelete"
                    @icon="arrow-rotate-left"
                  />
                {{/if}}
              </div>
              {{#if this.showDeletedContent}}
                <div class="nested-post__placeholder-reveal">
                  <div class="nested-post__placeholder-reveal-header">
                    <PostAvatar @post={{@post}} @size="small" />
                    <PostMetaData @post={{@post}} />
                  </div>
                  <PostCookedHtml @post={{@post}} />
                </div>
              {{/if}}
            </div>
          {{else if this.renderIgnoredPlaceholder}}
            <div
              class="nested-post__placeholder nested-post__placeholder--ignored"
              data-post-number={{@post.post_number}}
            >
              <div class="nested-post__placeholder-actions">
                <span class="nested-post__placeholder-label">{{i18n
                    "nested_replies.ignored_post_placeholder"
                  }}</span>
              </div>
            </div>
          {{else}}
            {{#let
              (lazyHash post=@post nestedReplyView=true)
              as |postOutletArgs|
            }}
              <PluginOutlet @name="post-article" @outletArgs={{postOutletArgs}}>
                <article
                  class="nested-post__article boxed"
                  data-post-id={{@post.id}}
                  data-post-number={{@post.post_number}}
                  data-topic-id={{@topic.id}}
                  {{@registerPost @post trackOnly=true}}
                >
                  <PluginOutlet
                    @name="post-article-content"
                    @outletArgs={{postOutletArgs}}
                  >
                    {{#if (PostNotice.shouldRender @post this.siteSettings)}}
                      <PostNotice @post={{@post}} />
                    {{/if}}
                    <div class="nested-post__header">
                      <PluginOutlet
                        @name="post-metadata"
                        @outletArgs={{postOutletArgs}}
                      >
                        <PostMetaData
                          @editPost={{fn @editPost @post}}
                          @multiSelect={{@multiSelect}}
                          @post={{@post}}
                          @selectBelow={{this.selectBelow}}
                          @selected={{this.selected}}
                          @selectReplies={{this.selectReplies}}
                          @showHistory={{fn @showHistory @post}}
                          @togglePostSelection={{this.togglePostSelection}}
                        />
                      </PluginOutlet>
                      {{#if this.isOP}}
                        <span class="nested-post__op-badge">{{i18n
                            "nested_replies.op_badge"
                          }}</span>
                      {{/if}}
                      {{#if @isPinned}}
                        <span class="nested-post__pinned-badge">{{i18n
                            "nested_replies.pinned_reply"
                          }}</span>
                      {{/if}}
                    </div>
                    <div class="nested-post__content regular">
                      <PluginOutlet
                        @name="post-content-cooked-html"
                        @outletArgs={{postOutletArgs}}
                      >
                        <PostCookedHtml @post={{@post}} />
                      </PluginOutlet>
                    </div>
                    <section class="nested-post__menu post-menu-area clearfix">
                      <PostMenu
                        @canCreatePost={{this.canCreatePost}}
                        @changeNotice={{fn @changeNotice @post}}
                        @changePostOwner={{fn @changePostOwner @post}}
                        @copyLink={{this.copyLink}}
                        @deletePost={{fn @deletePost @post}}
                        @editPost={{fn @editPost @post}}
                        @grantBadge={{fn @grantBadge @post}}
                        @lockPost={{fn @lockPost @post}}
                        @nestedReplyView={{true}}
                        @permanentlyDeletePost={{fn
                          @permanentlyDeletePost
                          @post
                        }}
                        @post={{@post}}
                        @rebakePost={{fn @rebakePost @post}}
                        @recoverPost={{fn @recoverPost @post}}
                        @repliesShown={{if
                          this.atMaxDepth
                          true
                          this.effectiveExpanded
                        }}
                        @replyToPost={{fn @replyToPost @post @depth}}
                        @share={{this.share}}
                        @showFlags={{fn @showFlags @post}}
                        @showLogin={{this.showLogin}}
                        @showPagePublish={{@showPagePublish}}
                        @toggleLike={{this.toggleLike}}
                        @togglePostType={{fn @togglePostType @post}}
                        @toggleReplies={{unless
                          this.atMaxDepth
                          this.handleReplies
                        }}
                        @toggleWiki={{fn @toggleWiki @post}}
                        @unhidePost={{fn @unhidePost @post}}
                        @unlockPost={{fn @unlockPost @post}}
                      />
                    </section>
                    {{#if this.showExpandRepliesButton}}
                      <NestedRepliesExpandButton
                        @disabled={{this.loadingReplies}}
                        @isLoading={{this.loadingReplies}}
                        @onClick={{this.handleReplies}}
                        @replyCount={{this.replyCount}}
                      />
                    {{/if}}
                    <PluginOutlet
                      @name="post-links"
                      @outletArgs={{postOutletArgs}}
                    >
                      <PostLinks @post={{@post}} />
                    </PluginOutlet>
                  </PluginOutlet>
                  {{#if this.showContinueThread}}
                    <div class="nested-post__controls">
                      <a
                        class="nested-post__continue-link"
                        href={{this.contextUrl}}
                      >
                        {{i18n "nested_replies.continue_thread"}}
                      </a>
                    </div>
                  {{/if}}
                </article>
              </PluginOutlet>
            {{/let}}
          {{/if}}
    
          {{#if this.renderChildren}}
            <NestedPostChildren
              @captureScrollAnchor={{@captureScrollAnchor}}
              @changeNotice={{@changeNotice}}
              @changePostOwner={{@changePostOwner}}
              @collapseFromDepth={{@collapseFromDepth}}
              @collapseParent={{this.toggleExpanded}}
              @deletePost={{@deletePost}}
              @depth={{@depth}}
              @directReplyCount={{@post.direct_reply_count}}
              @editPost={{@editPost}}
              @expansionState={{@expansionState}}
              @fetchedChildrenCache={{@fetchedChildrenCache}}
              @focusPost={{@focusPost}}
              @grantBadge={{@grantBadge}}
              @highlightParentLine={{this.highlightLine}}
              @initialPage={{@post.children_page}}
              @lockPost={{@lockPost}}
              @multiSelect={{@multiSelect}}
              @parentLineHighlighted={{this.lineHighlighted}}
              @parentPostNumber={{@post.post_number}}
              @path={{this.childPath}}
              @permanentlyDeletePost={{@permanentlyDeletePost}}
              @postSelected={{@postSelected}}
              @preloadedChildren={{@children}}
              @preview={{this.previewChildren}}
              @rebakePost={{@rebakePost}}
              @recoverPost={{@recoverPost}}
              @registerPost={{@registerPost}}
              @replyToPost={{@replyToPost}}
              @scrollAnchor={{@scrollAnchor}}
              @selectBelow={{@selectBelow}}
              @selectReplies={{@selectReplies}}
              @showFlags={{@showFlags}}
              @showHistory={{@showHistory}}
              @showPagePublish={{@showPagePublish}}
              @sort={{@sort}}
              @togglePostSelection={{@togglePostSelection}}
              @togglePostType={{@togglePostType}}
              @toggleReplies={{this.handleReplies}}
              @toggleWiki={{@toggleWiki}}
              @topic={{@topic}}
              @totalDescendantCount={{@post.total_descendant_count}}
              @unhidePost={{@unhidePost}}
              @unhighlightParentLine={{this.unhighlightLine}}
              @unlockPost={{@unlockPost}}
            />
          {{/if}}
        </div>
      {{/unless}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[28,[32,0],[\"nested-post\",[30,0,[\"depthClass\"]],[52,[30,1],\"--parent-line-highlighted\"],[52,[30,0,[\"effectiveCollapsed\"]],\"nested-post--collapsed\"],[52,[30,2],\"nested-post--pinned\"],[52,[30,3,[\"isWhisper\"]],\"nested-post--whisper\"],[52,[28,[32,1],[[30,3,[\"isModeratorAction\"]],[28,[32,2],[[30,3,[\"isWarning\"]],[30,3,[\"firstPost\"]]],null]],null],\"post--moderator moderator\"],[52,[30,3,[\"hidden\"]],\"nested-post--hidden post--hidden post-hidden\"],[52,[28,[32,1],[[30,3,[\"deleted\"]],[30,3,[\"user_deleted\"]]],null],\"nested-post--deleted\"],[52,[30,0,[\"cloakingData\",\"active\"]],\"nested-post--cloaked\"],[52,[30,0,[\"selected\"]],\"selected\"]],null]],[16,\"data-root-index\",[52,[30,0,[\"isRoot\"]],[30,3,[\"root_index\"]]]],[16,5,[30,0,[\"cloakingData\",\"style\"]]],[4,[30,0,[\"restoreScroll\"]],null,null],[4,[30,4],[[30,3]],[[\"trackOnly\"],[[28,[32,3],[[30,0,[\"isRoot\"]]],null]]]],[12],[1,\"\\n\"],[41,[51,[30,0,[\"cloakingData\",\"active\"]]],[[[41,[30,5],[[[1,\"      \"],[11,\"button\"],[16,\"aria-label\",[28,[32,4],[\"nested_replies.collapse_parent\"],null]],[24,0,\"nested-post__parent-line-btn\"],[24,4,\"button\"],[4,[32,5],[\"click\",[30,5]],null],[4,[32,5],[\"mouseenter\",[30,6]],null],[4,[32,5],[\"mouseleave\",[30,7]],null],[12],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[10,0],[14,0,\"nested-post__gutter\"],[12],[1,\"\\n\"],[41,[30,0,[\"isDeletedPlaceholder\"]],[[[1,\"        \"],[10,0],[14,0,\"nested-post__placeholder-avatar\"],[12],[1,\"\\n          \"],[1,[28,[32,6],[\"trash-can\"],null]],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"renderIgnoredPlaceholder\"]],[[[1,\"        \"],[11,\"button\"],[16,\"aria-label\",[28,[32,4],[\"nested_replies.toggle_ignored_content\"],null]],[24,0,\"nested-post__placeholder-avatar nested-post__placeholder-avatar--reveal\"],[16,\"data-post-number\",[30,3,[\"post_number\"]]],[16,\"disabled\",[30,0,[\"loadingIgnoredContent\"]]],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"revealIgnoredContent\"]]],null],[12],[1,\"\\n\"],[41,[30,0,[\"loadingIgnoredContent\"]],[[[1,\"            \"],[1,[28,[32,6],[\"spinner\"],[[\"class\"],[\"fa-spin\"]]]],[1,\"\\n\"]],[]],[[[1,\"            \"],[1,[28,[32,6],[\"far-eye-slash\"],null]],[1,\"\\n\"]],[]]],[1,\"        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,7],null,[[\"@post\",\"@size\"],[[30,3],\"small\"]],null],[1,\"\\n      \"]],[]]]],[]]],[41,[28,[32,2],[[30,0,[\"showDepthLine\"]],[28,[32,3],[[30,0,[\"effectiveCollapsed\"]]],null]],null],[[[1,\"        \"],[11,\"button\"],[16,\"aria-label\",[30,0,[\"depthLineLabel\"]]],[16,0,[28,[32,0],[\"nested-post__depth-line\",[52,[30,0,[\"lineHighlighted\"]],\"nested-post__depth-line--highlighted\"],[52,[51,[30,0,[\"hasReplies\"]]],\"nested-post__depth-line--leaf\"],[52,[30,0,[\"depthLineCollapsed\"]],\"nested-post__depth-line--collapsed\"]],null]],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"handleDepthLine\"]]],null],[4,[32,5],[\"mouseenter\",[30,0,[\"highlightLine\"]]],null],[4,[32,5],[\"mouseleave\",[30,0,[\"unhighlightLine\"]]],null],[12],[1,\"\\n\"],[41,[30,0,[\"showDepthLineIcon\"]],[[[1,\"            \"],[10,1],[14,0,\"nested-post__depth-line-icon\"],[12],[1,\"\\n              \"],[1,[28,[32,6],[\"discourse-circle-minus\"],null]],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n    \"],[10,0],[14,0,\"nested-post__main\"],[12],[1,\"\\n\"],[41,[30,0,[\"effectiveCollapsed\"]],[[[1,\"        \"],[11,\"button\"],[24,0,\"nested-post__collapsed-bar\"],[16,\"data-post-number\",[30,3,[\"post_number\"]]],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"toggleExpanded\"]]],null],[12],[1,\"\\n          \"],[1,[28,[32,6],[\"discourse-circle-plus\"],null]],[1,\"\\n\"],[41,[30,0,[\"isDeletedPlaceholder\"]],[[[1,\"            \"],[10,1],[14,0,\"nested-post__collapsed-username\"],[12],[1,[28,[32,4],[\"nested_replies.deleted_post_placeholder\"],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"renderIgnoredPlaceholder\"]],[[[1,\"            \"],[10,1],[14,0,\"nested-post__collapsed-username\"],[12],[1,[28,[32,4],[\"nested_replies.ignored_post_placeholder\"],null]],[13],[1,\"\\n\"]],[]],[[[1,\"            \"],[10,1],[14,0,\"nested-post__collapsed-username\"],[12],[1,[30,3,[\"username\"]]],[13],[1,\"\\n          \"]],[]]]],[]]],[1,\"          \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"nested-post__collapsed-separator\"],[12],[1,\"·\"],[13],[1,\"\\n          \"],[10,1],[14,0,\"nested-post__collapsed-reply-count\"],[12],[1,[30,0,[\"collapsedBarLabel\"]]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isDeletedPlaceholder\"]],[[[1,\"        \"],[10,0],[14,0,\"nested-post__placeholder nested-post__placeholder--deleted\"],[15,\"data-post-number\",[30,3,[\"post_number\"]]],[12],[1,\"\\n          \"],[10,0],[14,0,\"nested-post__placeholder-actions\"],[12],[1,\"\\n            \"],[10,1],[14,0,\"nested-post__placeholder-label\"],[12],[1,[28,[32,4],[\"nested_replies.deleted_post_placeholder\"],null]],[13],[1,\"\\n\"],[41,[30,0,[\"currentUser\",\"staff\"]],[[[1,\"              \"],[8,[32,8],[[24,0,\"btn-flat toggle-deleted-content\"]],[[\"@action\",\"@ariaLabel\",\"@icon\"],[[30,0,[\"toggleDeletedContent\"]],\"post.controls.view_deleted\",[52,[30,0,[\"showDeletedContent\"]],\"far-eye-slash\",\"far-eye\"]]],null],[1,\"\\n\"]],[]],null],[41,[30,3,[\"can_recover\"]],[[[1,\"              \"],[8,[32,8],[[24,0,\"btn-flat recover\"]],[[\"@action\",\"@ariaLabel\",\"@icon\"],[[28,[32,9],[[30,8],[30,3]],null],\"post.controls.undelete\",\"arrow-rotate-left\"]],null],[1,\"\\n\"]],[]],null],[1,\"          \"],[13],[1,\"\\n\"],[41,[30,0,[\"showDeletedContent\"]],[[[1,\"            \"],[10,0],[14,0,\"nested-post__placeholder-reveal\"],[12],[1,\"\\n              \"],[10,0],[14,0,\"nested-post__placeholder-reveal-header\"],[12],[1,\"\\n                \"],[8,[32,7],null,[[\"@post\",\"@size\"],[[30,3],\"small\"]],null],[1,\"\\n                \"],[8,[32,10],null,[[\"@post\"],[[30,3]]],null],[1,\"\\n              \"],[13],[1,\"\\n              \"],[8,[32,11],null,[[\"@post\"],[[30,3]]],null],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"renderIgnoredPlaceholder\"]],[[[1,\"        \"],[10,0],[14,0,\"nested-post__placeholder nested-post__placeholder--ignored\"],[15,\"data-post-number\",[30,3,[\"post_number\"]]],[12],[1,\"\\n          \"],[10,0],[14,0,\"nested-post__placeholder-actions\"],[12],[1,\"\\n            \"],[10,1],[14,0,\"nested-post__placeholder-label\"],[12],[1,[28,[32,4],[\"nested_replies.ignored_post_placeholder\"],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[44,[[28,[32,12],null,[[\"post\",\"nestedReplyView\"],[[30,3],true]]]],[[[1,\"          \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"post-article\",[30,9]]],[[\"default\"],[[[[1,\"\\n            \"],[11,\"article\"],[24,0,\"nested-post__article boxed\"],[16,\"data-post-id\",[30,3,[\"id\"]]],[16,\"data-post-number\",[30,3,[\"post_number\"]]],[16,\"data-topic-id\",[30,10,[\"id\"]]],[4,[30,4],[[30,3]],[[\"trackOnly\"],[true]]],[12],[1,\"\\n              \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"post-article-content\",[30,9]]],[[\"default\"],[[[[1,\"\\n\"],[41,[28,[32,14,[\"shouldRender\"]],[[30,3],[30,0,[\"siteSettings\"]]],null],[[[1,\"                  \"],[8,[32,14],null,[[\"@post\"],[[30,3]]],null],[1,\"\\n\"]],[]],null],[1,\"                \"],[10,0],[14,0,\"nested-post__header\"],[12],[1,\"\\n                  \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"post-metadata\",[30,9]]],[[\"default\"],[[[[1,\"\\n                    \"],[8,[32,10],null,[[\"@editPost\",\"@multiSelect\",\"@post\",\"@selectBelow\",\"@selected\",\"@selectReplies\",\"@showHistory\",\"@togglePostSelection\"],[[28,[32,9],[[30,11],[30,3]],null],[30,12],[30,3],[30,0,[\"selectBelow\"]],[30,0,[\"selected\"]],[30,0,[\"selectReplies\"]],[28,[32,9],[[30,13],[30,3]],null],[30,0,[\"togglePostSelection\"]]]],null],[1,\"\\n                  \"]],[]]]]],[1,\"\\n\"],[41,[30,0,[\"isOP\"]],[[[1,\"                    \"],[10,1],[14,0,\"nested-post__op-badge\"],[12],[1,[28,[32,4],[\"nested_replies.op_badge\"],null]],[13],[1,\"\\n\"]],[]],null],[41,[30,2],[[[1,\"                    \"],[10,1],[14,0,\"nested-post__pinned-badge\"],[12],[1,[28,[32,4],[\"nested_replies.pinned_reply\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"                \"],[13],[1,\"\\n                \"],[10,0],[14,0,\"nested-post__content regular\"],[12],[1,\"\\n                  \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"post-content-cooked-html\",[30,9]]],[[\"default\"],[[[[1,\"\\n                    \"],[8,[32,11],null,[[\"@post\"],[[30,3]]],null],[1,\"\\n                  \"]],[]]]]],[1,\"\\n                \"],[13],[1,\"\\n                \"],[10,\"section\"],[14,0,\"nested-post__menu post-menu-area clearfix\"],[12],[1,\"\\n                  \"],[8,[32,15],null,[[\"@canCreatePost\",\"@changeNotice\",\"@changePostOwner\",\"@copyLink\",\"@deletePost\",\"@editPost\",\"@grantBadge\",\"@lockPost\",\"@nestedReplyView\",\"@permanentlyDeletePost\",\"@post\",\"@rebakePost\",\"@recoverPost\",\"@repliesShown\",\"@replyToPost\",\"@share\",\"@showFlags\",\"@showLogin\",\"@showPagePublish\",\"@toggleLike\",\"@togglePostType\",\"@toggleReplies\",\"@toggleWiki\",\"@unhidePost\",\"@unlockPost\"],[[30,0,[\"canCreatePost\"]],[28,[32,9],[[30,14],[30,3]],null],[28,[32,9],[[30,15],[30,3]],null],[30,0,[\"copyLink\"]],[28,[32,9],[[30,16],[30,3]],null],[28,[32,9],[[30,11],[30,3]],null],[28,[32,9],[[30,17],[30,3]],null],[28,[32,9],[[30,18],[30,3]],null],true,[28,[32,9],[[30,19],[30,3]],null],[30,3],[28,[32,9],[[30,20],[30,3]],null],[28,[32,9],[[30,8],[30,3]],null],[52,[30,0,[\"atMaxDepth\"]],true,[30,0,[\"effectiveExpanded\"]]],[28,[32,9],[[30,21],[30,3],[30,22]],null],[30,0,[\"share\"]],[28,[32,9],[[30,23],[30,3]],null],[30,0,[\"showLogin\"]],[30,24],[30,0,[\"toggleLike\"]],[28,[32,9],[[30,25],[30,3]],null],[52,[51,[30,0,[\"atMaxDepth\"]]],[30,0,[\"handleReplies\"]]],[28,[32,9],[[30,26],[30,3]],null],[28,[32,9],[[30,27],[30,3]],null],[28,[32,9],[[30,28],[30,3]],null]]],null],[1,\"\\n                \"],[13],[1,\"\\n\"],[41,[30,0,[\"showExpandRepliesButton\"]],[[[1,\"                  \"],[8,[32,16],null,[[\"@disabled\",\"@isLoading\",\"@onClick\",\"@replyCount\"],[[30,0,[\"loadingReplies\"]],[30,0,[\"loadingReplies\"]],[30,0,[\"handleReplies\"]],[30,0,[\"replyCount\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"                \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"post-links\",[30,9]]],[[\"default\"],[[[[1,\"\\n                  \"],[8,[32,17],null,[[\"@post\"],[[30,3]]],null],[1,\"\\n                \"]],[]]]]],[1,\"\\n              \"]],[]]]]],[1,\"\\n\"],[41,[30,0,[\"showContinueThread\"]],[[[1,\"                \"],[10,0],[14,0,\"nested-post__controls\"],[12],[1,\"\\n                  \"],[10,3],[14,0,\"nested-post__continue-link\"],[15,6,[30,0,[\"contextUrl\"]]],[12],[1,\"\\n                    \"],[1,[28,[32,4],[\"nested_replies.continue_thread\"],null]],[1,\"\\n                  \"],[13],[1,\"\\n                \"],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[13],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[9]]],[1,\"      \"]],[]]]],[]]]],[]]],[1,\"\\n\"],[41,[30,0,[\"renderChildren\"]],[[[1,\"        \"],[8,[32,18],null,[[\"@captureScrollAnchor\",\"@changeNotice\",\"@changePostOwner\",\"@collapseFromDepth\",\"@collapseParent\",\"@deletePost\",\"@depth\",\"@directReplyCount\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@grantBadge\",\"@highlightParentLine\",\"@initialPage\",\"@lockPost\",\"@multiSelect\",\"@parentLineHighlighted\",\"@parentPostNumber\",\"@path\",\"@permanentlyDeletePost\",\"@postSelected\",\"@preloadedChildren\",\"@preview\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@sort\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleReplies\",\"@toggleWiki\",\"@topic\",\"@totalDescendantCount\",\"@unhidePost\",\"@unhighlightParentLine\",\"@unlockPost\"],[[30,29],[30,14],[30,15],[30,30],[30,0,[\"toggleExpanded\"]],[30,16],[30,22],[30,3,[\"direct_reply_count\"]],[30,11],[30,31],[30,32],[30,33],[30,17],[30,0,[\"highlightLine\"]],[30,3,[\"children_page\"]],[30,18],[30,12],[30,0,[\"lineHighlighted\"]],[30,3,[\"post_number\"]],[30,0,[\"childPath\"]],[30,19],[30,34],[30,35],[30,0,[\"previewChildren\"]],[30,20],[30,8],[30,4],[30,21],[30,36],[30,37],[30,38],[30,23],[30,13],[30,24],[30,39],[30,40],[30,25],[30,0,[\"handleReplies\"]],[30,26],[30,10],[30,3,[\"total_descendant_count\"]],[30,27],[30,0,[\"unhighlightLine\"]],[30,28]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"@parentLineHighlighted\",\"@isPinned\",\"@post\",\"@registerPost\",\"@collapseParent\",\"@highlightParentLine\",\"@unhighlightParentLine\",\"@recoverPost\",\"postOutletArgs\",\"@topic\",\"@editPost\",\"@multiSelect\",\"@showHistory\",\"@changeNotice\",\"@changePostOwner\",\"@deletePost\",\"@grantBadge\",\"@lockPost\",\"@permanentlyDeletePost\",\"@rebakePost\",\"@replyToPost\",\"@depth\",\"@showFlags\",\"@showPagePublish\",\"@togglePostType\",\"@toggleWiki\",\"@unhidePost\",\"@unlockPost\",\"@captureScrollAnchor\",\"@collapseFromDepth\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@postSelected\",\"@children\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@sort\",\"@togglePostSelection\"],[\"if\",\"unless\",\"let\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        or,
        and,
        not,
        i18n,
        on,
        dIcon,
        PostAvatar,
        DButton,
        fn,
        PostMetaData,
        PostCookedHtml,
        lazyHash,
        PluginOutlet,
        PostNotice,
        PostMenu,
        NestedRepliesExpandButton,
        PostLinks,
        NestedPostChildren
      }),
      "isStrictMode": true
    }), this);
  }
}