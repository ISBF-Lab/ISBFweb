import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { CHILDREN_PAGE_SIZE, flatRepliesEnabled, REPLY_PREVIEW_COUNT } from "discourse/lib/flat-replies";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import processNode from "../../lib/process-node";
import NestedPost from "./post";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class NestedPostChildren extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "store", [service]);
  }
  #store = (i(this, "store"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  static {
    g(this.prototype, "childNodes", [tracked], function () {
      return [];
    });
  }
  #childNodes = (i(this, "childNodes"), void 0);
  static {
    g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (i(this, "loading"), void 0);
  static {
    g(this.prototype, "page", [tracked], function () {
      return 0;
    });
  }
  #page = (i(this, "page"), void 0);
  static {
    g(this.prototype, "hasMore", [tracked], function () {
      return false;
    });
  }
  #hasMore = (i(this, "hasMore"), void 0);
  static {
    g(this.prototype, "loadingMore", [tracked], function () {
      return false;
    });
  }
  #loadingMore = (i(this, "loadingMore"), void 0);
  static {
    g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (i(this, "loaded"), void 0);
  static {
    g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (i(this, "error"), void 0);
  static {
    g(this.prototype, "previousPage", [tracked], function () {
      return 0;
    });
  }
  #previousPage = (i(this, "previousPage"), void 0);
  static {
    g(this.prototype, "loadingPrevious", [tracked], function () {
      return false;
    });
  }
  #loadingPrevious = (i(this, "loadingPrevious"), void 0);
  #failedRequest = null;
  // Tracks whether we've fetched from the server yet (vs only having preloaded data)
  _fetchedFromServer = false;
  _identityKey = null;
  _activeCacheKey = null;
  constructor() {
    super(...arguments);
    this.appEvents.on("nested-replies:child-created", this, this._onChildCreated);
    this._hydrateFromArgs();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("nested-replies:child-created", this, this._onChildCreated);
    this._reportToCache();
  }
  get identityKey() {
    return [this.args.topic?.id, this.args.parentPostNumber, this.args.sort].join(":");
  }
  get flatReplies() {
    return flatRepliesEnabled(this.siteSettings);
  }
  get displayItems() {
    const nodes = this.flatReplies && this.args.preview ? this.childNodes.slice(0, REPLY_PREVIEW_COUNT) : this.childNodes;
    const items = nodes.map(node => ({
      key: node.post.id,
      node
    }));
    if (this.flatReplies && !this.args.preview && this.previousPage > 0) {
      items.splice(REPLY_PREVIEW_COUNT, 0, {
        key: "gap",
        gap: true
      });
    }
    return items;
  }
  get canExpandPreview() {
    return this.flatReplies && this.args.preview && this.expectedCount > REPLY_PREVIEW_COUNT;
  }
  get previewLabel() {
    return i18n("nested_replies.view_remaining_replies", {
      count: Math.max(this.expectedCount - Math.min(this.childNodes.length, REPLY_PREVIEW_COUNT), 0)
    });
  }
  get childDepth() {
    return this.args.depth + 1;
  }
  get usesFlatDescendantPagination() {
    return this.siteSettings.nested_replies_cap_nesting_depth && this.childDepth >= this.siteSettings.nested_replies_max_depth;
  }
  get expectedCount() {
    return this.usesFlatDescendantPagination ? this.args.totalDescendantCount || this.args.directReplyCount || 0 : this.args.directReplyCount || 0;
  }
  get remainingCount() {
    return Math.max(this.expectedCount - this.childNodes.length, 0);
  }
  get loadMoreLabel() {
    const count = this.remainingCount;
    if (count > 0) {
      return i18n("nested_replies.load_more_children", {
        count
      });
    }
    return i18n("nested_replies.load_more_children_generic");
  }
  hydrateFromArgs() {
    this._hydrateFromArgs();
  }
  static {
    n(this.prototype, "hydrateFromArgs", [action]);
  }
  async loadChildren() {
    const identityKey = this.identityKey;
    const topicId = this.args.topic?.id;
    this.loading = true;
    this.error = false;
    try {
      const query = new URLSearchParams({
        sort: this.args.sort || "top",
        depth: this.childDepth
      });
      const data = await ajax(`/n/${this.args.topic.slug}/${this.args.topic.id}/children/${this.args.parentPostNumber}.json?${query}`);
      if (this.isDestroying || this.identityKey !== identityKey) {
        return;
      }
      this.childNodes = this._childrenForTopic(data.children, topicId).map(child => this._processNode(child));
      this.page = data.page;
      this.hasMore = data.has_more || false;
      this.loaded = true;
      this._fetchedFromServer = true;
      this._reportToCache();
    } catch (e) {
      if (!this.isDestroying && this.identityKey === identityKey) {
        if (this.flatReplies) {
          this.error = true;
          this.#failedRequest = "children";
        } else {
          popupAjaxError(e);
        }
      }
    } finally {
      if (!this.isDestroying && this.identityKey === identityKey) {
        this.loading = false;
      }
    }
  }
  async loadMore() {
    if (this.loadingMore || !this.hasMore) {
      return;
    }
    const identityKey = this.identityKey;
    const topicId = this.args.topic?.id;
    this.loadingMore = true;
    this.error = false;
    try {
      // First server fetch after preloaded data: get page 0 and merge
      // to preserve expanded state on already-loaded nodes.
      // Subsequent fetches: normal pagination.
      const nextPage = this._fetchedFromServer ? this.page + 1 : 0;
      const query = new URLSearchParams({
        page: nextPage,
        sort: this.args.sort || "top",
        depth: this.childDepth
      });
      const data = await ajax(`/n/${this.args.topic.slug}/${this.args.topic.id}/children/${this.args.parentPostNumber}.json?${query}`);
      if (this.isDestroying || this.identityKey !== identityKey) {
        return;
      }
      const newNodes = this._childrenForTopic(data.children, topicId).map(child => this._processNode(child));
      if (!this._fetchedFromServer) {
        // Merge: keep preloaded children (may have expanded subtrees),
        // append only siblings not already present.
        const existing = new Set(this.childNodes.map(n => n.post.post_number));
        const additional = newNodes.filter(n => !existing.has(n.post.post_number));
        this.childNodes = [...this.childNodes, ...additional];
        this._fetchedFromServer = true;
      } else {
        const additional = newNodes.filter(node => !this._includesPost(this.childNodes, node.post));
        this.childNodes = [...this.childNodes, ...additional];
      }
      this.page = data.page;
      this.hasMore = data.has_more || false;
      this._reportToCache();
    } catch (e) {
      if (!this.isDestroying && this.identityKey === identityKey) {
        if (this.flatReplies) {
          this.error = true;
          this.#failedRequest = "next";
        } else {
          popupAjaxError(e);
        }
      }
    } finally {
      if (!this.isDestroying && this.identityKey === identityKey) {
        this.loadingMore = false;
      }
    }
  }
  static {
    n(this.prototype, "loadMore", [action]);
  }
  async expandPreview() {
    this.args.toggleReplies?.();
    if (!this._fetchedFromServer) {
      await this.loadMore();
    }
  }
  static {
    n(this.prototype, "expandPreview", [action]);
  }
  async loadPrevious() {
    if (this.loadingPrevious || this.previousPage < 1) {
      return;
    }
    const identityKey = this.identityKey;
    this.loadingPrevious = true;
    this.error = false;
    try {
      const query = new URLSearchParams({
        sort: "old",
        depth: this.childDepth,
        page: this.previousPage - 1
      });
      const data = await ajax(`/n/${this.args.topic.slug}/${this.args.topic.id}/children/${this.args.parentPostNumber}.json?${query}`);
      if (this.isDestroying || this.identityKey !== identityKey) {
        return;
      }
      this.childNodes = this.#mergeNodes(this._childrenForTopic(data.children, this.args.topic.id).map(node => this._processNode(node)));
      this.previousPage--;
      this._reportToCache();
    } catch {
      if (!this.isDestroying && this.identityKey === identityKey) {
        this.error = true;
        this.#failedRequest = "previous";
      }
    } finally {
      if (!this.isDestroying && this.identityKey === identityKey) {
        this.loadingPrevious = false;
      }
    }
  }
  static {
    n(this.prototype, "loadPrevious", [action]);
  }
  retry() {
    if (this.#failedRequest === "previous") {
      return this.loadPrevious();
    }
    return this.#failedRequest === "next" ? this.loadMore() : this.loadChildren();
  }
  static {
    n(this.prototype, "retry", [action]);
  }
  #mergeNodes(nodes) {
    return [...this.childNodes, ...nodes].filter((node, index, all) => all.findIndex(item => item.post.id === node.post.id) === index).sort((left, right) => left.post.post_number - right.post.post_number);
  }
  _cacheKeyFor(parentPostNumber = this.args.parentPostNumber, topicId = this.args.topic?.id) {
    return `${topicId}:${parentPostNumber}`;
  }
  _hydrateFromArgs() {
    if (this._identityKey === this.identityKey) {
      return;
    }
    this._identityKey = this.identityKey;
    this._activeCacheKey = this._cacheKeyFor();
    this.childNodes = [];
    this.loading = false;
    this.page = 0;
    this.hasMore = false;
    this.loadingMore = false;
    this.loaded = false;
    this._fetchedFromServer = false;
    this.error = false;
    this.previousPage = 0;
    this.loadingPrevious = false;
    this.#failedRequest = null;
    const cached = this.args.fetchedChildrenCache?.get(this._activeCacheKey);
    if (cached) {
      this.childNodes = cached.childNodes;
      this.page = cached.page;
      this.hasMore = this.flatReplies ? cached.hasMore : this.usesFlatDescendantPagination ? this.expectedCount > this.childNodes.length : cached.hasMore;
      this.loaded = true;
      this._fetchedFromServer = cached.fetchedFromServer;
      this.previousPage = cached.previousPage || 0;
      return;
    }
    if (this.args.preloadedChildren?.length > 0) {
      this.childNodes = this.args.preloadedChildren;
      this.loaded = true;
      this.hasMore = this.expectedCount > this.childNodes.length;
      if (this.flatReplies && this.args.initialPage != null) {
        this.page = this.args.initialPage;
        this.previousPage = this.page;
        this._fetchedFromServer = true;
        this.hasMore = this.expectedCount > (this.page + 1) * CHILDREN_PAGE_SIZE;
      }
    } else if (this.args.directReplyCount > 0) {
      this.loadChildren();
    }
  }
  _reportToCache(cacheKey = this._activeCacheKey) {
    if (!this.loaded || !cacheKey || !this.args.fetchedChildrenCache) {
      return;
    }
    this.args.fetchedChildrenCache.set(cacheKey, {
      childNodes: this.childNodes,
      page: this.page,
      hasMore: this.hasMore,
      fetchedFromServer: this._fetchedFromServer,
      previousPage: this.previousPage
    });
  }
  _onChildCreated({
    topicId,
    post,
    parentPostNumber
  }) {
    if (String(topicId) !== String(this.args.topic?.id) || parentPostNumber !== this.args.parentPostNumber) {
      return;
    }
    const alreadyExists = this._includesPost(this.childNodes, post);
    if (alreadyExists) {
      return;
    }
    if (this.flatReplies && this.hasMore) {
      return;
    }
    this.childNodes = this.flatReplies ? this.#mergeNodes([{
      post,
      children: []
    }]) : [{
      post,
      children: []
    }, ...this.childNodes];
    this.loaded = true;
    this._reportToCache();
  }
  _childrenForTopic(children, topicId) {
    return (children || []).filter(child => child.topic_id != null && String(child.topic_id) === String(topicId));
  }
  _processNode(nodeData) {
    return processNode(this.store, this.args.topic, nodeData);
  }
  _includesPost(nodes, post) {
    return nodes.some(node => node.post.id === post.id || node.post.post_number === post.post_number);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class="nested-post-children"
      {{didUpdate this.hydrateFromArgs @topic.id @parentPostNumber @sort}}
    >
      <DConditionalLoadingSpinner @condition={{this.loading}}>
        {{#each this.displayItems key="key" as |item|}}
          {{#if item.gap}}
            <DButton
              class="btn-flat nested-post-children__previous"
              @action={{this.loadPrevious}}
              @disabled={{this.loadingPrevious}}
              @label="nested_replies.load_previous_replies"
            />
          {{else}}
            {{#let item.node as |node|}}
              <NestedPost
                @captureScrollAnchor={{@captureScrollAnchor}}
                @changeNotice={{@changeNotice}}
                @changePostOwner={{@changePostOwner}}
                @children={{node.children}}
                @collapseFromDepth={{@collapseFromDepth}}
                @collapseParent={{@collapseParent}}
                @deletePost={{@deletePost}}
                @depth={{this.childDepth}}
                @editPost={{@editPost}}
                @expansionState={{@expansionState}}
                @fetchedChildrenCache={{@fetchedChildrenCache}}
                @focusPost={{@focusPost}}
                @grantBadge={{@grantBadge}}
                @highlightParentLine={{@highlightParentLine}}
                @lockPost={{@lockPost}}
                @multiSelect={{@multiSelect}}
                @parentLineHighlighted={{@parentLineHighlighted}}
                @path={{@path}}
                @permanentlyDeletePost={{@permanentlyDeletePost}}
                @post={{node.post}}
                @postSelected={{@postSelected}}
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
                @toggleWiki={{@toggleWiki}}
                @topic={{@topic}}
                @unhidePost={{@unhidePost}}
                @unhighlightParentLine={{@unhighlightParentLine}}
                @unlockPost={{@unlockPost}}
              />
            {{/let}}
          {{/if}}
        {{/each}}
    
        {{#if this.error}}
          <p class="nested-post-children__error">{{i18n
              "nested_replies.replies_load_error"
            }}</p>
          <DButton class="btn-flat" @action={{this.retry}} @label="retry" />
        {{/if}}
        {{#if this.canExpandPreview}}
          <DButton
            class="btn-flat nested-post-children__expand"
            @action={{this.expandPreview}}
            @translatedLabel={{this.previewLabel}}
          />
        {{else if this.hasMore}}
          {{#unless @preview}}
            <DButton
              class={{dConcatClass
                "btn-flat"
                "nested-post-children__load-more"
                (if @parentLineHighlighted "--parent-line-highlighted")
              }}
              @action={{this.loadMore}}
              @disabled={{this.loadingMore}}
              @translatedLabel={{this.loadMoreLabel}}
            />
          {{/unless}}
        {{/if}}
        {{#if this.flatReplies}}
          {{#unless @preview}}
            <DButton
              class="btn-flat nested-post-children__collapse"
              @action={{@toggleReplies}}
              @label="nested_replies.collapse"
            />
          {{/unless}}
        {{/if}}
      </DConditionalLoadingSpinner>
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"nested-post-children\"],[4,[32,0],[[30,0,[\"hydrateFromArgs\"]],[30,1,[\"id\"]],[30,2],[30,3]],null],[12],[1,\"\\n  \"],[8,[32,1],null,[[\"@condition\"],[[30,0,[\"loading\"]]]],[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"displayItems\"]]],null]],null],\"key\",[[[41,[30,4,[\"gap\"]],[[[1,\"        \"],[8,[32,2],[[24,0,\"btn-flat nested-post-children__previous\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"loadPrevious\"]],[30,0,[\"loadingPrevious\"]],\"nested_replies.load_previous_replies\"]],null],[1,\"\\n\"]],[]],[[[44,[[30,4,[\"node\"]]],[[[1,\"          \"],[8,[32,3],null,[[\"@captureScrollAnchor\",\"@changeNotice\",\"@changePostOwner\",\"@children\",\"@collapseFromDepth\",\"@collapseParent\",\"@deletePost\",\"@depth\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@grantBadge\",\"@highlightParentLine\",\"@lockPost\",\"@multiSelect\",\"@parentLineHighlighted\",\"@path\",\"@permanentlyDeletePost\",\"@post\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@sort\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@unhidePost\",\"@unhighlightParentLine\",\"@unlockPost\"],[[30,6],[30,7],[30,8],[30,5,[\"children\"]],[30,9],[30,10],[30,11],[30,0,[\"childDepth\"]],[30,12],[30,13],[30,14],[30,15],[30,16],[30,17],[30,18],[30,19],[30,20],[30,21],[30,22],[30,5,[\"post\"]],[30,23],[30,24],[30,25],[30,26],[30,27],[30,28],[30,29],[30,30],[30,31],[30,32],[30,33],[30,3],[30,34],[30,35],[30,36],[30,1],[30,37],[30,38],[30,39]]],null],[1,\"\\n\"]],[5]]]],[]]]],[4]],null],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"      \"],[10,2],[14,0,\"nested-post-children__error\"],[12],[1,[28,[32,4],[\"nested_replies.replies_load_error\"],null]],[13],[1,\"\\n      \"],[8,[32,2],[[24,0,\"btn-flat\"]],[[\"@action\",\"@label\"],[[30,0,[\"retry\"]],\"retry\"]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"canExpandPreview\"]],[[[1,\"      \"],[8,[32,2],[[24,0,\"btn-flat nested-post-children__expand\"]],[[\"@action\",\"@translatedLabel\"],[[30,0,[\"expandPreview\"]],[30,0,[\"previewLabel\"]]]],null],[1,\"\\n\"]],[]],[[[41,[30,0,[\"hasMore\"]],[[[41,[51,[30,40]],[[[1,\"        \"],[8,[32,2],[[16,0,[28,[32,5],[\"btn-flat\",\"nested-post-children__load-more\",[52,[30,20],\"--parent-line-highlighted\"]],null]]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"loadMore\"]],[30,0,[\"loadingMore\"]],[30,0,[\"loadMoreLabel\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"]],[]],null]],[]]],[41,[30,0,[\"flatReplies\"]],[[[41,[51,[30,40]],[[[1,\"        \"],[8,[32,2],[[24,0,\"btn-flat nested-post-children__collapse\"]],[[\"@action\",\"@label\"],[[30,41],\"nested_replies.collapse\"]],null],[1,\"\\n\"]],[]],null]],[]],null],[1,\"  \"]],[]]]]],[1,\"\\n\"],[13]],[\"@topic\",\"@parentPostNumber\",\"@sort\",\"item\",\"node\",\"@captureScrollAnchor\",\"@changeNotice\",\"@changePostOwner\",\"@collapseFromDepth\",\"@collapseParent\",\"@deletePost\",\"@editPost\",\"@expansionState\",\"@fetchedChildrenCache\",\"@focusPost\",\"@grantBadge\",\"@highlightParentLine\",\"@lockPost\",\"@multiSelect\",\"@parentLineHighlighted\",\"@path\",\"@permanentlyDeletePost\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@registerPost\",\"@replyToPost\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@unhidePost\",\"@unhighlightParentLine\",\"@unlockPost\",\"@preview\",\"@toggleReplies\"],[\"each\",\"-track-array\",\"if\",\"let\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didUpdate,
        DConditionalLoadingSpinner,
        DButton,
        NestedPost,
        i18n,
        dConcatClass
      }),
      "isStrictMode": true
    }), this);
  }
}