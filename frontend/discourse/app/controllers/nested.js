import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import NestedActivityLog from "discourse/components/modal/nested-activity-log";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse/lib/decorators";
import { flatRepliesEnabled } from "discourse/lib/flat-replies";
import {
  mergeFlatReplyPage,
  mergeFlatReplyPreload,
} from "discourse/lib/flat-reply-pages";
import {
  NESTED_VIEW_CACHE_FORMAT_VERSION,
  snapshotExpansionState,
  snapshotFetchedChildrenCache,
  snapshotNestedModelData,
} from "discourse/lib/nested-view-cache-snapshot";
import { headerOffset } from "discourse/lib/offset-calculator";
import QuoteState from "discourse/lib/quote-state";
import DiscourseURL from "discourse/lib/url";
import Composer from "discourse/models/composer";
import Post from "discourse/models/post";
import { i18n } from "discourse-i18n";
import processNode, {
  registerPostInTopicPostStream,
} from "../lib/process-node";

export default class NestedController extends Controller {
  @service appEvents;
  @service composer;
  @service store;
  @service dialog;
  @service currentUser;
  @service messageBus;
  @service modal;
  @service nestedViewCache;
  @service router;
  @service site;
  @service siteSettings;

  @tracked topic;
  @tracked opPost;
  @tracked rootNodes = [];
  @tracked page = 0;
  @tracked firstRootPage = 0;
  @tracked loadingPreviousRoots = false;
  @tracked hasMoreRoots = false;
  @tracked loadingMore = false;
  @tracked sort;
  @tracked effectiveSort;
  @tracked messageBusLastId;
  @tracked postNumber;
  @tracked context = null;
  @tracked contextMode = false;
  @tracked contextChain = null;
  @tracked initialFocusedPath = [];
  @tracked targetPostNumber = null;
  @tracked contextNoAncestors = false;
  @tracked ancestorsTruncated = false;
  @tracked topAncestorPostNumber = null;
  @tracked newRootPostIds = [];
  @tracked editingTopic = false;
  @tracked pinnedPostIds = [];
  // Persisted in the URL across in-topic navigation by design — once a
  // user lands via a consolidated reply notification, browsing within
  // the topic keeps the collapsed view, and the URL is shareable in that
  // state. If we ever want to scope it to entry-only, clear after the
  // initial render in the route.
  @tracked collapseReplies = false;

  // Externalized expansion state: postNumber → { expanded, collapsed }
  // Components read on construction, write on toggle.
  // Persisted across back/forward navigations via NestedViewCache.
  @tracked expansionState = new Map();

  // Cache of dynamically loaded children: postNumber → { childNodes, page, hasMore, fetchedFromServer }
  // Populated by NestedPostChildren on every mutation, read on restoration.
  @tracked fetchedChildrenCache = new Map();

  // Scroll anchor for cache restoration: { postNumber, offsetFromTop, scrollY? }
  @tracked scrollAnchor = null;

  quoteState = new QuoteState();

  // Flat registry of all rendered posts by post_number.
  // Populated by NestedPost components via appEvents so that readPosts
  // can find posts at any depth, not just those in the preloaded tree.
  postRegistry = new Map();
  #latestScrollAnchor = null;
  #postEventsSubscribed = false;
  #messageBusChannel = null;
  #pendingPostIds = new Set();
  #onRepeatTarget = () => this.revealFlatTarget(this.targetPostNumber);

  // The topic controller/route are hydrated in setupController so we can
  // delegate shared actions and read shared state instead of duplicating
  // core logic.
  get #topicController() {
    return getOwner(this).lookup("controller:topic");
  }

  get #topicRoute() {
    return getOwner(this).lookup("route:topic");
  }

  get buffered() {
    return this.#topicController.buffered;
  }

  get showCategoryChooser() {
    return this.#topicController.showCategoryChooser;
  }

  get canEditTags() {
    return this.#topicController.canEditTags;
  }

  get minimumRequiredTags() {
    return this.#topicController.minimumRequiredTags;
  }

  get multiSelect() {
    return this.#topicController.multiSelect;
  }

  get selectedPostsCount() {
    return this.#topicController.selectedPostsCount;
  }

  get newRootPostCount() {
    return this.contextMode ? 0 : this.newRootPostIds.length;
  }

  get modelData() {
    return {
      topic: this.topic,
      opPost: this.opPost,
      rootNodes: this.rootNodes,
      page: this.page,
      firstRootPage: this.firstRootPage,
      hasMoreRoots: this.hasMoreRoots,
      sort: this.sort,
      effectiveSort: this.effectiveSort,
      messageBusLastId: this.messageBusLastId,
      pinnedPostIds: this.pinnedPostIds,
      postNumber: this.postNumber,
      context: this.context,
      contextMode: this.contextMode,
      contextChain: this.contextChain,
      initialFocusedPath: this.initialFocusedPath,
      targetPostNumber: this.targetPostNumber,
      contextNoAncestors: this.contextNoAncestors,
      ancestorsTruncated: this.ancestorsTruncated,
      topAncestorPostNumber: this.topAncestorPostNumber,
      newRootPostIds: this.newRootPostIds,
      editingTopic: this.editingTopic,
      collapseReplies: this.collapseReplies,
    };
  }

  get canSelectAll() {
    return this.#nestedSelectablePostIds().some(
      (id) => !this.#topicController.selectedPostIds.includes(id)
    );
  }

  get canDeselectAll() {
    return this.selectedPostsCount > 0;
  }

  get canDeleteSelected() {
    const selectedPosts = this.#topicController.selectedPosts;

    return (
      this.selectedPostsCount > 0 &&
      this.selectedPostsCount === selectedPosts.length &&
      selectedPosts.every((post) => post.can_delete)
    );
  }

  get canMergeTopic() {
    return this.#topicController.canMergeTopic;
  }

  get canChangeOwner() {
    return this.#topicController.canChangeOwner;
  }

  get canMergePosts() {
    return this.#topicController.canMergePosts;
  }

  hasFlatPost(postNumber) {
    return postNumber === 1
      ? Boolean(this.opPost)
      : Boolean(this.#flatRootForPostNumber(postNumber));
  }

  flatModelForTarget(postNumber, incoming) {
    const model = {
      ...this.modelData,
      postNumber,
      targetPostNumber: postNumber,
    };
    if (incoming) {
      const roots = new Map(this.rootNodes.map((node) => [node.post.id, node]));
      for (const node of incoming.rootNodes) {
        const current = roots.get(node.post.id) || node;
        const key = `${this.topic.id}:${node.post.post_number}`;
        const entry = mergeFlatReplyPreload(
          this.fetchedChildrenCache.get(key) ||
            mergeFlatReplyPreload(null, current.children || [], {
              page: current.post.children_page,
              count: current.post.total_descendant_count,
            }),
          node.children,
          {
            page: node.post.children_page,
            count: node.post.total_descendant_count,
          }
        );
        for (const child of entry.childNodes) {
          child.post.topic = this.topic;
          child.post =
            registerPostInTopicPostStream(this.topic, child.post) || child.post;
        }
        this.fetchedChildrenCache.set(key, entry);
        current.children = entry.childNodes;
        current.post.set("children_page", null);
        current.post.topic = this.topic;
        roots.set(current.post.id, current);
      }
      model.rootNodes = [...roots.values()].sort(
        (left, right) => left.post.post_number - right.post.post_number
      );
      this.topic.set("reply_navigation", incoming.topic.reply_navigation);
    }
    return model;
  }

  revealFlatTarget(postNumber) {
    if (!flatRepliesEnabled(this.siteSettings) || !postNumber) {
      return;
    }
    const root = this.#flatRootForPostNumber(postNumber);
    if (!root || root.post.post_number === postNumber) {
      return;
    }
    const rootPostNumber = root.post.post_number;
    this.expansionState.set(rootPostNumber, {
      expanded: true,
      collapsed: false,
    });
    const topic = this.topic;
    schedule("afterRender", () => {
      if (this.topic === topic && !this.isDestroying) {
        this.appEvents.trigger("nested-replies:reveal-root", {
          topicId: topic.id,
          rootPostNumber,
        });
      }
    });
  }

  @bind
  postSelected(post) {
    return this.#topicController.postSelected(post);
  }

  @action
  toggleMultiSelect(event) {
    return this.#topicController.toggleMultiSelect(event);
  }

  @action
  togglePostSelection(post) {
    return this.#topicController.togglePostSelection(post);
  }

  @action
  selectReplies(post) {
    return this.#topicController.selectReplies(post);
  }

  @action
  selectBelow(post) {
    const postIds = this.#visiblePostIdsBelow(post);

    if (postIds.length > 0) {
      this.#topicController._updateSelectedPostIds(postIds);
    }
  }

  @action
  selectAll(event) {
    event?.preventDefault();
    this.#topicController._updateSelectedPostIds(
      this.#nestedSelectablePostIds()
    );
  }

  @action
  deselectAll(event) {
    return this.#topicController.deselectAll(event);
  }

  @action
  deleteSelected() {
    const user = this.currentUser;
    this.dialog.yesNoConfirm({
      message: i18n("post.delete.confirm", {
        count: this.selectedPostsCount,
      }),
      didConfirm: () => {
        Post.deleteMany(this.#topicController.selectedPostIds);
        (this.topic?.postStream?.posts || []).forEach(
          (post) =>
            this.postSelected(post) &&
            post.setDeletedState &&
            post.setDeletedState(user)
        );
        this.toggleMultiSelect();
      },
    });
  }

  @action
  mergePosts() {
    return this.#topicController.mergePosts();
  }

  @action
  async loadMoreRoots() {
    if (this.loadingMore || !this.hasMoreRoots) {
      return;
    }

    this.loadingMore = true;
    const topicId = this.topic.id;
    try {
      const nextPage = this.page + 1;
      const query = new URLSearchParams({
        page: nextPage,
        sort: this.effectiveSort || this.sort || "top",
      });
      const data = await ajax(
        `/n/${this.topic.slug}/${this.topic.id}.json?${query}`
      );
      if (this.isDestroying || this.topic?.id !== topicId) {
        return;
      }

      const newNodes = (data.roots || []).map((root) =>
        this.#processNode(root)
      );

      this.rootNodes = [
        ...this.rootNodes,
        ...newNodes.filter(
          (node) =>
            !this.rootNodes.some(
              (existing) => existing.post.id === node.post.id
            )
        ),
      ];
      if (flatRepliesEnabled(this.siteSettings)) {
        this.rootNodes = this.rootNodes.sort(
          (left, right) => left.post.post_number - right.post.post_number
        );
      }
      if (data.navigation) {
        this.topic.set("reply_navigation", data.navigation);
      }
      this.page = data.page;
      this.hasMoreRoots = data.has_more_roots || false;
      this.#assignSuggestedAndRelated(data);
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loadingMore = false;
    }
  }

  @action
  async loadPreviousRoots() {
    if (this.loadingPreviousRoots || this.firstRootPage < 1) {
      return;
    }
    const topic = this.topic;
    const roots = document.querySelector(".nested-view__roots");
    const previousHeight = roots?.getBoundingClientRect().height || 0;
    this.loadingPreviousRoots = true;
    try {
      const data = await ajax(`/n/${topic.slug}/${topic.id}.json`, {
        data: { sort: "old", page: this.firstRootPage - 1 },
      });
      if (this.isDestroying || this.topic !== topic) {
        return;
      }
      const existing = new Set(this.rootNodes.map((node) => node.post.id));
      this.rootNodes = [
        ...data.roots
          .filter((node) => !existing.has(node.id))
          .map((node) => this.#processNode(node)),
        ...this.rootNodes,
      ];
      this.firstRootPage = data.page;
      schedule("afterRender", () => {
        if (!this.isDestroying && this.topic === topic && roots?.isConnected) {
          window.scrollBy(
            0,
            roots.getBoundingClientRect().height - previousHeight
          );
        }
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.loadingPreviousRoots = false;
      }
    }
  }

  @action
  changeSort(newSort) {
    if (newSort === this.sort) {
      return;
    }

    const shouldScrollToRoots = !this.contextMode;

    this.router.transitionTo({ queryParams: { sort: newSort } }).then(() => {
      if (shouldScrollToRoots) {
        schedule("afterRender", this, this.#scrollToRoots);
      }
    });
  }

  @action
  viewFullThread() {
    this.saveToCache();
    this.nestedViewCache.useNextTransition();
    this.router.transitionTo(
      "topic.fromParams",
      this.topic.slug,
      this.topic.id,
      {
        queryParams: { sort: this.sort, context: null },
      }
    );
  }

  @action
  setFocusedPostNumber(postNumber, focusedPath = []) {
    this.postNumber = postNumber;
    this.targetPostNumber = postNumber;
    this.initialFocusedPath = focusedPath;
  }

  @action
  saveScrollPosition(scrollAnchor) {
    this.saveScrollAnchor(scrollAnchor);
  }

  @action
  clearScrollAnchor() {
    this.scrollAnchor = null;
  }

  saveScrollAnchor(scrollAnchor) {
    if (!this.topic || !scrollAnchor) {
      return;
    }

    this.#latestScrollAnchor = scrollAnchor;
    this.#saveScrollAnchorToSession(this.#cacheKey(), scrollAnchor);
  }

  saveToCache(scrollAnchor = this.#latestScrollAnchor) {
    if (!this.topic) {
      return;
    }

    const modelData = this.modelData;

    const cacheKey = this.#cacheKey();

    this.nestedViewCache.save(cacheKey, {
      formatVersion: NESTED_VIEW_CACHE_FORMAT_VERSION,
      modelData: snapshotNestedModelData(modelData),
      expansionState: snapshotExpansionState(this.expansionState),
      fetchedChildrenCache: snapshotFetchedChildrenCache(
        this.fetchedChildrenCache
      ),
      scrollAnchor,
    });

    if (scrollAnchor) {
      this.#saveScrollAnchorToSession(cacheKey, scrollAnchor);
    }
  }

  @action
  viewParentContext() {
    this.saveToCache();

    if (this.ancestorsTruncated && this.topAncestorPostNumber) {
      this.router.transitionTo(
        "topic.fromParamsNear",
        this.topic.slug,
        this.topic.id,
        this.topAncestorPostNumber,
        { queryParams: { sort: this.sort } }
      );
    } else {
      this.router.transitionTo(
        "topic.fromParamsNear",
        this.topic.slug,
        this.topic.id,
        this.targetPostNumber,
        { queryParams: { sort: this.sort, context: null } }
      );
    }
  }

  @action
  replyToPost(post) {
    const topic = this.topic;
    if (!topic.details?.can_create_post) {
      return;
    }

    let replyTarget = post;

    const opts = {
      action: Composer.REPLY,
      draftKey: topic.draft_key,
      draftSequence: topic.draft_sequence || 0,
      skipJumpOnSave: true,
    };

    if (replyTarget && replyTarget.post_number !== 1) {
      opts.post = replyTarget;
    } else {
      opts.topic = topic;
    }

    this.composer.open(opts);
  }

  @action
  async editPost(post) {
    await this.#topicController.editPost(post);
    this.composer.set("skipJumpOnSave", true);
  }

  @action
  deletePost(post, opts) {
    if (post.post_number === 1) {
      return this.#topicController.deletePost(post, opts);
    }

    if (!post.can_delete) {
      return;
    }

    this.dialog.yesNoConfirm({
      message: i18n("post.confirm_delete"),
      didConfirm: () => {
        post
          .destroy(this.currentUser)
          .then(() => this.#markPostDeletedLocally(post.id))
          .catch(popupAjaxError);
      },
    });
  }

  @action
  recoverPost(post) {
    this.#topicController.recoverPost(post);
  }

  @action
  async togglePinPost(post) {
    if (!this.currentUser?.staff) {
      return;
    }

    try {
      const result = await ajax(
        `/n/${this.topic.slug}/${this.topic.id}/pin.json`,
        {
          type: "PUT",
          data: { post_id: post.id },
        }
      );

      this.pinnedPostIds = result.pinned_post_ids || [];

      if (this.pinnedPostIds.includes(post.id)) {
        // Move newly pinned post to front of rootNodes
        const idx = this.rootNodes.findIndex((n) => n.post.id === post.id);
        if (idx > 0) {
          const pinned = this.rootNodes[idx];
          const rest = this.rootNodes.filter((_, i) => i !== idx);
          this.rootNodes = [pinned, ...rest];
        }
      }
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  selectText() {
    const tc = this.#topicController;
    this.#ensurePostInStream(this.quoteState.postId);
    tc.quoteState.copyFrom(this.quoteState);
    return tc.selectText();
  }

  @action
  buildQuoteMarkdown() {
    const tc = this.#topicController;
    this.#ensurePostInStream(this.quoteState.postId);
    tc.quoteState.copyFrom(this.quoteState);
    return tc.buildQuoteMarkdown();
  }

  @action
  showHistory(post) {
    this.#topicRoute.showHistory(post);
  }

  @action
  showFlags(post) {
    this.#topicRoute.showFlags(post);
  }

  @action
  changeNotice(post) {
    return this.#topicController.changeNotice(post);
  }

  @action
  changePostOwner(post) {
    return this.#topicRoute.changeOwner(post);
  }

  @action
  grantBadge(post) {
    return this.#topicRoute.showGrantBadgeModal(post);
  }

  @action
  lockPost(post) {
    return this.#topicController.lockPost(post);
  }

  @action
  unlockPost(post) {
    return this.#topicController.unlockPost(post);
  }

  @action
  permanentlyDeletePost(post) {
    return this.#topicController.permanentlyDeletePost(post);
  }

  @action
  rebakePost(post) {
    return this.#topicController.rebakePost(post);
  }

  @action
  showPagePublish() {
    return this.#topicRoute.showPagePublish();
  }

  @action
  togglePostType(post) {
    return this.#topicController.togglePostType(post);
  }

  @action
  toggleWiki(post) {
    return this.#topicController.toggleWiki(post);
  }

  @action
  unhidePost(post) {
    return this.#topicController.unhidePost(post);
  }

  @action
  showActivityLog() {
    this.modal.show(NestedActivityLog, {
      model: { topic: this.topic, editPost: this.editPost },
    });
  }

  // editingTopic is @tracked locally because the topic controller's
  // editingTopic is a classic property (not @tracked) — a plain getter
  // aliasing it won't trigger Glimmer re-renders. We sync the flag to
  // the topic controller so its finishedEditingTopic save logic works.
  @action
  startEditingTopic(event) {
    event?.preventDefault();
    if (!this.topic?.details?.can_edit) {
      return;
    }
    this.editingTopic = true;
    this.#topicController.set("editingTopic", true);
  }

  @action
  cancelEditingTopic() {
    this.#topicController.cancelEditingTopic();
    this.editingTopic = false;
  }

  @action
  finishedEditingTopic() {
    this.#topicController.finishedEditingTopic();
    this.editingTopic = false;
  }

  @action
  topicCategoryChanged(categoryId) {
    this.#topicController.topicCategoryChanged(categoryId);
  }

  @action
  topicTagsChanged(value) {
    this.#topicController.topicTagsChanged(value);
  }

  subscribe() {
    this.unsubscribe();
    this.appEvents.on("post:created", this, this.#onPostCreated);
    this.appEvents.on("nested:scroll-to-target", this, this.#onRepeatTarget);

    this.appEvents.on(
      "nested-replies:post-registered",
      this,
      this.#onPostRegistered
    );
    this.appEvents.on(
      "nested-replies:post-unregistered",
      this,
      this.#onPostUnregistered
    );
    this.appEvents.on(
      "nested-replies:scroll-restored",
      this,
      this.#onScrollRestored
    );
    this.#postEventsSubscribed = true;

    // Register the OP post directly since it's not rendered by NestedPost
    if (this.opPost) {
      this.postRegistry.set(this.opPost.post_number, this.opPost);
    }

    if (this.topic?.id && this.messageBusLastId != null) {
      this.#messageBusChannel = `/topic/${this.topic.id}`;
      this.messageBus.subscribe(
        this.#messageBusChannel,
        this._onMessage,
        this.messageBusLastId
      );
    }
  }

  unsubscribe() {
    if (this.#postEventsSubscribed) {
      this.appEvents.off("post:created", this, this.#onPostCreated);
      this.appEvents.off("nested:scroll-to-target", this, this.#onRepeatTarget);
      this.appEvents.off(
        "nested-replies:post-registered",
        this,
        this.#onPostRegistered
      );
      this.appEvents.off(
        "nested-replies:post-unregistered",
        this,
        this.#onPostUnregistered
      );
      this.appEvents.off(
        "nested-replies:scroll-restored",
        this,
        this.#onScrollRestored
      );
      this.#postEventsSubscribed = false;
    }
    if (this.#messageBusChannel) {
      this.messageBus.unsubscribe(this.#messageBusChannel, this._onMessage);
      this.#messageBusChannel = null;
    }
    this.postRegistry.clear();
  }

  @action
  async loadNewRoots() {
    if (this.contextMode) {
      this.newRootPostIds = [];
      return;
    }

    const ids = [...this.newRootPostIds];
    this.newRootPostIds = [];

    if (flatRepliesEnabled(this.siteSettings) && ids.length > 0) {
      try {
        const topic = this.topic;
        const navigation = await ajax(
          `/n/${topic.slug}/${topic.id}/navigation.json`,
          { data: { root_index: topic.reply_navigation?.root_count } }
        );
        if (this.topic === topic) {
          DiscourseURL.routeTo(`${topic.url}/${navigation.root_post_number}`);
        }
      } catch (error) {
        this.newRootPostIds = [...ids, ...this.newRootPostIds];
        popupAjaxError(error);
      }
      return;
    }

    const topicId = this.topic?.id;
    const results = await Promise.allSettled(
      ids.map((id) => ajax(`/posts/${id}.json`))
    );

    if (this.topic?.id !== topicId) {
      return;
    }

    const newNodes = [];
    for (const result of results) {
      if (
        result.status === "fulfilled" &&
        this.#postBelongsToTopic(result.value, topicId)
      ) {
        newNodes.push(this.#processNode({ ...result.value, children: [] }));
      }
    }

    if (newNodes.length > 0) {
      this.rootNodes = [...newNodes, ...this.rootNodes];
    }
  }

  readPosts(topicId, postNumbers) {
    if (this.topic?.id !== topicId) {
      return;
    }

    for (const postNumber of postNumbers) {
      const post = this.postRegistry.get(postNumber);
      if (post && !post.read) {
        post.set("read", true);
      }
    }
  }

  #visiblePostIdsBelow(post) {
    const viewSelector = this.contextMode
      ? ".nested-context-view"
      : ".nested-view:not(.nested-context-view)";
    const view = document.querySelector(viewSelector);
    if (!view) {
      return [post.id];
    }

    const postIds = Array.from(
      view.querySelectorAll("article[data-post-id]")
    ).map((element) => Number(element.dataset.postId));
    const index = postIds.indexOf(post.id);

    return index === -1 ? [post.id] : postIds.slice(index);
  }

  #nestedSelectablePostIds() {
    return (this.topic?.postStream?.posts || [])
      .map((post) => post.id)
      .filter((id) => id != null);
  }

  #scrollToRoots() {
    const roots = document.querySelector(
      ".nested-view:not(.nested-context-view) > .nested-view__roots"
    );

    if (!roots) {
      return;
    }

    const controls = document.querySelector(
      ".nested-view:not(.nested-context-view) > .nested-view__controls"
    );
    const controlsHeight = controls?.offsetHeight || 0;
    const rect = roots.getBoundingClientRect();

    window.scrollTo({
      top: window.scrollY + rect.top - headerOffset() - controlsHeight,
    });
  }

  #cacheKey() {
    return this.nestedViewCache.buildKey(this.topic.id, {
      sort: this.sort,
      post_number: this.postNumber,
      context: this.context ?? undefined,
    });
  }

  #saveScrollAnchorToSession(cacheKey, scrollAnchor) {
    try {
      sessionStorage.setItem(
        `nested-view-scroll:${cacheKey}`,
        JSON.stringify(scrollAnchor)
      );
    } catch {
      // Ignore storage failures; in-memory scroll restoration still works.
    }
  }

  #ensurePostInStream(postId) {
    const postStream = this.topic?.postStream;
    if (!postStream) {
      return;
    }

    const id = parseInt(postId, 10);
    if (!postStream.findLoadedPost(id)) {
      for (const post of this.postRegistry.values()) {
        if (post.id === id) {
          registerPostInTopicPostStream(this.topic, post);
          break;
        }
      }
    }
  }

  #onPostRegistered(post) {
    const topicId = this.topic?.id;
    if (
      post?.post_number != null &&
      topicId != null &&
      String(post.topic?.id) === String(topicId)
    ) {
      this.topic?.postStream?.storePost(post);
      this.postRegistry.set(post.post_number, post);
    }
  }

  #onPostUnregistered(post) {
    if (
      post?.post_number != null &&
      this.postRegistry.get(post.post_number) === post
    ) {
      this.postRegistry.delete(post.post_number);
    }
  }

  #onScrollRestored() {
    this.scrollAnchor = null;
  }

  #flatRootForPostNumber(postNumber) {
    for (const node of this.rootNodes) {
      if (
        node.post.post_number === postNumber ||
        node.children?.some((child) => child.post.post_number === postNumber) ||
        this.fetchedChildrenCache
          .get(`${this.topic.id}:${node.post.post_number}`)
          ?.childNodes.some((child) => child.post.post_number === postNumber)
      ) {
        return node;
      }
    }
  }

  #onPostCreated(post) {
    if (
      flatRepliesEnabled(this.siteSettings) &&
      this.#postBelongsToTopic(post) &&
      this.#isVisibleInTree(post)
    ) {
      this.#insertOwnFlatReply(post);
    }
  }

  #insertOwnFlatReply(post) {
    if (this.#isPostKnown(post.id)) {
      return;
    }
    const parent = post.reply_to_post_number;
    const root = parent > 1 ? this.#flatRootForPostNumber(parent) : null;
    if (parent > 1 && !root) {
      return;
    }
    post.topic = this.topic;
    post = registerPostInTopicPostStream(this.topic, post) || post;
    const node = { post, children: [], _renderKey: post.id };
    if (root) {
      const rootPostNumber = root.post.post_number;
      const key = `${this.topic.id}:${rootPostNumber}`;
      const current =
        this.fetchedChildrenCache.get(key) ||
        mergeFlatReplyPreload(null, root.children || [], {
          page: root.post.children_page,
          count: root.post.total_descendant_count,
        });
      this.fetchedChildrenCache.set(
        key,
        mergeFlatReplyPage(current, [node], {
          count: (root.post.total_descendant_count || 0) + 1,
          saved: true,
        })
      );
      root.children = [...root.children, node];
      this.expansionState.set(rootPostNumber, {
        expanded: true,
        collapsed: false,
      });
      this.appEvents.trigger("nested-replies:child-created", {
        topicId: this.topic.id,
        post,
        parentPostNumber: rootPostNumber,
        isOwnPost: true,
      });
    } else {
      this.rootNodes = [...this.rootNodes, node].sort(
        (left, right) => left.post.post_number - right.post.post_number
      );
    }
    this.postRegistry.set(post.post_number, post);
    this.targetPostNumber = post.post_number;
    this.scrollAnchor = null;
    this.revealFlatTarget(post.post_number);
    this.#refreshFlatNavigation(post.post_number);
  }

  async #refreshFlatNavigation(postNumber) {
    const topic = this.topic;
    try {
      const navigation = await ajax(
        `/n/${topic.slug}/${topic.id}/navigation.json`,
        { data: { post_number: postNumber } }
      );
      if (this.topic === topic) {
        topic.set("reply_navigation", navigation);
        this.rootNodes
          .find((node) => node.post.post_number === navigation.root_post_number)
          ?.post.set("root_index", navigation.root_index);
      }
    } catch {
      // A saved reply remains visible if navigation metadata cannot be refreshed.
    }
  }

  async #handleCreated(data) {
    // Skip if this post is already known (e.g. cache restore replaying
    // messages that were already processed before navigating away)
    if (this.#isPostKnown(data.id) || this.#pendingPostIds.has(data.id)) {
      return;
    }

    this.#pendingPostIds.add(data.id);
    const topicId = this.topic?.id;
    try {
      const postData = await ajax(`/posts/${data.id}.json`);
      if (
        this.topic?.id !== topicId ||
        !this.#postBelongsToTopic(postData, topicId) ||
        this.#isPostKnown(data.id)
      ) {
        return;
      }

      if (this.#isActivityLogPost(postData)) {
        this.#notifyActivityChanged(data);
        return;
      }

      if (!this.#isVisibleInTree(postData)) {
        return;
      }

      const replyTo = postData.reply_to_post_number;
      const isRoot = !replyTo || replyTo === 1;
      let flatNavigation;
      if (flatRepliesEnabled(this.siteSettings)) {
        if (data.user_id === this.currentUser?.id) {
          this.#insertOwnFlatReply(this.#processNode(postData).post);
          return;
        }
        flatNavigation = await ajax(
          `/n/${this.topic.slug}/${topicId}/navigation.json`,
          { data: { post_number: postData.post_number } }
        );
        if (this.topic?.id !== topicId) {
          return;
        }
        this.topic.set("reply_navigation", flatNavigation);
      }

      if (isRoot) {
        if (this.contextMode) {
          return;
        }

        const node = this.#processNode({ ...postData, children: [] });
        if (data.user_id === this.currentUser?.id) {
          this.rootNodes = [node, ...this.rootNodes];
        } else {
          this.newRootPostIds = [...this.newRootPostIds, data.id];
        }
      } else {
        const node = this.#processNode({ ...postData, children: [] });
        this.appEvents.trigger("nested-replies:child-created", {
          topicId,
          post: node.post,
          parentPostNumber:
            flatNavigation?.root_post_number ||
            this.#visibleParentPostNumber(postData),
          isOwnPost: data.user_id === this.currentUser?.id,
        });
      }
    } catch {
      // Post may not be visible to this user
    } finally {
      this.#pendingPostIds.delete(data.id);
    }
  }

  // Mirrors the server-side filter in NestedReplies::TreeLoader#apply_visibility:
  // small_action posts (close/open/etc.) belong in the activity log, not the tree;
  // whispers with an action_code (e.g. assigns) are likewise activity-log-only.
  #isVisibleInTree(postData) {
    return !this.#isActivityLogPost(postData);
  }

  #isActivityLogPost(postData) {
    const postTypes = this.site.post_types;
    if (postData.post_type === postTypes.small_action) {
      return true;
    }
    if (postData.post_type === postTypes.whisper && postData.action_code) {
      return true;
    }
    return false;
  }

  #notifyActivityChanged(data) {
    const topicId = this.topic?.id;
    if (topicId) {
      this.topic = this.store.createRecord("topic", {
        id: topicId,
        has_activity_log: true,
      });
    }
    this.appEvents.trigger("nested-replies:activity-changed", {
      topicId,
      postId: data.id,
      type: data.type,
    });
  }

  #visibleParentPostNumber(postData) {
    const replyTo = postData.reply_to_post_number;
    if (!this.siteSettings.nested_replies_cap_nesting_depth) {
      return replyTo;
    }

    const ancestors = [];
    let postNumber = replyTo;

    while (postNumber && postNumber !== 1) {
      ancestors.unshift(postNumber);
      const post = this.postRegistry.get(postNumber);
      if (!post) {
        return replyTo;
      }
      postNumber = post.reply_to_post_number;
    }

    const maxDepth = this.siteSettings.nested_replies_max_depth;
    return ancestors.length > maxDepth ? ancestors[maxDepth - 1] : replyTo;
  }

  #postBelongsToTopic(postData, topicId = this.topic?.id) {
    return (
      postData?.topic_id != null &&
      String(postData.topic_id) === String(topicId)
    );
  }

  #isPostKnown(postId) {
    if (this.rootNodes.some((n) => n.post.id === postId)) {
      return true;
    }
    if (this.newRootPostIds.includes(postId)) {
      return true;
    }
    for (const post of this.postRegistry.values()) {
      if (post.id === postId) {
        return true;
      }
    }
    for (const entry of this.fetchedChildrenCache.values()) {
      if (entry.childNodes.some((node) => node.post.id === postId)) {
        return true;
      }
    }
    return false;
  }

  async #handlePostChanged(data) {
    if (data.type === "deleted") {
      if (this.topic?.has_activity_log) {
        this.#notifyActivityChanged(data);
      }
      this.#markPostDeletedLocally(data.id);
      return;
    }

    const topicId = this.topic?.id;
    try {
      const postData = await ajax(`/posts/${data.id}.json`);
      if (
        this.topic?.id !== topicId ||
        !this.#postBelongsToTopic(postData, topicId)
      ) {
        return;
      }

      if (this.#isActivityLogPost(postData)) {
        this.#notifyActivityChanged(data);
        return;
      }

      const existing = [...this.postRegistry.values()].find(
        (p) => p.id === data.id
      );
      if (existing) {
        // Route through the store so Post.munge runs — it rebuilds
        // actions_summary as ActionSummary instances and repopulates
        // actionByName. Without this, flagsAvailable (reads actionByName)
        // and postActionFor (reads actions_summary) drift apart after an
        // "acted" event, which crashes the flag modal on the next submit.
        const updated = this.store.createRecord("post", postData);
        existing.updateFromPost(updated);
        if (!postData.deleted_at) {
          existing.set("deleted_post_placeholder", false);
        }
      }
    } catch {
      // Post may not be visible
    }
  }

  #markPostDeletedLocally(postId) {
    for (const post of this.postRegistry.values()) {
      if (post.id === postId) {
        post.set("deleted_at", new Date());
        post.set("deleted_post_placeholder", true);
        if (!this.currentUser?.staff) {
          post.set("cooked", "");
        }
        break;
      }
    }
  }

  #processNode(nodeData) {
    return processNode(this.store, this.topic, nodeData);
  }

  #assignSuggestedAndRelated(data) {
    if (!this.topic) {
      return;
    }
    if (data.suggested_topics !== undefined) {
      this.topic.suggested_topics = data.suggested_topics;
    }
    if (data.related_topics !== undefined) {
      this.topic.related_topics = data.related_topics;
    }
    if (data.related_messages !== undefined) {
      this.topic.related_messages = data.related_messages;
    }
    if (data.suggested_group_name !== undefined) {
      this.topic.suggested_group_name = data.suggested_group_name;
    }
  }

  @bind
  _onMessage(data, globalId, messageId) {
    if (messageId != null) {
      this.messageBusLastId = messageId;
    }

    switch (data.type) {
      case "created":
        this.#handleCreated(data);
        break;
      case "revised":
      case "rebaked":
      case "deleted":
      case "recovered":
      case "acted":
        this.#handlePostChanged(data);
        break;
    }
  }
}
