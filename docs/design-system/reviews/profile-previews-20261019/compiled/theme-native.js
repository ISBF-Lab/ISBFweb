const {
  getObjectForTheme: getObjectForTheme
} = window.moduleBroker.lookup("discourse/lib/theme-settings-store");
const {
  scheduleOnce: scheduleOnce,
  schedule: schedule
} = window.moduleBroker.lookup("@ember/runloop");
const {
  default: Service,
  service: service
} = window.moduleBroker.lookup("@ember/service");
const {
  _INTERNAL_SOURCE_KEY: _INTERNAL_SOURCE_KEY,
  apiInitializer: apiInitializer$1
} = window.moduleBroker.lookup("discourse/lib/api");
const {
  default: Composer
} = window.moduleBroker.lookup("discourse/models/composer");
const {
  default: dConcatClass
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-concat-class");
const {
  default: I18n,
  i18n: i18n
} = window.moduleBroker.lookup("discourse-i18n");
const {
  default: Component
} = window.moduleBroker.lookup("@glimmer/component");
const {
  trustHTML: trustHTML
} = window.moduleBroker.lookup("@ember/template");
const {
  default: ExpandPost
} = window.moduleBroker.lookup("discourse/components/expand-post");
const {
  default: DDecoratedHtml
} = window.moduleBroker.lookup("discourse/ui-kit/d-decorated-html");
const {
  default: DUserLink
} = window.moduleBroker.lookup("discourse/ui-kit/d-user-link");
const {
  default: dAvatar
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-avatar");
const {
  default: dCategoryLink
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-category-link");
const {
  default: dFormatDate
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-format-date");
const {
  default: dReplaceEmoji
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-replace-emoji");
const {
  tracked: tracked,
  cached: cached
} = window.moduleBroker.lookup("@glimmer/tracking");
const {
  fn: fn,
  eq: eq$1,
  not: not$1,
  and: and,
  or: or$1,
  hash: hash
} = window.moduleBroker.lookup("@ember/helper");
const {
  on: on
} = window.moduleBroker.lookup("@ember/modifier");
const {
  default: EmberObject,
  action: action,
  get: get
} = window.moduleBroker.lookup("@ember/object");
const {
  default: didInsert
} = window.moduleBroker.lookup("@ember/render-modifiers/modifiers/did-insert");
const {
  default: didUpdate
} = window.moduleBroker.lookup("@ember/render-modifiers/modifiers/did-update");
const {
  default: willDestroy
} = window.moduleBroker.lookup("@ember/render-modifiers/modifiers/will-destroy");
const {
  default: dIcon
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-icon");
const {
  ajax: ajax
} = window.moduleBroker.lookup("discourse/lib/ajax");
const {
  setComponentTemplate: setComponentTemplate
} = window.moduleBroker.lookup("@ember/component");
const {
  createTemplateFactory: createTemplateFactory
} = window.moduleBroker.lookup("@ember/template-factory");
const {
  registerModuleForModifyClass: registerModuleForModifyClass
} = window.moduleBroker.lookup("discourse/lib/deferred-class-modifications");
const {
  default: PluginOutlet
} = window.moduleBroker.lookup("discourse/components/plugin-outlet");
const {
  default: lazyHash
} = window.moduleBroker.lookup("discourse/helpers/lazy-hash");
const {
  default: DButton
} = window.moduleBroker.lookup("discourse/ui-kit/d-button");
const {
  default: Category
} = window.moduleBroker.lookup("discourse/models/category");
const {
  default: Form
} = window.moduleBroker.lookup("discourse/components/form");
const {
  not: not,
  eq: eq,
  or: or,
  notEq: notEq,
  and: and$1,
  gt: gt
} = window.moduleBroker.lookup("discourse/truth-helpers");
const {
  default: DModal
} = window.moduleBroker.lookup("discourse/ui-kit/d-modal");
const {
  default: DMenu
} = window.moduleBroker.lookup("discourse/float-kit/components/d-menu");
const {
  default: DDropdownMenu
} = window.moduleBroker.lookup("discourse/ui-kit/d-dropdown-menu");
const {
  default: DPopupInputTip
} = window.moduleBroker.lookup("discourse/ui-kit/d-popup-input-tip");
const {
  default: DTextField
} = window.moduleBroker.lookup("discourse/ui-kit/d-text-field");
const {
  getOwner: getOwner
} = window.moduleBroker.lookup("@ember/owner");
const {
  default: EmbedMode
} = window.moduleBroker.lookup("discourse/lib/embed-mode");
const {
  default: loadScript
} = window.moduleBroker.lookup("discourse/lib/load-script");
const {
  modifier: modifier
} = window.moduleBroker.lookup("ember-modifier");
const {
  popupAjaxError: popupAjaxError
} = window.moduleBroker.lookup("discourse/lib/ajax-error");
const {
  default: lightbox,
  sortLightboxItems: sortLightboxItems
} = window.moduleBroker.lookup("discourse/lib/lightbox");
const {
  default: templateOnly
} = window.moduleBroker.lookup("@ember/component/template-only");
const {
  default: dCategoryBadge
} = window.moduleBroker.lookup("discourse/ui-kit/helpers/d-category-badge");
const {
  default: Draft
} = window.moduleBroker.lookup("discourse/models/draft");
const {
  loadTopicView: loadTopicView
} = window.moduleBroker.lookup("discourse/models/topic");
const {
  optionalRequire: optionalRequire,
  clipboardCopy: clipboardCopy
} = window.moduleBroker.lookup("discourse/lib/utilities");
const {
  default: Flag
} = window.moduleBroker.lookup("discourse/components/modal/flag");
const {
  default: PostFlag
} = window.moduleBroker.lookup("discourse/lib/flag-targets/post-flag");
const {
  default: FlagActionType
} = window.moduleBroker.lookup("discourse/components/flag-action-type");
const {
  default: FlagSelection
} = window.moduleBroker.lookup("discourse/components/flag-selection");
const {
  default: ReviewableBundledAction
} = window.moduleBroker.lookup("discourse/components/reviewable-bundled-action");
const {
  default: DFutureDateInput
} = window.moduleBroker.lookup("discourse/ui-kit/d-future-date-input");
const {
  default: DismissNotificationConfirmationModal
} = window.moduleBroker.lookup("discourse/components/modal/dismiss-notification-confirmation");
const {
  default: UserMenuNotificationItem
} = window.moduleBroker.lookup("discourse/lib/user-menu/notification-item");
const {
  default: Notification
} = window.moduleBroker.lookup("discourse/models/notification");
const {
  default: DToggleSwitch
} = window.moduleBroker.lookup("discourse/ui-kit/d-toggle-switch");
const {
  default: MenuItem
} = window.moduleBroker.lookup("discourse/components/user-menu/menu-item");
const {
  default: DRelativeDate
} = window.moduleBroker.lookup("discourse/ui-kit/d-relative-date");
const {
  default: logout
} = window.moduleBroker.lookup("discourse/lib/logout");
const {
  getCurrentPushSubscription: getCurrentPushSubscription
} = window.moduleBroker.lookup("discourse/lib/push-notifications");
const {
  default: HomeLogo
} = window.moduleBroker.lookup("discourse/components/header/home-logo");
const {
  default: Logo
} = window.moduleBroker.lookup("discourse/components/header/logo");
const {
  default: getURL
} = window.moduleBroker.lookup("discourse/lib/get-url");
const {
  headerOffset: headerOffset
} = window.moduleBroker.lookup("discourse/lib/offset-calculator");
const {
  default: DiscourseURL
} = window.moduleBroker.lookup("discourse/lib/url");
const {
  default: TopicNavigation
} = window.moduleBroker.lookup("discourse/components/topic-navigation");
const {
  default: TopicTimeline
} = window.moduleBroker.lookup("discourse/components/topic-timeline");
const {
  default: DCloseOnClickOutside
} = window.moduleBroker.lookup("discourse/ui-kit/modifiers/d-close-on-click-outside");
const {
  default: PostMenuBookmarkButton
} = window.moduleBroker.lookup("discourse/components/post/menu/buttons/bookmark");
const {
  default: PostMenuLikeButton
} = window.moduleBroker.lookup("discourse/components/post/menu/buttons/like");
const {
  default: PostCookedHtml
} = window.moduleBroker.lookup("discourse/components/post/cooked-html");
const {
  default: DConditionalLoadingSpinner
} = window.moduleBroker.lookup("discourse/ui-kit/d-conditional-loading-spinner");
const {
  default: PostMenuButtonConfig
} = window.moduleBroker.lookup("discourse/components/post/menu/button-config");
const {
  default: PostMenuButtonWrapper
} = window.moduleBroker.lookup("discourse/components/post/menu/button-wrapper");
const {
  default: TopicFooterButtons
} = window.moduleBroker.lookup("discourse/components/topic-footer-buttons");
const {
  default: TopicMap
} = window.moduleBroker.lookup("discourse/components/topic-map");
const {
  default: routeAction
} = window.moduleBroker.lookup("discourse/helpers/route-action");
const {
  withPluginApi: withPluginApi$1
} = window.moduleBroker.lookup("discourse/lib/plugin-api");
const {
  default: CustomNotification
} = window.moduleBroker.lookup("discourse/lib/notification-types/custom");
const {
  UploadPreProcessorPlugin: UploadPreProcessorPlugin
} = window.moduleBroker.lookup("discourse/lib/uppy-plugin-base");
const {
  default: DiscourseRoute
} = window.moduleBroker.lookup("discourse/routes/discourse");
const {
  registerDestructor: registerDestructor
} = window.moduleBroker.lookup("@ember/destroyable");
const {
  default: AvatarSelector
} = window.moduleBroker.lookup("discourse/components/modal/avatar-selector");
const {
  default: Bookmark
} = window.moduleBroker.lookup("discourse/components/modal/bookmark");
const {
  default: CreateInvite
} = window.moduleBroker.lookup("discourse/components/modal/create-invite");
const {
  default: CreateInviteBulk
} = window.moduleBroker.lookup("discourse/components/modal/create-invite-bulk");
const {
  default: CreateInviteWithRoles
} = window.moduleBroker.lookup("discourse/components/modal/create-invite-with-roles");
const {
  default: DiscardDraft
} = window.moduleBroker.lookup("discourse/components/modal/discard-draft");
const {
  default: EditUserDirectoryColumns
} = window.moduleBroker.lookup("discourse/components/modal/edit-user-directory-columns");
const {
  default: GroupAddMembers
} = window.moduleBroker.lookup("discourse/components/modal/group-add-members");
const {
  default: GroupDefaultNotifications
} = window.moduleBroker.lookup("discourse/components/modal/group-default-notifications");
const {
  default: RequestGroupMembershipForm
} = window.moduleBroker.lookup("discourse/components/modal/request-group-membership-form");
const {
  default: SecondFactorAddSecurityKey
} = window.moduleBroker.lookup("discourse/components/modal/second-factor-add-security-key");
const {
  default: SecondFactorAddTotp
} = window.moduleBroker.lookup("discourse/components/modal/second-factor-add-totp");
const {
  default: SecondFactorBackupEdit
} = window.moduleBroker.lookup("discourse/components/modal/second-factor-backup-edit");
const {
  default: SecondFactorEdit
} = window.moduleBroker.lookup("discourse/components/modal/second-factor-edit");
const {
  default: SecondFactorEditSecurityKey
} = window.moduleBroker.lookup("discourse/components/modal/second-factor-edit-security-key");
const {
  default: bodyClass
} = window.moduleBroker.lookup("discourse/helpers/body-class");
const {
  default: GroupIndex
} = window.moduleBroker.lookup("discourse/routes/group/index");
const {
  bind: bind
} = window.moduleBroker.lookup("discourse/lib/decorators");
const {
  wantsNewWindow: wantsNewWindow
} = window.moduleBroker.lookup("discourse/lib/intercept-click");
const {
  default: CalendarSubscriptionUrl
} = window.moduleBroker.lookup("discourse/components/calendar-subscription-url");
const {
  default: UserTip
} = window.moduleBroker.lookup("discourse/components/user-tip");
const {
  default: BrowseMore
} = window.moduleBroker.lookup("discourse/components/more-topics/browse-more");
const {
  default: TopicListItem
} = window.moduleBroker.lookup("discourse/components/topic-list/item");
const {
  default: TopicLink
} = window.moduleBroker.lookup("discourse/components/topic-list/topic-link");
const {
  default: TopicStatus
} = window.moduleBroker.lookup("discourse/components/topic-status");
const settings = getObjectForTheme(4);
function themePrefix(key) {
  return `theme_translations.4.${key}`;
}
const SOURCE$1 = Object.freeze({
  "type": "theme",
  "id": 4
});
function apiInitializer(...args) {
  // A leading string is the legacy version argument, which shifts opts along.
  const optsIndex = typeof args[0] === "string" ? 2 : 1;
  args[optsIndex] = {
    ...args[optsIndex],
    [_INTERNAL_SOURCE_KEY]: SOURCE$1
  };
  return apiInitializer$1(...args);
}
const UNTITLED_PATTERN = /^校园动态 \[isbf-untitled:[0-9a-f-]{36}\]$/;
function isUntitledTopicTitle(title) {
  return typeof title === "string" && UNTITLED_PATTERN.test(title);
}
function optionalTopicTitle(title) {
  return isUntitledTopicTitle(title) ? "" : title ?? "";
}
function setOptionalTopicTitle(model, value) {
  const explicitTitle = value ?? "";
  const title = explicitTitle.trim() ? explicitTitle : isUntitledTopicTitle(model.title) ? model.title : `校园动态 [isbf-untitled:${crypto.randomUUID()}]`;
  model.setProperties({
    isbf_optional_title: explicitTitle,
    title
  });
}
function prepareOptionalTopicTitle(model) {
  setOptionalTopicTitle(model, model.isbf_optional_title ?? optionalTopicTitle(model.title));
}
var Mod34 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  isUntitledTopicTitle: isUntitledTopicTitle,
  optionalTopicTitle: optionalTopicTitle,
  prepareOptionalTopicTitle: prepareOptionalTopicTitle,
  setOptionalTopicTitle: setOptionalTopicTitle
});
const PUBLIC_ACTION_TYPES = new Set([1, 2, 4, 5, 6, 7, 9, 11, 17]);
function hasPostPreviewTarget({
  postId,
  topicId,
  postNumber
}) {
  const positiveInteger = value => Number.isSafeInteger(Number(value)) && Number(value) > 0;
  return positiveInteger(postId) || positiveInteger(topicId) && positiveInteger(postNumber);
}
function isActivityPreview(item, path) {
  const pathname = (path ?? "").split(/[?#]/)[0];
  return /^\/u\/[^/]+\/activity(?:\/|$)/.test(pathname) && !/\/(?:drafts|bookmarks|pending|messages|notifications)(?:\/|$)/.test(pathname) && hasPostPreviewTarget({
    postId: item?.post_id,
    topicId: item?.topic_id,
    postNumber: item?.post_number
  }) && PUBLIC_ACTION_TYPES.has(Number(item?.action_type)) && (!item.post_type || Number(item.post_type) === 1) && !item.draft_key;
}
function postPreview(html) {
  const document = new DOMParser().parseFromString(html ?? "", "text/html");
  const body = document.body;
  body.querySelectorAll("script, style, iframe, aside.quote, aside.onebox, .lightbox-wrapper .meta").forEach(element => element.remove());
  const images = [];
  const sources = new Set();
  for (const image of body.querySelectorAll("img:not(.emoji)")) {
    if (image.matches(".avatar, .favicon, .ytp-thumbnail-image")) {
      continue;
    }
    const source = image.getAttribute("src");
    if (!source) {
      continue;
    }
    try {
      const url = new URL(source, window.location.href);
      if (["https:", "http:"].includes(url.protocol) && !sources.has(url.href)) {
        images.push({
          src: url.href
        });
        sources.add(url.href);
      }
    } catch {
      continue;
    }
    if (images.length === 3) {
      break;
    }
  }
  body.querySelectorAll("a.lightbox, img:not(.emoji)").forEach(element => {
    element.remove();
  });
  body.querySelectorAll("img.emoji").forEach(image => {
    image.replaceWith(document.createTextNode(image.getAttribute("alt") ?? ""));
  });
  body.querySelectorAll("p, div, br, li, blockquote, h1, h2, h3").forEach(element => {
    element.append(document.createTextNode(" "));
  });
  const text = body.textContent.replace(/\s+/g, " ").trim();
  const characters = Array.from(text);
  return {
    text: characters.length > 300 ? `${characters.slice(0, 300).join("")}…` : text,
    images
  };
}
var Mod90 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  hasPostPreviewTarget: hasPostPreviewTarget,
  isActivityPreview: isActivityPreview,
  postPreview: postPreview
});
const cache = new Map();
const pendingRequests = new Map();
const invalidatedPosts = new Set();
const generations = new Map();
const postNumbers = new Map();
const queue$1 = [];
const pollCache = new Map();
const pendingPolls = new Map();
let activeRequests$1 = 0;
let generation = 0;
function rememberPostNumber(key, postId) {
  if (!key) {
    return;
  }
  postNumbers.delete(key);
  postNumbers.set(key, postId);
  if (postNumbers.size > 50) {
    postNumbers.delete(postNumbers.keys().next().value);
  }
}
function runQueue$1() {
  while (activeRequests$1 < 4 && queue$1.length) {
    activeRequests$1 += 1;
    runJob$1(queue$1.shift());
  }
}
function runJob$1(job) {
  const isPoll = job.kind === "polls";
  ajax(isPoll ? `/posts/${job.postId}.json` : job.url).then(result => {
    const postId = job.postId || Number(result.id);
    if (!Number.isSafeInteger(postId) || postId <= 0) {
      throw new Error("Post response is missing its ID");
    }
    rememberPostNumber(job.postNumberKey, postId);
    if (invalidatedPosts.has(postId) || (generations.get(postId) || 0) > job.startedGeneration) {
      job.resolve(isPoll ? null : "");
    } else if (isPoll) {
      pollCache.set(job.key, {
        value: result,
        at: Date.now()
      });
      if (pollCache.size > 100) {
        pollCache.delete(pollCache.keys().next().value);
      }
      job.resolve(result);
    } else {
      cache.set(postId, result.cooked);
      if (cache.size > 50) {
        cache.delete(cache.keys().next().value);
      }
      job.resolve(result.cooked);
    }
  }).catch(job.reject).finally(() => {
    if (!isPoll && pendingRequests.get(job.key)?.promise === job.promise) {
      pendingRequests.delete(job.key);
    }
    activeRequests$1 -= 1;
    runQueue$1();
  });
}
function loadCookedPost(postId, {
  topicId,
  postNumber
} = {}) {
  if (!hasPostPreviewTarget({
    postId,
    topicId,
    postNumber
  })) {
    return Promise.reject(new Error("Post preview target is missing"));
  }
  const postNumberKey = hasPostPreviewTarget({
    topicId,
    postNumber
  }) ? `${Number(topicId)}/${Number(postNumber)}` : null;
  postId = Number.isSafeInteger(Number(postId)) && Number(postId) > 0 ? Number(postId) : postNumbers.get(postNumberKey);
  if (postId) {
    rememberPostNumber(postNumberKey, postId);
  }
  if (invalidatedPosts.has(postId)) {
    return Promise.resolve("");
  }
  if (cache.has(postId)) {
    const cooked = cache.get(postId);
    cache.delete(postId);
    cache.set(postId, cooked);
    return Promise.resolve(cooked);
  }
  const key = postId || postNumberKey;
  const targetGeneration = postId ? generations.get(postId) || 0 : generation;
  const pending = pendingRequests.get(key);
  if (pending && pending.targetGeneration === targetGeneration) {
    return pending.promise;
  }
  const job = {
    key,
    postId,
    postNumberKey,
    startedGeneration: generation,
    targetGeneration,
    url: postId ? `/posts/${postId}/cooked` : `/posts/by_number/${postNumberKey}.json`
  };
  job.promise = new Promise((resolve, reject) => {
    Object.assign(job, {
      reject,
      resolve
    });
  });
  pendingRequests.set(key, job);
  queue$1.push(job);
  runQueue$1();
  return job.promise;
}
function loadPostPolls(postId, userId, {
  refresh = false
} = {}) {
  const id = Number(postId);
  if (!Number.isSafeInteger(id) || id <= 0 || invalidatedPosts.has(id)) {
    return Promise.resolve(null);
  }
  const key = `${userId || "guest"}:${id}`;
  if (pendingPolls.has(key)) {
    return pendingPolls.get(key);
  }
  const cached = pollCache.get(key);
  if (!refresh && cached && Date.now() - cached.at < 30000) {
    return Promise.resolve(cached.value);
  }
  pollCache.delete(key);
  const promise = new Promise((resolve, reject) => {
    queue$1.push({
      kind: "polls",
      key,
      postId: id,
      reject,
      resolve,
      startedGeneration: generation
    });
    runQueue$1();
  }).finally(() => {
    if (pendingPolls.get(key) === promise) {
      pendingPolls.delete(key);
    }
  });
  pendingPolls.set(key, promise);
  return promise;
}
function invalidateCookedPost(postId, hidden = true) {
  const id = Number(postId);
  generations.set(id, ++generation);
  if (hidden) {
    invalidatedPosts.add(id);
  } else {
    invalidatedPosts.delete(id);
  }
  cache.delete(id);
  for (const key of pollCache.keys()) {
    if (key.endsWith(`:${id}`)) {
      pollCache.delete(key);
    }
  }
  for (const key of pendingPolls.keys()) {
    if (key.endsWith(`:${id}`)) {
      pendingPolls.delete(key);
    }
  }
}
const countCache = new Map();
const pendingCountIds = new Set();
const countResolvers = new Map();
let countTimer;
async function flushCounts() {
  const ids = [...pendingCountIds].slice(0, 50);
  ids.forEach(id => pendingCountIds.delete(id));
  countTimer = null;
  try {
    const result = await ajax("/isbf/reposts/counts", {
      data: {
        topic_ids: ids
      }
    });
    ids.forEach(id => {
      const count = Number(result.counts?.[id] ?? 0);
      countCache.set(id, count);
      countResolvers.get(id)?.forEach(resolve => resolve(count));
      countResolvers.delete(id);
    });
  } catch {
    ids.forEach(id => {
      countResolvers.get(id)?.forEach(resolve => resolve(null));
      countResolvers.delete(id);
    });
  }
  if (pendingCountIds.size) {
    countTimer = setTimeout(flushCounts, 40);
  }
}
function loadRepostCount(topicId) {
  if (countCache.has(topicId)) {
    return Promise.resolve(countCache.get(topicId));
  }
  pendingCountIds.add(topicId);
  return new Promise(resolve => {
    const resolvers = countResolvers.get(topicId) ?? [];
    resolvers.push(resolve);
    countResolvers.set(topicId, resolvers);
    countTimer ??= setTimeout(flushCounts, 40);
  });
}
var Mod14 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  invalidateCookedPost: invalidateCookedPost,
  loadCookedPost: loadCookedPost,
  loadPostPolls: loadPostPolls,
  loadRepostCount: loadRepostCount
});
class ISBFPostPreview extends Component {
  #generation = 0;
  #observer;
  #requested = false;
  static {
    dt7948.g(this.prototype, "_failedImages", [tracked], function () {
      return [];
    });
  }
  #_failedImages = (dt7948.i(this, "_failedImages"), void 0);
  static {
    dt7948.g(this.prototype, "_preview", [tracked], function () {
      return null;
    });
  }
  #_preview = (dt7948.i(this, "_preview"), void 0);
  get isRail() {
    return this.args.variant === "rail";
  }
  get isSummary() {
    return this.args.variant === "summary";
  }
  get preview() {
    return this.args.disabled ? {
      text: "",
      images: []
    } : this._preview ?? postPreview(this.args.excerpt);
  }
  static {
    dt7948.n(this.prototype, "preview", [cached]);
  }
  get images() {
    if (this.args.disabled || this.isRail || this.isSummary) {
      return [];
    }
    return (this._preview?.images ?? []).filter(image => !this._failedImages.includes(image.src)).slice(0, 3);
  }
  get text() {
    return this.isRail && this.title || this.preview.text || i18n(themePrefix(this.isRail || this.isSummary ? this.preview.images.length ? "isbf_v2.preview_picture" : "isbf_v2.preview_post" : "isbf_v2.preview_open"));
  }
  get title() {
    return optionalTopicTitle(this.args.title);
  }
  observe(element) {
    this.#observer?.disconnect();
    this.#generation += 1;
    this.#requested = false;
    this._preview = null;
    this._failedImages = [];
    if (this.args.disabled || !hasPostPreviewTarget(this.args) || this.isRail && this.title) {
      return;
    }
    this.#observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.#observer.disconnect();
        this.#loadBody();
      }
    }, {
      rootMargin: "200px",
      threshold: 0
    });
    this.#observer.observe(element);
  }
  static {
    dt7948.n(this.prototype, "observe", [action]);
  }
  destroyObserver() {
    this.#generation += 1;
    this.#observer?.disconnect();
  }
  static {
    dt7948.n(this.prototype, "destroyObserver", [action]);
  }
  imageFailed(source) {
    this._failedImages = [...this._failedImages, source];
  }
  static {
    dt7948.n(this.prototype, "imageFailed", [action]);
  }
  async #loadBody() {
    if (this.#requested) {
      return;
    }
    this.#requested = true;
    const generation = this.#generation;
    try {
      const cooked = await loadCookedPost(this.args.postId, {
        topicId: this.args.topicId,
        postNumber: this.args.postNumber
      });
      if (!this.isDestroying && generation === this.#generation) {
        this._preview = postPreview(cooked);
      }
    } catch {
      // The existing excerpt and post link remain usable if the request fails.
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <a
      class={{dConcatClass
        "isbf-post-preview"
        (if this.isRail "--rail" (if this.isSummary "--summary" "--activity"))
      }}
      href={{@href}}
      ...attributes
      {{didInsert this.observe}}
      {{didUpdate
        this.observe
        @postId
        @topicId
        @postNumber
        @disabled
        @title
        @excerpt
        @variant
      }}
      {{willDestroy this.destroyObserver}}
    >
      <span class="isbf-post-preview__text">{{dReplaceEmoji this.text}}</span>
      {{#if this.images.length}}
        <span class="isbf-post-preview__images">
          {{#each this.images key="src" as |image|}}
            <img
              alt={{i18n (themePrefix "isbf_v2.preview_image")}}
              class="isbf-post-preview__image"
              decoding="async"
              loading="lazy"
              src={{image.src}}
              {{on "error" (fn this.imageFailed image.src)}}
            />
          {{/each}}
        </span>
      {{/if}}
      {{#if this.isRail}}{{dIcon "chevron-right"}}{{/if}}
    </a>
    */
    {
      "id": null,
      "block": "[[[11,3],[16,0,[28,[32,0],[\"isbf-post-preview\",[52,[30,0,[\"isRail\"]],\"--rail\",[52,[30,0,[\"isSummary\"]],\"--summary\",\"--activity\"]]],null]],[16,6,[30,1]],[17,2],[4,[32,1],[[30,0,[\"observe\"]]],null],[4,[32,2],[[30,0,[\"observe\"]],[30,3],[30,4],[30,5],[30,6],[30,7],[30,8],[30,9]],null],[4,[32,3],[[30,0,[\"destroyObserver\"]]],null],[12],[1,\"\\n  \"],[10,1],[14,0,\"isbf-post-preview__text\"],[12],[1,[28,[32,4],[[30,0,[\"text\"]]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"images\",\"length\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-post-preview__images\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"images\"]]],null]],null],\"src\",[[[1,\"        \"],[11,\"img\"],[16,\"alt\",[28,[32,5],[[28,[32,6],[\"isbf_v2.preview_image\"],null]],null]],[24,0,\"isbf-post-preview__image\"],[24,\"decoding\",\"async\"],[24,\"loading\",\"lazy\"],[16,\"src\",[30,10,[\"src\"]]],[4,[32,7],[\"error\",[28,[32,8],[[30,0,[\"imageFailed\"]],[30,10,[\"src\"]]],null]],null],[12],[13],[1,\"\\n\"]],[10]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[41,[30,0,[\"isRail\"]],[[[1,[28,[32,9],[\"chevron-right\"],null]]],[]],null],[1,\"\\n\"],[13]],[\"@href\",\"&attrs\",\"@postId\",\"@topicId\",\"@postNumber\",\"@disabled\",\"@title\",\"@excerpt\",\"@variant\",\"image\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        didInsert,
        didUpdate,
        willDestroy,
        dReplaceEmoji,
        i18n,
        themePrefix,
        on,
        fn,
        dIcon
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-post-preview", ISBFPostPreview);
var Mod88 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFPostPreview
});
class ISBFActivityPreview extends Component {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  get available() {
    return !this.post.hidden && !this.post.deleted;
  }
  get enabled() {
    return isActivityPreview(this.post, this.router.currentURL);
  }
  get post() {
    return this.args.outletArgs.item;
  }
  get title() {
    return optionalTopicTitle(this.post.title);
  }
  get user() {
    return {
      id: this.post.user_id,
      name: this.post.name,
      username: this.post.username,
      avatar_template: this.post.avatar_template
    };
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <article class="isbf-activity-preview">
        <div class="isbf-activity-preview__header">
          <DUserLink @user={{this.user}}>
            {{dAvatar this.user imageSize="large" ignoreTitle="true"}}
          </DUserLink>
          <div class="isbf-activity-preview__details">
            {{#if this.title}}
              <a
                class="isbf-activity-preview__title"
                href={{this.post.postUrl}}
              >{{dReplaceEmoji this.title}}</a>
            {{/if}}
            <div class="isbf-activity-preview__metadata">
              {{#if this.post.category}}
                <span>{{dCategoryLink
                    this.post.category
                    styleType="square"
                  }}</span>
              {{/if}}
              <span>{{dFormatDate this.post.created_at leaveAgo="true"}}</span>
            </div>
          </div>
          {{#if this.available}}<ExpandPost @item={{this.post}} />{{/if}}
        </div>
        {{#if this.available}}
          {{#if this.post.expandedExcerpt}}
            <div
              class="excerpt isbf-activity-preview__body"
              data-post-id={{this.post.post_id}}
              data-topic-id={{this.post.topic_id}}
              data-user-id={{this.post.user_id}}
            >
              <DDecoratedHtml
                @className="cooked"
                @html={{trustHTML this.post.expandedExcerpt}}
              />
            </div>
          {{else}}
            <ISBFPostPreview
              @excerpt={{this.post.excerpt}}
              @href={{this.post.postUrl}}
              @postId={{this.post.post_id}}
              @postNumber={{this.post.post_number}}
              @topicId={{this.post.topic_id}}
              @variant="activity"
            />
          {{/if}}
        {{else}}
          <ISBFPostPreview
            @disabled={{true}}
            @href={{this.post.postUrl}}
            @variant="activity"
          />
        {{/if}}
      </article>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,\"article\"],[14,0,\"isbf-activity-preview\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-activity-preview__header\"],[12],[1,\"\\n      \"],[8,[32,0],null,[[\"@user\"],[[30,0,[\"user\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[1,[28,[32,1],[[30,0,[\"user\"]]],[[\"imageSize\",\"ignoreTitle\"],[\"large\",\"true\"]]]],[1,\"\\n      \"]],[]]]]],[1,\"\\n      \"],[10,0],[14,0,\"isbf-activity-preview__details\"],[12],[1,\"\\n\"],[41,[30,0,[\"title\"]],[[[1,\"          \"],[10,3],[14,0,\"isbf-activity-preview__title\"],[15,6,[30,0,[\"post\",\"postUrl\"]]],[12],[1,[28,[32,2],[[30,0,[\"title\"]]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,0],[14,0,\"isbf-activity-preview__metadata\"],[12],[1,\"\\n\"],[41,[30,0,[\"post\",\"category\"]],[[[1,\"            \"],[10,1],[12],[1,[28,[32,3],[[30,0,[\"post\",\"category\"]]],[[\"styleType\"],[\"square\"]]]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,1],[12],[1,[28,[32,4],[[30,0,[\"post\",\"created_at\"]]],[[\"leaveAgo\"],[\"true\"]]]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"available\"]],[[[8,[32,5],null,[[\"@item\"],[[30,0,[\"post\"]]]],null]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"available\"]],[[[41,[30,0,[\"post\",\"expandedExcerpt\"]],[[[1,\"        \"],[10,0],[14,0,\"excerpt isbf-activity-preview__body\"],[15,\"data-post-id\",[30,0,[\"post\",\"post_id\"]]],[15,\"data-topic-id\",[30,0,[\"post\",\"topic_id\"]]],[15,\"data-user-id\",[30,0,[\"post\",\"user_id\"]]],[12],[1,\"\\n          \"],[8,[32,6],null,[[\"@className\",\"@html\"],[\"cooked\",[28,[32,7],[[30,0,[\"post\",\"expandedExcerpt\"]]],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,8],null,[[\"@excerpt\",\"@href\",\"@postId\",\"@postNumber\",\"@topicId\",\"@variant\"],[[30,0,[\"post\",\"excerpt\"]],[30,0,[\"post\",\"postUrl\"]],[30,0,[\"post\",\"post_id\"]],[30,0,[\"post\",\"post_number\"]],[30,0,[\"post\",\"topic_id\"]],\"activity\"]],null],[1,\"\\n\"]],[]]]],[]],[[[1,\"      \"],[8,[32,8],null,[[\"@disabled\",\"@href\",\"@variant\"],[true,[30,0,[\"post\",\"postUrl\"]],\"activity\"]],null],[1,\"\\n\"]],[]]],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DUserLink,
        dAvatar,
        dReplaceEmoji,
        dCategoryLink,
        dFormatDate,
        ExpandPost,
        DDecoratedHtml,
        trustHTML,
        ISBFPostPreview
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-activity-preview", ISBFActivityPreview);
var Mod89 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFActivityPreview
});
class ISBFSummaryTopicTitle extends Component {
  get disabled() {
    const topic = this.args.outletArgs.topic;
    return topic.hidden || topic.deleted;
  }
  get titled() {
    return Boolean(optionalTopicTitle(this.args.outletArgs.topic.title).trim());
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.titled}}
      <a href={{@outletArgs.url}} ...attributes>{{trustHTML
          @outletArgs.topic.fancyTitle
        }}</a>
    {{else}}
      <ISBFPostPreview
        ...attributes
        @disabled={{this.disabled}}
        @href={{@outletArgs.url}}
        @postNumber={{@outletArgs.postNumber}}
        @title={{@outletArgs.topic.title}}
        @topicId={{@outletArgs.topic.id}}
        @variant="summary"
      />
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"titled\"]],[[[1,\"  \"],[11,3],[16,6,[30,1,[\"url\"]]],[17,2],[12],[1,[28,[32,0],[[30,1,[\"topic\",\"fancyTitle\"]]],null]],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[8,[32,1],[[17,2]],[[\"@disabled\",\"@href\",\"@postNumber\",\"@title\",\"@topicId\",\"@variant\"],[[30,0,[\"disabled\"]],[30,1,[\"url\"]],[30,1,[\"postNumber\"]],[30,1,[\"topic\",\"title\"]],[30,1,[\"topic\",\"id\"]],\"summary\"]],null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        trustHTML,
        ISBFPostPreview
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-summary-topic-title", ISBFSummaryTopicTitle);
var Mod181 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFSummaryTopicTitle
});
const CAREERS_FIELDS = ["isbf_careers_salary", "isbf_careers_home"];
const CAREERS_SALARY_MAX_LENGTH = 120;
function careersConfig(site) {
  const config = site?.isbf_careers;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && config.enabled === true && config.version === 1 ? config : null;
}
function isCareersCategory(model) {
  const config = careersConfig(model?.site);
  const category = model?.action === "reply" ? model.topic?.category_id ?? model.topic?.category?.id : model?.categoryId;
  return Boolean(config && Number(category) === config.category_id);
}
function isCareersComposer(model) {
  return Boolean(isCareersCategory(model) && (model.creatingTopic || model.editingPost && model.post?.post_number === 1));
}
function careersSalary(value) {
  return typeof value === "string" ? value.replace(/^\p{White_Space}+|\p{White_Space}+$/gu, "") : "";
}
function validCareersSalary(value) {
  return (value == null || typeof value === "string" && !/[\p{Cc}\p{Cs}]/u.test(value)) && Array.from(careersSalary(value)).length <= CAREERS_SALARY_MAX_LENGTH;
}
function careersPayload(model, field) {
  if (!isCareersComposer(model)) {
    return;
  }
  if (field === CAREERS_FIELDS[0]) {
    return careersSalary(model[field]);
  }
  if (field === CAREERS_FIELDS[1]) {
    return model[field] === true;
  }
}
function restoreCareers(model, options = {}) {
  if (!isCareersCategory(model)) {
    return;
  }
  model.set("isbf_anonymous", false);
  if (!isCareersComposer(model)) {
    return;
  }
  const metadata = options.post?.isbf_careers ?? model.post?.isbf_careers ?? model.topic?.isbf_careers;
  const values = [metadata?.salary, metadata?.show_on_home];
  CAREERS_FIELDS.forEach((field, index) => {
    const value = options[field] ?? options.post?.[field] ?? model[field] ?? values[index];
    model.set(field, index === 0 ? careersSalary(value) : value === true);
  });
}
function careersQuery() {
  return {
    q: "isbf-careers:all order:created"
  };
}
function careersImageUrl(value) {
  if (typeof value !== "string" || !value.trim()) {
    return null;
  }
  const url = value.trim();
  return /^(?:https?:\/\/|\/(?!\/))/i.test(url) && !/[\\\s]/.test(url) ? url : null;
}
var Mod167 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  CAREERS_FIELDS: CAREERS_FIELDS,
  CAREERS_SALARY_MAX_LENGTH: CAREERS_SALARY_MAX_LENGTH,
  careersConfig: careersConfig,
  careersImageUrl: careersImageUrl,
  careersPayload: careersPayload,
  careersQuery: careersQuery,
  careersSalary: careersSalary,
  isCareersCategory: isCareersCategory,
  isCareersComposer: isCareersComposer,
  restoreCareers: restoreCareers,
  validCareersSalary: validCareersSalary
});
const MARKETPLACE_FIELDS = ["isbf_marketplace_price", "isbf_marketplace_images", "isbf_marketplace_home"];
function marketplaceConfig(site) {
  const config = site?.isbf_marketplace;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && config.private_images === true && config.version === 1 ? config : null;
}
function isMarketplaceComposer(model) {
  const config = marketplaceConfig(model?.site);
  return Boolean(config && Number(model.categoryId) === config.category_id && (model.creatingTopic || model.editingPost && model.post?.post_number === 1));
}
function marketplaceImageIds(value) {
  try {
    const ids = typeof value === "string" ? JSON.parse(value) : value;
    return Array.isArray(ids) ? [...new Set(ids.filter(id => typeof id === "string" && /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(id)))] : [];
  } catch {
    return [];
  }
}
function marketplacePrice(cents) {
  return Number.isSafeInteger(cents) && cents >= 0 ? `¥${(cents / 100).toFixed(2)}` : null;
}
function validMarketplacePrice(value) {
  const text = String(value ?? "").trim();
  if (!/^(0|[1-9]\d*)(\.\d{1,2})?$/.test(text)) {
    return false;
  }
  const [whole, fraction = ""] = text.split(".");
  return Number.isSafeInteger(Number(whole) * 100 + Number(fraction.padEnd(2, "0")));
}
function marketplacePayload(model, field) {
  if (!isMarketplaceComposer(model)) {
    return;
  }
  if (field === MARKETPLACE_FIELDS[0]) {
    return String(model[field] ?? "").trim();
  }
  if (field === MARKETPLACE_FIELDS[1]) {
    return JSON.stringify(marketplaceImageIds(model[field]));
  }
  return model[field] === true;
}
function restoreMarketplace(model, options = {}) {
  if (!isMarketplaceComposer(model)) {
    return;
  }
  const metadata = options.post?.isbf_marketplace ?? model.post?.isbf_marketplace ?? model.topic?.isbf_marketplace;
  const values = [metadata && marketplacePrice(metadata.price_cents)?.slice(1), metadata?.images?.map(image => image.id), metadata?.show_on_home];
  MARKETPLACE_FIELDS.forEach((field, index) => {
    const value = options[field] ?? options.post?.[field] ?? model[field] ?? values[index];
    model.set(field, index === 0 ? String(value ?? "") : index === 1 ? JSON.stringify(marketplaceImageIds(value)) : value === true);
  });
  model.set("isbf_anonymous", false);
}
function marketplaceQuery() {
  return {
    q: "isbf-marketplace:all order:created"
  };
}
function marketplaceUploadMarkdown(upload, model) {
  if (!isMarketplaceComposer(model) || !/^\/isbf\/marketplace\/images\/[a-f0-9-]{36}$/i.test(upload.url || "")) {
    return;
  }
  const ids = marketplaceImageIds([upload.id]);
  if (!ids.length) {
    return;
  }
  model.set("isbf_marketplace_images", JSON.stringify([...new Set([...marketplaceImageIds(model.isbf_marketplace_images), ...ids])]));
  const name = String(upload.original_filename || upload.name || "image").replace(/[\[\]\\|\n\r]/g, "");
  return `![${name}](${upload.url})`;
}
function marketplaceImageUrl(url) {
  return /^\/isbf\/marketplace\/images\/[a-f0-9-]{36}(?:\/thumbnail)?$/i.test(url || "") ? url : null;
}
function marketplaceDetailImages(metadata, renderedSources = []) {
  const shown = new Set(renderedSources.map(source => String(source).match(/\/isbf\/marketplace\/images\/([a-f0-9-]{36})(?:\/thumbnail)?(?:$|[?#])/i)?.[1]?.toLowerCase()));
  return (metadata?.images || []).filter(image => marketplaceImageIds([image.id]).length && marketplaceImageUrl(image.url) && !shown.has(image.id.toLowerCase())).map(image => ({
    ...image,
    thumbnail: marketplaceImageUrl(image.thumbnail_url) || image.url
  }));
}
var Mod98 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  MARKETPLACE_FIELDS: MARKETPLACE_FIELDS,
  isMarketplaceComposer: isMarketplaceComposer,
  marketplaceConfig: marketplaceConfig,
  marketplaceDetailImages: marketplaceDetailImages,
  marketplaceImageIds: marketplaceImageIds,
  marketplaceImageUrl: marketplaceImageUrl,
  marketplacePayload: marketplacePayload,
  marketplacePrice: marketplacePrice,
  marketplaceQuery: marketplaceQuery,
  marketplaceUploadMarkdown: marketplaceUploadMarkdown,
  restoreMarketplace: restoreMarketplace,
  validMarketplacePrice: validMarketplacePrice
});
const TEAMUP_HOME_FIELD = "isbf_teamup_home";
function teamupConfig(site) {
  const config = site?.isbf_teamup;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && config.version === 1 && config.enabled !== false ? config : null;
}
function isTeamupCategory(model) {
  const category = model?.action === "reply" ? model.topic?.category_id ?? model.topic?.category?.id : model?.categoryId;
  const id = teamupConfig(model?.site)?.category_id;
  return Boolean(id && Number(category) === id);
}
function isTeamupComposer(model) {
  return Boolean(isTeamupCategory(model) && (model.creatingTopic || model.editingPost && model.post?.post_number === 1));
}
function teamupPayload(model) {
  return isTeamupComposer(model) ? model[TEAMUP_HOME_FIELD] === true : undefined;
}
function restoreTeamup(model, options = {}) {
  if (!isTeamupCategory(model)) {
    return;
  }
  model.set("isbf_anonymous", false);
  if (!isTeamupComposer(model)) {
    return;
  }
  const metadata = options.post?.isbf_teamup ?? model.post?.isbf_teamup ?? model.topic?.isbf_teamup;
  model.set(TEAMUP_HOME_FIELD, (options[TEAMUP_HOME_FIELD] ?? options.post?.[TEAMUP_HOME_FIELD] ?? model[TEAMUP_HOME_FIELD] ?? metadata?.show_on_home ?? false) === true);
}
function teamupQuery() {
  return {
    q: "isbf-teamup:all order:created"
  };
}
var Mod113 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  TEAMUP_HOME_FIELD: TEAMUP_HOME_FIELD,
  isTeamupCategory: isTeamupCategory,
  isTeamupComposer: isTeamupComposer,
  restoreTeamup: restoreTeamup,
  teamupConfig: teamupConfig,
  teamupPayload: teamupPayload,
  teamupQuery: teamupQuery
});
function isQuickPost(model) {
  const eventCategoryId = Number(settings.calendar_category_id);
  return model?.action === "createTopic" && !model.creatingEvent && !isTeamupCategory(model) && !isCareersCategory(model) && Number(model.categoryId) !== marketplaceConfig(model.site)?.category_id && !(model?.site?.isbf_learning?.category_id > 0 && Number(model.categoryId) === model.site.isbf_learning.category_id) && !(eventCategoryId > 0 && Number(model.categoryId) === eventCategoryId) && Boolean(document.querySelector(".isbf-v2-shell"));
}
var Mod10 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  isQuickPost: isQuickPost
});
class ISBFV2ComposerCancel extends Component {
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  get visible() {
    const model = this.args.outletArgs?.model;
    return isQuickPost(model) || isMarketplaceComposer(model) || isCareersComposer(model) || isTeamupComposer(model);
  }
  close(event) {
    this.composer.saveAndClose(event);
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <button
        class="isbf-v2-composer-cancel"
        type="button"
        {{on "click" this.close}}
      >
        {{i18n (themePrefix "isbf_v2.compose_cancel")}}
      </button>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[11,\"button\"],[24,0,\"isbf-v2-composer-cancel\"],[24,4,\"button\"],[4,[32,0],[\"click\",[30,0,[\"close\"]]],null],[12],[1,\"\\n    \"],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.compose_cancel\"],null]],null]],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        on,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-composer-cancel", ISBFV2ComposerCancel);
var Mod8 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2ComposerCancel
});
function canPublishAnonymously(model, currentUser, siteSettings) {
  if (!model || !currentUser?.can_post_anonymously || currentUser.is_anonymous || isTeamupCategory(model) || isCareersCategory(model) || !["createTopic", "reply"].includes(model.action) || model.archetypeId === "private_message" || [true, "true"].includes(model.academy_official)) {
    return false;
  }
  if (model.action === "reply" && model.topic?.archetype === "private_message") {
    return false;
  }
  const categoryId = model.action === "reply" ? model.topic?.category_id ?? model.topic?.category?.id : model.categoryId;
  const category = categoryId ? Category.findById(categoryId) : null;
  if (marketplaceConfig(model.site)?.category_id === Number(categoryId)) {
    return false;
  }
  const officialCategoryId = Number(siteSettings.academy_official_category);
  return !category?.read_restricted && !(officialCategoryId > 0 && Number(categoryId) === officialCategoryId);
}
var Mod15 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  canPublishAnonymously: canPublishAnonymously
});
const OFFICIAL_FIELDS = ["isbf_official_campuses", "isbf_official_types"];
function officialConfig(site) {
  const config = site?.get ? site.get("isbf_official") : site?.isbf_official;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && Array.isArray(config.campuses) && Array.isArray(config.types) && config.types.length > 0 && (config.revision === undefined || Number.isSafeInteger(config.revision)) && [...config.campuses, ...config.types].every(item => item && typeof item.id === "string" && /^[a-z][a-z0-9-]*$/.test(item.id) && typeof item.label === "string" && (item.enabled === undefined || typeof item.enabled === "boolean")) ? config : null;
}
function officialSelectionIds(values) {
  return Array.isArray(values) ? [...new Set(values.filter(id => typeof id === "string"))] : [];
}
function officialSelectionLimit(values) {
  return Array.isArray(values) && values.length <= 100 && new TextEncoder().encode(JSON.stringify(values)).length <= 4096;
}
function officialComposerItems(items, selectedIds) {
  const selected = new Set(officialSelectionIds(selectedIds));
  const known = new Set(items.map(item => item.id));
  return [...items.filter(item => item.enabled !== false || selected.has(item.id)), ...[...selected].filter(id => !known.has(id)).map(id => ({
    id,
    label: id,
    enabled: false
  }))];
}
function officialSelectionsAvailable(model, config) {
  return OFFICIAL_FIELDS.every((field, index) => {
    const values = model[field] ?? [];
    const items = index === 0 ? config.campuses : config.types;
    const original = model.editingFirstPost ? officialSelectionIds(model.post?.[field] ?? model.topic?.[field]) : [];
    return officialSelectionLimit(values) && values.every(id => items.some(item => item.id === id && (item.enabled !== false || original.includes(id))));
  });
}
function officialSelections(values, items) {
  const allowed = new Set(items.map(item => item.id));
  return Array.isArray(values) ? [...new Set(values.filter(id => allowed.has(id)))] : [];
}
function buildOfficialQuery(config, campus = "", type = "") {
  return [`isbf-official:${config.category_id}`, officialSelections([campus], config.campuses)[0] ? `isbf-campus:${campus}` : null, officialSelections([type], config.types)[0] ? `isbf-official-type:${type}` : null, "order:activity"].filter(Boolean).join(" ");
}
function isOfficialComposer(model, config) {
  return Boolean(config && model && !model.privateMessage && !model.creatingPrivateMessage && model.archetypeId !== "private_message" && model.topic?.archetype !== "private_message" && Number(model.categoryId ?? model.topic?.category_id) === config.category_id && (model.creatingTopic || model.editingFirstPost));
}
function restoreOfficialSelections(model, config) {
  if (!isOfficialComposer(model, config)) {
    return;
  }
  OFFICIAL_FIELDS.forEach(field => {
    if (model[field] === undefined || model[field] === null) {
      model.set(field, officialSelectionIds(model.editingFirstPost ? model.post?.[field] ?? model.topic?.[field] : []));
    }
  });
}
function officialPayload(model, config, field) {
  if (!isOfficialComposer(model, config)) {
    return undefined;
  }
  return JSON.stringify(model[field] ?? []);
}
function officialSelectionsComplete(model, config) {
  return isOfficialComposer(model, config) && officialSelections(model.isbf_official_types, config.types).length > 0;
}
function officialLocationLabel(location, campusIds, config, separator = "、") {
  const campuses = config?.campuses ?? [];
  const selected = new Set(officialSelections(campusIds, campuses));
  const labels = campuses.filter(campus => selected.has(campus.id)).map(campus => campus.label).join(separator);
  const address = typeof location === "string" ? location.trim() : "";
  return [labels, address].filter(Boolean).join(" · ");
}
class OfficialRequestGuard {
  #generation = 0;
  next() {
    return ++this.#generation;
  }
  isCurrent(generation) {
    return this.#generation === generation;
  }
}
var Mod54 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  OFFICIAL_FIELDS: OFFICIAL_FIELDS,
  OfficialRequestGuard: OfficialRequestGuard,
  buildOfficialQuery: buildOfficialQuery,
  isOfficialComposer: isOfficialComposer,
  officialComposerItems: officialComposerItems,
  officialConfig: officialConfig,
  officialLocationLabel: officialLocationLabel,
  officialPayload: officialPayload,
  officialSelectionIds: officialSelectionIds,
  officialSelectionLimit: officialSelectionLimit,
  officialSelections: officialSelections,
  officialSelectionsAvailable: officialSelectionsAvailable,
  officialSelectionsComplete: officialSelectionsComplete,
  restoreOfficialSelections: restoreOfficialSelections
});
const OFFICIAL_CALENDAR_FIELD = "isbf_official_calendar_items";
const OFFICIAL_TIMEZONE = "Asia/Shanghai";
function isOfficialCalendarPath(path, officialPath) {
  if (!path || !officialPath) {
    return false;
  }
  const currentPath = path.split(/[?#]/)[0];
  const categoryPath = officialPath.split("/l/")[0].replace(/\/$/, "");
  return currentPath === categoryPath || currentPath.startsWith(`${categoryPath}/`);
}
function parts(value, withTime = false) {
  return Object.fromEntries(new Intl.DateTimeFormat("en-CA", {
    timeZone: OFFICIAL_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    ...(withTime ? {
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23"
    } : {})
  }).formatToParts(new Date(value)).map(part => [part.type, part.value]));
}
function officialDateKey(value) {
  const date = parts(value);
  return `${date.year}-${date.month}-${date.day}`;
}
function officialOccursOn(item, key) {
  const dayStart = new Date(`${key}T00:00:00+08:00`).getTime();
  const nextDay = dayStart + 86400000;
  const start = new Date(item.starts_at).getTime();
  const end = new Date(item.ends_at).getTime();
  return start === end ? start >= dayStart && start < nextDay : start < nextDay && end > dayStart;
}
function officialInput(value, allDay) {
  const date = parts(value, !allDay);
  const day = `${date.year}-${date.month}-${date.day}`;
  return allDay ? day : `${day}T${date.hour}:${date.minute}`;
}
function officialTimeFormatter(item) {
  return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
    timeZone: OFFICIAL_TIMEZONE,
    year: "numeric",
    month: "short",
    day: "numeric",
    ...(!item.all_day ? {
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23"
    } : {})
  });
}
function officialTimeLabel(item) {
  if (!item?.starts_at || !item?.ends_at) {
    return "";
  }
  const format = officialTimeFormatter(item);
  const start = format.format(new Date(item.starts_at));
  if (item.schedule_kind === "deadline") {
    return i18n(themePrefix(item.all_day ? "isbf_v2.schedule_deadline_day" : "isbf_v2.schedule_deadline_time"), {
      date: start
    });
  }
  const endTime = new Date(item.ends_at).getTime() - (item.all_day ? 1 : 0);
  if (item.ends_at === item.starts_at || item.all_day && officialDateKey(item.starts_at) === officialDateKey(endTime)) {
    return i18n(themePrefix(item.all_day ? "isbf_v2.schedule_event_day" : "isbf_v2.schedule_event_time"), {
      date: start
    });
  }
  return i18n(themePrefix("isbf_v2.schedule_event_range"), {
    start,
    end: format.format(new Date(endTime))
  });
}
function officialActivityTimeLines(item) {
  const start = new Date(item?.starts_at).getTime();
  const end = new Date(item?.ends_at).getTime();
  if (item?.schedule_kind !== "event" || !item.starts_at || !item.ends_at || !Number.isFinite(start) || !Number.isFinite(end) || end < start) {
    return [];
  }
  const format = officialTimeFormatter(item);
  const date = format.format(new Date(start));
  const lines = [i18n(themePrefix("isbf_v2.schedule_activity_start_line"), {
    date: item.all_day ? i18n(themePrefix("isbf_v2.schedule_activity_day_value"), {
      date
    }) : date
  })];
  const displayedEnd = end - (item.all_day && end > start ? 1 : 0);
  if (item.all_day ? officialDateKey(start) !== officialDateKey(displayedEnd) : start !== end) {
    lines.push(i18n(themePrefix("isbf_v2.schedule_activity_end_line"), {
      date: format.format(new Date(displayedEnd))
    }));
  }
  return lines;
}
function isOfficialCalendarComposer(model, site) {
  const categoryId = site?.isbf_calendar?.official_category_id;
  return Boolean(Number(categoryId) > 0 && model && !model.privateMessage && !model.creatingPrivateMessage && model.archetypeId !== "private_message" && model.topic?.archetype !== "private_message" && Number(model.categoryId ?? model.topic?.category_id) === Number(categoryId) && (model.creatingTopic || model.editingFirstPost));
}
function officialCalendarTopicTitle(model) {
  const value = model?.creatingTopic && typeof model.isbf_optional_title === "string" ? model.isbf_optional_title : model?.title ?? model?.topic?.title;
  return optionalTopicTitle(typeof value === "string" ? value : "").trim();
}
function officialCalendarNeedsTitle(model, site = model?.site) {
  return Boolean(isOfficialCalendarComposer(model, site) && (model[OFFICIAL_CALENDAR_FIELD] ?? []).some(item => item && !item.cancelled));
}
function officialCalendarItemTitle(topicTitle, kind, {
  draft = false
} = {}) {
  const title = optionalTopicTitle(typeof topicTitle === "string" ? topicTitle : "").trim();
  if (!title) {
    if (!draft) {
      throw new RangeError("Official time items require a topic title");
    }
    return i18n(themePrefix(kind === "deadline" ? "isbf_v2.schedule_registration_deadline" : "isbf_v2.schedule_activity_time"));
  }
  if (Array.from(title).length <= 120) {
    return title;
  }
  let result = "";
  let count = 0;
  for (const {
    segment
  } of new Intl.Segmenter(undefined, {
    granularity: "grapheme"
  }).segment(title)) {
    const length = Array.from(segment).length;
    if (count + length > 120) {
      break;
    }
    result += segment;
    count += length;
  }
  return result;
}
function officialCalendarTitleDuplicatesTopic(item, topicTitle) {
  const title = optionalTopicTitle(typeof topicTitle === "string" ? topicTitle : "").trim();
  const itemTitle = typeof item?.title === "string" ? item.title.trim() : "";
  return Boolean(title && itemTitle && (itemTitle === title || itemTitle === officialCalendarItemTitle(title, item.schedule_kind)));
}
function calendarItemsWithTopicTitle(items, topicTitle, options = {}) {
  return canonicalCalendarItems(items ?? []).map(item => ({
    ...item,
    title: officialCalendarItemTitle(topicTitle, item.schedule_kind, options)
  }));
}
function officialCalendarEventOptionLabel(event, index) {
  const label = i18n(themePrefix("isbf_v2.schedule_unnamed_event"), {
    number: index + 1
  });
  const start = typeof event?.start === "string" ? event.start.slice(0, 16).replaceAll("-", "/").replace("T", " ") : "";
  return start ? label + " · " + start : label;
}
function canonicalCalendarItems(items = []) {
  const active = items.filter(item => !item.cancelled);
  return active.map(item => {
    const result = {
      ...(item.id ? {
        id: item.id,
        revision: item.revision
      } : {}),
      title: item.title,
      schedule_kind: item.schedule_kind,
      starts_at: item.starts_at,
      ends_at: item.ends_at,
      all_day: Boolean(item.all_day)
    };
    if (item.schedule_kind === "event") {
      for (const field of ["location", "organizer"]) {
        if (Object.hasOwn(item, field)) {
          result[field] = item[field]?.trim() || "";
        }
      }
      if (Object.hasOwn(item, "registration_deadline_index") || Object.hasOwn(item, "registration_deadline_id")) {
        const deadline = registrationDeadline(item, items);
        result.registration_deadline_index = deadline ? active.indexOf(deadline) : null;
      }
    }
    return result;
  });
}
function registrationDeadline(item, items) {
  const deadline = Object.hasOwn(item, "registration_deadline_index") ? items[item.registration_deadline_index] : items.find(candidate => candidate.id && candidate.id === item.registration_deadline_id);
  return deadline && !deadline.cancelled && deadline.schedule_kind === "deadline" ? deadline : null;
}
function officialCalendarGroups(items = []) {
  const active = items.filter(item => !item.cancelled);
  const linked = new Set();
  const groups = active.map(item => {
    const deadline = item.schedule_kind === "event" ? registrationDeadline(item, items) : null;
    if (deadline) {
      linked.add(deadline);
    }
    return {
      item,
      deadline,
      isEvent: item.schedule_kind === "event"
    };
  });
  return groups.filter(group => !linked.has(group.item));
}
function calendarEditorItem(item) {
  return {
    ...item,
    start: officialInput(item.starts_at, item.all_day),
    end: item.ends_at === item.starts_at ? "" : officialInput(new Date(item.ends_at).getTime() - (item.all_day ? 86400000 : 0), item.all_day)
  };
}
function calendarEditorItems(items) {
  return officialCalendarGroups(canonicalCalendarItems(items)).map(({
    item,
    deadline
  }) => ({
    ...calendarEditorItem(item),
    has_registration_deadline: Boolean(deadline),
    registration_deadline: deadline ? calendarEditorItem(deadline) : {
      title: "",
      schedule_kind: "deadline",
      all_day: false,
      start: "",
      end: ""
    }
  }));
}
function calendarItemsFromEditor(items) {
  const result = [];
  for (const item of items) {
    const source = calendarItemFromEditor(item);
    result.push(source);
    if (item.schedule_kind !== "event") {
      continue;
    }
    source.registration_deadline_index = null;
    if (item.has_registration_deadline) {
      const deadline = item.registration_deadline;
      source.registration_deadline_index = result.length;
      result.push(calendarItemFromEditor({
        ...deadline,
        title: deadline.id ? deadline.title : i18n(themePrefix("isbf_v2.schedule_registration_name"), {
          name: item.title
        }).slice(0, 120),
        schedule_kind: "deadline"
      }));
    }
  }
  return result;
}
function calendarItemFromEditor(item) {
  const starts = new Date(`${item.start}${item.all_day ? "T00:00:00" : ""}+08:00`);
  if (!Number.isFinite(starts.getTime()) || officialDateKey(starts) !== item.start.slice(0, 10)) {
    throw new RangeError("Invalid official calendar date");
  }
  let ends = starts;
  if (item.all_day) {
    const endDate = item.schedule_kind === "deadline" ? item.start : item.end || item.start;
    const end = new Date(`${endDate}T00:00:00+08:00`);
    if (!Number.isFinite(end.getTime()) || officialDateKey(end) !== endDate) {
      throw new RangeError("Invalid official calendar end date");
    }
    ends = new Date(end.getTime() + 86400000);
  } else if (item.schedule_kind === "event" && item.end) {
    ends = new Date(`${item.end}+08:00`);
    if (!Number.isFinite(ends.getTime()) || officialDateKey(ends) !== item.end.slice(0, 10)) {
      throw new RangeError("Invalid official calendar end date");
    }
  }
  if (ends < starts) {
    throw new RangeError("Invalid official calendar time range");
  }
  return canonicalCalendarItems([{
    ...item,
    starts_at: starts.toISOString(),
    ends_at: ends.toISOString()
  }])[0];
}
function calendarEditorSections(items = []) {
  const active = canonicalCalendarItems(items);
  const events = [];
  const deadlines = [];
  active.forEach((item, position) => {
    const draft = {
      ...calendarEditorItem(item),
      editor_position: position,
      editor_original: {
        ...item
      }
    };
    if (item.schedule_kind === "event") {
      draft.editor_key = `event-${position}`;
      events.push(draft);
    } else {
      draft.related_event = "";
      deadlines.push(draft);
    }
  });
  for (const event of events) {
    const deadline = deadlines.find(item => item.editor_position === event.registration_deadline_index);
    if (deadline) {
      if (deadline.related_event) {
        throw new RangeError("Duplicate official calendar relationship");
      }
      deadline.related_event = event.editor_key;
    }
  }
  return {
    events,
    deadlines
  };
}
function calendarItemsFromSections({
  events = [],
  deadlines = []
}, topicTitle) {
  const invalid = (section, message) => {
    const error = new RangeError(message);
    error.section = section;
    return error;
  };
  const keys = new Set();
  for (const event of events) {
    if (!event.editor_key || keys.has(event.editor_key)) {
      throw invalid("event", "Invalid official calendar event key");
    }
    keys.add(event.editor_key);
  }
  const linked = new Map();
  for (const deadline of deadlines) {
    if (deadline.related_event) {
      if (!keys.has(deadline.related_event) || linked.has(deadline.related_event)) {
        throw invalid("deadline", "Invalid official calendar relationship");
      }
      linked.set(deadline.related_event, deadline);
    }
  }
  const rows = [...events, ...deadlines].sort((a, b) => a.editor_position - b.editor_position);
  const result = rows.map(source => {
    const row = topicTitle === undefined ? source : {
      ...source,
      title: officialCalendarItemTitle(topicTitle, source.schedule_kind, {
        draft: true
      })
    };
    if (typeof row.title !== "string" || !row.title.trim() || Array.from(row.title).length > 120) {
      throw invalid(row.schedule_kind, "Invalid official calendar title");
    }
    let item;
    try {
      item = calendarItemFromEditor(row);
    } catch (error) {
      throw invalid(row.schedule_kind, error.message);
    }
    const original = row.editor_original;
    if (original) {
      const previous = calendarEditorItem(original);
      if (row.start === previous.start && row.end === previous.end && row.all_day === previous.all_day) {
        item.starts_at = original.starts_at;
        item.ends_at = original.ends_at;
      }
    }
    if (row.schedule_kind === "event") {
      const deadline = linked.get(row.editor_key);
      if (deadline || Object.hasOwn(row, "registration_deadline_index")) {
        item.registration_deadline_index = deadline ? rows.indexOf(deadline) : null;
      }
    }
    return item;
  });
  return canonicalCalendarItems(result);
}
var Mod56 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  OFFICIAL_CALENDAR_FIELD: OFFICIAL_CALENDAR_FIELD,
  OFFICIAL_TIMEZONE: OFFICIAL_TIMEZONE,
  calendarEditorItems: calendarEditorItems,
  calendarEditorSections: calendarEditorSections,
  calendarItemFromEditor: calendarItemFromEditor,
  calendarItemsFromEditor: calendarItemsFromEditor,
  calendarItemsFromSections: calendarItemsFromSections,
  calendarItemsWithTopicTitle: calendarItemsWithTopicTitle,
  canonicalCalendarItems: canonicalCalendarItems,
  isOfficialCalendarComposer: isOfficialCalendarComposer,
  isOfficialCalendarPath: isOfficialCalendarPath,
  officialActivityTimeLines: officialActivityTimeLines,
  officialCalendarEventOptionLabel: officialCalendarEventOptionLabel,
  officialCalendarGroups: officialCalendarGroups,
  officialCalendarItemTitle: officialCalendarItemTitle,
  officialCalendarNeedsTitle: officialCalendarNeedsTitle,
  officialCalendarTitleDuplicatesTopic: officialCalendarTitleDuplicatesTopic,
  officialCalendarTopicTitle: officialCalendarTopicTitle,
  officialDateKey: officialDateKey,
  officialOccursOn: officialOccursOn,
  officialTimeLabel: officialTimeLabel
});
class ISBFOfficialCalendarEditor extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return null;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  static {
    dt7948.g(this.prototype, "section", [tracked], function () {
      return this.args.model.section === "deadline" ? "deadline" : "event";
    });
  }
  #section = (dt7948.i(this, "section"), void 0);
  #formApi;
  #nextPosition = 0;
  static {
    dt7948.g(this.prototype, "_itemCount", [tracked], function () {
      return null;
    });
  }
  #_itemCount = (dt7948.i(this, "_itemCount"), void 0);
  static {
    dt7948.g(this.prototype, "_events", [tracked], function () {
      return null;
    });
  }
  #_events = (dt7948.i(this, "_events"), void 0);
  get formData() {
    return calendarEditorSections(calendarItemsWithTopicTitle(this.args.model.items, this.args.model.getTopicTitle?.() ?? "", {
      draft: true
    }));
  }
  static {
    dt7948.n(this.prototype, "formData", [cached]);
  }
  get isEventSection() {
    return this.section === "event";
  }
  get canAdd() {
    const count = this._itemCount ?? this.formData.events.length + this.formData.deadlines.length;
    return !this.saving && count < (this.site.isbf_calendar?.max_items ?? 20);
  }
  get eventOptions() {
    return (this._events ?? this.formData.events).map((event, index) => ({
      value: event.editor_key,
      label: officialCalendarEventOptionLabel(event, index)
    }));
  }
  registerApi(api) {
    this.#formApi = api;
    this.#nextPosition = this.formData.events.length + this.formData.deadlines.length;
  }
  static {
    dt7948.n(this.prototype, "registerApi", [action]);
  }
  selectSection(section) {
    this.section = section;
  }
  static {
    dt7948.n(this.prototype, "selectSection", [action]);
  }
  navigateTabs(event) {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      return;
    }
    event.preventDefault();
    this.section = event.key === "Home" ? "event" : event.key === "End" ? "deadline" : this.isEventSection ? "deadline" : "event";
    event.currentTarget.querySelector('[data-section="' + this.section + '"]').focus();
  }
  static {
    dt7948.n(this.prototype, "navigateTabs", [action]);
  }
  updateCount(name, value, data) {
    this._itemCount = data.events.length + data.deadlines.length;
    this._events = data.events.map(item => ({
      ...item
    }));
    this.error = null;
    const match = name.match(/^((?:events|deadlines)\.\d+)\.all_day$/);
    if (match) {
      const item = this.#formApi.get(match[1]);
      for (const field of ["start", "end"]) {
        if (item[field]) {
          this.#formApi.set(match[1] + "." + field, value ? item[field].slice(0, 10) : item[field].slice(0, 10) + "T09:00");
        }
      }
    }
  }
  static {
    dt7948.n(this.prototype, "updateCount", [action]);
  }
  addItem() {
    if (!this.canAdd) {
      return;
    }
    const position = this.#nextPosition++;
    const event = this.isEventSection;
    const collection = event ? "events" : "deadlines";
    this.#formApi.set(collection, this.#formApi.get(collection).concat({
      title: officialCalendarItemTitle(this.args.model.getTopicTitle?.() ?? "", event ? "event" : "deadline", {
        draft: true
      }),
      schedule_kind: event ? "event" : "deadline",
      all_day: false,
      start: "",
      end: "",
      editor_position: position,
      ...(event ? {
        editor_key: "event-" + position,
        location: "",
        organizer: ""
      } : {
        related_event: ""
      })
    }));
  }
  static {
    dt7948.n(this.prototype, "addItem", [action]);
  }
  removeItem(collection, index) {
    if (this.saving) {
      return;
    }
    const rows = this.#formApi.get(collection);
    if (collection === "events") {
      const key = rows[index].editor_key;
      this.#formApi.set("deadlines", this.#formApi.get("deadlines").filter(item => item.related_event !== key));
    }
    this.#formApi.set(collection, rows.filter((_, i) => i !== index));
  }
  static {
    dt7948.n(this.prototype, "removeItem", [action]);
  }
  async save(data) {
    if (this.saving) {
      return;
    }
    let items;
    try {
      items = calendarItemsFromSections(data, this.args.model.getTopicTitle?.() ?? "");
    } catch (error) {
      if (error.section) {
        this.section = error.section;
      }
      this.error = i18n(themePrefix("isbf_v2.schedule_invalid_item"));
      return;
    }
    const max = this.site.isbf_calendar?.max_items ?? 20;
    if (items.length > max) {
      this.error = i18n(themePrefix("isbf_v2.schedule_too_many_items"), {
        max
      });
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      await this.args.model.onSave(items);
      if (!this.isDestroying) {
        this.args.closeModal();
      }
    } catch {
      if (!this.isDestroying) {
        this.error = i18n(themePrefix("isbf_v2.schedule_save_error"));
      }
    } finally {
      this.saving = false;
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-official-calendar-editor"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
    >
      <:body>
        <p>{{i18n (themePrefix "isbf_v2.schedule_timezone_hint")}}</p>
        <div
          aria-label={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
          class="isbf-official-calendar-editor__tabs"
          role="tablist"
          {{on "keydown" this.navigateTabs}}
        >
          <DButton
            aria-controls="isbf-calendar-event-panel"
            aria-selected={{if this.isEventSection "true" "false"}}
            data-section="event"
            id="isbf-calendar-event-tab"
            role="tab"
            tabindex={{if this.isEventSection "0" "-1"}}
            @action={{fn this.selectSection "event"}}
            @label={{themePrefix "isbf_v2.schedule_activity_time"}}
          />
          <DButton
            aria-controls="isbf-calendar-deadline-panel"
            aria-selected={{if this.isEventSection "false" "true"}}
            data-section="deadline"
            id="isbf-calendar-deadline-tab"
            role="tab"
            tabindex={{if this.isEventSection "-1" "0"}}
            @action={{fn this.selectSection "deadline"}}
            @label={{themePrefix "isbf_v2.schedule_registration_deadline"}}
          />
        </div>
        <Form
          @data={{this.formData}}
          @onRegisterApi={{this.registerApi}}
          @onSet={{this.updateCount}}
          @onSubmit={{this.save}}
          as |form|
        >
          <div
            aria-labelledby="isbf-calendar-event-tab"
            hidden={{not this.isEventSection}}
            id="isbf-calendar-event-panel"
            role="tabpanel"
            tabindex="0"
          ><form.Collection @name="events" as |collection index item|><div
                class="isbf-official-calendar-editor__item"
              >
                <collection.Field
                  @name="all_day"
                  @title={{i18n (themePrefix "isbf_v2.schedule_date_only")}}
                  @type="checkbox"
                  as |field|
                ><field.Control /></collection.Field>
                <collection.Field
                  @name="start"
                  @title={{i18n (themePrefix "isbf_v2.schedule_start")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  @validation={{if this.isEventSection "required"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.start}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="end"
                  @title={{i18n (themePrefix "isbf_v2.schedule_end_optional")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.end}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="location"
                  @title={{i18n (themePrefix "isbf_v2.schedule_location")}}
                  @type="input"
                  as |field|
                ><field.Control maxlength="255" /></collection.Field>
                <collection.Field
                  @name="organizer"
                  @title={{i18n (themePrefix "isbf_v2.schedule_organizer")}}
                  @type="input"
                  as |field|
                ><field.Control maxlength="120" /></collection.Field>
                <DButton
                  class="isbf-official-calendar-editor__remove"
                  @action={{fn this.removeItem "events" index}}
                  @disabled={{this.saving}}
                  @icon="trash-can"
                  @label={{themePrefix "isbf_v2.schedule_remove_item"}}
                />
              </div></form.Collection></div>
          <div
            aria-labelledby="isbf-calendar-deadline-tab"
            hidden={{this.isEventSection}}
            id="isbf-calendar-deadline-panel"
            role="tabpanel"
            tabindex="0"
          ><form.Collection @name="deadlines" as |collection index item|><div
                class="isbf-official-calendar-editor__item"
              >
                <collection.Field
                  @name="all_day"
                  @title={{i18n (themePrefix "isbf_v2.schedule_date_only")}}
                  @type="checkbox"
                  as |field|
                ><field.Control /></collection.Field>
                <collection.Field
                  @name="start"
                  @title={{i18n (themePrefix "isbf_v2.schedule_due")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  @validation={{if this.isEventSection null "required"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.start}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="related_event"
                  @title={{i18n (themePrefix "isbf_v2.schedule_related_event")}}
                  @type="select"
                  as |field|
                ><field.Control as |select|><select.Option @value="">{{i18n
                        (themePrefix "isbf_v2.schedule_independent_deadline")
                      }}</select.Option>{{#each
                      this.eventOptions
                      as |option|
                    }}<select.Option
                        @value={{option.value}}
                      >{{option.label}}</select.Option>{{/each}}</field.Control></collection.Field>
                <DButton
                  class="isbf-official-calendar-editor__remove"
                  @action={{fn this.removeItem "deadlines" index}}
                  @disabled={{this.saving}}
                  @icon="trash-can"
                  @label={{themePrefix "isbf_v2.schedule_remove_item"}}
                />
              </div></form.Collection></div>
          <DButton
            class="isbf-official-calendar-editor__add"
            @action={{this.addItem}}
            @disabled={{not this.canAdd}}
            @icon="plus"
            @label={{themePrefix "isbf_v2.schedule_add_item"}}
          />
          {{#if this.error}}<p
              class="isbf-official-calendar-editor__error"
              role="alert"
            >{{this.error}}</p>{{/if}}
          <form.Submit
            @disabled={{this.saving}}
            @label={{themePrefix "isbf_v2.schedule_save_items"}}
          />
        </Form>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-official-calendar-editor\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_editor_title\"],null]],null]]],[[\"body\"],[[[[1,\"\\n    \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_timezone_hint\"],null]],null]],[13],[1,\"\\n    \"],[11,0],[16,\"aria-label\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_editor_title\"],null]],null]],[24,0,\"isbf-official-calendar-editor__tabs\"],[24,\"role\",\"tablist\"],[4,[32,3],[\"keydown\",[30,0,[\"navigateTabs\"]]],null],[12],[1,\"\\n      \"],[8,[32,4],[[24,\"aria-controls\",\"isbf-calendar-event-panel\"],[16,\"aria-selected\",[52,[30,0,[\"isEventSection\"]],\"true\",\"false\"]],[24,\"data-section\",\"event\"],[24,1,\"isbf-calendar-event-tab\"],[24,\"role\",\"tab\"],[16,\"tabindex\",[52,[30,0,[\"isEventSection\"]],\"0\",\"-1\"]]],[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"selectSection\"]],\"event\"],null],[28,[32,2],[\"isbf_v2.schedule_activity_time\"],null]]],null],[1,\"\\n      \"],[8,[32,4],[[24,\"aria-controls\",\"isbf-calendar-deadline-panel\"],[16,\"aria-selected\",[52,[30,0,[\"isEventSection\"]],\"false\",\"true\"]],[24,\"data-section\",\"deadline\"],[24,1,\"isbf-calendar-deadline-tab\"],[24,\"role\",\"tab\"],[16,\"tabindex\",[52,[30,0,[\"isEventSection\"]],\"-1\",\"0\"]]],[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"selectSection\"]],\"deadline\"],null],[28,[32,2],[\"isbf_v2.schedule_registration_deadline\"],null]]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[8,[32,6],null,[[\"@data\",\"@onRegisterApi\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"registerApi\"]],[30,0,[\"updateCount\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[10,0],[14,\"aria-labelledby\",\"isbf-calendar-event-tab\"],[15,\"hidden\",[28,[32,7],[[30,0,[\"isEventSection\"]]],null]],[14,1,\"isbf-calendar-event-panel\"],[14,\"role\",\"tabpanel\"],[14,\"tabindex\",\"0\"],[12],[8,[30,2,[\"Collection\"]],null,[[\"@name\"],[\"events\"]],[[\"default\"],[[[[10,0],[14,0,\"isbf-official-calendar-editor__item\"],[12],[1,\"\\n            \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"all_day\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_date_only\"],null]],null],\"checkbox\"]],[[\"default\"],[[[[8,[30,6,[\"Control\"]],null,null,null]],[6]]]]],[1,\"\\n            \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\",\"@validation\"],[\"start\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_start\"],null]],null],[52,[30,5,[\"all_day\"]],\"input-date\",\"input-datetime-local\"],[52,[30,0,[\"isEventSection\"]],\"required\"]]],[[\"default\"],[[[[10,0],[14,0,\"isbf-official-calendar-editor__datetime\"],[15,\"data-empty\",[28,[32,7],[[30,5,[\"start\"]]],null]],[12],[1,\"\\n                \"],[8,[30,7,[\"Control\"]],null,null,null],[1,\"\\n                \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-official-calendar-editor__date-placeholder\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_date_placeholder\"],null]],null]],[41,[51,[30,5,[\"all_day\"]]],[[[1,\" --:--\"]],[]],null],[13],[1,\"\\n              \"],[13]],[7]]]]],[1,\"\\n            \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"end\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_end_optional\"],null]],null],[52,[30,5,[\"all_day\"]],\"input-date\",\"input-datetime-local\"]]],[[\"default\"],[[[[10,0],[14,0,\"isbf-official-calendar-editor__datetime\"],[15,\"data-empty\",[28,[32,7],[[30,5,[\"end\"]]],null]],[12],[1,\"\\n                \"],[8,[30,8,[\"Control\"]],null,null,null],[1,\"\\n                \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-official-calendar-editor__date-placeholder\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_date_placeholder\"],null]],null]],[41,[51,[30,5,[\"all_day\"]]],[[[1,\" --:--\"]],[]],null],[13],[1,\"\\n              \"],[13]],[8]]]]],[1,\"\\n            \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"location\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_location\"],null]],null],\"input\"]],[[\"default\"],[[[[8,[30,9,[\"Control\"]],[[24,\"maxlength\",\"255\"]],null,null]],[9]]]]],[1,\"\\n            \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"organizer\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_organizer\"],null]],null],\"input\"]],[[\"default\"],[[[[8,[30,10,[\"Control\"]],[[24,\"maxlength\",\"120\"]],null,null]],[10]]]]],[1,\"\\n            \"],[8,[32,4],[[24,0,\"isbf-official-calendar-editor__remove\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[28,[32,5],[[30,0,[\"removeItem\"]],\"events\",[30,4]],null],[30,0,[\"saving\"]],\"trash-can\",[28,[32,2],[\"isbf_v2.schedule_remove_item\"],null]]],null],[1,\"\\n          \"],[13]],[3,4,5]]]]],[13],[1,\"\\n      \"],[10,0],[14,\"aria-labelledby\",\"isbf-calendar-deadline-tab\"],[15,\"hidden\",[30,0,[\"isEventSection\"]]],[14,1,\"isbf-calendar-deadline-panel\"],[14,\"role\",\"tabpanel\"],[14,\"tabindex\",\"0\"],[12],[8,[30,2,[\"Collection\"]],null,[[\"@name\"],[\"deadlines\"]],[[\"default\"],[[[[10,0],[14,0,\"isbf-official-calendar-editor__item\"],[12],[1,\"\\n            \"],[8,[30,11,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"all_day\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_date_only\"],null]],null],\"checkbox\"]],[[\"default\"],[[[[8,[30,14,[\"Control\"]],null,null,null]],[14]]]]],[1,\"\\n            \"],[8,[30,11,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\",\"@validation\"],[\"start\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_due\"],null]],null],[52,[30,13,[\"all_day\"]],\"input-date\",\"input-datetime-local\"],[52,[30,0,[\"isEventSection\"]],null,\"required\"]]],[[\"default\"],[[[[10,0],[14,0,\"isbf-official-calendar-editor__datetime\"],[15,\"data-empty\",[28,[32,7],[[30,13,[\"start\"]]],null]],[12],[1,\"\\n                \"],[8,[30,15,[\"Control\"]],null,null,null],[1,\"\\n                \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-official-calendar-editor__date-placeholder\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_date_placeholder\"],null]],null]],[41,[51,[30,13,[\"all_day\"]]],[[[1,\" --:--\"]],[]],null],[13],[1,\"\\n              \"],[13]],[15]]]]],[1,\"\\n            \"],[8,[30,11,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"related_event\",[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_related_event\"],null]],null],\"select\"]],[[\"default\"],[[[[8,[30,16,[\"Control\"]],null,null,[[\"default\"],[[[[8,[30,17,[\"Option\"]],null,[[\"@value\"],[\"\"]],[[\"default\"],[[[[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_independent_deadline\"],null]],null]]],[]]]]],[42,[28,[31,3],[[28,[31,3],[[30,0,[\"eventOptions\"]]],null]],null],null,[[[8,[30,17,[\"Option\"]],null,[[\"@value\"],[[30,18,[\"value\"]]]],[[\"default\"],[[[[1,[30,18,[\"label\"]]]],[]]]]]],[18]],null]],[17]]]]]],[16]]]]],[1,\"\\n            \"],[8,[32,4],[[24,0,\"isbf-official-calendar-editor__remove\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[28,[32,5],[[30,0,[\"removeItem\"]],\"deadlines\",[30,12]],null],[30,0,[\"saving\"]],\"trash-can\",[28,[32,2],[\"isbf_v2.schedule_remove_item\"],null]]],null],[1,\"\\n          \"],[13]],[11,12,13]]]]],[13],[1,\"\\n      \"],[8,[32,4],[[24,0,\"isbf-official-calendar-editor__add\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"addItem\"]],[28,[32,7],[[30,0,[\"canAdd\"]]],null],\"plus\",[28,[32,2],[\"isbf_v2.schedule_add_item\"],null]]],null],[1,\"\\n      \"],[41,[30,0,[\"error\"]],[[[10,2],[14,0,\"isbf-official-calendar-editor__error\"],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n      \"],[8,[30,2,[\"Submit\"]],null,[[\"@disabled\",\"@label\"],[[30,0,[\"saving\"]],[28,[32,2],[\"isbf_v2.schedule_save_items\"],null]]],null],[1,\"\\n    \"]],[2]]]]],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\",\"form\",\"collection\",\"index\",\"item\",\"field\",\"field\",\"field\",\"field\",\"field\",\"collection\",\"index\",\"item\",\"field\",\"field\",\"field\",\"select\",\"option\"],[\"if\",\"unless\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        on,
        DButton,
        fn,
        Form,
        not
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-calendar-editor", ISBFOfficialCalendarEditor);
var Mod60 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialCalendarEditor
});
class ISBFOfficialCalendarComposer extends Component {
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get visible() {
    return Boolean(this.site.isbf_calendar && isOfficialCalendarComposer(this.args.model, this.site));
  }
  get eventCount() {
    return this.items.filter(item => item.schedule_kind === "event").length;
  }
  get deadlineCount() {
    return this.items.filter(item => item.schedule_kind === "deadline").length;
  }
  get items() {
    return canonicalCalendarItems(this.args.model[OFFICIAL_CALENDAR_FIELD] ?? []);
  }
  get eventLabel() {
    return i18n(themePrefix(this.eventCount ? "isbf_v2.schedule_activity_count" : "isbf_v2.schedule_activity_time"), {
      count: this.eventCount
    });
  }
  get deadlineLabel() {
    return i18n(themePrefix(this.deadlineCount ? "isbf_v2.schedule_registration_count" : "isbf_v2.schedule_registration_deadline"), {
      count: this.deadlineCount
    });
  }
  edit(section) {
    const model = this.args.model;
    this.modal.show(ISBFOfficialCalendarEditor, {
      model: {
        section,
        items: model[OFFICIAL_CALENDAR_FIELD] ?? [],
        getTopicTitle: () => officialCalendarTopicTitle(model),
        onSave: items => {
          if (this.isDestroying || model !== this.args.model || !isOfficialCalendarComposer(model, this.site)) {
            throw new Error("Official composer is no longer active");
          }
          model.set(OFFICIAL_CALENDAR_FIELD, items);
        }
      }
    });
  }
  static {
    dt7948.n(this.prototype, "edit", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-official-calendar-composer">
        <DButton
          class="isbf-official-calendar-composer__event"
          @action={{fn this.edit "event"}}
          @icon={{if this.eventCount "pencil" "plus"}}
          @translatedLabel={{this.eventLabel}}
        />
        <DButton
          class="isbf-official-calendar-composer__deadline"
          @action={{fn this.edit "deadline"}}
          @icon={{if this.deadlineCount "pencil" "plus"}}
          @translatedLabel={{this.deadlineLabel}}
        />
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-official-calendar-composer\"],[12],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-official-calendar-composer__event\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[28,[32,1],[[30,0,[\"edit\"]],\"event\"],null],[52,[30,0,[\"eventCount\"]],\"pencil\",\"plus\"],[30,0,[\"eventLabel\"]]]],null],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-official-calendar-composer__deadline\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[28,[32,1],[[30,0,[\"edit\"]],\"deadline\"],null],[52,[30,0,[\"deadlineCount\"]],\"pencil\",\"plus\"],[30,0,[\"deadlineLabel\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-calendar-composer", ISBFOfficialCalendarComposer);
var Mod59 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialCalendarComposer
});
class ISBFOfficialPicker extends Component {
  fallbackPlacements = ["bottom-start", "bottom-end"];
  get label() {
    const selected = this.options.filter(item => item.selected);
    if (!selected.length) {
      return i18n(themePrefix(this.args.allKey ?? this.args.labelKey));
    }
    if (selected.length === 1) {
      return selected[0].label;
    }
    return i18n(themePrefix("isbf_v2.explore_selected_count"), {
      label: i18n(themePrefix(this.args.labelKey)),
      count: selected.length
    });
  }
  get options() {
    return this.args.items.map(item => ({
      ...item,
      label: item.enabled === false ? i18n(themePrefix("isbf_v2.official_inactive"), {
        label: item.label
      }) : item.label,
      selected: this.args.selectedIds.includes(item.id)
    }));
  }
  get allSelected() {
    return !this.args.selectedIds.length;
  }
  async select(menu, id) {
    this.args.onSelect(id);
    await menu.close();
  }
  static {
    dt7948.n(this.prototype, "select", [action]);
  }
  toggle(id, event) {
    this.args.onSelect(id, event.target.checked);
  }
  static {
    dt7948.n(this.prototype, "toggle", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DMenu
      @ariaLabel={{i18n (themePrefix @labelKey)}}
      @contentClass="isbf-official-picker__menu"
      @fallbackPlacements={{this.fallbackPlacements}}
      @icon="chevron-down"
      @label={{this.label}}
      @placement="bottom-start"
      @triggerClass="btn-flat isbf-official-picker__trigger"
    >
      <:content as |menu|>
        <DDropdownMenu as |dropdown|>
          {{#unless @multiple}}
            <dropdown.item>
              <DButton
                class="btn-flat isbf-official-picker__item"
                @action={{fn this.select menu ""}}
                @ariaPressed={{this.allSelected}}
                @translatedLabel={{i18n (themePrefix @allKey)}}
              />
            </dropdown.item>
          {{/unless}}
          {{#each this.options as |item|}}
            <dropdown.item>
              {{#if @multiple}}
                <label class="isbf-official-picker__item">
                  <input
                    checked={{item.selected}}
                    type="checkbox"
                    {{on "change" (fn this.toggle item.id)}}
                  />
                  <span>{{item.label}}</span>
                </label>
              {{else}}
                <DButton
                  class="btn-flat isbf-official-picker__item"
                  @action={{fn this.select menu item.id}}
                  @ariaPressed={{item.selected}}
                  @translatedLabel={{item.label}}
                />
              {{/if}}
            </dropdown.item>
          {{/each}}
        </DDropdownMenu>
      </:content>
    </DMenu>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@fallbackPlacements\",\"@icon\",\"@label\",\"@placement\",\"@triggerClass\"],[[28,[32,1],[[28,[32,2],[[30,1]],null]],null],\"isbf-official-picker__menu\",[30,0,[\"fallbackPlacements\"]],\"chevron-down\",[30,0,[\"label\"]],\"bottom-start\",\"btn-flat isbf-official-picker__trigger\"]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,3],null,null,[[\"default\"],[[[[1,\"\\n\"],[41,[51,[30,4]],[[[1,\"        \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,4],[[24,0,\"btn-flat isbf-official-picker__item\"]],[[\"@action\",\"@ariaPressed\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"select\"]],[30,2],\"\"],null],[30,0,[\"allSelected\"]],[28,[32,1],[[28,[32,2],[[30,5]],null]],null]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[]],null],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"options\"]]],null]],null],null,[[[1,\"        \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n\"],[41,[30,4],[[[1,\"            \"],[10,\"label\"],[14,0,\"isbf-official-picker__item\"],[12],[1,\"\\n              \"],[11,\"input\"],[16,\"checked\",[30,6,[\"selected\"]]],[24,4,\"checkbox\"],[4,[32,6],[\"change\",[28,[32,5],[[30,0,[\"toggle\"]],[30,6,[\"id\"]]],null]],null],[12],[13],[1,\"\\n              \"],[10,1],[12],[1,[30,6,[\"label\"]]],[13],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],[[[1,\"            \"],[8,[32,4],[[24,0,\"btn-flat isbf-official-picker__item\"]],[[\"@action\",\"@ariaPressed\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"select\"]],[30,2],[30,6,[\"id\"]]],null],[30,6,[\"selected\"]],[30,6,[\"label\"]]]],null],[1,\"\\n\"]],[]]],[1,\"        \"]],[]]]]],[1,\"\\n\"]],[6]],null],[1,\"    \"]],[3]]]]],[1,\"\\n  \"]],[2]]]]]],[\"@labelKey\",\"menu\",\"dropdown\",\"@multiple\",\"@allKey\",\"item\"],[\"unless\",\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        themePrefix,
        DDropdownMenu,
        DButton,
        fn,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-picker", ISBFOfficialPicker);
var Mod53 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialPicker
});
class ISBFOfficialComposer extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get config() {
    return officialConfig(this.site);
  }
  get visible() {
    return isOfficialComposer(this.args.model, this.config);
  }
  get campuses() {
    return officialSelectionIds(get(this.args.model, "isbf_official_campuses"));
  }
  get types() {
    return officialSelectionIds(get(this.args.model, "isbf_official_types"));
  }
  get campusItems() {
    return officialComposerItems(this.config.campuses, this.campuses);
  }
  get typeItems() {
    return officialComposerItems(this.config.types, this.types);
  }
  select(field, id, checked) {
    const items = field === "isbf_official_campuses" ? this.config.campuses : this.config.types;
    const selected = officialSelectionIds(this.args.model[field]);
    if (checked && !items.some(item => item.id === id && item.enabled !== false)) {
      return;
    }
    const next = checked ? [...new Set([...selected, id])] : selected.filter(value => value !== id);
    if (checked && !officialSelectionLimit(next)) {
      return;
    }
    this.args.model.set(field, next);
  }
  static {
    dt7948.n(this.prototype, "select", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-official-composer">
        <div class="isbf-official-composer__menus">
          {{#if this.campusItems.length}}
            <div class="isbf-official-composer__campus">
              <ISBFOfficialPicker
                @allKey="isbf_v2.official_campus_optional"
                @items={{this.campusItems}}
                @labelKey="isbf_v2.official_campus"
                @multiple={{true}}
                @onSelect={{fn this.select "isbf_official_campuses"}}
                @selectedIds={{this.campuses}}
              />
            </div>
          {{/if}}
          <div class="isbf-official-composer__type">
            <ISBFOfficialPicker
              @items={{this.typeItems}}
              @labelKey="isbf_v2.official_type"
              @multiple={{true}}
              @onSelect={{fn this.select "isbf_official_types"}}
              @selectedIds={{this.types}}
            />
          </div>
        </div>
      </div>
    {{/if}}
    <ISBFOfficialCalendarComposer @model={{@model}} />
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-official-composer\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-official-composer__menus\"],[12],[1,\"\\n\"],[41,[30,0,[\"campusItems\",\"length\"]],[[[1,\"        \"],[10,0],[14,0,\"isbf-official-composer__campus\"],[12],[1,\"\\n          \"],[8,[32,0],null,[[\"@allKey\",\"@items\",\"@labelKey\",\"@multiple\",\"@onSelect\",\"@selectedIds\"],[\"isbf_v2.official_campus_optional\",[30,0,[\"campusItems\"]],\"isbf_v2.official_campus\",true,[28,[32,1],[[30,0,[\"select\"]],\"isbf_official_campuses\"],null],[30,0,[\"campuses\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,0],[14,0,\"isbf-official-composer__type\"],[12],[1,\"\\n        \"],[8,[32,0],null,[[\"@items\",\"@labelKey\",\"@multiple\",\"@onSelect\",\"@selectedIds\"],[[30,0,[\"typeItems\"]],\"isbf_v2.official_type\",true,[28,[32,1],[[30,0,[\"select\"]],\"isbf_official_types\"],null],[30,0,[\"types\"]]]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null],[8,[32,2],null,[[\"@model\"],[[30,1]]],null]],[\"@model\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFOfficialPicker,
        fn,
        ISBFOfficialCalendarComposer
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-composer", ISBFOfficialComposer);
var Mod51 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialComposer
});
class ISBFV2ComposerOptions extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "anonymousSelection", [tracked], function () {
      return null;
    });
  }
  #anonymousSelection = (dt7948.i(this, "anonymousSelection"), void 0);
  get model() {
    return this.args.outletArgs?.model;
  }
  get isQuickPost() {
    return isQuickPost(this.model);
  }
  get canAnonymize() {
    return canPublishAnonymously(this.model, this.currentUser, this.siteSettings);
  }
  get isAnonymous() {
    const selected = Boolean(this.model?.isbf_anonymous);
    return this.anonymousSelection?.model === this.model ? selected && this.anonymousSelection.value : selected;
  }
  toggleAnonymous() {
    const selected = !this.isAnonymous;
    this.model.set("isbf_anonymous", selected);
    this.anonymousSelection = {
      model: this.model,
      value: selected
    };
  }
  static {
    dt7948.n(this.prototype, "toggleAnonymous", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFOfficialComposer @model={{this.model}} />
    <span aria-hidden="true" class="isbf-v2-composer"></span>
    {{#if this.isQuickPost}}
      <div class="isbf-v2-composer-options">
        <div
          aria-hidden="true"
          class="isbf-v2-composer-options__avatar isbf-avatar"
        >
          {{dAvatar this.currentUser imageSize="large"}}
          {{#unless this.isAnonymous}}<PluginOutlet
              @name="user-avatar-frame"
              @outletArgs={{lazyHash user=this.currentUser motion="static"}}
            />{{/unless}}
        </div>
      </div>
    {{/if}}
    {{#if this.canAnonymize}}
      <div class="isbf-v2-anonymous-option">
        <DButton
          class="isbf-v2-anonymous-option__toggle"
          @action={{this.toggleAnonymous}}
          @ariaPressed={{this.isAnonymous}}
          @label={{themePrefix "isbf_v2.anonymous_post"}}
        />
        <span>{{i18n (themePrefix "isbf_v2.anonymous_post_hint")}}</span>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@model\"],[[30,0,[\"model\"]]]],null],[1,\"\\n\"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-v2-composer\"],[12],[13],[1,\"\\n\"],[41,[30,0,[\"isQuickPost\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-v2-composer-options\"],[12],[1,\"\\n    \"],[10,0],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-v2-composer-options__avatar isbf-avatar\"],[12],[1,\"\\n      \"],[1,[28,[32,1],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"large\"]]]],[1,\"\\n      \"],[41,[51,[30,0,[\"isAnonymous\"]]],[[[8,[32,2],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,3],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"canAnonymize\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-v2-anonymous-option\"],[12],[1,\"\\n    \"],[8,[32,4],[[24,0,\"isbf-v2-anonymous-option__toggle\"]],[[\"@action\",\"@ariaPressed\",\"@label\"],[[30,0,[\"toggleAnonymous\"]],[30,0,[\"isAnonymous\"]],[28,[32,5],[\"isbf_v2.anonymous_post\"],null]]],null],[1,\"\\n    \"],[10,1],[12],[1,[28,[32,6],[[28,[32,5],[\"isbf_v2.anonymous_post_hint\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFOfficialComposer,
        dAvatar,
        PluginOutlet,
        lazyHash,
        DButton,
        themePrefix,
        i18n
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-composer-options", ISBFV2ComposerOptions);
var Mod9 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2ComposerOptions
});
class ISBFV2ComposerTitle extends Component {
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "focused", [tracked], function () {
      return false;
    });
  }
  #focused = (dt7948.i(this, "focused"), void 0);
  get model() {
    return this.args.outletArgs?.model;
  }
  get enabled() {
    return isQuickPost(this.model);
  }
  get disabled() {
    return this.model.loading || this.model.disableTitleInput;
  }
  get titleRequired() {
    return officialCalendarNeedsTitle(this.model, this.site);
  }
  get label() {
    return i18n(themePrefix(this.titleRequired ? "isbf_v2.schedule_post_title" : "isbf_v2.optional_title"));
  }
  get validation() {
    if (this.focused) {
      return;
    }
    if (this.titleRequired && !officialCalendarTopicTitle(this.model)) {
      return EmberObject.create({
        failed: true,
        reason: i18n(themePrefix("isbf_v2.schedule_title_required")),
        lastShownAt: this.composer.get("lastValidatedAt")
      });
    }
    if (!this.model.isbf_optional_title?.trim()) {
      return;
    }
    let reason;
    if (this.model.missingTitleCharacters > 0) {
      reason = i18n("composer.error.title_too_short", {
        count: this.model.minimumTitleLength
      });
    } else if (this.model.titleLength > this.siteSettings.max_topic_title_length) {
      reason = i18n("composer.error.title_too_long", {
        count: this.siteSettings.max_topic_title_length
      });
    }
    if (reason) {
      return EmberObject.create({
        failed: true,
        reason,
        lastShownAt: this.composer.get("lastValidatedAt")
      });
    }
  }
  updateTitle(event) {
    setOptionalTopicTitle(this.model, event.target.value);
  }
  static {
    dt7948.n(this.prototype, "updateTitle", [action]);
  }
  focusTitle() {
    this.focused = true;
  }
  static {
    dt7948.n(this.prototype, "focusTitle", [action]);
  }
  blurTitle() {
    this.focused = false;
  }
  static {
    dt7948.n(this.prototype, "blurTitle", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <div class="isbf-v2-composer-title">
        <div class="title-input">
          <DTextField
            aria-required={{if this.titleRequired "true" "false"}}
            @aria-label={{this.label}}
            @autocomplete="off"
            @disabled={{this.disabled}}
            @id="isbf-optional-title"
            @maxLength={{this.siteSettings.max_topic_title_length}}
            @placeholder={{this.label}}
            @value={{this.model.isbf_optional_title}}
            {{on "input" this.updateTitle}}
            {{on "focus" this.focusTitle}}
            {{on "blur" this.blurTitle}}
          />
          <DPopupInputTip @validation={{this.validation}} />
        </div>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-v2-composer-title\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"title-input\"],[12],[1,\"\\n      \"],[8,[32,0],[[16,\"aria-required\",[52,[30,0,[\"titleRequired\"]],\"true\",\"false\"]],[4,[32,1],[\"input\",[30,0,[\"updateTitle\"]]],null],[4,[32,1],[\"focus\",[30,0,[\"focusTitle\"]]],null],[4,[32,1],[\"blur\",[30,0,[\"blurTitle\"]]],null]],[[\"@aria-label\",\"@autocomplete\",\"@disabled\",\"@id\",\"@maxLength\",\"@placeholder\",\"@value\"],[[30,0,[\"label\"]],\"off\",[30,0,[\"disabled\"]],\"isbf-optional-title\",[30,0,[\"siteSettings\",\"max_topic_title_length\"]],[30,0,[\"label\"]],[30,0,[\"model\",\"isbf_optional_title\"]]]],null],[1,\"\\n      \"],[8,[32,2],null,[[\"@validation\"],[[30,0,[\"validation\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DTextField,
        on,
        DPopupInputTip
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-composer-title", ISBFV2ComposerTitle);
var Mod33 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2ComposerTitle
});
function feedbackCategory(site, categoryId) {
  const id = Number(categoryId);
  if (!Number.isSafeInteger(id) || id <= 0) {
    return null;
  }
  return site?.categories?.find(category => Number(category.id) === id) ?? null;
}
function isFeedbackPath(path, category) {
  if (!category) {
    return false;
  }
  const match = (path ?? "").split("?")[0].match(/^\/c\/(?:[^/]+\/)*?(\d+)(?:\/l\/[^/]+)?\/?$/);
  return Boolean(match && Number(match[1]) === Number(category.id));
}
function feedbackHref(category) {
  if (!category) {
    return null;
  }
  const path = category.url || category.path || `/c/${category.id}`;
  return `${path.replace(/\/$/, "")}/l/latest`;
}
function feedbackComposeHref(category) {
  return category ? `/new-topic?category_id=${category.id}` : "/new-topic";
}
var Mod50 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  feedbackCategory: feedbackCategory,
  feedbackComposeHref: feedbackComposeHref,
  feedbackHref: feedbackHref,
  isFeedbackPath: isFeedbackPath
});
const PREFERENCES = new Set(["account", "security", "profile", "emails", "notifications", "tracking", "users", "tags", "interface", "apps", "navigation-menu", "calendar-subscriptions", "email", "second-factor"]);
const PRIVATE_MESSAGES = new Set(["user-private-messages.user.index", "user-private-messages.user.new", "user-private-messages.user.unread", "user-private-messages.user.archive", "user-private-messages.user.sent", "user-private-messages.user.warnings", "user-private-messages.group.index", "user-private-messages.group.new", "user-private-messages.group.unread", "user-private-messages.group.archive", "user-private-messages.tags.index", "user-private-messages.tags.show"]);
const USER_CONTENT = new Map([["user-activity.bookmarks", "bookmarks"], ["user-activity.bookmarks-with-reminders", "bookmarks"], ["user-activity.drafts", "drafts"], ["user-activity.pending", "pending"], ["user.summary", "profile-summary"], ["user.badges", "profile-badges"], ["user.deleted-posts", "deleted-posts"], ["user.profile-hidden", "profile-hidden"]]);
const GROUP_PAGES = new Set(["group.index", "group.members", "group.requests", "group.permissions", "group.activity.index", "group.activity.posts", "group.activity.topics", "group.activity.mentions"]);
const GROUP_MANAGEMENT = new Set(["group.manage.index", "group.manage.profile", "group.manage.membership", "group.manage.interaction", "group.manage.email", "group.manage.members", "group.manage.categories", "group.manage.tags", "group.manage.logs"]);
const INFORMATION = new Set(["about", "faq", "guidelines", "conduct", "rules", "tos", "privacy"]);
function normalizedRouteName(routeName = "") {
  return (routeName ?? "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
}
function frontendConsistencyScope(routeName) {
  const name = normalizedRouteName(routeName);
  const [parent, child] = name.split(".");
  if (parent === "preferences" && PREFERENCES.has(child) && name === `${parent}.${child}`) {
    return {
      id: "preferences",
      layout: "feature",
      userContent: true
    };
  }
  if (name === "users" || name === "users.index") {
    return {
      id: "directory",
      layout: "feature",
      userContent: false
    };
  }
  if (name === "user-invited.index" || name === "user-invited.show") {
    return {
      id: "invitations",
      layout: "feature",
      userContent: true
    };
  }
  if (USER_CONTENT.has(name)) {
    return {
      id: USER_CONTENT.get(name),
      layout: "feed",
      userContent: true
    };
  }
  if (PRIVATE_MESSAGES.has(name)) {
    return {
      id: "messages",
      layout: "feed",
      userContent: true
    };
  }
  if (name === "badges.index" || name === "badges.show") {
    return {
      id: "badges",
      layout: "feed",
      userContent: false
    };
  }
  if (name === "full-page-search") {
    return {
      id: "search",
      layout: "feature",
      userContent: false
    };
  }
  if (name === "tags.index") {
    return {
      id: "tags",
      layout: "feed",
      userContent: false
    };
  }
  if (name === "groups.index" || name === "groups.new") {
    return {
      id: "groups",
      layout: "feature",
      userContent: false
    };
  }
  if (GROUP_PAGES.has(name)) {
    return {
      id: "group",
      layout: "feature",
      userContent: false
    };
  }
  if (GROUP_MANAGEMENT.has(name)) {
    return {
      id: "group-manage",
      layout: "feature",
      userContent: false
    };
  }
  if (["group.messages.index", "group.messages.inbox", "group.messages.archive"].includes(name)) {
    return {
      id: "group-messages",
      layout: "feature",
      userContent: false
    };
  }
  if (INFORMATION.has(name)) {
    return {
      id: "information",
      layout: "feed",
      userContent: false
    };
  }
  return null;
}
var Mod135 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  frontendConsistencyScope: frontendConsistencyScope,
  normalizedRouteName: normalizedRouteName
});
function notificationsEnabled(path, currentUser, siteSettings) {
  if (!currentUser || !siteSettings.isbf_notifications_enabled) {
    return false;
  }
  const match = path.split("?")[0].match(/^\/u\/([^/]+)\/notifications(?:\/|$)/);
  return Boolean(match && decodeURIComponent(match[1]).toLowerCase() === currentUser.username.toLowerCase());
}
function mergeEntries(existing, incoming) {
  const entries = new Map(existing.map(entry => [entry.key, entry]));
  for (const entry of incoming) {
    if (!entries.has(entry.key)) {
      entries.set(entry.key, entry);
    }
  }
  return [...entries.values()];
}
let initialTab = "all";
function setInitialNotificationTab(tab) {
  initialTab = tab;
}
function consumeInitialNotificationTab() {
  const tab = initialTab;
  initialTab = "all";
  return tab;
}
var Mod23 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  consumeInitialNotificationTab: consumeInitialNotificationTab,
  mergeEntries: mergeEntries,
  notificationsEnabled: notificationsEnabled,
  setInitialNotificationTab: setInitialNotificationTab
});
const secondaryMenus = new WeakMap();
function isConversationTopic(topic, path, siteSettings) {
  return !EmbedMode.enabled && /^\/t\//.test(path ?? "") && topic?.archetype === "regular" && topic.is_nested_view && siteSettings.nested_replies_enabled && siteSettings.nested_replies_cap_nesting_depth && siteSettings.nested_replies_max_depth === 1;
}
function isConversationPost(post, path, siteSettings) {
  return post?.post_type === 1 && isConversationTopic(post.topic, path, siteSettings);
}
function isFeedStyleTopic(topic, path) {
  return /^\/t\//.test(path ?? "") && topic?.archetype === "regular" && !topic.is_nested_view;
}
function isFeedStylePost(post, path, nestedReplyView = false) {
  return isFeedStyleTopic(post?.topic, path) && post.post_type === 1 && !nestedReplyView;
}
function rememberSecondaryMenu(post, entries) {
  secondaryMenus.set(post, entries);
}
function secondaryMenuFor(post) {
  return secondaryMenus.get(post) ?? [];
}
function cardReplyCount(post) {
  return post.post_number === 1 ? Math.max(0, Number(post.topic.replyCount) || 0) : Math.max(0, Number(post.reply_count) || 0);
}
var Mod31 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  cardReplyCount: cardReplyCount,
  isConversationPost: isConversationPost,
  isConversationTopic: isConversationTopic,
  isFeedStylePost: isFeedStylePost,
  isFeedStyleTopic: isFeedStyleTopic,
  rememberSecondaryMenu: rememberSecondaryMenu,
  secondaryMenuFor: secondaryMenuFor
});
function alumniConfig(site) {
  const config = site?.isbf_alumni;
  return config?.enabled === true && Array.isArray(config.countries) ? config : null;
}
function alumniRegions(config, country) {
  return country === "CN" ? config?.countries?.find(item => item.code === country)?.regions || [] : [];
}
function alumniLocation(user) {
  return [user.country_name, user.country_code === "CN" ? user.region_name : null].filter(Boolean).join(" · ");
}
var Mod84 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  alumniConfig: alumniConfig,
  alumniLocation: alumniLocation,
  alumniRegions: alumniRegions
});
function labelFontSize(zoom) {
  return Math.max(10, Math.min(9 + zoom, 18));
}
function visibleLabelLayers(candidates, size) {
  const accepted = [];
  const ordered = [...candidates].sort((left, right) => Number(Boolean(right.selected)) - Number(Boolean(left.selected)));
  for (const candidate of ordered) {
    const box = candidate.box;
    if (box.left < 0 || box.top < 0 || box.right > size.x || box.bottom > size.y || accepted.some(({
      box: other
    }) => box.left < other.right && box.right > other.left && box.top < other.bottom && box.bottom > other.top)) {
      continue;
    }
    accepted.push(candidate);
  }
  return accepted.map(({
    layer
  }) => layer);
}
var Mod87 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  labelFontSize: labelFontSize,
  visibleLabelLayers: visibleLabelLayers
});
let leafletPromise;
const COUNTRY_VIEWS = {
  CN: {
    center: [35, 105],
    zoom: 3
  },
  US: {
    center: [39, -98],
    zoom: 3
  },
  CA: {
    center: [57, -106],
    zoom: 3
  },
  GB: {
    center: [55, -3],
    zoom: 5
  },
  AU: {
    center: [-25, 134],
    zoom: 3
  },
  JP: {
    center: [37, 138],
    zoom: 4
  },
  DE: {
    center: [51, 10],
    zoom: 5
  },
  FR: {
    center: [47, 2],
    zoom: 5
  }
};
function sameOriginPath(url) {
  return typeof url === "string" && /^\/(?!\/)/.test(url) && !url.includes("\\") ? url : null;
}
function leaflet(config) {
  const script = sameOriginPath(config.leaflet_js_url);
  const stylesheet = sameOriginPath(config.leaflet_css_url);
  if (!script || !stylesheet) {
    throw new Error("Missing map assets");
  }
  if (!leafletPromise) {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = stylesheet;
    document.head.appendChild(link);
    leafletPromise = loadScript(script).then(() => {
      if (!window.L) {
        throw new Error("Missing map library");
      }
      return window.L;
    }).catch(error => {
      leafletPromise = null;
      link.remove();
      throw error;
    });
  }
  return leafletPromise;
}
class ISBFAlumniMap extends Component {
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return true;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  #element;
  #map;
  #world;
  #detail;
  #regionMarkers;
  #observer;
  #request = 0;
  #layers = new Map();
  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
    this.#observer?.disconnect();
    this.#map?.remove();
  }
  insert(element) {
    this.#element = element;
    this.initialize();
  }
  static {
    dt7948.n(this.prototype, "insert", [action]);
  }
  async initialize() {
    const request = ++this.#request;
    this.error = false;
    this.loading = true;
    try {
      const L = await leaflet(this.args.config);
      const data = await this.#loadLayer(this.args.config.world_map_url);
      if (request !== this.#request || this.isDestroying) {
        return;
      }
      this.#map?.remove();
      this.#map = L.map(this.#element, {
        scrollWheelZoom: false,
        attributionControl: false,
        minZoom: 1,
        maxZoom: 9,
        worldCopyJump: true
      }).setView([35, 105], 3);
      this.#world = L.geoJSON(data, {
        style: {
          className: "isbf-alumni-map__country",
          weight: 1
        },
        onEachFeature: (feature, layer) => {
          const code = feature.properties.country_code || feature.properties.code;
          if (code === "CN") {
            this.#bindLabel(layer, feature.properties.name);
          }
          if (this.args.config.countries.some(item => item.code === code)) {
            layer.on("click", () => this.args.onSelect({
              country: code
            }));
          }
        }
      }).addTo(this.#map);
      this.#map.on("zoomend moveend", () => this.#refreshLabels());
      this.#observer?.disconnect();
      this.#observer = new ResizeObserver(() => this.#map?.invalidateSize());
      this.#observer.observe(this.#element);
      this.loading = false;
      await this.updateSelection();
    } catch {
      if (request === this.#request && !this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (request === this.#request && !this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "initialize", [action]);
  }
  returnToChina() {
    if (this.args.country === "CN" && !this.args.region) {
      this.updateSelection();
    } else {
      this.args.onSelect({
        country: "CN"
      });
    }
  }
  static {
    dt7948.n(this.prototype, "returnToChina", [action]);
  }
  async updateSelection() {
    if (!this.#map) {
      return;
    }
    const request = ++this.#request;
    this.#detail?.remove();
    this.#regionMarkers?.remove();
    this.#detail = null;
    this.#regionMarkers = null;
    this.error = false;
    const country = this.args.country;
    const region = this.args.region;
    let countryLayer;
    this.#world.eachLayer(layer => {
      const code = layer.feature.properties.country_code || layer.feature.properties.code;
      layer.setStyle({
        className: "isbf-alumni-map__country",
        fillOpacity: code === country ? 0.45 : 0.15
      });
      if (code === country) {
        countryLayer = layer;
      }
    });
    const view = COUNTRY_VIEWS[country];
    if (view) {
      this.#map.setView(view.center, view.zoom);
    } else if (countryLayer) {
      this.#map.fitBounds(countryLayer.getBounds(), {
        padding: [20, 20],
        maxZoom: 4
      });
    } else if (!country) {
      this.#map.setView([20, 0], 1);
    }
    const url = country === "CN" ? this.args.config.region_map_urls?.CN : null;
    if (!url) {
      this.#refreshLabels();
      return;
    }
    try {
      const data = await this.#loadLayer(url);
      if (request !== this.#request || this.isDestroying) {
        return;
      }
      const L = window.L;
      this.#detail = L.geoJSON(data, {
        style: feature => ({
          className: "isbf-alumni-map__region",
          weight: 1,
          fillOpacity: feature.properties.code === region ? 0.55 : 0.2
        }),
        onEachFeature: (feature, layer) => {
          this.#bindLabel(layer, feature.properties.name);
          layer.on("click", () => this.args.onSelect({
            country,
            region: feature.properties.code
          }));
          if (feature.properties.code === region) {
            this.#map.fitBounds(layer.getBounds(), {
              padding: [20, 20],
              maxZoom: 6
            });
          }
        }
      }).addTo(this.#map);
      const regions = this.args.config.countries.find(item => item.code === country)?.regions || [];
      const boundaries = new Set(data.features.map(feature => feature.properties.code));
      this.#regionMarkers = L.layerGroup(regions.filter(item => !boundaries.has(item.code) && Number.isFinite(item.center?.lat) && Number.isFinite(item.center?.lng)).map(item => {
        const marker = L.circleMarker([item.center.lat, item.center.lng], {
          radius: item.code === region ? 7 : 5,
          className: "isbf-alumni-map__region",
          regionCode: item.code
        });
        this.#bindLabel(marker, item.name);
        marker.on("click", () => this.args.onSelect({
          country,
          region: item.code
        }));
        if (item.code === region) {
          this.#map.setView([item.center.lat, item.center.lng], 7);
        }
        return marker;
      })).addTo(this.#map);
      this.#refreshLabels();
    } catch {
      if (request === this.#request && !this.isDestroying) {
        this.error = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "updateSelection", [action]);
  }
  #bindLabel(layer, name) {
    layer.bindTooltip(this.#label(name), {
      className: "isbf-alumni-map__china-label",
      direction: "center",
      permanent: false
    });
    layer.on("mouseout", () => this.#refreshLabels());
  }
  #refreshLabels() {
    if (!this.#map) {
      return;
    }
    const zoom = this.#map.getZoom();
    const fontSize = labelFontSize(zoom);
    this.#element.style.setProperty("--isbf-alumni-label-size", `${fontSize}px`);
    this.#world?.eachLayer(layer => layer.closeTooltip());
    const candidates = [];
    const bounds = this.#map.getBounds();
    const context = document.createElement("canvas").getContext("2d");
    context.font = `${fontSize}px sans-serif`;
    const collect = layer => {
      layer.closeTooltip();
      if (zoom < 4) {
        return;
      }
      const center = layer.getLatLng?.() || layer.getCenter();
      if (!bounds.contains(center)) {
        return;
      }
      const point = this.#map.latLngToContainerPoint(center);
      const name = layer.getTooltip().getContent().textContent;
      const width = context.measureText(name).width + 10;
      const height = fontSize * 1.25 + 6;
      candidates.push({
        layer,
        selected: (layer.feature?.properties.code || layer.options.regionCode) === this.args.region,
        box: {
          left: point.x - width / 2,
          right: point.x + width / 2,
          top: point.y - height / 2,
          bottom: point.y + height / 2
        }
      });
    };
    this.#detail?.eachLayer(collect);
    this.#regionMarkers?.eachLayer(collect);
    visibleLabelLayers(candidates, this.#map.getSize()).forEach(layer => layer.openTooltip());
  }
  #label(name) {
    const label = document.createElement("span");
    label.textContent = name || "";
    return label;
  }
  async #loadLayer(url) {
    const path = sameOriginPath(url);
    if (!path) {
      throw new Error("Invalid map asset");
    }
    if (!this.#layers.has(path)) {
      this.#layers.set(path, ajax(path).catch(error => {
        this.#layers.delete(path);
        throw error;
      }));
    }
    return this.#layers.get(path);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div class="isbf-alumni-map">
      <DButton
        class="btn-flat isbf-alumni-map__reset"
        @action={{this.returnToChina}}
        @translatedLabel={{i18n (themePrefix "isbf_v2.alumni_return_china")}}
      />
      <div
        aria-label={{i18n (themePrefix "isbf_v2.alumni_map")}}
        class="isbf-alumni-map__canvas"
        {{didInsert this.insert}}
        {{didUpdate this.updateSelection @country @region}}
      ></div>
      {{#if this.loading}}<p role="status">{{i18n
            (themePrefix "isbf_v2.learning_loading")
          }}</p>{{/if}}
      {{#if this.error}}<p role="alert">{{i18n
            (themePrefix "isbf_v2.alumni_map_error")
          }}</p><DButton
          @action={{this.initialize}}
          @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
        />{{/if}}
      <small class="isbf-alumni-map__credit">Natural Earth · Leaflet</small>
    </div>
    */
    {
      "id": null,
      "block": "[[[10,0],[14,0,\"isbf-alumni-map\"],[12],[1,\"\\n  \"],[8,[32,0],[[24,0,\"btn-flat isbf-alumni-map__reset\"]],[[\"@action\",\"@translatedLabel\"],[[30,0,[\"returnToChina\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_return_china\"],null]],null]]],null],[1,\"\\n  \"],[11,0],[16,\"aria-label\",[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_map\"],null]],null]],[24,0,\"isbf-alumni-map__canvas\"],[4,[32,3],[[30,0,[\"insert\"]]],null],[4,[32,4],[[30,0,[\"updateSelection\"]],[30,1],[30,2]],null],[12],[13],[1,\"\\n  \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_loading\"],null]],null]],[13]],[]],null],[1,\"\\n  \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_map_error\"],null]],null]],[13],[8,[32,0],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"initialize\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.explore_retry\"],null]],null]]],null]],[]],null],[1,\"\\n  \"],[10,\"small\"],[14,0,\"isbf-alumni-map__credit\"],[12],[1,\"Natural Earth · Leaflet\"],[13],[1,\"\\n\"],[13]],[\"@country\",\"@region\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        i18n,
        themePrefix,
        didInsert,
        didUpdate
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-alumni-map", ISBFAlumniMap);
var Mod80 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFAlumniMap
});
class ISBFAlumniProfile extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "profile", [tracked], function () {
      return {
        display_name: "",
        country_code: "CN",
        region_code: "",
        industry: "",
        visible: false
      };
    });
  }
  #profile = (dt7948.i(this, "profile"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return true;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (dt7948.i(this, "loaded"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  constructor() {
    super(...arguments);
    this.load();
  }
  get regions() {
    return alumniRegions(this.args.config, this.profile.country_code);
  }
  get disabled() {
    return !this.loaded || this.loading || this.saving;
  }
  async load() {
    this.loading = true;
    this.error = false;
    try {
      const response = await ajax("/isbf/alumni/me");
      if (this.isDestroying) {
        return;
      }
      this.profile = {
        ...this.profile,
        country_code: response.country_code || "CN",
        region_code: response.country_code === "CN" ? response.region_code : "",
        industry: response.industry || "",
        visible: response.visible === true,
        display_name: response.display_name || this.currentUser.name || this.currentUser.username
      };
      this.loaded = true;
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  change(field, event) {
    const value = field === "visible" ? event.target.checked : event.target.value;
    const next = {
      ...this.profile,
      [field]: value
    };
    if (field === "country_code") {
      next.region_code = "";
    }
    this.profile = next;
  }
  static {
    dt7948.n(this.prototype, "change", [action]);
  }
  async save(event) {
    event.preventDefault();
    if (this.disabled) {
      return;
    }
    this.saving = true;
    this.error = false;
    try {
      await ajax("/isbf/alumni/me", {
        type: "PUT",
        data: this.profile
      });
      if (!this.isDestroying) {
        this.args.onSaved();
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-alumni-profile"
      @closeModal={{@onClose}}
      @submitOnEnter={{false}}
      @title={{i18n (themePrefix "isbf_v2.alumni_my_profile")}}
    >
      <:body>
        {{#if this.loading}}<p role="status">{{i18n
              (themePrefix "isbf_v2.learning_loading")
            }}</p>
        {{else if this.loaded}}
          <form {{on "submit" this.save}}>
            <label>{{i18n (themePrefix "isbf_v2.alumni_name")}}<input
                disabled={{this.saving}}
                maxlength="60"
                required
                type="text"
                value={{this.profile.display_name}}
                {{on "input" (fn this.change "display_name")}}
              /></label>
            <label>{{i18n (themePrefix "isbf_v2.alumni_country")}}<select
                disabled={{this.saving}}
                required
                value={{this.profile.country_code}}
                {{on "change" (fn this.change "country_code")}}
              >
                {{#each @config.countries as |country|}}<option
                    selected={{eq this.profile.country_code country.code}}
                    value={{country.code}}
                  >{{country.name}}</option>{{/each}}
              </select></label>
            {{#if this.regions.length}}<label>{{i18n
                  (themePrefix "isbf_v2.alumni_region")
                }}<select
                  disabled={{this.saving}}
                  required
                  value={{this.profile.region_code}}
                  {{on "change" (fn this.change "region_code")}}
                >
                  <option value="">{{i18n
                      (themePrefix "isbf_v2.alumni_select")
                    }}</option>
                  {{#each this.regions as |region|}}<option
                      selected={{eq this.profile.region_code region.code}}
                      value={{region.code}}
                    >{{region.name}}</option>{{/each}}
                </select></label>{{/if}}
            <label>{{i18n (themePrefix "isbf_v2.alumni_industry")}}<input
                disabled={{this.saving}}
                maxlength="60"
                required
                type="text"
                value={{this.profile.industry}}
                {{on "input" (fn this.change "industry")}}
              /></label>
            <label class="isbf-alumni-profile__visible"><input
                checked={{this.profile.visible}}
                disabled={{this.saving}}
                type="checkbox"
                {{on "change" (fn this.change "visible")}}
              />{{i18n (themePrefix "isbf_v2.alumni_visible")}}</label>
            <div class="isbf-alumni-profile__actions"><DButton
                @action={{@onClose}}
                @translatedLabel={{i18n "cancel"}}
              /><button
                class="btn btn-primary"
                disabled={{this.disabled}}
                type="submit"
              >{{i18n "save"}}</button></div>
          </form>
        {{/if}}
        {{#if this.error}}<p role="alert">{{i18n
              (themePrefix "isbf_v2.alumni_save_error")
            }}</p>{{#unless this.loaded}}<DButton
              @action={{this.load}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />{{/unless}}{{/if}}
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-alumni-profile\"]],[[\"@closeModal\",\"@submitOnEnter\",\"@title\"],[[30,1],false,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_my_profile\"],null]],null]]],[[\"body\"],[[[[1,\"\\n    \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"loaded\"]],[[[1,\"      \"],[11,\"form\"],[4,[32,3],[\"submit\",[30,0,[\"save\"]]],null],[12],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_name\"],null]],null]],[11,\"input\"],[16,\"disabled\",[30,0,[\"saving\"]]],[24,\"maxlength\",\"60\"],[24,\"required\",\"\"],[16,2,[30,0,[\"profile\",\"display_name\"]]],[24,4,\"text\"],[4,[32,3],[\"input\",[28,[32,4],[[30,0,[\"change\"]],\"display_name\"],null]],null],[12],[13],[13],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_country\"],null]],null]],[11,\"select\"],[16,\"disabled\",[30,0,[\"saving\"]]],[24,\"required\",\"\"],[16,2,[30,0,[\"profile\",\"country_code\"]]],[4,[32,3],[\"change\",[28,[32,4],[[30,0,[\"change\"]],\"country_code\"],null]],null],[12],[1,\"\\n            \"],[42,[28,[31,2],[[28,[31,2],[[30,2,[\"countries\"]]],null]],null],null,[[[10,\"option\"],[15,\"selected\",[28,[32,5],[[30,0,[\"profile\",\"country_code\"]],[30,3,[\"code\"]]],null]],[15,2,[30,3,[\"code\"]]],[12],[1,[30,3,[\"name\"]]],[13]],[3]],null],[1,\"\\n          \"],[13],[13],[1,\"\\n        \"],[41,[30,0,[\"regions\",\"length\"]],[[[10,\"label\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_region\"],null]],null]],[11,\"select\"],[16,\"disabled\",[30,0,[\"saving\"]]],[24,\"required\",\"\"],[16,2,[30,0,[\"profile\",\"region_code\"]]],[4,[32,3],[\"change\",[28,[32,4],[[30,0,[\"change\"]],\"region_code\"],null]],null],[12],[1,\"\\n              \"],[10,\"option\"],[14,2,\"\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_select\"],null]],null]],[13],[1,\"\\n              \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"regions\"]]],null]],null],null,[[[10,\"option\"],[15,\"selected\",[28,[32,5],[[30,0,[\"profile\",\"region_code\"]],[30,4,[\"code\"]]],null]],[15,2,[30,4,[\"code\"]]],[12],[1,[30,4,[\"name\"]]],[13]],[4]],null],[1,\"\\n            \"],[13],[13]],[]],null],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_industry\"],null]],null]],[11,\"input\"],[16,\"disabled\",[30,0,[\"saving\"]]],[24,\"maxlength\",\"60\"],[24,\"required\",\"\"],[16,2,[30,0,[\"profile\",\"industry\"]]],[24,4,\"text\"],[4,[32,3],[\"input\",[28,[32,4],[[30,0,[\"change\"]],\"industry\"],null]],null],[12],[13],[13],[1,\"\\n        \"],[10,\"label\"],[14,0,\"isbf-alumni-profile__visible\"],[12],[11,\"input\"],[16,\"checked\",[30,0,[\"profile\",\"visible\"]]],[16,\"disabled\",[30,0,[\"saving\"]]],[24,4,\"checkbox\"],[4,[32,3],[\"change\",[28,[32,4],[[30,0,[\"change\"]],\"visible\"],null]],null],[12],[13],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_visible\"],null]],null]],[13],[1,\"\\n        \"],[10,0],[14,0,\"isbf-alumni-profile__actions\"],[12],[8,[32,6],null,[[\"@action\",\"@translatedLabel\"],[[30,1],[28,[32,1],[\"cancel\"],null]]],null],[10,\"button\"],[14,0,\"btn btn-primary\"],[15,\"disabled\",[30,0,[\"disabled\"]]],[14,4,\"submit\"],[12],[1,[28,[32,1],[\"save\"],null]],[13],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"]],[]],null]],[]]],[1,\"    \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.alumni_save_error\"],null]],null]],[13],[41,[51,[30,0,[\"loaded\"]]],[[[8,[32,6],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"load\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.explore_retry\"],null]],null]]],null]],[]],null]],[]],null],[1,\"\\n  \"]],[]]]]]],[\"@onClose\",\"@config\",\"country\",\"region\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        on,
        fn,
        eq,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-alumni-profile", ISBFAlumniProfile);
var Mod81 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFAlumniProfile
});
class ISBFAlumni extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "isbfBackNavigation", [service]);
  }
  #isbfBackNavigation = (dt7948.i(this, "isbfBackNavigation"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "country", [tracked], function () {
      return "CN";
    });
  }
  #country = (dt7948.i(this, "country"), void 0);
  static {
    dt7948.g(this.prototype, "region", [tracked], function () {
      return "";
    });
  }
  #region = (dt7948.i(this, "region"), void 0);
  static {
    dt7948.g(this.prototype, "users", [tracked], function () {
      return [];
    });
  }
  #users = (dt7948.i(this, "users"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "hasMore", [tracked], function () {
      return false;
    });
  }
  #hasMore = (dt7948.i(this, "hasMore"), void 0);
  static {
    dt7948.g(this.prototype, "editing", [tracked], function () {
      return false;
    });
  }
  #editing = (dt7948.i(this, "editing"), void 0);
  static {
    dt7948.g(this.prototype, "geography", [tracked], function () {
      return null;
    });
  }
  #geography = (dt7948.i(this, "geography"), void 0);
  static {
    dt7948.g(this.prototype, "geographyError", [tracked], function () {
      return false;
    });
  }
  #geographyError = (dt7948.i(this, "geographyError"), void 0);
  #page = 0;
  #request = 0;
  #trigger;
  constructor() {
    super(...arguments);
    if (this.config && this.currentUser) {
      this.loadGeography();
      this.loadDirectory();
    } else if (this.config) {
      this.login();
    }
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }
  get config() {
    return alumniConfig(this.site);
  }
  get backHref() {
    return this.isbfBackNavigation.href("/isbf/workbench");
  }
  get mapConfig() {
    return this.geography ? {
      ...this.config,
      countries: this.geography.countries
    } : null;
  }
  get countries() {
    return this.mapConfig?.countries || this.config?.countries || [];
  }
  get regions() {
    return alumniRegions(this.mapConfig, this.country);
  }
  get directoryUsers() {
    return this.users.map(user => ({
      ...user,
      location: alumniLocation(user),
      href: `/u/${encodeURIComponent(user.username)}`
    }));
  }
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }
  static {
    dt7948.n(this.prototype, "goBack", [action]);
  }
  async loadGeography() {
    this.geographyError = false;
    try {
      const response = await ajax(this.config.geography_url);
      if (!this.isDestroying) {
        this.geography = response;
      }
    } catch {
      if (!this.isDestroying) {
        this.geographyError = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadGeography", [action]);
  }
  login() {
    this.appEvents.trigger("show-login");
  }
  static {
    dt7948.n(this.prototype, "login", [action]);
  }
  countryChanged(event) {
    this.selectLocation({
      country: event.target.value
    });
  }
  static {
    dt7948.n(this.prototype, "countryChanged", [action]);
  }
  regionChanged(event) {
    this.selectLocation({
      country: this.country,
      region: event.target.value
    });
  }
  static {
    dt7948.n(this.prototype, "regionChanged", [action]);
  }
  selectLocation({
    country = "",
    region = ""
  }) {
    this.country = country;
    this.region = country === "CN" ? region : "";
    this.loadDirectory();
  }
  static {
    dt7948.n(this.prototype, "selectLocation", [action]);
  }
  async loadDirectory(append = false) {
    if (!this.currentUser || !this.config || append && this.loading) {
      return;
    }
    const request = ++this.#request;
    const page = append ? this.#page + 1 : 1;
    this.loading = true;
    this.error = false;
    if (!append) {
      this.users = [];
      this.hasMore = false;
    }
    try {
      const response = await ajax("/isbf/alumni/directory", {
        data: {
          country: this.country,
          region: this.region,
          page
        }
      });
      if (request !== this.#request) {
        return;
      }
      this.users = append ? [...this.users, ...response.users] : response.users || [];
      this.hasMore = response.has_more === true;
      this.#page = page;
    } catch {
      if (request === this.#request) {
        this.error = true;
      }
    } finally {
      if (request === this.#request) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadDirectory", [action]);
  }
  retry() {
    this.loadDirectory(this.users.length > 0);
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  openProfile() {
    this.#trigger = document.activeElement;
    this.editing = true;
  }
  static {
    dt7948.n(this.prototype, "openProfile", [action]);
  }
  closeProfile() {
    this.editing = false;
    this.#trigger?.focus();
  }
  static {
    dt7948.n(this.prototype, "closeProfile", [action]);
  }
  profileSaved() {
    this.closeProfile();
    this.loadDirectory();
  }
  static {
    dt7948.n(this.prototype, "profileSaved", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-alumni">
      <header class="isbf-alumni__header">
        <a
          aria-label={{i18n "back_button"}}
          class="isbf-alumni__back"
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >
          {{dIcon "arrow-left"}}<h1>{{i18n
              (themePrefix "isbf_v2.workbench_alumni")
            }}</h1>
        </a>
        {{#if this.currentUser.isbf_alumni_member}}
          {{#if this.mapConfig}}
            <DButton
              @action={{this.openProfile}}
              @translatedLabel={{i18n
                (themePrefix "isbf_v2.alumni_my_profile")
              }}
            />
          {{/if}}
        {{/if}}
      </header>
      {{#if this.currentUser}}
        {{#if this.config}}
          {{#if this.editing}}<ISBFAlumniProfile
              @config={{this.mapConfig}}
              @onClose={{this.closeProfile}}
              @onSaved={{this.profileSaved}}
            />{{/if}}
          <div class="isbf-alumni__filters">
            <label>{{i18n (themePrefix "isbf_v2.alumni_country")}}
              <select
                value={{this.country}}
                {{on "change" this.countryChanged}}
              >
                <option value="">{{i18n
                    (themePrefix "isbf_v2.alumni_all")
                  }}</option>
                {{#each this.countries as |country|}}<option
                    selected={{eq this.country country.code}}
                    value={{country.code}}
                  >{{country.name}}</option>{{/each}}
              </select>
            </label>
            {{#if this.regions.length}}<label>{{i18n
                  (themePrefix "isbf_v2.alumni_region")
                }}
                <select
                  value={{this.region}}
                  {{on "change" this.regionChanged}}
                ><option value="">{{i18n
                      (themePrefix "isbf_v2.alumni_all")
                    }}</option>
                  {{#each this.regions as |region|}}<option
                      selected={{eq this.region region.code}}
                      value={{region.code}}
                    >{{region.name}}</option>{{/each}}
                </select>
              </label>{{/if}}
          </div>
          {{#if this.mapConfig}}<ISBFAlumniMap
              @config={{this.mapConfig}}
              @country={{this.country}}
              @onSelect={{this.selectLocation}}
              @region={{this.region}}
            />{{else if this.geographyError}}<p
              class="isbf-alumni__notice"
              role="alert"
            >{{i18n (themePrefix "isbf_v2.alumni_map_error")}}</p><DButton
              @action={{this.loadGeography}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />{{/if}}
          <section
            aria-busy={{this.loading}}
            aria-label={{i18n (themePrefix "isbf_v2.alumni_directory")}}
            class="isbf-alumni__directory"
          >
            {{#each this.directoryUsers key="id" as |user|}}
              <article class="isbf-alumni__person"><a
                  href={{user.href}}
                >{{user.display_name}}</a><span>{{user.location}}</span><span
                >{{user.industry}}</span></article>
            {{/each}}
            {{#if this.loading}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_loading")
                }}</p>
            {{else if this.error}}<p role="alert">{{i18n
                  (themePrefix "isbf_v2.alumni_load_error")
                }}</p><DButton
                @action={{this.retry}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
              />
            {{else if this.hasMore}}<DButton
                @action={{fn this.loadDirectory true}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
              />
            {{else if (eq this.users.length 0)}}<p>{{i18n
                  (themePrefix "isbf_v2.alumni_empty")
                }}</p>{{/if}}
          </section>
        {{else}}<p class="isbf-alumni__notice">{{i18n
              (themePrefix "isbf_v2.alumni_unavailable")
            }}</p>{{/if}}
      {{else}}<div class="isbf-alumni__notice"><p>{{i18n
              (themePrefix "isbf_v2.alumni_login")
            }}</p><DButton
            @action={{this.login}}
            @translatedLabel={{i18n "log_in"}}
          /></div>{{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-alumni\"],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-alumni__header\"],[12],[1,\"\\n    \"],[11,3],[16,\"aria-label\",[28,[32,0],[\"back_button\"],null]],[24,0,\"isbf-alumni__back\"],[16,6,[30,0,[\"backHref\"]]],[4,[32,1],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,\"\\n      \"],[1,[28,[32,2],[\"arrow-left\"],null]],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.workbench_alumni\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"currentUser\",\"isbf_alumni_member\"]],[[[41,[30,0,[\"mapConfig\"]],[[[1,\"        \"],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"openProfile\"]],[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_my_profile\"],null]],null]]],null],[1,\"\\n\"]],[]],null]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[41,[30,0,[\"config\"]],[[[1,\"      \"],[41,[30,0,[\"editing\"]],[[[8,[32,5],null,[[\"@config\",\"@onClose\",\"@onSaved\"],[[30,0,[\"mapConfig\"]],[30,0,[\"closeProfile\"]],[30,0,[\"profileSaved\"]]]],null]],[]],null],[1,\"\\n      \"],[10,0],[14,0,\"isbf-alumni__filters\"],[12],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_country\"],null]],null]],[1,\"\\n          \"],[11,\"select\"],[16,2,[30,0,[\"country\"]]],[4,[32,1],[\"change\",[30,0,[\"countryChanged\"]]],null],[12],[1,\"\\n            \"],[10,\"option\"],[14,2,\"\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_all\"],null]],null]],[13],[1,\"\\n            \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"countries\"]]],null]],null],null,[[[10,\"option\"],[15,\"selected\",[28,[32,6],[[30,0,[\"country\"]],[30,1,[\"code\"]]],null]],[15,2,[30,1,[\"code\"]]],[12],[1,[30,1,[\"name\"]]],[13]],[1]],null],[1,\"\\n          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n        \"],[41,[30,0,[\"regions\",\"length\"]],[[[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_region\"],null]],null]],[1,\"\\n            \"],[11,\"select\"],[16,2,[30,0,[\"region\"]]],[4,[32,1],[\"change\",[30,0,[\"regionChanged\"]]],null],[12],[10,\"option\"],[14,2,\"\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_all\"],null]],null]],[13],[1,\"\\n              \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"regions\"]]],null]],null],null,[[[10,\"option\"],[15,\"selected\",[28,[32,6],[[30,0,[\"region\"]],[30,2,[\"code\"]]],null]],[15,2,[30,2,[\"code\"]]],[12],[1,[30,2,[\"name\"]]],[13]],[2]],null],[1,\"\\n            \"],[13],[1,\"\\n          \"],[13]],[]],null],[1,\"\\n      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"mapConfig\"]],[[[8,[32,7],null,[[\"@config\",\"@country\",\"@onSelect\",\"@region\"],[[30,0,[\"mapConfig\"]],[30,0,[\"country\"]],[30,0,[\"selectLocation\"]],[30,0,[\"region\"]]]],null]],[]],[[[41,[30,0,[\"geographyError\"]],[[[10,2],[14,0,\"isbf-alumni__notice\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_map_error\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"loadGeography\"]],[28,[32,0],[[28,[32,3],[\"isbf_v2.explore_retry\"],null]],null]]],null]],[]],null]],[]]],[1,\"\\n      \"],[10,\"section\"],[15,\"aria-busy\",[30,0,[\"loading\"]]],[15,\"aria-label\",[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_directory\"],null]],null]],[14,0,\"isbf-alumni__directory\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"directoryUsers\"]]],null]],null],\"id\",[[[1,\"          \"],[10,\"article\"],[14,0,\"isbf-alumni__person\"],[12],[10,3],[15,6,[30,3,[\"href\"]]],[12],[1,[30,3,[\"display_name\"]]],[13],[10,1],[12],[1,[30,3,[\"location\"]]],[13],[10,1],[12],[1,[30,3,[\"industry\"]]],[13],[13],[1,\"\\n\"]],[3]],null],[1,\"        \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.learning_loading\"],null]],null]],[13],[1,\"\\n        \"]],[]],[[[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_load_error\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"retry\"]],[28,[32,0],[[28,[32,3],[\"isbf_v2.explore_retry\"],null]],null]]],null],[1,\"\\n        \"]],[]],[[[41,[30,0,[\"hasMore\"]],[[[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[28,[32,8],[[30,0,[\"loadDirectory\"]],true],null],[28,[32,0],[[28,[32,3],[\"isbf_v2.load_more\"],null]],null]]],null],[1,\"\\n        \"]],[]],[[[41,[28,[32,6],[[30,0,[\"users\",\"length\"]],0],null],[[[10,2],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_empty\"],null]],null]],[13]],[]],null]],[]]]],[]]]],[]]],[1,\"      \"],[13],[1,\"\\n    \"]],[]],[[[10,2],[14,0,\"isbf-alumni__notice\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_unavailable\"],null]],null]],[13]],[]]],[1,\"\\n  \"]],[]],[[[10,0],[14,0,\"isbf-alumni__notice\"],[12],[10,2],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.alumni_login\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"login\"]],[28,[32,0],[\"log_in\"],null]]],null],[13]],[]]],[1,\"\\n\"],[13]],[\"country\",\"region\",\"user\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        on,
        dIcon,
        themePrefix,
        DButton,
        ISBFAlumniProfile,
        eq,
        ISBFAlumniMap,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-alumni", ISBFAlumni);
var Mod82 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFAlumni
});
function plainText(html) {
  const element = document.createElement("div");
  element.innerHTML = html ?? "";
  return element.textContent?.replace(/\s+/g, " ").trim() ?? "";
}
function compactNumber(value) {
  const count = Number(value) || 0;
  return count ? new Intl.NumberFormat(undefined, {
    notation: "compact"
  }).format(count) : "";
}
function postCardTitle(title, cookedHtml) {
  if (cookedHtml === null || cookedHtml === undefined) {
    return null;
  }
  const normalizedTitle = title?.replace(/\s+/g, " ").trim();
  const body = plainText(cookedHtml);
  if (!normalizedTitle || isUntitledTopicTitle(normalizedTitle) || body && (body.startsWith(normalizedTitle) || normalizedTitle.startsWith(body.slice(0, 80)))) {
    return null;
  }
  return normalizedTitle;
}
async function openQuotedRepost({
  composer,
  router,
  currentUser,
  topicId,
  postNumber,
  username,
  cookedHtml,
  title
}) {
  if (!currentUser) {
    router.transitionTo("login");
    return false;
  }
  const sourceText = plainText(cookedHtml).slice(0, 500);
  const body = `[quote="${username}, post:${postNumber}, topic:${topicId}"]\n${sourceText}\n[/quote]\n\n`;
  const previousModel = composer.model;
  const previousDraftKey = previousModel?.draftKey;
  await composer.openNewTopic({
    body,
    title: optionalTopicTitle(title)
  });

  // Native openNewTopic returns undefined on both success and draft cancellation.
  const model = composer.model;
  if (!model || model.action !== Composer.CREATE_TOPIC || model.composeState !== Composer.OPEN || !model.draftKey || model === previousModel && model.draftKey === previousDraftKey || model.reply !== body) {
    return false;
  }
  model.set("isbf_repost_source_topic_id", topicId);
  return true;
}
var Mod30 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  compactNumber: compactNumber,
  openQuotedRepost: openQuotedRepost,
  plainText: plainText,
  postCardTitle: postCardTitle
});
const controllers = new WeakMap();
const linkedPreviews = new WeakMap();
let activeViewer;
function isImageAttachment(file) {
  return /\.(avif|bmp|gif|ico|jpe?g|png|svg|webp)$/i.test(file?.name || "");
}
function contentImageUrl(value) {
  if (typeof value !== "string" || /[\\\u0000-\u0020]/.test(value)) {
    return null;
  }
  if (!/^(https?:\/\/|\/(?!\/))/i.test(value)) {
    return null;
  }
  try {
    const url = new URL(value, "https://image.invalid");
    return url.username || url.password ? null : value;
  } catch {
    return null;
  }
}
function imageDimensions(link, image) {
  for (const [attribute, value] of [["data-target-width", image.naturalWidth || image.getAttribute("width")], ["data-target-height", image.naturalHeight || image.getAttribute("height")]]) {
    if (Number(value) > 0) {
      link.setAttribute(attribute, value);
    }
  }
}
function prepareContentImages(element, previewLabel) {
  const added = [];
  for (const image of element.querySelectorAll("img")) {
    if (image.matches(".emoji, .avatar, .favicon, .site-logo") || linkedPreviews.get(image)?.isConnected || image.closest(".lightbox, .spoiler, .spoiled, [data-isbf-image-preview-ignore]")) {
      continue;
    }
    const url = contentImageUrl(image.getAttribute("data-large-src") || image.getAttribute("data-orig-src") || image.getAttribute("src"));
    if (!url) {
      continue;
    }
    const link = element.ownerDocument.createElement("a");
    link.className = "lightbox isbf-content-image-link";
    link.href = url;
    link.title = image.alt || previewLabel;
    link.setAttribute("aria-label", previewLabel);
    imageDimensions(link, image);
    const existingLink = image.closest("a");
    if (existingLink) {
      // Keep onebox and other linked content navigable; provide a separate preview.
      link.classList.add("isbf-content-image-attachment");
      link.textContent = previewLabel;
      existingLink.after(link);
      linkedPreviews.set(image, link);
    } else {
      image.before(link);
      link.append(image);
    }
    added.push({
      image,
      link,
      wrapped: !existingLink
    });
  }
  return () => {
    for (const {
      image,
      link,
      wrapped
    } of added) {
      if (wrapped && link.contains(image)) {
        link.replaceWith(image);
      } else {
        link.remove();
        if (linkedPreviews.get(image) === link) {
          linkedPreviews.delete(image);
        }
      }
    }
  };
}
function watchViewer(controller, origin, options) {
  if (activeViewer) {
    return false;
  }
  const doc = origin.ownerDocument;
  const existing = new Set(doc.querySelectorAll(".pswp"));
  let viewer;
  let cancelled = false;
  let afterClose;
  const finish = () => {
    observer.disconnect();
    clearTimeout(timeout);
    if (activeViewer?.controller === controller) {
      activeViewer = null;
    }
    if (!cancelled && origin.isConnected) {
      origin.focus({
        preventScroll: true
      });
    }
    afterClose?.();
  };
  const close = () => viewer?.querySelector(".pswp__button--close")?.click();
  const retry = event => {
    const button = event.currentTarget;
    const url = viewer.querySelector(".pswp__button--original-image")?.href;
    const target = [...controller.element.querySelectorAll(".lightbox")].find(item => {
      const source = item.href || item.dataset.largeSrc;
      return source && new URL(source, doc.baseURI).href === url;
    }) || origin;
    afterClose = () => {
      if (!controller.destroyed && target.isConnected) {
        target.click();
      }
    };
    button.disabled = true;
    close();
  };
  const observer = new MutationObserver(() => {
    if (!viewer) {
      viewer = [...doc.querySelectorAll(".pswp")].find(candidate => !existing.has(candidate));
      if (viewer) {
        viewer.classList.add("isbf-content-image-viewer");
        if (cancelled) {
          close();
        }
      }
    } else if (!viewer.isConnected) {
      finish();
      return;
    }
    if (!origin.isConnected && !cancelled) {
      cancelled = true;
      close();
    }
    if (!viewer || cancelled) {
      return;
    }
    for (const error of viewer.querySelectorAll(".pswp__error-msg")) {
      if (error.querySelector(".isbf-content-image-retry")) {
        continue;
      }
      const button = doc.createElement("button");
      button.className = "btn isbf-content-image-retry";
      button.type = "button";
      button.textContent = options.retryLabel;
      button.addEventListener("click", retry);
      error.append(button);
    }
  });
  observer.observe(doc.body, {
    childList: true,
    subtree: true
  });
  // Native lightbox does not expose its instance; bound the pending-open observer.
  const timeout = setTimeout(() => {
    if (!viewer) {
      finish();
    }
  }, 30000);
  activeViewer = {
    controller,
    cancel() {
      cancelled = true;
      afterClose = null;
      if (viewer) {
        close();
        finish();
      }
    }
  };
  return true;
}
function decorateContentImages(element, options = {}) {
  if (controllers.has(element)) {
    return () => {};
  }
  const restores = [prepareContentImages(element, options.previewLabel)];
  const controller = {
    element,
    destroyed: false
  };
  controllers.set(element, controller);
  let pending = false;
  const click = async event => {
    const target = event.target;
    if (target.matches?.("img")) {
      const ownedLink = target.closest(".isbf-content-image-link");
      if (ownedLink && ownedLink.contains(target)) {
        const source = contentImageUrl(target.getAttribute("data-large-src") || target.getAttribute("data-orig-src") || target.getAttribute("src"));
        if (!source) {
          event.preventDefault();
          event.stopImmediatePropagation();
          return;
        }
        ownedLink.href = source;
        imageDimensions(ownedLink, target);
      } else if (!target.closest(".lightbox")) {
        restores.push(prepareContentImages(element, options.previewLabel));
      }
    }
    const item = target.closest?.(".lightbox");
    if (!item || !element.contains(item) || item.closest(".spoiler, .spoiled") || event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
      return;
    }
    event.preventDefault();
    event.stopImmediatePropagation();
    if (pending || activeViewer || controller.destroyed) {
      return;
    }
    pending = true;
    try {
      const items = sortLightboxItems([...element.querySelectorAll(".lightbox")].filter(entry => !entry.closest(".spoiler, .spoiled")));
      const sourceOf = entry => [entry.href || entry.dataset.largeSrc, entry.querySelector("img")?.getAttribute("src")].join("|");
      const sources = items.map(sourceOf);
      const gallery = element.ownerDocument.createElement("div");
      const copies = items.map(entry => {
        const copy = entry.cloneNode(true);
        // Native initialization is cached and does not expose teardown. A fresh
        // snapshot avoids stale galleries and duplicate handlers on rendered links.
        copy.closest = selector => entry.closest(selector);
        copy.getBoundingClientRect = () => entry.getBoundingClientRect();
        const image = copy.querySelector("img");
        const original = entry.querySelector("img");
        if (image && original) {
          image.getBoundingClientRect = () => original.getBoundingClientRect();
        }
        gallery.append(copy);
        return copy;
      });
      await lightbox(gallery, options.post ? {
        post: options.post
      } : {});
      if (controller.destroyed || !element.isConnected || !element.contains(item) || items.some((entry, index) => !element.contains(entry) || sourceOf(entry) !== sources[index])) {
        return;
      }
      if (watchViewer(controller, item, options)) {
        copies[items.indexOf(item)]?.click();
      }
    } catch (error) {
      if (!controller.destroyed) {
        options.onError?.(error);
      }
    } finally {
      pending = false;
    }
  };
  element.addEventListener("click", click, true);
  return () => {
    controller.destroyed = true;
    element.removeEventListener("click", click, true);
    if (activeViewer?.controller === controller) {
      activeViewer.cancel();
    }
    controllers.delete(element);
    for (const restore of restores.reverse()) {
      restore();
    }
  };
}
var Mod104 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  contentImageUrl: contentImageUrl,
  decorateContentImages: decorateContentImages,
  isImageAttachment: isImageAttachment,
  prepareContentImages: prepareContentImages
});
var contentImages = modifier(element => decorateContentImages(element, {
  onError: popupAjaxError,
  previewLabel: i18n(themePrefix("isbf_v2.preview_image")),
  retryLabel: i18n(themePrefix("isbf_v2.image_retry"))
}));
var Mod105 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: contentImages
});
const __discourseComponentClass$5 = setComponentTemplate(createTemplateFactory(
/*
  <article class="isbf-marketplace-card" ...attributes {{contentImages}}>
  {{#if @imageUrl}}
    <a
      aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
      class="lightbox isbf-marketplace-card__image"
      href={{@imageUrl}}
    ><img alt={{@topic.title}} loading="lazy" src={{@image}} /></a>
  {{else}}
    <span aria-hidden="true" class="isbf-marketplace-card__image">
      {{#if @image}}<img alt="" loading="lazy" src={{@image}} />{{/if}}
    </span>
  {{/if}}
  <a class="isbf-marketplace-card__content" href={{@topic.url}}>
    <strong class="isbf-marketplace-card__title">{{@topic.title}}</strong>
    <span class="isbf-marketplace-card__description">{{@description}}</span>
    {{yield}}
  </a>
</article>
*/
{
  "id": null,
  "block": "[[[11,\"article\"],[24,0,\"isbf-marketplace-card\"],[17,1],[4,[32,0],null,null],[12],[1,\"\\n\"],[41,[30,2],[[[1,\"    \"],[10,3],[15,\"aria-label\",[28,[32,1],[[28,[32,2],[\"isbf_v2.preview_image\"],null]],null]],[14,0,\"lightbox isbf-marketplace-card__image\"],[15,6,[30,2]],[12],[10,\"img\"],[15,\"alt\",[30,3,[\"title\"]]],[14,\"loading\",\"lazy\"],[15,\"src\",[30,4]],[12],[13],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-marketplace-card__image\"],[12],[1,\"\\n      \"],[41,[30,4],[[[10,\"img\"],[14,\"alt\",\"\"],[14,\"loading\",\"lazy\"],[15,\"src\",[30,4]],[12],[13]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]]],[1,\"  \"],[10,3],[14,0,\"isbf-marketplace-card__content\"],[15,6,[30,3,[\"url\"]]],[12],[1,\"\\n    \"],[10,\"strong\"],[14,0,\"isbf-marketplace-card__title\"],[12],[1,[30,3,[\"title\"]]],[13],[1,\"\\n    \"],[10,1],[14,0,\"isbf-marketplace-card__description\"],[12],[1,[30,5]],[13],[1,\"\\n    \"],[18,6,null],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"&attrs\",\"@imageUrl\",\"@topic\",\"@image\",\"@description\",\"&default\"],[\"if\",\"yield\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    contentImages,
    i18n,
    themePrefix
  }),
  "isStrictMode": true
}), templateOnly());
registerModuleForModifyClass("isbf-workbench-listing-card", __discourseComponentClass$5);
var Mod165 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass$5
});
class ISBFCareersSalary extends Component {
  get salary() {
    const post = this.args.outletArgs?.post;
    if (post && post.post_number !== 1) {
      return "";
    }
    return careersSalary((this.args.metadata ?? post?.isbf_careers ?? post?.topic?.isbf_careers)?.salary);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.salary}}<span
        class="isbf-careers-salary"
      >{{this.salary}}</span>{{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"salary\"]],[[[10,1],[14,0,\"isbf-careers-salary\"],[12],[1,[30,0,[\"salary\"]]],[13]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "isStrictMode": true
    }), this);
  }
}
class ISBFCareersCard extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "previewImage", [tracked], function () {
      return null;
    });
  }
  #previewImage = (dt7948.i(this, "previewImage"), void 0);
  #imageOwner;
  #imageUserId;
  #request = 0;
  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }
  get description() {
    return plainText(this.args.topic.isbf_careers?.description || this.args.topic.excerpt);
  }
  get image() {
    return careersImageUrl(this.args.topic.image_url) || (this.#imageOwner === this.args.topic && this.#imageUserId === this.currentUser?.id ? this.previewImage : null);
  }
  async loadImage() {
    const topic = this.args.topic;
    const postId = Number(topic.first_post_id);
    const userId = this.currentUser?.id;
    const request = ++this.#request;
    this.previewImage = null;
    this.#imageOwner = topic;
    this.#imageUserId = userId;
    if (careersImageUrl(topic.image_url) || !userId || !Number.isSafeInteger(postId) || postId <= 0 || topic.hidden) {
      return;
    }
    try {
      const cooked = await loadCookedPost(postId);
      if (!this.isDestroying && request === this.#request && this.args.topic === topic && this.currentUser?.id === userId && Number(topic.first_post_id) === postId && !topic.hidden) {
        this.previewImage = careersImageUrl(postPreview(cooked).images[0]?.src);
      }
    } catch {
      // The native topic link remains usable when a cover cannot be loaded.
    }
  }
  static {
    dt7948.n(this.prototype, "loadImage", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFWorkbenchListingCard
      class="isbf-careers-card"
      @description={{this.description}}
      @image={{this.image}}
      @imageUrl={{this.image}}
      @topic={{@topic}}
      {{didInsert this.loadImage}}
      {{didUpdate
        this.loadImage
        @topic
        @topic.image_url
        @topic.first_post_id
        @topic.hidden
        this.currentUser.id
      }}
    >
      <ISBFCareersSalary @metadata={{@topic.isbf_careers}} />
    </ISBFWorkbenchListingCard>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-careers-card\"],[4,[32,1],[[30,0,[\"loadImage\"]]],null],[4,[32,2],[[30,0,[\"loadImage\"]],[30,1],[30,1,[\"image_url\"]],[30,1,[\"first_post_id\"]],[30,1,[\"hidden\"]],[30,0,[\"currentUser\",\"id\"]]],null]],[[\"@description\",\"@image\",\"@imageUrl\",\"@topic\"],[[30,0,[\"description\"]],[30,0,[\"image\"]],[30,0,[\"image\"]],[30,1]]],[[\"default\"],[[[[1,\"\\n  \"],[8,[32,3],null,[[\"@metadata\"],[[30,1,[\"isbf_careers\"]]]],null],[1,\"\\n\"]],[]]]]]],[\"@topic\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFWorkbenchListingCard: __discourseComponentClass$5,
        didInsert,
        didUpdate,
        ISBFCareersSalary
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-careers-card", ISBFCareersCard);
var Mod162 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFCareersSalary: ISBFCareersSalary,
  default: ISBFCareersCard
});
class ISBFWorkbenchTopicPage extends Component {
  static {
    dt7948.g(this.prototype, "isbfBackNavigation", [service]);
  }
  #isbfBackNavigation = (dt7948.i(this, "isbfBackNavigation"), void 0);
  get labels() {
    const prefix = this.args.kind;
    return Object.fromEntries(["back", "empty", "error", "login", "publish", "unavailable"].map(key => [key, i18n(themePrefix(`isbf_v2.${prefix}_${key}`))]));
  }
  get title() {
    return i18n(themePrefix(`isbf_v2.workbench_${this.args.kind}`));
  }
  get backHref() {
    return this.isbfBackNavigation.href("/isbf/workbench");
  }
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }
  static {
    dt7948.n(this.prototype, "goBack", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main
      aria-busy={{@loading}}
      class="isbf-workbench-topic-page"
      ...attributes
    >
      <header class="isbf-marketplace__header">
        <a
          aria-label={{i18n "back_button"}}
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >{{dIcon "arrow-left"}}</a>
        <h1>{{this.title}}</h1>
      </header>
      {{#if @config}}
        {{#if @currentUser}}
          {{yield}}
          {{#if @loading}}
            <p class="isbf-marketplace__notice" role="status">{{i18n
                (themePrefix "isbf_v2.learning_loading")
              }}</p>
          {{else if @error}}
            <p
              class="isbf-marketplace__notice"
              role="alert"
            >{{this.labels.error}}</p>
            <DButton
              @action={{@onRetry}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />
          {{else if @canLoadMore}}
            <DButton
              @action={{@onLoadMore}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
            />
          {{else}}
            {{#unless @hasTopics}}
              <p class="isbf-marketplace__notice">{{this.labels.empty}}</p>
            {{/unless}}
          {{/if}}
          {{#if @canCreate}}
            <DButton
              class="btn-primary isbf-marketplace__create"
              @action={{@onCreate}}
              @icon="plus"
              @translatedLabel={{this.labels.publish}}
            />
          {{/if}}
        {{else}}
          <div class="isbf-marketplace__notice">
            <p>{{this.labels.login}}</p>
            <DButton @action={{@onLogin}} @label="log_in" />
          </div>
        {{/if}}
      {{else}}
        <p class="isbf-marketplace__notice">{{this.labels.unavailable}}</p>
      {{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[11,\"main\"],[16,\"aria-busy\",[30,1]],[24,0,\"isbf-workbench-topic-page\"],[17,2],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-marketplace__header\"],[12],[1,\"\\n    \"],[11,3],[16,\"aria-label\",[28,[32,0],[\"back_button\"],null]],[16,6,[30,0,[\"backHref\"]]],[4,[32,1],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,[28,[32,2],[\"arrow-left\"],null]],[13],[1,\"\\n    \"],[10,\"h1\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[41,[30,3],[[[41,[30,4],[[[1,\"      \"],[18,13,null],[1,\"\\n\"],[41,[30,1],[[[1,\"        \"],[10,2],[14,0,\"isbf-marketplace__notice\"],[14,\"role\",\"status\"],[12],[1,[28,[32,0],[[28,[32,3],[\"isbf_v2.learning_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,5],[[[1,\"        \"],[10,2],[14,0,\"isbf-marketplace__notice\"],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"labels\",\"error\"]]],[13],[1,\"\\n        \"],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,6],[28,[32,0],[[28,[32,3],[\"isbf_v2.explore_retry\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[41,[30,7],[[[1,\"        \"],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[30,8],[28,[32,0],[[28,[32,3],[\"isbf_v2.load_more\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[41,[51,[30,9]],[[[1,\"          \"],[10,2],[14,0,\"isbf-marketplace__notice\"],[12],[1,[30,0,[\"labels\",\"empty\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"      \"]],[]]]],[]]]],[]]],[41,[30,10],[[[1,\"        \"],[8,[32,4],[[24,0,\"btn-primary isbf-marketplace__create\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[30,11],\"plus\",[30,0,[\"labels\",\"publish\"]]]],null],[1,\"\\n\"]],[]],null]],[]],[[[1,\"      \"],[10,0],[14,0,\"isbf-marketplace__notice\"],[12],[1,\"\\n        \"],[10,2],[12],[1,[30,0,[\"labels\",\"login\"]]],[13],[1,\"\\n        \"],[8,[32,4],null,[[\"@action\",\"@label\"],[[30,12],\"log_in\"]],null],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]]]],[]],[[[1,\"    \"],[10,2],[14,0,\"isbf-marketplace__notice\"],[12],[1,[30,0,[\"labels\",\"unavailable\"]]],[13],[1,\"\\n\"]],[]]],[13]],[\"@loading\",\"&attrs\",\"@config\",\"@currentUser\",\"@error\",\"@onRetry\",\"@canLoadMore\",\"@onLoadMore\",\"@hasTopics\",\"@canCreate\",\"@onCreate\",\"@onLogin\",\"&default\"],[\"if\",\"yield\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        on,
        dIcon,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-workbench-topic-page", ISBFWorkbenchTopicPage);
var Mod111 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFWorkbenchTopicPage
});
class ISBFCareers extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "topicList", [tracked], function () {
      return null;
    });
  }
  #topicList = (dt7948.i(this, "topicList"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  #request = 0;
  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.load);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }
  get config() {
    return careersConfig(this.site);
  }
  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }
  get canCreate() {
    return Boolean(this.config?.publishing_enabled !== false && this.currentUser && this.site.categories?.find(category => category.id === this.config?.category_id)?.canCreateTopic);
  }
  login() {
    this.appEvents.trigger("show-login");
  }
  static {
    dt7948.n(this.prototype, "login", [action]);
  }
  create() {
    if (!this.canCreate) {
      return;
    }
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: Composer.NEW_TOPIC_KEY
    });
  }
  static {
    dt7948.n(this.prototype, "create", [action]);
  }
  async load() {
    if (!this.config || !this.currentUser || this.loading) {
      return;
    }
    const request = ++this.#request;
    const userId = this.currentUser?.id;
    const config = this.config;
    this.loading = true;
    this.error = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: careersQuery()
      });
      if (this.#isCurrent(request, userId, config)) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (this.#isCurrent(request, userId, config)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request, userId, config)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async loadMore() {
    if (!this.currentUser || !this.config || this.loading || !this.canLoadMore) {
      return;
    }
    const request = ++this.#request;
    const userId = this.currentUser?.id;
    const config = this.config;
    this.loading = true;
    this.error = false;
    const list = this.topicList;
    try {
      await list.loadMore();
      if (this.#isCurrent(request, userId, config)) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (this.#isCurrent(request, userId, config)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request, userId, config)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  #isCurrent(request, userId, config) {
    return !this.isDestroying && request === this.#request && this.currentUser?.id === userId && this.config === config;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFWorkbenchTopicPage
      class="isbf-careers"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="careers"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFCareersCard @topic={{topic}} />
      {{/each}}
    </ISBFWorkbenchTopicPage>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-careers\"]],[[\"@canCreate\",\"@canLoadMore\",\"@config\",\"@currentUser\",\"@error\",\"@hasTopics\",\"@kind\",\"@loading\",\"@onCreate\",\"@onLoadMore\",\"@onLogin\",\"@onRetry\"],[[30,0,[\"canCreate\"]],[30,0,[\"canLoadMore\"]],[30,0,[\"config\"]],[30,0,[\"currentUser\"]],[30,0,[\"error\"]],[30,0,[\"topics\",\"length\"]],\"careers\",[30,0,[\"loading\"]],[30,0,[\"create\"]],[30,0,[\"loadMore\"]],[30,0,[\"login\"]],[30,0,[\"retry\"]]]],[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"    \"],[8,[32,1],null,[[\"@topic\"],[[30,1]]],null],[1,\"\\n\"]],[1]],null]],[]]]]]],[\"topic\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFWorkbenchTopicPage,
        ISBFCareersCard
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-careers", ISBFCareers);
var Mod164 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCareers
});
function normalizeExplorePreferences(preferences = {}) {
  const ids = values => [...new Set((values || []).map(Number))].filter(id => Number.isSafeInteger(id) && id > 0);
  return {
    category_ids: ids(preferences.category_ids),
    tag_ids: ids(preferences.tag_ids),
    order: preferences.order === "hot" ? "hot" : "activity"
  };
}
function preferencesSignature(preferences) {
  return JSON.stringify(normalizeExplorePreferences(preferences));
}
function createExplorePreferenceWriter({
  save,
  onSaved,
  onState,
  delay = 300
}) {
  let cancelled = false;
  let failed = false;
  let pending = null;
  let saving = false;
  let timer;
  async function flush() {
    clearTimeout(timer);
    timer = null;
    if (cancelled || failed || saving || !pending) {
      return;
    }
    const snapshot = pending;
    pending = null;
    saving = true;
    onState("saving");
    try {
      const result = await save(snapshot);
      if (!cancelled) {
        onSaved?.(snapshot, result);
      }
    } catch {
      if (!cancelled) {
        pending ||= snapshot;
        failed = true;
        onState("failed");
      }
    } finally {
      saving = false;
      if (!cancelled && !failed) {
        if (pending) {
          timer = setTimeout(flush, delay);
        } else {
          onState("saved");
        }
      }
    }
  }
  return {
    cancel() {
      cancelled = true;
      pending = null;
      clearTimeout(timer);
    },
    retry() {
      failed = false;
      return flush();
    },
    update(preferences) {
      if (cancelled) {
        return;
      }
      pending = normalizeExplorePreferences(preferences);
      clearTimeout(timer);
      if (!failed && !saving) {
        onState("pending");
        timer = setTimeout(flush, delay);
      }
    }
  };
}
var Mod41 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  createExplorePreferenceWriter: createExplorePreferenceWriter,
  normalizeExplorePreferences: normalizeExplorePreferences,
  preferencesSignature: preferencesSignature
});
const queue = [];
let activeRequests = 0;
function runJob(job) {
  activeRequests += 1;
  Promise.resolve().then(job.work).then(job.resolve, job.reject).finally(() => {
    activeRequests -= 1;
    runQueue();
  });
}
function runQueue() {
  while (activeRequests < 2 && queue.length) {
    const job = queue.shift();
    if (!job.isCurrent()) {
      job.resolve(null);
      continue;
    }
    runJob(job);
  }
}
function enqueueExploreQuery(work, isCurrent = () => true) {
  return new Promise((resolve, reject) => {
    queue.push({
      isCurrent,
      reject,
      resolve,
      work
    });
    runQueue();
  });
}
function categoryFilterId(category) {
  const id = Number(category?.id);
  return Number.isInteger(id) && id > 0 && id <= 2147483647 ? id : null;
}
function buildExploreQuery({
  categoryId,
  tags = [],
  order = "activity"
}) {
  const clauses = [];
  if (categoryId !== undefined) {
    const id = categoryFilterId({
      id: categoryId
    });
    if (id === null) {
      throw new Error("Invalid explore category ID");
    }
    clauses.push(`isbf-category:${id}`);
  }
  if (tags.length) {
    clauses.push(`tag:${[...new Set(tags)].join(",")}`);
  }
  clauses.push(`order:${order === "hot" ? "hot" : "activity"}`);
  return clauses.join(" ");
}
function uniqueTopicList(topics) {
  const seen = new Set();
  return Array.from(topics || []).filter(topic => {
    if (seen.has(topic.id)) {
      return false;
    }
    seen.add(topic.id);
    return true;
  });
}
var Mod43 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  buildExploreQuery: buildExploreQuery,
  categoryFilterId: categoryFilterId,
  enqueueExploreQuery: enqueueExploreQuery,
  uniqueTopicList: uniqueTopicList
});
function previewForHeights(heights, budget) {
  let count = 0;
  let height = 0;
  for (const itemHeight of heights) {
    if (!Number.isFinite(itemHeight) || itemHeight <= 0) {
      return {
        complete: false,
        count
      };
    }
    if (count > 0 && height + itemHeight > Math.max(0, budget)) {
      return {
        complete: true,
        count
      };
    }
    count += 1;
    height += itemHeight;
  }
  return {
    complete: true,
    count
  };
}
function explorePreviewBudget(root) {
  const viewport = window.visualViewport;
  const height = viewport?.height || window.innerHeight;
  const offset = viewport?.offsetTop || 0;
  const occupied = [];
  for (const element of document.querySelectorAll(".d-header, .isbf-v2-feed-header, .isbf-v2-page-header, .isbf-v2-section-heading, .isbf-explore__toolbar, .isbf-explore__status, .isbf-explore__error, .isbf-v2-mobile-nav")) {
    const rect = element.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0 || rect.bottom <= offset || rect.top >= offset + height) {
      continue;
    }
    occupied.push([Math.max(0, rect.top - offset), Math.min(height, rect.bottom - offset)]);
  }
  occupied.sort((a, b) => a[0] - b[0]);
  let occupiedHeight = 0;
  let previousEnd = 0;
  for (const [start, end] of occupied) {
    if (end > previousEnd) {
      occupiedHeight += end - Math.max(start, previousEnd);
      previousEnd = end;
    }
  }
  const header = root.querySelector(".isbf-explore-group__header");
  const footer = root.querySelector(".isbf-explore-group__footer");
  return Math.max(0, height - occupiedHeight - (header?.getBoundingClientRect().height || 0) - (footer?.getBoundingClientRect().height || 0));
}
var Mod42 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  explorePreviewBudget: explorePreviewBudget,
  previewForHeights: previewForHeights
});
function createViewTracker(endpoint, idParameter) {
  const counts = new Map();
  const requests = new Map();
  const pendingKeys = new Set();
  let timer;
  async function flush() {
    const keys = [...pendingKeys].slice(0, 50);
    keys.forEach(key => pendingKeys.delete(key));
    timer = null;
    try {
      const result = await ajax(endpoint, {
        data: {
          [idParameter]: keys.map(key => requests.get(key).id)
        },
        type: "POST"
      });
      keys.forEach(key => {
        const request = requests.get(key);
        const value = result.counts?.[request.id];
        const count = typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : null;
        if (count !== null) {
          counts.set(key, count);
        }
        request.resolve(count);
        requests.delete(key);
      });
    } catch {
      keys.forEach(key => {
        requests.get(key)?.resolve(null);
        requests.delete(key);
      });
    }
    if (pendingKeys.size) {
      timer = setTimeout(flush, 40);
    }
  }
  return function recordVisibleView(id, userId) {
    const key = userId + ":" + id;
    if (counts.has(key)) {
      return Promise.resolve(counts.get(key));
    }
    if (requests.has(key)) {
      return requests.get(key).promise;
    }
    let resolve;
    const promise = new Promise(done => {
      resolve = done;
    });
    requests.set(key, {
      promise,
      resolve,
      id
    });
    pendingKeys.add(key);
    timer ??= setTimeout(flush, 40);
    return promise;
  };
}
var Mod32 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  createViewTracker: createViewTracker
});
const recordVisibleView = createViewTracker("/isbf/views/impressions", "topic_ids");
const recordVisiblePostView = createViewTracker("/isbf/views/post-impressions", "post_ids");
var Mod18 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  recordVisiblePostView: recordVisiblePostView,
  recordVisibleView: recordVisibleView
});
function isPinningContext(router, site, siteSettings) {
  if (site?.isbf_pinning?.enabled !== true) {
    return false;
  }
  const path = (router?.currentURL || "").split(/[?#]/)[0].replace(/\/$/, "") || "/";
  if (path === "/" || path === "/latest") {
    return true;
  }
  const categoryId = Number(site.isbf_pinning.official_category_id || siteSettings?.academy_official_category);
  const match = path.match(/^\/c\/[^/]+\/(\d+)(?:\/l\/latest)?$/);
  return categoryId > 0 && Number(match?.[1]) === categoryId;
}
function pinningMeta(topic, now = Date.now()) {
  const metadata = topic?.isbf_home_pinning;
  if (!metadata || typeof metadata !== "object") {
    return null;
  }
  return {
    ...metadata,
    active: metadata.scoped === true && metadata.active === true && Number.isFinite(Date.parse(metadata.pinned_at)) && Date.parse(metadata.pinned_until) > now
  };
}
function pinDeadline(value) {
  if (typeof value !== "string") {
    return null;
  }
  const iso = value.replace(/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})\s?([+-]\d{2}:\d{2})$/, "$1T$2:00$3");
  const parts = iso.match(/^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})$/);
  if (!parts || Number(parts[2]) > 23 || Number(parts[3]) > 59 || Number(parts[4] || 0) > 59) {
    return null;
  }
  const calendar = new Date(`${parts[1]}T00:00:00Z`);
  if (!Number.isFinite(calendar.getTime()) || calendar.toISOString().slice(0, 10) !== parts[1]) {
    return null;
  }
  const timestamp = Date.parse(iso);
  return Number.isFinite(timestamp) ? new Date(timestamp) : null;
}
async function saveHomePin(topic, {
  enabled,
  until
}) {
  if (!Number.isSafeInteger(Number(topic?.id)) || Number(topic.id) <= 0) {
    throw new Error("Invalid topic");
  }
  if (enabled && (!until || !Number.isFinite(Date.parse(until)) || Date.parse(until) <= Date.now())) {
    throw new Error("Invalid pin deadline");
  }
  const result = await ajax(`/t/${topic.id}/status`, {
    type: "PUT",
    data: {
      status: "pinned_globally",
      enabled: Boolean(enabled),
      until: enabled ? new Date(until).toISOString() : null,
      isbf_home_pin: true
    }
  });
  const metadata = result?.isbf_home_pinning;
  if (!metadata || typeof metadata.scoped !== "boolean" || typeof metadata.active !== "boolean") {
    throw new Error("Missing pin response");
  }
  if (topic.set) {
    topic.setProperties({
      isbf_home_pinning: metadata,
      ...(enabled ? {} : {
        pinned: false,
        pinned_at: null,
        pinned_until: null,
        latest_created_order_pinned_at: null
      })
    });
  } else {
    Object.assign(topic, {
      isbf_home_pinning: metadata,
      ...(enabled ? {} : {
        pinned: false,
        pinned_at: null,
        pinned_until: null,
        latest_created_order_pinned_at: null
      })
    });
  }
  return metadata;
}
function pinTime(topic, now) {
  const metadata = pinningMeta(topic, now);
  if (metadata?.scoped) {
    return metadata.active ? Date.parse(metadata.pinned_at) : 0;
  }
  return topic.pinned ? Date.parse(topic.latest_created_order_pinned_at) || 0 : 0;
}
function compareHomeTopics(left, right, now = Date.now()) {
  return pinTime(right, now) - pinTime(left, now) || (Date.parse(right.created_at ?? right.createdAt) || 0) - (Date.parse(left.created_at ?? left.createdAt) || 0) || Number(right.id) - Number(left.id);
}
function sortHomePinList(list, now = Date.now()) {
  if (list?.isbfHomePinScope === true && Array.isArray(list.topics)) {
    const topics = [...list.topics].sort((left, right) => compareHomeTopics(left, right, now));
    if (list.set) {
      list.set("topics", topics);
    } else {
      list.topics = topics;
    }
  }
}
class PinExpiryScheduler {
  #lists = new Map();
  #timer;
  #now;
  #setTimer;
  #clearTimer;
  #onChange;
  #enabled;
  constructor({
    onChange,
    enabled = () => true,
    now = Date.now,
    setTimer = (callback, delay) => globalThis.setTimeout(callback, delay),
    clearTimer = timer => globalThis.clearTimeout(timer)
  }) {
    this.#onChange = onChange;
    this.#enabled = enabled;
    this.#now = now;
    this.#setTimer = setTimer;
    this.#clearTimer = clearTimer;
  }
  register(list, onSorted) {
    if (list?.isbfHomePinScope === true) {
      this.#lists.set(list, onSorted);
      this.#schedule();
    }
  }
  remove(list) {
    this.#lists.delete(list);
    this.#schedule();
  }
  refresh() {
    const now = this.#now();
    if (this.#enabled()) {
      for (const [list, onSorted] of this.#lists) {
        if (!list.isDestroying && !list.isDestroyed) {
          sortHomePinList(list, now);
          onSorted?.(list);
        }
      }
      this.#onChange?.(now);
    }
    this.#schedule();
  }
  destroy() {
    this.#clearTimer(this.#timer);
    this.#timer = null;
    this.#lists.clear();
  }
  #schedule() {
    this.#clearTimer(this.#timer);
    this.#timer = null;
    if (!this.#enabled()) {
      return;
    }
    const now = this.#now();
    let next = Infinity;
    for (const list of this.#lists.keys()) {
      if (list.isDestroying || list.isDestroyed) {
        this.#lists.delete(list);
        continue;
      }
      for (const topic of list.topics || []) {
        const metadata = pinningMeta(topic, now);
        if (metadata?.active) {
          next = Math.min(next, Date.parse(metadata.pinned_until));
        }
      }
    }
    if (Number.isFinite(next)) {
      this.#timer = this.#setTimer(() => this.refresh(), Math.min(2147483647, Math.max(1, next - now + 1)));
    }
  }
}
var Mod118 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  PinExpiryScheduler: PinExpiryScheduler,
  compareHomeTopics: compareHomeTopics,
  isPinningContext: isPinningContext,
  pinDeadline: pinDeadline,
  pinningMeta: pinningMeta,
  saveHomePin: saveHomePin,
  sortHomePinList: sortHomePinList
});
function text(node) {
  const copy = node?.cloneNode(true);
  copy?.querySelectorAll("img.emoji").forEach(image => {
    image.replaceWith(document.createTextNode(image.getAttribute("alt") || ""));
  });
  return copy?.textContent?.replace(/\s+/g, " ").trim() || "";
}
function extractFeedPolls(html = "") {
  if (!html || !html.includes("data-poll-name")) {
    return {
      html,
      polls: []
    };
  }
  const element = document.createElement("div");
  element.innerHTML = html;
  const polls = [];
  element.querySelectorAll(".poll[data-poll-name]").forEach(poll => {
    if (poll.closest("aside.quote")) {
      return;
    }
    const options = [...poll.querySelectorAll("li[data-poll-option-id]")].map(option => ({
      id: option.getAttribute("data-poll-option-id"),
      label: text(option)
    }));
    polls.push({
      name: poll.getAttribute("data-poll-name"),
      title: text(poll.querySelector(".poll-title")),
      type: poll.getAttribute("data-poll-type") || "regular",
      options
    });
    (poll.closest(".poll-outer") || poll).remove();
  });
  return {
    html: element.innerHTML,
    polls
  };
}
function buildPollPreviews(descriptors, metadata = []) {
  return descriptors.map(descriptor => {
    const poll = metadata?.find(item => item.name === descriptor.name);
    const options = descriptor.options;
    const actual = poll?.options || [];
    const voters = poll?.voters;
    // Votes are omitted by the native serializer when this viewer cannot see results.
    const visible = actual.length === options.length && actual.length > 0 && options.every(option => actual.some(item => item.id === option.id && Number.isFinite(item.votes) && item.votes >= 0)) && Number.isFinite(voters) && voters >= 0;
    const type = poll?.type || descriptor.type;
    const percentages = new Map();
    const round = optionalRequire("discourse/plugins/poll/lib/even-round");
    if (visible && ["regular", "multiple", "number"].includes(type) && round) {
      const ordered = [...actual].sort((a, b) => b.votes - a.votes || (a.html < b.html ? -1 : 1));
      const values = ordered.map(option => voters ? 100 * option.votes / voters : 0);
      const rounded = voters === 0 ? values : type === "multiple" ? values.map(Math.floor) : round(values);
      ordered.forEach((option, index) => percentages.set(option.id, rounded[index]));
    }
    return {
      name: descriptor.name,
      title: descriptor.title,
      type,
      voters: visible ? voters : null,
      closed: poll?.status === "closed",
      remaining: Math.max(0, options.length - 3),
      options: options.slice(0, 3).map(option => ({
        ...option,
        percentage: percentages.has(option.id) ? percentages.get(option.id) : null
      }))
    };
  });
}
var Mod151 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  buildPollPreviews: buildPollPreviews,
  extractFeedPolls: extractFeedPolls
});
class ISBFFlagModal extends Flag {
  static {
    dt7948.g(this.prototype, "severeConfirmed", [tracked], function () {
      return false;
    });
  }
  #severeConfirmed = (dt7948.i(this, "severeConfirmed"), void 0);
  static {
    dt7948.g(this.prototype, "severeError", [tracked], function () {
      return null;
    });
  }
  #severeError = (dt7948.i(this, "severeError"), void 0);
  static {
    dt7948.g(this.prototype, "severeReason", [tracked], function () {
      return "";
    });
  }
  #severeReason = (dt7948.i(this, "severeReason"), void 0);
  static {
    dt7948.g(this.prototype, "severeStep", [tracked], function () {
      return false;
    });
  }
  #severeStep = (dt7948.i(this, "severeStep"), void 0);
  static {
    dt7948.g(this.prototype, "severeSubmitting", [tracked], function () {
      return false;
    });
  }
  #severeSubmitting = (dt7948.i(this, "severeSubmitting"), void 0);
  get canSevereReport() {
    return this.args.model.canSevereReport?.() === true;
  }
  get severeSubmitEnabled() {
    const length = [...this.severeReason.trim()].length;
    return this.canSevereReport && length >= 10 && length <= 2000 && this.severeConfirmed && !this.severeSubmitting;
  }
  closeReporting() {
    if (!this.severeSubmitting) {
      this.args.closeModal();
    }
  }
  static {
    dt7948.n(this.prototype, "closeReporting", [action]);
  }
  enterSevere() {
    if (this.canSevereReport) {
      this.severeStep = true;
    }
  }
  static {
    dt7948.n(this.prototype, "enterSevere", [action]);
  }
  leaveSevere() {
    if (!this.severeSubmitting) {
      this.severeStep = false;
    }
  }
  static {
    dt7948.n(this.prototype, "leaveSevere", [action]);
  }
  handleReportingKeydown(event) {
    if (this.severeStep) {
      if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        this.submitSevere();
      }
      return;
    }
    this.onKeydown(event);
  }
  static {
    dt7948.n(this.prototype, "handleReportingKeydown", [action]);
  }
  updateConfirmation(event) {
    this.severeConfirmed = event.target.checked;
  }
  static {
    dt7948.n(this.prototype, "updateConfirmation", [action]);
  }
  updateReason(event) {
    this.severeReason = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateReason", [action]);
  }
  async submitSevere() {
    if (!this.severeSubmitEnabled) {
      return;
    }
    this.severeSubmitting = true;
    this.severeError = null;
    try {
      const post = this.args.model.flagModel;
      const result = await ajax("/isbf/moderation/severe-reports", {
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify({
          post_id: post.id,
          reason: this.severeReason.trim(),
          confirmed: true
        })
      });
      if (Number(result.post_id) !== Number(post.id) || result.hidden !== true) {
        throw new Error("Unexpected severe report response");
      }
      post.setProperties({
        cooked: "",
        isbf_severe_report_pending: true
      });
      this.args.model.setHidden();
      this.args.closeModal();
    } catch (error) {
      this.severeError = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.severe_failed"));
    } finally {
      this.severeSubmitting = false;
    }
  }
  static {
    dt7948.n(this.prototype, "submitSevere", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="flag-modal isbf-flag-modal"
      @bodyClass="flag-modal-body"
      @closeModal={{this.closeReporting}}
      @dismissable={{not this.severeSubmitting}}
      @submitOnEnter={{false}}
      @title={{i18n this.title}}
      {{on "keydown" this.handleReportingKeydown}}
    >
      <:body>
        {{#if this.severeStep}}
          <p>{{i18n (themePrefix "isbf_v2.severe_description")}}</p>
          <label for="isbf-severe-reason">{{i18n
              (themePrefix "isbf_v2.severe_reason")
            }}</label>
          <textarea
            aria-describedby="isbf-severe-hint"
            disabled={{this.severeSubmitting}}
            id="isbf-severe-reason"
            value={{this.severeReason}}
            {{on "input" this.updateReason}}
          ></textarea>
          <p class="isbf-flag-modal__hint" id="isbf-severe-hint">{{i18n
              (themePrefix "isbf_v2.severe_hint")
            }}</p>
          <label class="isbf-flag-modal__confirmation">
            <input
              checked={{this.severeConfirmed}}
              disabled={{this.severeSubmitting}}
              type="checkbox"
              {{on "change" this.updateConfirmation}}
            />
            {{i18n (themePrefix "isbf_v2.severe_confirm")}}
          </label>
          {{#if this.severeError}}<p
              class="isbf-flag-modal__error"
              role="alert"
            >{{this.severeError}}</p>{{/if}}
        {{/if}}
        <div hidden={{this.severeStep}}>
          <p>{{trustHTML (i18n "flagging.review_process_description")}}</p>
          <PluginOutlet
            @connectorTagName="div"
            @name="after-flag-modal-review-process-description"
            @outletArgs={{lazyHash post=@model.flagModel}}
          />
          <form>
            <FlagSelection
              @flags={{this.flagsAvailable}}
              @nameKey={{this.selected.name_key}}
              as |f|
            >
              <FlagActionType
                @changePostActionType={{this.changePostActionType}}
                @flag={{f}}
                @isConfirmed={{this.isConfirmed}}
                @message={{this.message}}
                @selectedFlag={{this.selected}}
                @staffFlagsAvailable={{this.staffFlagsAvailable}}
                @username={{@model.flagModel.username}}
              />
            </FlagSelection>
          </form>
          <PluginOutlet
            @connectorTagName="div"
            @name="flag-modal-bottom"
            @outletArgs={{lazyHash post=@model.flagModel}}
          />
        </div>
      </:body>
      <:footer>
        {{#if this.severeStep}}
          <DButton
            class="btn-danger isbf-flag-modal__severe"
            @action={{this.submitSevere}}
            @disabled={{not this.severeSubmitEnabled}}
            @label={{themePrefix "isbf_v2.severe_submit"}}
            @loading={{this.severeSubmitting}}
          />
          <DButton
            @action={{this.leaveSevere}}
            @disabled={{this.severeSubmitting}}
            @label={{themePrefix "isbf_v2.severe_back"}}
          />
        {{else}}
          <DButton
            class="btn-primary flag-modal__create-flag"
            @action={{this.createFlag}}
            @disabled={{not this.submitEnabled}}
            @icon={{if this.selected.require_message "envelope" "flag"}}
            @label={{this.submitLabel}}
            @title="flagging.submit_tooltip"
          />
          {{#if this.canSevereReport}}
            <DButton
              class="btn-danger isbf-flag-modal__severe"
              @action={{this.enterSevere}}
              @icon="triangle-exclamation"
              @label={{themePrefix "isbf_v2.severe_report"}}
            />
          {{/if}}
          {{#if this.canSendWarning}}
            <DButton
              class="btn-danger flag-modal__send-warning"
              @action={{this.createFlagAsWarning}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.official_warning"
            />
          {{/if}}
          {{#if this.canTakeAction}}
            <ReviewableBundledAction
              class="flag-modal__take-action"
              @bundle={{this.flagActions}}
              @performAction={{this.takeAction}}
              @reviewableUpdating={{not this.submitEnabled}}
            />
            <DButton
              class="btn-danger flag-modal__flag-for-review"
              @action={{this.flagForReview}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.flag_for_review"
            />
          {{/if}}
          {{#if this.showDeleteSpammer}}
            <DButton
              class="btn-danger delete-spammer flag-modal__delete-spammer"
              @action={{this.deleteSpammer}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.delete_spammer"
            />
          {{/if}}
        {{/if}}
      </:footer>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"flag-modal isbf-flag-modal\"],[4,[32,3],[\"keydown\",[30,0,[\"handleReportingKeydown\"]]],null]],[[\"@bodyClass\",\"@closeModal\",\"@dismissable\",\"@submitOnEnter\",\"@title\"],[\"flag-modal-body\",[30,0,[\"closeReporting\"]],[28,[32,1],[[30,0,[\"severeSubmitting\"]]],null],false,[28,[32,2],[[30,0,[\"title\"]]],null]]],[[\"body\",\"footer\"],[[[[1,\"\\n\"],[41,[30,0,[\"severeStep\"]],[[[1,\"      \"],[10,2],[12],[1,[28,[32,2],[[28,[32,4],[\"isbf_v2.severe_description\"],null]],null]],[13],[1,\"\\n      \"],[10,\"label\"],[14,\"for\",\"isbf-severe-reason\"],[12],[1,[28,[32,2],[[28,[32,4],[\"isbf_v2.severe_reason\"],null]],null]],[13],[1,\"\\n      \"],[11,\"textarea\"],[24,\"aria-describedby\",\"isbf-severe-hint\"],[16,\"disabled\",[30,0,[\"severeSubmitting\"]]],[24,1,\"isbf-severe-reason\"],[16,2,[30,0,[\"severeReason\"]]],[4,[32,3],[\"input\",[30,0,[\"updateReason\"]]],null],[12],[13],[1,\"\\n      \"],[10,2],[14,0,\"isbf-flag-modal__hint\"],[14,1,\"isbf-severe-hint\"],[12],[1,[28,[32,2],[[28,[32,4],[\"isbf_v2.severe_hint\"],null]],null]],[13],[1,\"\\n      \"],[10,\"label\"],[14,0,\"isbf-flag-modal__confirmation\"],[12],[1,\"\\n        \"],[11,\"input\"],[16,\"checked\",[30,0,[\"severeConfirmed\"]]],[16,\"disabled\",[30,0,[\"severeSubmitting\"]]],[24,4,\"checkbox\"],[4,[32,3],[\"change\",[30,0,[\"updateConfirmation\"]]],null],[12],[13],[1,\"\\n        \"],[1,[28,[32,2],[[28,[32,4],[\"isbf_v2.severe_confirm\"],null]],null]],[1,\"\\n      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"severeError\"]],[[[10,2],[14,0,\"isbf-flag-modal__error\"],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"severeError\"]]],[13]],[]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[10,0],[15,\"hidden\",[30,0,[\"severeStep\"]]],[12],[1,\"\\n      \"],[10,2],[12],[1,[28,[32,5],[[28,[32,2],[\"flagging.review_process_description\"],null]],null]],[13],[1,\"\\n      \"],[8,[32,6],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"after-flag-modal-review-process-description\",[28,[32,7],null,[[\"post\"],[[30,1,[\"flagModel\"]]]]]]],null],[1,\"\\n      \"],[10,\"form\"],[12],[1,\"\\n        \"],[8,[32,8],null,[[\"@flags\",\"@nameKey\"],[[30,0,[\"flagsAvailable\"]],[30,0,[\"selected\",\"name_key\"]]]],[[\"default\"],[[[[1,\"\\n          \"],[8,[32,9],null,[[\"@changePostActionType\",\"@flag\",\"@isConfirmed\",\"@message\",\"@selectedFlag\",\"@staffFlagsAvailable\",\"@username\"],[[30,0,[\"changePostActionType\"]],[30,2],[30,0,[\"isConfirmed\"]],[30,0,[\"message\"]],[30,0,[\"selected\"]],[30,0,[\"staffFlagsAvailable\"]],[30,1,[\"flagModel\",\"username\"]]]],null],[1,\"\\n        \"]],[2]]]]],[1,\"\\n      \"],[13],[1,\"\\n      \"],[8,[32,6],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"flag-modal-bottom\",[28,[32,7],null,[[\"post\"],[[30,1,[\"flagModel\"]]]]]]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"]],[]],[[[1,\"\\n\"],[41,[30,0,[\"severeStep\"]],[[[1,\"      \"],[8,[32,10],[[24,0,\"btn-danger isbf-flag-modal__severe\"]],[[\"@action\",\"@disabled\",\"@label\",\"@loading\"],[[30,0,[\"submitSevere\"]],[28,[32,1],[[30,0,[\"severeSubmitEnabled\"]]],null],[28,[32,4],[\"isbf_v2.severe_submit\"],null],[30,0,[\"severeSubmitting\"]]]],null],[1,\"\\n      \"],[8,[32,10],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"leaveSevere\"]],[30,0,[\"severeSubmitting\"]],[28,[32,4],[\"isbf_v2.severe_back\"],null]]],null],[1,\"\\n\"]],[]],[[[1,\"      \"],[8,[32,10],[[24,0,\"btn-primary flag-modal__create-flag\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\",\"@title\"],[[30,0,[\"createFlag\"]],[28,[32,1],[[30,0,[\"submitEnabled\"]]],null],[52,[30,0,[\"selected\",\"require_message\"]],\"envelope\",\"flag\"],[30,0,[\"submitLabel\"]],\"flagging.submit_tooltip\"]],null],[1,\"\\n\"],[41,[30,0,[\"canSevereReport\"]],[[[1,\"        \"],[8,[32,10],[[24,0,\"btn-danger isbf-flag-modal__severe\"]],[[\"@action\",\"@icon\",\"@label\"],[[30,0,[\"enterSevere\"]],\"triangle-exclamation\",[28,[32,4],[\"isbf_v2.severe_report\"],null]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"canSendWarning\"]],[[[1,\"        \"],[8,[32,10],[[24,0,\"btn-danger flag-modal__send-warning\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"createFlagAsWarning\"]],[28,[32,1],[[30,0,[\"submitEnabled\"]]],null],\"triangle-exclamation\",\"flagging.official_warning\"]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"canTakeAction\"]],[[[1,\"        \"],[8,[32,11],[[24,0,\"flag-modal__take-action\"]],[[\"@bundle\",\"@performAction\",\"@reviewableUpdating\"],[[30,0,[\"flagActions\"]],[30,0,[\"takeAction\"]],[28,[32,1],[[30,0,[\"submitEnabled\"]]],null]]],null],[1,\"\\n        \"],[8,[32,10],[[24,0,\"btn-danger flag-modal__flag-for-review\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"flagForReview\"]],[28,[32,1],[[30,0,[\"submitEnabled\"]]],null],\"triangle-exclamation\",\"flagging.flag_for_review\"]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"showDeleteSpammer\"]],[[[1,\"        \"],[8,[32,10],[[24,0,\"btn-danger delete-spammer flag-modal__delete-spammer\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"deleteSpammer\"]],[28,[32,1],[[30,0,[\"submitEnabled\"]]],null],\"triangle-exclamation\",\"flagging.delete_spammer\"]],null],[1,\"\\n\"]],[]],null]],[]]],[1,\"  \"]],[]]]]]],[\"@model\",\"f\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        not,
        i18n,
        on,
        themePrefix,
        trustHTML,
        PluginOutlet,
        lazyHash,
        FlagSelection,
        FlagActionType,
        DButton,
        ReviewableBundledAction
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-flag-modal", ISBFFlagModal);
var Mod45 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFFlagModal
});
const hiddenPosts = new Set();
const reportedModels = new Map();
function isReportedHidden(postId) {
  return hiddenPosts.has(Number(postId));
}
function rememberHiddenPost(postId, appEvents, hidden = true, severePending) {
  const id = Number(postId);
  if (!Number.isInteger(id) || id <= 0) {
    return;
  }
  if (hidden) {
    hiddenPosts.add(id);
  } else {
    hiddenPosts.delete(id);
  }
  invalidateCookedPost(id, hidden);
  reportedModels.get(id)?.setProperties({
    cooked: "",
    hidden,
    ...(!hidden || typeof severePending === "boolean" ? {
      isbf_severe_report_pending: hidden && severePending === true
    } : {})
  });
  appEvents.trigger("isbf:post-hidden", id, hidden);
}
function severeReportAvailable(post, siteSettings, site) {
  return Boolean((site?.isbf_severe_reports_enabled ?? siteSettings?.isbf_severe_reports_enabled) === true && post.isbf_can_severe_report && !post.isbf_severe_report_pending && !post.hidden && post.post_type === 1 && post.topic?.archetype !== "private_message");
}
function openPostReport({
  post,
  modal,
  siteSettings,
  site,
  appEvents
}) {
  reportedModels.set(Number(post.id), post);
  return modal.show(post.post_type === 1 && post.topic?.archetype !== "private_message" ? ISBFFlagModal : Flag, {
    model: {
      canSevereReport: () => severeReportAvailable(post, siteSettings, site),
      flagTarget: new PostFlag(),
      flagModel: post,
      setHidden: () => {
        post.set("hidden", true);
        rememberHiddenPost(post.id, appEvents);
      }
    }
  });
}
var Mod46 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  isReportedHidden: isReportedHidden,
  openPostReport: openPostReport,
  rememberHiddenPost: rememberHiddenPost,
  severeReportAvailable: severeReportAvailable
});
function displayName(user) {
  return user?.name?.trim() ? user.name : user?.username;
}
function displayIdentity(user) {
  return user?.name?.trim() && user.username ? `${user.name} @${user.username}` : displayName(user);
}
function notificationDisplayLabel(item, fallback) {
  const notification = item.notification;
  const data = notification.data;
  const director = item.renderDirector;
  const type = director.notificationName;
  if (!fallback || !data.display_username || type === "replied" && data.reply_to_post_number != null && data.consolidated_count > 1) {
    return fallback;
  }
  const name = item.siteSettings.enable_names ? notification.acting_user_name ?? data.display_name : null;
  const actor = displayIdentity({
    name,
    username: data.display_username
  });
  if (type === "liked" || type === "reaction") {
    const count = Number(data.count) || 1;
    const multipleActors = type === "liked" || Boolean(data.username2);
    if (multipleActors && count > 2) {
      return i18n(type === "liked" ? "notifications.liked_by_multiple_users" : "notifications.reaction_multiple_users", {
        username: actor,
        count: count - 1
      });
    }
    if (multipleActors && count === 2 && data.username2) {
      return i18n(type === "liked" ? "notifications.liked_by_2_users" : "notifications.reaction_2_users", {
        username: actor,
        username2: displayIdentity({
          name: item.siteSettings.enable_names ? data.name2 : null,
          username: data.username2
        })
      });
    }
    return actor;
  }
  if (type === "group_mentioned") {
    return `${actor} @${data.group_name}`;
  }
  if (type === "moved_post") {
    return i18n("notifications.user_moved_post", {
      username: actor
    });
  }
  return [director.username, notification.acting_user_name, data.display_name].includes(fallback) ? actor : fallback;
}
var Mod137 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  displayIdentity: displayIdentity,
  displayName: displayName,
  notificationDisplayLabel: notificationDisplayLabel
});
class ISBFHomePinDialog extends Component {
  static {
    dt7948.g(this.prototype, "errorMessage", [tracked], function () {
      return null;
    });
  }
  #errorMessage = (dt7948.i(this, "errorMessage"), void 0);
  static {
    dt7948.g(this.prototype, "isSubmitting", [tracked], function () {
      return false;
    });
  }
  #isSubmitting = (dt7948.i(this, "isSubmitting"), void 0);
  static {
    dt7948.g(this.prototype, "until", [tracked]);
  }
  #until = (dt7948.i(this, "until"), void 0);
  #closed = false;
  constructor() {
    super(...arguments);
    const metadata = pinningMeta(this.args.model.topic);
    this.until = metadata?.active ? metadata.pinned_until : new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }
  get title() {
    return i18n(themePrefix(pinningMeta(this.args.model.topic)?.active ? "isbf_v2.pin_update" : "isbf_v2.pin"));
  }
  get submitDisabled() {
    return this.isSubmitting;
  }
  close() {
    this.#closed = true;
    this.args.closeModal();
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  updateUntil(value) {
    if (!this.isSubmitting && !this.#closed) {
      this.until = value;
      this.errorMessage = null;
    }
  }
  static {
    dt7948.n(this.prototype, "updateUntil", [action]);
  }
  async submit(event) {
    event?.preventDefault();
    if (this.#closed || this.isSubmitting) {
      return;
    }
    const timestamp = pinDeadline(this.until)?.getTime() ?? NaN;
    if (!Number.isFinite(timestamp) || timestamp <= Date.now()) {
      this.errorMessage = i18n(themePrefix("isbf_v2.pin_validation"));
      return;
    }
    this.errorMessage = null;
    this.isSubmitting = true;
    try {
      const metadata = await saveHomePin(this.args.model.topic, {
        enabled: true,
        until: new Date(timestamp).toISOString()
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      this.args.model.onSaved?.(metadata);
      this.close();
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.errorMessage = error?.jqXHR?.responseJSON?.errors?.[0] || error?.jqXHR?.responseJSON?.error || i18n(themePrefix("isbf_v2.pin_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.isSubmitting = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "submit", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-home-pin-dialog"
      @closeModal={{this.close}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        <form {{on "submit" this.submit}}>
          <fieldset
            class="isbf-home-pin-dialog__field"
            disabled={{this.isSubmitting}}
          >
            <legend>{{i18n (themePrefix "isbf_v2.pin_until")}}</legend>
            <DFutureDateInput
              @clearable={{false}}
              @includeDateTime={{true}}
              @input={{this.until}}
              @noRelativeOptions={{true}}
              @onChangeInput={{this.updateUntil}}
            />
          </fieldset>
          {{#if this.errorMessage}}
            <p
              class="isbf-home-pin-dialog__error"
              role="alert"
            >{{this.errorMessage}}</p>
          {{/if}}
          <div class="isbf-home-pin-dialog__actions">
            <DButton @action={{this.close}} @label="cancel" />
            <DButton
              class="btn-primary"
              @disabled={{this.submitDisabled}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.pin_save")}}
              @type="submit"
            />
          </div>
        </form>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-home-pin-dialog\"]],[[\"@closeModal\",\"@submitOnEnter\",\"@title\"],[[30,0,[\"close\"]],false,[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[11,\"form\"],[4,[32,1],[\"submit\",[30,0,[\"submit\"]]],null],[12],[1,\"\\n      \"],[10,\"fieldset\"],[14,0,\"isbf-home-pin-dialog__field\"],[15,\"disabled\",[30,0,[\"isSubmitting\"]]],[12],[1,\"\\n        \"],[10,\"legend\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.pin_until\"],null]],null]],[13],[1,\"\\n        \"],[8,[32,4],null,[[\"@clearable\",\"@includeDateTime\",\"@input\",\"@noRelativeOptions\",\"@onChangeInput\"],[false,true,[30,0,[\"until\"]],true,[30,0,[\"updateUntil\"]]]],null],[1,\"\\n      \"],[13],[1,\"\\n\"],[41,[30,0,[\"errorMessage\"]],[[[1,\"        \"],[10,2],[14,0,\"isbf-home-pin-dialog__error\"],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"errorMessage\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,0],[14,0,\"isbf-home-pin-dialog__actions\"],[12],[1,\"\\n        \"],[8,[32,5],null,[[\"@action\",\"@label\"],[[30,0,[\"close\"]],\"cancel\"]],null],[1,\"\\n        \"],[8,[32,5],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@translatedLabel\",\"@type\"],[[30,0,[\"submitDisabled\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.pin_save\"],null]],null],\"submit\"]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"]],[]]]]]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        on,
        i18n,
        themePrefix,
        DFutureDateInput,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-home-pin-dialog", ISBFHomePinDialog);
var Mod117 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFHomePinDialog
});
class ISBFMarketplacePrice extends Component {
  get post() {
    return this.args.outletArgs?.post;
  }
  get metadata() {
    return this.args.metadata ?? this.post?.isbf_marketplace ?? this.post?.topic?.isbf_marketplace;
  }
  get price() {
    if (this.post && this.post.post_number !== 1) {
      return null;
    }
    return marketplacePrice(this.metadata?.price_cents);
  }
  get images() {
    if (this.post?.post_number !== 1 || !this.metadata) {
      return [];
    }
    const body = document.createElement("div");
    body.innerHTML = this.post.cooked || "";
    const sources = [...body.querySelectorAll("img[src]")].map(image => image.getAttribute("src"));
    return marketplaceDetailImages(this.metadata, sources);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.images.length}}
      <div class="isbf-marketplace-detail-images" {{contentImages}}>
        {{#each this.images key="id" as |image|}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
            class="lightbox"
            href={{image.url}}
          ><img
              alt={{this.post.topic.title}}
              loading="lazy"
              src={{image.thumbnail}}
            /></a>
        {{/each}}
      </div>
    {{/if}}
    {{#if this.price}}<span
        class="isbf-marketplace-price"
      >{{this.price}}</span>{{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"images\",\"length\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-marketplace-detail-images\"],[4,[32,0],null,null],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"images\"]]],null]],null],\"id\",[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,1],[[28,[32,2],[\"isbf_v2.preview_image\"],null]],null]],[14,0,\"lightbox\"],[15,6,[30,1,[\"url\"]]],[12],[10,\"img\"],[15,\"alt\",[30,0,[\"post\",\"topic\",\"title\"]]],[14,\"loading\",\"lazy\"],[15,\"src\",[30,1,[\"thumbnail\"]]],[12],[13],[13],[1,\"\\n\"]],[1]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"price\"]],[[[10,1],[14,0,\"isbf-marketplace-price\"],[12],[1,[30,0,[\"price\"]]],[13]],[]],null]],[\"image\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        contentImages,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFMarketplaceCard extends Component {
  get image() {
    const image = this.args.topic.isbf_marketplace?.images?.[0];
    return marketplaceImageUrl(image?.thumbnail_url) || this.imageUrl;
  }
  get imageUrl() {
    return marketplaceImageUrl(this.args.topic.isbf_marketplace?.images?.[0]?.url);
  }
  get description() {
    return plainText(this.args.topic.isbf_marketplace?.description ?? this.args.topic.excerpt);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFWorkbenchListingCard
      @description={{this.description}}
      @image={{this.image}}
      @imageUrl={{this.imageUrl}}
      @topic={{@topic}}
    >
      <ISBFMarketplacePrice @metadata={{@topic.isbf_marketplace}} />
    </ISBFWorkbenchListingCard>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@description\",\"@image\",\"@imageUrl\",\"@topic\"],[[30,0,[\"description\"]],[30,0,[\"image\"]],[30,0,[\"imageUrl\"]],[30,1]]],[[\"default\"],[[[[1,\"\\n  \"],[8,[32,1],null,[[\"@metadata\"],[[30,1,[\"isbf_marketplace\"]]]],null],[1,\"\\n\"]],[]]]]]],[\"@topic\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFWorkbenchListingCard: __discourseComponentClass$5,
        ISBFMarketplacePrice
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-marketplace-card", ISBFMarketplaceCard);
var Mod93 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFMarketplacePrice: ISBFMarketplacePrice,
  default: ISBFMarketplaceCard
});
class ISBFOfficialActivitySummary extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get groups() {
    return officialCalendarGroups(this.args.items).map(group => ({
      ...group,
      showTitle: !officialCalendarTitleDuplicatesTopic(group.item, this.args.topicTitle),
      timeLines: officialActivityTimeLines(group.item),
      locationLabel: officialLocationLabel(group.item.location, this.args.campusIds, officialConfig(this.site), i18n(themePrefix("isbf_v2.official_campus_separator"))),
      timeLabel: group.isEvent ? null : officialTimeLabel(group.item),
      deadlineLabel: group.deadline ? officialTimeLabel(group.deadline) : i18n(themePrefix("isbf_v2.schedule_none"))
    }));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.groups.length}}
      <div class="isbf-official-activity-summary" ...attributes>
        {{#each this.groups as |group|}}
          {{#if group.isEvent}}
            <section
              aria-label={{group.item.title}}
              class="isbf-official-activity-summary__activity"
              data-schedule-id={{group.item.id}}
              role="group"
            >
              {{#if group.showTitle}}
                <h3
                  class="isbf-official-activity-summary__title"
                >{{group.item.title}}</h3>
              {{/if}}
              <dl class="isbf-official-activity-summary__fields">
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n
                      (themePrefix "isbf_v2.schedule_activity_time")
                    }}</dt>
                  <dd>
                    {{#each group.timeLines as |line|}}
                      <span
                        class="isbf-official-activity-summary__time-line"
                      >{{line}}</span>
                    {{/each}}
                  </dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n
                      (themePrefix "isbf_v2.schedule_registration_deadline")
                    }}</dt>
                  <dd>{{group.deadlineLabel}}</dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n (themePrefix "isbf_v2.schedule_location")}}</dt>
                  <dd>{{if
                      group.locationLabel
                      group.locationLabel
                      (i18n (themePrefix "isbf_v2.schedule_not_provided"))
                    }}</dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n (themePrefix "isbf_v2.schedule_organizer")}}</dt>
                  <dd>{{if
                      group.item.organizer
                      group.item.organizer
                      (i18n (themePrefix "isbf_v2.schedule_not_provided"))
                    }}</dd>
                </div>
              </dl>
              {{#if (has-block)}}
                <div class="isbf-official-activity-summary__actions">
                  {{yield group.item}}
                  {{#if group.deadline}}
                    {{yield group.deadline}}
                  {{/if}}
                </div>
              {{/if}}
            </section>
          {{else}}
            <section
              aria-label={{group.item.title}}
              class="isbf-official-activity-summary__deadline"
              data-schedule-id={{group.item.id}}
              role="group"
            >
              {{#if group.showTitle}}
                <strong>{{group.item.title}}</strong>
              {{/if}}
              <span>{{group.timeLabel}}</span>
              {{#if (has-block)}}
                <div class="isbf-official-activity-summary__actions">
                  {{yield group.item}}
                </div>
              {{/if}}
            </section>
          {{/if}}
        {{/each}}
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"groups\",\"length\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-official-activity-summary\"],[17,1],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"groups\"]]],null]],null],null,[[[41,[30,2,[\"isEvent\"]],[[[1,\"        \"],[10,\"section\"],[15,\"aria-label\",[30,2,[\"item\",\"title\"]]],[14,0,\"isbf-official-activity-summary__activity\"],[15,\"data-schedule-id\",[30,2,[\"item\",\"id\"]]],[14,\"role\",\"group\"],[12],[1,\"\\n\"],[41,[30,2,[\"showTitle\"]],[[[1,\"            \"],[10,\"h3\"],[14,0,\"isbf-official-activity-summary__title\"],[12],[1,[30,2,[\"item\",\"title\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,\"dl\"],[14,0,\"isbf-official-activity-summary__fields\"],[12],[1,\"\\n            \"],[10,0],[14,0,\"isbf-official-activity-summary__field\"],[12],[1,\"\\n              \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_activity_time\"],null]],null]],[13],[1,\"\\n              \"],[10,\"dd\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,2,[\"timeLines\"]]],null]],null],null,[[[1,\"                  \"],[10,1],[14,0,\"isbf-official-activity-summary__time-line\"],[12],[1,[30,3]],[13],[1,\"\\n\"]],[3]],null],[1,\"              \"],[13],[1,\"\\n            \"],[13],[1,\"\\n            \"],[10,0],[14,0,\"isbf-official-activity-summary__field\"],[12],[1,\"\\n              \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_registration_deadline\"],null]],null]],[13],[1,\"\\n              \"],[10,\"dd\"],[12],[1,[30,2,[\"deadlineLabel\"]]],[13],[1,\"\\n            \"],[13],[1,\"\\n            \"],[10,0],[14,0,\"isbf-official-activity-summary__field\"],[12],[1,\"\\n              \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_location\"],null]],null]],[13],[1,\"\\n              \"],[10,\"dd\"],[12],[1,[52,[30,2,[\"locationLabel\"]],[30,2,[\"locationLabel\"]],[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_not_provided\"],null]],null]]],[13],[1,\"\\n            \"],[13],[1,\"\\n            \"],[10,0],[14,0,\"isbf-official-activity-summary__field\"],[12],[1,\"\\n              \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_organizer\"],null]],null]],[13],[1,\"\\n              \"],[10,\"dd\"],[12],[1,[52,[30,2,[\"item\",\"organizer\"]],[30,2,[\"item\",\"organizer\"]],[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_not_provided\"],null]],null]]],[13],[1,\"\\n            \"],[13],[1,\"\\n          \"],[13],[1,\"\\n\"],[41,[48,[30,4]],[[[1,\"            \"],[10,0],[14,0,\"isbf-official-activity-summary__actions\"],[12],[1,\"\\n              \"],[18,4,[[30,2,[\"item\"]]]],[1,\"\\n\"],[41,[30,2,[\"deadline\"]],[[[1,\"                \"],[18,4,[[30,2,[\"deadline\"]]]],[1,\"\\n\"]],[]],null],[1,\"            \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"section\"],[15,\"aria-label\",[30,2,[\"item\",\"title\"]]],[14,0,\"isbf-official-activity-summary__deadline\"],[15,\"data-schedule-id\",[30,2,[\"item\",\"id\"]]],[14,\"role\",\"group\"],[12],[1,\"\\n\"],[41,[30,2,[\"showTitle\"]],[[[1,\"            \"],[10,\"strong\"],[12],[1,[30,2,[\"item\",\"title\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,1],[12],[1,[30,2,[\"timeLabel\"]]],[13],[1,\"\\n\"],[41,[48,[30,4]],[[[1,\"            \"],[10,0],[14,0,\"isbf-official-activity-summary__actions\"],[12],[1,\"\\n              \"],[18,4,[[30,2,[\"item\"]]]],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]]]],[2]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"&attrs\",\"group\",\"line\",\"&default\"],[\"if\",\"each\",\"-track-array\",\"has-block\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-activity-summary", ISBFOfficialActivitySummary);
var Mod77 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialActivitySummary
});
function isOfficialCalendarPost(post, site, path, nestedReplyView = false) {
  const categoryId = Number(site?.isbf_official?.category_id ?? site?.isbf_calendar?.official_category_id);
  return Boolean(Number.isSafeInteger(categoryId) && categoryId > 0 && post?.post_number === 1 && Number(post.topic?.category_id ?? post.topic?.categoryId) === categoryId && isFeedStylePost(post, path, nestedReplyView));
}
var Mod146 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  isOfficialCalendarPost: isOfficialCalendarPost
});
class ISBFOfficialCalendarItems extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  #requestGeneration = 0;
  static {
    dt7948.g(this.prototype, "_busyId", [tracked], function () {
      return null;
    });
  }
  #_busyId = (dt7948.i(this, "_busyId"), void 0);
  static {
    dt7948.g(this.prototype, "_entryIds", [tracked], function () {
      return {};
    });
  }
  #_entryIds = (dt7948.i(this, "_entryIds"), void 0);
  static {
    dt7948.g(this.prototype, "_refreshedItems", [tracked], function () {
      return null;
    });
  }
  #_refreshedItems = (dt7948.i(this, "_refreshedItems"), void 0);
  static {
    dt7948.g(this.prototype, "_refreshedCampuses", [tracked], function () {
      return null;
    });
  }
  #_refreshedCampuses = (dt7948.i(this, "_refreshedCampuses"), void 0);
  static {
    dt7948.g(this.prototype, "_refreshedPostId", [tracked], function () {
      return null;
    });
  }
  #_refreshedPostId = (dt7948.i(this, "_refreshedPostId"), void 0);
  constructor() {
    super(...arguments);
    this.appEvents.on("isbf:calendar-entry-changed", this.onEntryChanged);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#requestGeneration++;
    this.appEvents.off("isbf:calendar-entry-changed", this.onEntryChanged);
  }
  get post() {
    return this.args.outletArgs?.post;
  }
  get officialLayout() {
    return isOfficialCalendarPost(this.post, this.site, this.router.currentURL, this.args.outletArgs?.state?.nestedReplyView);
  }
  get topicTitle() {
    return this.args.topicTitle ?? this.post?.topic?.title;
  }
  get campusIds() {
    return (this._refreshedPostId === this.post?.id ? this._refreshedCampuses : null) ?? this.args.campusIds ?? this.post?.isbf_official_campuses ?? this.post?.topic?.isbf_official_campuses;
  }
  get items() {
    const source = (this._refreshedPostId === this.post?.id ? this._refreshedItems : null) ?? this.args.items ?? this.post?.[OFFICIAL_CALENDAR_FIELD] ?? [];
    const multiple = source.filter(item => !item.cancelled).length > 1;
    return source.map(item => {
      const added = Boolean(Object.hasOwn(this._entryIds, item.id) ? this._entryIds[item.id] : item.personal_entry_id);
      return {
        ...item,
        timeLabel: officialTimeLabel(item),
        added,
        busy: this._busyId === item.id,
        addDisabled: Boolean(this._busyId || added || item.cancelled),
        addLabel: themePrefix(added ? "isbf_v2.schedule_added" : !multiple ? "isbf_v2.schedule_add" : item.schedule_kind === "deadline" ? "isbf_v2.schedule_add_deadline" : "isbf_v2.schedule_add_event")
      };
    });
  }
  onEntryChanged({
    source_item_id,
    id,
    removed
  } = {}) {
    if (!this.isDestroying && source_item_id) {
      this._entryIds = {
        ...this._entryIds,
        [source_item_id]: removed ? null : id
      };
    }
  }
  static {
    dt7948.n(this.prototype, "onEntryChanged", [action]);
  }
  async add(item) {
    if (this.args.readOnly || this.isDestroying) {
      return;
    }
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    if (this._busyId || item.added || item.cancelled) {
      return;
    }
    const request = ++this.#requestGeneration;
    const postId = this.post?.id;
    this._busyId = item.id;
    this.error = false;
    try {
      const {
        entry
      } = await ajax(`/isbf/api/official-items/${item.id}/add.json`, {
        type: "POST",
        data: {
          revision: item.revision
        }
      });
      if (this.#isCurrent(request, postId)) {
        this.appEvents.trigger("isbf:calendar-entry-changed", entry);
      }
    } catch (error) {
      if (this.#isCurrent(request, postId)) {
        this.error = true;
        if (error.jqXHR?.status === 409 && postId) {
          try {
            const post = await ajax(`/posts/${postId}.json`);
            if (this.#isCurrent(request, postId)) {
              this._refreshedPostId = postId;
              this._refreshedItems = post[OFFICIAL_CALENDAR_FIELD] ?? [];
              this._refreshedCampuses = post.isbf_official_campuses ?? null;
            }
          } catch {
            if (this.#isCurrent(request, postId)) {
              this.error = true;
            }
          }
        }
      }
    } finally {
      if (!this.isDestroying && request === this.#requestGeneration) {
        this._busyId = null;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "add", [action]);
  }
  #isCurrent(request, postId) {
    return !this.isDestroying && request === this.#requestGeneration && this.post?.id === postId;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.items.length}}
      {{#if this.officialLayout}}
        <ISBFOfficialActivitySummary
          @campusIds={{this.campusIds}}
          @items={{this.items}}
          @topicTitle={{this.topicTitle}}
          as |item|
        >
          {{#unless @readOnly}}
            <DButton
              class="btn-primary"
              @action={{fn this.add item}}
              @disabled={{item.addDisabled}}
              @icon={{if item.added "check" "calendar-days"}}
              @isLoading={{item.busy}}
              @label={{item.addLabel}}
            />
          {{/unless}}
        </ISBFOfficialActivitySummary>
      {{else}}
        <section
          aria-label={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
          class="isbf-official-calendar-items"
        >
          {{#each this.items key="id" as |item|}}
            <div
              class="isbf-official-calendar-items__item"
              data-schedule-id={{item.id}}
            >
              <div class="isbf-official-calendar-items__information">
                <strong>{{item.title}}</strong><span>{{item.timeLabel}}</span>
              </div>
              {{#unless @readOnly}}
                <DButton
                  @action={{fn this.add item}}
                  @disabled={{item.addDisabled}}
                  @icon={{if item.added "check" "calendar-days"}}
                  @isLoading={{item.busy}}
                  @label={{item.addLabel}}
                />
              {{/unless}}
            </div>
          {{/each}}
        </section>
      {{/if}}
      {{#if this.error}}
        <p class="isbf-official-calendar-items__error" role="alert">
          {{i18n (themePrefix "isbf_v2.schedule_add_error")}}
        </p>
      {{/if}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"items\",\"length\"]],[[[41,[30,0,[\"officialLayout\"]],[[[1,\"    \"],[8,[32,0],null,[[\"@campusIds\",\"@items\",\"@topicTitle\"],[[30,0,[\"campusIds\"]],[30,0,[\"items\"]],[30,0,[\"topicTitle\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[51,[30,2]],[[[1,\"        \"],[8,[32,1],[[24,0,\"btn-primary\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@isLoading\",\"@label\"],[[28,[32,2],[[30,0,[\"add\"]],[30,1]],null],[30,1,[\"addDisabled\"]],[52,[30,1,[\"added\"]],\"check\",\"calendar-days\"],[30,1,[\"busy\"]],[30,1,[\"addLabel\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"]],[1]]]]],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,\"section\"],[15,\"aria-label\",[28,[32,3],[[28,[32,4],[\"isbf_v2.schedule_editor_title\"],null]],null]],[14,0,\"isbf-official-calendar-items\"],[12],[1,\"\\n\"],[42,[28,[31,3],[[28,[31,3],[[30,0,[\"items\"]]],null]],null],\"id\",[[[1,\"        \"],[10,0],[14,0,\"isbf-official-calendar-items__item\"],[15,\"data-schedule-id\",[30,3,[\"id\"]]],[12],[1,\"\\n          \"],[10,0],[14,0,\"isbf-official-calendar-items__information\"],[12],[1,\"\\n            \"],[10,\"strong\"],[12],[1,[30,3,[\"title\"]]],[13],[10,1],[12],[1,[30,3,[\"timeLabel\"]]],[13],[1,\"\\n          \"],[13],[1,\"\\n\"],[41,[51,[30,2]],[[[1,\"            \"],[8,[32,1],null,[[\"@action\",\"@disabled\",\"@icon\",\"@isLoading\",\"@label\"],[[28,[32,2],[[30,0,[\"add\"]],[30,3]],null],[30,3,[\"addDisabled\"]],[52,[30,3,[\"added\"]],\"check\",\"calendar-days\"],[30,3,[\"busy\"]],[30,3,[\"addLabel\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[3]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]]],[41,[30,0,[\"error\"]],[[[1,\"    \"],[10,2],[14,0,\"isbf-official-calendar-items__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n      \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.schedule_add_error\"],null]],null]],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null]],[]],null]],[\"item\",\"@readOnly\",\"item\"],[\"if\",\"unless\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFOfficialActivitySummary,
        DButton,
        fn,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-calendar-items", ISBFOfficialCalendarItems);
var Mod61 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialCalendarItems
});
class ISBFPollPreviews extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "data", [tracked], function () {
      return null;
    });
  }
  #data = (dt7948.i(this, "data"), void 0);
  static {
    dt7948.g(this.prototype, "failed", [tracked], function () {
      return false;
    });
  }
  #failed = (dt7948.i(this, "failed"), void 0);
  static {
    dt7948.g(this.prototype, "loadedIdentity", [tracked], function () {
      return null;
    });
  }
  #loadedIdentity = (dt7948.i(this, "loadedIdentity"), void 0);
  #request = 0;
  constructor() {
    super(...arguments);
    this.load();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#request += 1;
  }
  get viewerId() {
    return this.currentUser?.id || null;
  }
  get identity() {
    return `${this.viewerId || "guest"}:${this.args.postId}:${this.args.cooked}`;
  }
  get polls() {
    const current = this.loadedIdentity === this.identity;
    const data = current ? this.data : null;
    const descriptors = extractFeedPolls(data?.cooked ?? this.args.cooked).polls;
    return buildPollPreviews(descriptors, data?.polls).map(poll => ({
      ...poll,
      title: poll.title || i18n(themePrefix("isbf_v2.poll_button")),
      typeLabel: ["regular", "multiple", "number", "ranked_choice"].includes(poll.type) ? i18n(themePrefix(`isbf_v2.poll_type_${poll.type}`)) : i18n(themePrefix("isbf_v2.poll_button")),
      votersLabel: poll.voters === null ? null : i18n(themePrefix("isbf_v2.poll_participants"), {
        count: poll.voters
      }),
      remainingLabel: poll.remaining ? i18n(themePrefix("isbf_v2.poll_more_options"), {
        count: poll.remaining
      }) : null,
      options: poll.options.map(option => ({
        ...option,
        hasPercentage: option.percentage !== null,
        percentageLabel: option.percentage === null ? null : i18n("number.percent", {
          count: option.percentage
        }),
        barStyle: option.percentage === null ? null : trustHTML(`width:${Math.max(0, Math.min(100, option.percentage))}%`)
      }))
    }));
  }
  async load() {
    const request = ++this.#request;
    const identity = this.identity;
    this.loadedIdentity = null;
    this.data = null;
    this.failed = false;
    if (this.args.measureOnly) {
      return;
    }
    try {
      const data = await loadPostPolls(this.args.postId, this.viewerId, {
        refresh: true
      });
      if (!this.isDestroying && request === this.#request && identity === this.identity) {
        this.data = data;
        this.loadedIdentity = identity;
      }
    } catch {
      if (!this.isDestroying && request === this.#request && identity === this.identity) {
        this.failed = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class="isbf-poll-previews"
      {{didUpdate this.load @postId @cooked this.viewerId}}
    >
      {{#each this.polls key="name" as |poll|}}
        <section class="isbf-poll-preview">
          <h3 class="isbf-poll-preview__title">{{poll.title}}</h3>
          <div class="isbf-poll-preview__meta">
            <span>{{poll.typeLabel}}</span>
            {{#if poll.votersLabel}}<span>· {{poll.votersLabel}}</span>{{/if}}
            {{#if poll.closed}}<span>·
                {{i18n (themePrefix "isbf_v2.poll_closed")}}</span>{{/if}}
          </div>
          <ul class="isbf-poll-preview__options">
            {{#each poll.options key="id" as |option|}}
              <li class="isbf-poll-preview__option">
                <span class="isbf-poll-preview__label">{{option.label}}</span>
                {{#if option.hasPercentage}}
                  <span
                    class="isbf-poll-preview__percentage"
                  >{{option.percentageLabel}}</span>
                  <div aria-hidden="true" class="isbf-poll-preview__track">
                    <div
                      class="isbf-poll-preview__bar"
                      style={{option.barStyle}}
                    ></div>
                  </div>
                {{/if}}
              </li>
            {{/each}}
          </ul>
          {{#if this.failed}}<p class="isbf-poll-preview__meta">{{i18n
                (themePrefix "isbf_v2.poll_results_unavailable")
              }}</p>{{/if}}
          <div class="isbf-poll-preview__footer">
            {{#if poll.remainingLabel}}<span
                class="isbf-poll-preview__more"
              >{{poll.remainingLabel}}</span>{{/if}}
            <a class="isbf-poll-preview__link" href={{@topicUrl}}>{{i18n
                (themePrefix "isbf_v2.poll_view")
              }}</a>
          </div>
        </section>
      {{/each}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"isbf-poll-previews\"],[4,[32,0],[[30,0,[\"load\"]],[30,1],[30,2],[30,0,[\"viewerId\"]]],null],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"polls\"]]],null]],null],\"name\",[[[1,\"    \"],[10,\"section\"],[14,0,\"isbf-poll-preview\"],[12],[1,\"\\n      \"],[10,\"h3\"],[14,0,\"isbf-poll-preview__title\"],[12],[1,[30,3,[\"title\"]]],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-poll-preview__meta\"],[12],[1,\"\\n        \"],[10,1],[12],[1,[30,3,[\"typeLabel\"]]],[13],[1,\"\\n        \"],[41,[30,3,[\"votersLabel\"]],[[[10,1],[12],[1,\"· \"],[1,[30,3,[\"votersLabel\"]]],[13]],[]],null],[1,\"\\n        \"],[41,[30,3,[\"closed\"]],[[[10,1],[12],[1,\"·\\n            \"],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.poll_closed\"],null]],null]],[13]],[]],null],[1,\"\\n      \"],[13],[1,\"\\n      \"],[10,\"ul\"],[14,0,\"isbf-poll-preview__options\"],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,3,[\"options\"]]],null]],null],\"id\",[[[1,\"          \"],[10,\"li\"],[14,0,\"isbf-poll-preview__option\"],[12],[1,\"\\n            \"],[10,1],[14,0,\"isbf-poll-preview__label\"],[12],[1,[30,4,[\"label\"]]],[13],[1,\"\\n\"],[41,[30,4,[\"hasPercentage\"]],[[[1,\"              \"],[10,1],[14,0,\"isbf-poll-preview__percentage\"],[12],[1,[30,4,[\"percentageLabel\"]]],[13],[1,\"\\n              \"],[10,0],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-poll-preview__track\"],[12],[1,\"\\n                \"],[10,0],[14,0,\"isbf-poll-preview__bar\"],[15,5,[30,4,[\"barStyle\"]]],[12],[13],[1,\"\\n              \"],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[13],[1,\"\\n\"]],[4]],null],[1,\"      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"failed\"]],[[[10,2],[14,0,\"isbf-poll-preview__meta\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.poll_results_unavailable\"],null]],null]],[13]],[]],null],[1,\"\\n      \"],[10,0],[14,0,\"isbf-poll-preview__footer\"],[12],[1,\"\\n        \"],[41,[30,3,[\"remainingLabel\"]],[[[10,1],[14,0,\"isbf-poll-preview__more\"],[12],[1,[30,3,[\"remainingLabel\"]]],[13]],[]],null],[1,\"\\n        \"],[10,3],[14,0,\"isbf-poll-preview__link\"],[15,6,[30,5]],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.poll_view\"],null]],null]],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[3]],null],[13]],[\"@postId\",\"@cooked\",\"poll\",\"option\",\"@topicUrl\"],[\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didUpdate,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-poll-previews", ISBFPollPreviews);
var Mod150 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFPollPreviews
});
class ISBFV2FeedCard extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "body", [tracked], function () {
      return null;
    });
  }
  #body = (dt7948.i(this, "body"), void 0);
  static {
    dt7948.g(this.prototype, "bodyFailed", [tracked], function () {
      return false;
    });
  }
  #bodyFailed = (dt7948.i(this, "bodyFailed"), void 0);
  static {
    dt7948.g(this.prototype, "bookmarked", [tracked]);
  }
  #bookmarked = (dt7948.i(this, "bookmarked"), void 0);
  static {
    dt7948.g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (dt7948.i(this, "expanded"), void 0);
  static {
    dt7948.g(this.prototype, "hidden", [tracked], function () {
      return false;
    });
  }
  #hidden = (dt7948.i(this, "hidden"), void 0);
  static {
    dt7948.g(this.prototype, "isFlagging", [tracked], function () {
      return false;
    });
  }
  #isFlagging = (dt7948.i(this, "isFlagging"), void 0);
  static {
    dt7948.g(this.prototype, "isLiking", [tracked], function () {
      return false;
    });
  }
  #isLiking = (dt7948.i(this, "isLiking"), void 0);
  static {
    dt7948.g(this.prototype, "isPinning", [tracked], function () {
      return false;
    });
  }
  #isPinning = (dt7948.i(this, "isPinning"), void 0);
  static {
    dt7948.g(this.prototype, "isReplying", [tracked], function () {
      return false;
    });
  }
  #isReplying = (dt7948.i(this, "isReplying"), void 0);
  static {
    dt7948.g(this.prototype, "liked", [tracked]);
  }
  #liked = (dt7948.i(this, "liked"), void 0);
  static {
    dt7948.g(this.prototype, "likeCount", [tracked]);
  }
  #likeCount = (dt7948.i(this, "likeCount"), void 0);
  static {
    dt7948.g(this.prototype, "menuOpen", [tracked], function () {
      return false;
    });
  }
  #menuOpen = (dt7948.i(this, "menuOpen"), void 0);
  static {
    dt7948.g(this.prototype, "pinNow", [tracked], function () {
      return Date.now();
    });
  }
  #pinNow = (dt7948.i(this, "pinNow"), void 0);
  static {
    dt7948.g(this.prototype, "repostCount", [tracked], function () {
      return null;
    });
  }
  #repostCount = (dt7948.i(this, "repostCount"), void 0);
  static {
    dt7948.g(this.prototype, "viewCount", [tracked], function () {
      return null;
    });
  }
  #viewCount = (dt7948.i(this, "viewCount"), void 0);
  #bodyRequest = 0;
  #observer;
  #pollBody;
  #pollContent;
  #rootElement;
  #viewInFlight = false;
  #viewObserver;
  constructor() {
    super(...arguments);
    this.hidden = isReportedHidden(this.args.topic.first_post_id) || Boolean(this.args.topic.hidden);
    this.appEvents.on("isbf:post-hidden", this.onPostHidden);
    this.appEvents.on("isbf:home-pins-changed", this.onHomePinsChanged);
    this.bookmarked = Boolean(this.args.topic.bookmarked);
    this.liked = Boolean(this.args.topic.op_liked);
    this.likeCount = Number(this.args.topic.op_like_count) || 0;
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:post-hidden", this.onPostHidden);
    this.appEvents.off("isbf:home-pins-changed", this.onHomePinsChanged);
    this.#observer?.disconnect();
    this.#viewObserver?.disconnect();
    document.removeEventListener("visibilitychange", this.onDocumentVisibilityChange);
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onDocumentKeydown, true);
  }
  get avatarUrl() {
    return this.args.topic.creator?.avatar_template?.replace("{size}", "96");
  }
  get bodyHtml() {
    if (this.hidden) {
      return null;
    }
    if (this.body) {
      return trustHTML(this.pollContent.html);
    }
    if (this.args.topic.excerpt) {
      return trustHTML(`<p>${this.args.topic.excerpt}</p>`);
    }
    return null;
  }
  get pollContent() {
    return this.#pollContentFor(this.hidden ? "" : this.body || "");
  }
  get contentReady() {
    return this.body !== null || this.bodyFailed;
  }
  get officialLayout() {
    return this.args.officialLayout || isOfficialCalendarPath(this.router.currentURL, settings.official_path);
  }
  get canFlag() {
    return Boolean(this.currentUser) && !this.hidden && ((this.site.isbf_severe_reports_enabled ?? this.siteSettings.isbf_severe_reports_enabled) === true && this.args.topic.isbf_can_severe_report || this.args.topic.op_can_flag === true || this.currentUser.id !== this.args.topic.creator?.id);
  }
  get canLike() {
    return Boolean(this.currentUser) && (this.args.topic.op_can_like || this.liked);
  }
  get pinMetadata() {
    return pinningMeta(this.args.topic, this.pinNow);
  }
  get showHomePin() {
    return !this.hidden && isPinningContext(this.router, this.site, this.siteSettings) && this.pinMetadata?.active === true;
  }
  get canManageHomePin() {
    const config = this.site.isbf_pinning;
    return !this.hidden && this.currentUser?.admin === true && config?.enabled === true && config?.home_actions_enabled === true && isPinningContext(this.router, this.site, this.siteSettings) && this.pinMetadata?.can_manage === true;
  }
  get creatorName() {
    return displayName(this.args.topic.creator);
  }
  get displayTitle() {
    if (this.hidden) {
      return null;
    }
    return postCardTitle(this.args.topic.title, this.body);
  }
  get formattedLikeCount() {
    return compactNumber(this.likeCount);
  }
  get formattedReplyCount() {
    return compactNumber(this.args.topic.replyCount);
  }
  get formattedRepostCount() {
    return compactNumber(this.repostCount);
  }
  get formattedViewCount() {
    return this.viewCount === null ? "" : compactNumber(this.viewCount) || "0";
  }
  get viewLabel() {
    return this.viewCount === null ? i18n(themePrefix("isbf_v2.views")) : i18n(themePrefix("isbf_v2.views_count"), {
      count: this.viewCount
    });
  }
  get profileUrl() {
    return `/u/${this.args.topic.creator?.username}`;
  }
  get showExpand() {
    return !this.hidden && plainText(this.pollContent.html || this.args.topic.excerpt).length > 900;
  }
  get relativeTime() {
    const date = new Date(this.args.topic.createdAt);
    const seconds = Math.round((date.getTime() - Date.now()) / 1000);
    const formatter = new Intl.RelativeTimeFormat(undefined, {
      numeric: "auto"
    });
    if (Math.abs(seconds) < 60) {
      return formatter.format(seconds, "second");
    }
    const minutes = Math.round(seconds / 60);
    if (Math.abs(minutes) < 60) {
      return formatter.format(minutes, "minute");
    }
    const hours = Math.round(minutes / 60);
    if (Math.abs(hours) < 24) {
      return formatter.format(hours, "hour");
    }
    return formatter.format(Math.round(hours / 24), "day");
  }
  get topicUrl() {
    return this.args.topic.url;
  }
  observe(element) {
    this.#rootElement = element;
    if (this.args.measureOnly) {
      this.#loadContent();
      return;
    }
    this.#observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.#observer.disconnect();
        this.#loadContent();
      }
    }, {
      rootMargin: "320px 0px"
    });
    this.#observer.observe(element);
  }
  static {
    dt7948.n(this.prototype, "observe", [action]);
  }
  observeVisibleView(element) {
    if (!this.currentUser || this.args.measureOnly) {
      return;
    }
    this.#rootElement = element;
    this.#viewObserver = new IntersectionObserver(entries => {
      if (document.visibilityState === "visible" && entries.some(entry => entry.isIntersecting && entry.intersectionRect.width > 0 && entry.intersectionRect.height > 0)) {
        this.#recordView();
      }
    }, {
      rootMargin: "0px",
      threshold: 0
    });
    this.#viewObserver.observe(element);
    document.addEventListener("visibilitychange", this.onDocumentVisibilityChange);
  }
  static {
    dt7948.n(this.prototype, "observeVisibleView", [action]);
  }
  onDocumentVisibilityChange() {
    if (document.visibilityState !== "visible" || !this.#rootElement) {
      return;
    }
    const rect = this.#rootElement.getBoundingClientRect();
    if (rect.top < window.innerHeight && rect.bottom > 0 && rect.left < window.innerWidth && rect.right > 0) {
      this.#recordView();
    }
  }
  static {
    dt7948.n(this.prototype, "onDocumentVisibilityChange", [action]);
  }
  toggleExpanded() {
    this.expanded = !this.expanded;
  }
  static {
    dt7948.n(this.prototype, "toggleExpanded", [action]);
  }
  openTopic(event) {
    if (event.defaultPrevented || event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey || window.getSelection()?.toString() || event.target.closest("a, button, input, select, textarea, summary, audio, video, [contenteditable], [role='button'], [role='link']")) {
      return;
    }
    event.stopPropagation();
    this.args.navigateToTopic(this.args.topic);
  }
  static {
    dt7948.n(this.prototype, "openTopic", [action]);
  }
  async reply() {
    if (this.isReplying) {
      return;
    }
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    const topic = this.args.topic;
    this.isReplying = true;
    try {
      await loadTopicView(topic, {});
      if (!topic.get("details.can_create_post")) {
        await this.router.transitionTo(this.topicUrl);
        return;
      }
      const draftData = await Draft.get(topic.draft_key);
      const options = {
        action: Composer.REPLY,
        draftKey: topic.draft_key,
        draftSequence: draftData.draft_sequence,
        topic
      };
      if (draftData.draft) {
        const draft = JSON.parse(draftData.draft);
        options.reply = draft.reply;
        options.whisper = draft.whisper;
        if (Composer.isEditDraft(draft)) {
          options.draft = draft;
        }
      }
      await this.composer.open(options);
    } catch (error) {
      await this.#showError(error);
    } finally {
      this.isReplying = false;
    }
  }
  static {
    dt7948.n(this.prototype, "reply", [action]);
  }
  async toggleLike() {
    if (!this.canLike || this.isLiking) {
      return;
    }
    this.isLiking = true;
    try {
      if (this.liked) {
        await ajax(`/post_actions/${this.args.topic.first_post_id}`, {
          data: {
            post_action_type_id: 2
          },
          type: "DELETE"
        });
        this.liked = false;
        this.likeCount = Math.max(0, this.likeCount - 1);
      } else {
        await ajax("/post_actions", {
          data: {
            id: this.args.topic.first_post_id,
            post_action_type_id: 2
          },
          type: "POST"
        });
        this.liked = true;
        this.likeCount += 1;
      }
    } catch (error) {
      await this.#showError(error);
    } finally {
      this.isLiking = false;
    }
  }
  static {
    dt7948.n(this.prototype, "toggleLike", [action]);
  }
  async toggleBookmark() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    try {
      if (this.bookmarked) {
        await ajax(`/t/${this.args.topic.id}/remove_bookmarks`, {
          type: "PUT"
        });
      } else {
        await ajax(`/t/${this.args.topic.id}/bookmark`, {
          type: "PUT"
        });
      }
      this.bookmarked = !this.bookmarked;
    } catch (error) {
      await this.#showError(error);
    }
  }
  static {
    dt7948.n(this.prototype, "toggleBookmark", [action]);
  }
  async repost() {
    await openQuotedRepost({
      composer: this.composer,
      router: this.router,
      currentUser: this.currentUser,
      topicId: this.args.topic.id,
      postNumber: 1,
      username: this.args.topic.creator?.username,
      cookedHtml: this.body || this.args.topic.excerpt,
      title: this.args.topic.title
    });
  }
  static {
    dt7948.n(this.prototype, "repost", [action]);
  }
  toggleMenu(event) {
    event.stopPropagation();
    this.menuOpen = !this.menuOpen;
    if (this.menuOpen) {
      document.addEventListener("pointerdown", this.onOutsidePointer, true);
      document.addEventListener("keydown", this.onDocumentKeydown, true);
    } else {
      this.#closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "toggleMenu", [action]);
  }
  onOutsidePointer(event) {
    if (!this.#rootElement?.querySelector(".isbf-feed-card__menu-wrap")?.contains(event.target)) {
      this.#closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "onOutsidePointer", [action]);
  }
  onDocumentKeydown(event) {
    if (event.key === "Escape") {
      this.#closeMenu();
      this.#rootElement?.querySelector(".isbf-feed-card__menu-trigger")?.focus();
    }
  }
  static {
    dt7948.n(this.prototype, "onDocumentKeydown", [action]);
  }
  async flag() {
    if (this.isFlagging) {
      return;
    }
    if (!this.currentUser) {
      this.appEvents.trigger("show-login");
      return;
    }
    this.isFlagging = true;
    try {
      const post = await this.store.find("post", this.args.topic.first_post_id);
      if (this.isDestroying) {
        return;
      }
      post.set("topic", this.args.topic);
      this.#closeMenu();
      this.#rootElement?.querySelector(".isbf-feed-card__menu-trigger")?.focus();
      openPostReport({
        post,
        modal: this.modal,
        siteSettings: this.siteSettings,
        site: this.site,
        appEvents: this.appEvents
      });
    } catch (error) {
      await this.#showError(error);
    } finally {
      this.isFlagging = false;
    }
  }
  static {
    dt7948.n(this.prototype, "flag", [action]);
  }
  onHomePinsChanged() {
    this.pinNow = Date.now();
  }
  static {
    dt7948.n(this.prototype, "onHomePinsChanged", [action]);
  }
  async openHomePin() {
    if (!this.canManageHomePin || this.isPinning) {
      return;
    }
    this.isPinning = true;
    try {
      await this.#closePinMenu();
      if (this.isDestroying || !this.canManageHomePin) {
        return;
      }
      this.modal.show(ISBFHomePinDialog, {
        model: {
          topic: this.args.topic,
          onSaved: this.onHomePinSaved
        }
      });
    } finally {
      if (!this.isDestroying) {
        this.isPinning = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "openHomePin", [action]);
  }
  onHomePinSaved() {
    if (!this.isDestroying) {
      this.pinNow = Date.now();
      this.appEvents.trigger("isbf:home-pin-saved");
    }
  }
  static {
    dt7948.n(this.prototype, "onHomePinSaved", [action]);
  }
  async cancelHomePin() {
    if (!this.canManageHomePin || this.isPinning) {
      return;
    }
    this.isPinning = true;
    try {
      await this.#closePinMenu();
      if (this.isDestroying) {
        return;
      }
      await saveHomePin(this.args.topic, {
        enabled: false
      });
      this.onHomePinSaved();
    } catch (error) {
      if (!this.isDestroying) {
        await this.#showError(error);
      }
    } finally {
      if (!this.isDestroying) {
        this.isPinning = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "cancelHomePin", [action]);
  }
  onPostHidden(postId, hidden = true) {
    if (Number(postId) === Number(this.args.topic.first_post_id)) {
      this.hidden = hidden;
      this.#bodyRequest += 1;
      this.body = null;
      this.bodyFailed = false;
      this.#closeMenu();
      if (!hidden) {
        this.#loadContent();
      }
    }
  }
  static {
    dt7948.n(this.prototype, "onPostHidden", [action]);
  }
  #pollContentFor(body) {
    if (body !== this.#pollBody) {
      this.#pollBody = body;
      this.#pollContent = extractFeedPolls(body);
    }
    return this.#pollContent;
  }
  async #recordView() {
    if (this.#viewInFlight || this.viewCount !== null) {
      return;
    }
    this.#viewInFlight = true;
    const count = await recordVisibleView(this.args.topic.id, this.currentUser.id);
    this.#viewInFlight = false;
    if (count !== null && !this.isDestroying) {
      this.viewCount = count;
      this.#viewObserver?.disconnect();
      document.removeEventListener("visibilitychange", this.onDocumentVisibilityChange);
    }
  }
  async #loadContent() {
    const request = ++this.#bodyRequest;
    const postId = this.args.topic.first_post_id;
    if (this.hidden) {
      return;
    }
    if (!postId) {
      this.bodyFailed = true;
      return;
    }
    const [body, count] = await Promise.allSettled([loadCookedPost(postId), this.args.measureOnly ? Promise.resolve(null) : loadRepostCount(this.args.topic.id)]);
    if (this.isDestroying || this.hidden || isReportedHidden(postId) || request !== this.#bodyRequest) {
      return;
    }
    if (body.status === "fulfilled") {
      this.body = body.value;
    } else {
      this.bodyFailed = true;
    }
    if (count.status === "fulfilled") {
      this.repostCount = count.value;
    }
  }
  async #closePinMenu() {
    this.#closeMenu();
    this.#rootElement?.querySelector(".isbf-feed-card__menu-trigger")?.focus();
    await new Promise(resolve => schedule("afterRender", resolve));
  }
  #closeMenu() {
    this.menuOpen = false;
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onDocumentKeydown, true);
  }
  async #showError(error) {
    const message = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.action_failed"));
    await this.dialog.alert(message);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{! eslint-disable ember/template-no-invalid-interactive }}
    <article
      class="isbf-feed-card"
      data-content-ready={{if this.contentReady "true" "false"}}
      {{didInsert this.observe}}
      {{didInsert this.observeVisibleView}}
      {{on "click" this.openTopic}}
    >
      <a class="isbf-feed-card__avatar isbf-avatar" href={{this.profileUrl}}>
        <img
          alt=""
          height="42"
          loading="lazy"
          src={{this.avatarUrl}}
          width="42"
        />
        <PluginOutlet
          @name="user-avatar-frame"
          @outletArgs={{lazyHash user=@topic.creator motion="static"}}
        />
      </a>
      <div class="isbf-feed-card__main">
        {{#if this.showHomePin}}
          <div class="isbf-feed-card__pin">
            {{dIcon "thumbtack"}}{{i18n (themePrefix "isbf_v2.pinned")}}
          </div>
        {{/if}}
        <header class="isbf-feed-card__header">
          <a
            class="isbf-feed-card__author"
            href={{this.profileUrl}}
          >{{this.creatorName}}</a>
          <a
            class="isbf-feed-card__username"
            href={{this.profileUrl}}
          >@{{@topic.creator.username}}</a>
          <span aria-hidden="true">·</span>
          <a
            class="isbf-feed-card__time"
            href={{this.topicUrl}}
            title={{@topic.createdAt}}
          >{{this.relativeTime}}</a>
          <div class="isbf-feed-card__menu-wrap">
            <button
              aria-expanded={{if this.menuOpen "true" "false"}}
              aria-label={{i18n (themePrefix "isbf_v2.more_actions")}}
              class="isbf-feed-card__menu-trigger"
              type="button"
              {{on "click" this.toggleMenu}}
            >{{dIcon "ellipsis"}}</button>
            {{#if this.menuOpen}}
              <div class="isbf-feed-card__menu" role="menu">
                {{#if this.canManageHomePin}}
                  <button
                    class="isbf-feed-card__pin-action"
                    disabled={{this.isPinning}}
                    role="menuitem"
                    type="button"
                    {{on "click" this.openHomePin}}
                  >{{dIcon "thumbtack"}}{{i18n
                      (themePrefix
                        (if this.showHomePin "isbf_v2.pin_update" "isbf_v2.pin")
                      )
                    }}</button>
                  {{#if this.showHomePin}}
                    <button
                      class="isbf-feed-card__pin-action"
                      disabled={{this.isPinning}}
                      role="menuitem"
                      type="button"
                      {{on "click" this.cancelHomePin}}
                    >{{dIcon "thumbtack"}}{{i18n
                        (themePrefix "isbf_v2.pin_cancel")
                      }}</button>
                  {{/if}}
                {{/if}}
                {{#if this.canFlag}}<button
                    disabled={{this.isFlagging}}
                    role="menuitem"
                    type="button"
                    {{on "click" this.flag}}
                  >{{dIcon "flag"}}{{i18n
                      (themePrefix "isbf_v2.report")
                    }}</button>{{/if}}
              </div>
            {{/if}}
          </div>
        </header>
        {{#if this.displayTitle}}<a
            class="isbf-feed-card__title"
            href={{this.topicUrl}}
          >{{this.displayTitle}}</a>{{/if}}
        <div
          class={{if
            this.expanded
            "isbf-feed-card__body is-expanded"
            "isbf-feed-card__body"
          }}
        >{{#if this.hidden}}{{i18n
              (themePrefix "isbf_v2.report_hidden")
            }}{{else}}<DDecoratedHtml
              @className="isbf-content-images"
              @html={{this.bodyHtml}}
              @preservePointerTarget={{true}}
            />{{/if}}</div>
        {{#if this.bodyFailed}}<a
            class="isbf-feed-card__fallback"
            href={{this.topicUrl}}
          >{{i18n (themePrefix "isbf_v2.view_post")}}</a>{{/if}}
        {{#if this.showExpand}}<button
            class="isbf-feed-card__expand"
            type="button"
            {{on "click" this.toggleExpanded}}
          >{{i18n
              (themePrefix
                (if this.expanded "isbf_v2.show_less" "isbf_v2.show_more")
              )
            }}</button>{{/if}}
        {{#if this.pollContent.polls.length}}
          <ISBFPollPreviews
            @cooked={{this.body}}
            @measureOnly={{@measureOnly}}
            @postId={{@topic.first_post_id}}
            @topicUrl={{this.topicUrl}}
          />
        {{/if}}
        {{#unless this.hidden}}
          {{#if this.officialLayout}}
            <ISBFOfficialActivitySummary
              @campusIds={{@topic.isbf_official_campuses}}
              @items={{@topic.isbf_official_calendar_items}}
              @topicTitle={{@topic.title}}
            />
          {{else}}
            <ISBFOfficialCalendarItems
              @items={{@topic.isbf_official_calendar_items}}
              @readOnly={{true}}
            />
          {{/if}}
        {{/unless}}
        {{#unless this.hidden}}<ISBFMarketplacePrice
            @metadata={{@topic.isbf_marketplace}}
          /><ISBFCareersSalary @metadata={{@topic.isbf_careers}} />{{/unless}}
        <footer class="isbf-feed-card__actions">
          <button
            aria-label={{i18n (themePrefix "isbf_v2.reply")}}
            disabled={{this.isReplying}}
            type="button"
            {{on "click" this.reply}}
          >{{dIcon "comment"}}{{#if this.formattedReplyCount}}<span
              >{{this.formattedReplyCount}}</span>{{/if}}</button>
          <button
            aria-label={{i18n (themePrefix "isbf_v2.repost")}}
            type="button"
            {{on "click" this.repost}}
          >{{dIcon "retweet"}}{{#if this.formattedRepostCount}}<span
              >{{this.formattedRepostCount}}</span>{{/if}}</button>
          <button
            aria-label={{i18n (themePrefix "isbf_v2.like")}}
            class={{if this.liked "is-liked"}}
            disabled={{this.isLiking}}
            type="button"
            {{on "click" this.toggleLike}}
          >{{dIcon "heart"}}{{#if this.formattedLikeCount}}<span
              >{{this.formattedLikeCount}}</span>{{/if}}</button>
          <span
            aria-label={{this.viewLabel}}
            class="isbf-feed-card__views"
          >{{dIcon "chart-bar"}}{{#if this.formattedViewCount}}<span
              >{{this.formattedViewCount}}</span>{{/if}}</span>
          <button
            aria-label={{i18n (themePrefix "isbf_v2.bookmark_action")}}
            class={{if this.bookmarked "is-bookmarked"}}
            type="button"
            {{on "click" this.toggleBookmark}}
          >{{dIcon "bookmark"}}</button>
        </footer>
      </div>
    </article>
    */
    {
      "id": null,
      "block": "[[[11,\"article\"],[24,0,\"isbf-feed-card\"],[16,\"data-content-ready\",[52,[30,0,[\"contentReady\"]],\"true\",\"false\"]],[4,[32,0],[[30,0,[\"observe\"]]],null],[4,[32,0],[[30,0,[\"observeVisibleView\"]]],null],[4,[32,1],[\"click\",[30,0,[\"openTopic\"]]],null],[12],[1,\"\\n  \"],[10,3],[14,0,\"isbf-feed-card__avatar isbf-avatar\"],[15,6,[30,0,[\"profileUrl\"]]],[12],[1,\"\\n    \"],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"42\"],[14,\"loading\",\"lazy\"],[15,\"src\",[30,0,[\"avatarUrl\"]]],[14,\"width\",\"42\"],[12],[13],[1,\"\\n    \"],[8,[32,2],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,3],null,[[\"user\",\"motion\"],[[30,1,[\"creator\"]],\"static\"]]]]],null],[1,\"\\n  \"],[13],[1,\"\\n  \"],[10,0],[14,0,\"isbf-feed-card__main\"],[12],[1,\"\\n\"],[41,[30,0,[\"showHomePin\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-feed-card__pin\"],[12],[1,\"\\n        \"],[1,[28,[32,4],[\"thumbtack\"],null]],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.pinned\"],null]],null]],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[10,\"header\"],[14,0,\"isbf-feed-card__header\"],[12],[1,\"\\n      \"],[10,3],[14,0,\"isbf-feed-card__author\"],[15,6,[30,0,[\"profileUrl\"]]],[12],[1,[30,0,[\"creatorName\"]]],[13],[1,\"\\n      \"],[10,3],[14,0,\"isbf-feed-card__username\"],[15,6,[30,0,[\"profileUrl\"]]],[12],[1,\"@\"],[1,[30,1,[\"creator\",\"username\"]]],[13],[1,\"\\n      \"],[10,1],[14,\"aria-hidden\",\"true\"],[12],[1,\"·\"],[13],[1,\"\\n      \"],[10,3],[14,0,\"isbf-feed-card__time\"],[15,6,[30,0,[\"topicUrl\"]]],[15,\"title\",[30,1,[\"createdAt\"]]],[12],[1,[30,0,[\"relativeTime\"]]],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-feed-card__menu-wrap\"],[12],[1,\"\\n        \"],[11,\"button\"],[16,\"aria-expanded\",[52,[30,0,[\"menuOpen\"]],\"true\",\"false\"]],[16,\"aria-label\",[28,[32,5],[[28,[32,6],[\"isbf_v2.more_actions\"],null]],null]],[24,0,\"isbf-feed-card__menu-trigger\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggleMenu\"]]],null],[12],[1,[28,[32,4],[\"ellipsis\"],null]],[13],[1,\"\\n\"],[41,[30,0,[\"menuOpen\"]],[[[1,\"          \"],[10,0],[14,0,\"isbf-feed-card__menu\"],[14,\"role\",\"menu\"],[12],[1,\"\\n\"],[41,[30,0,[\"canManageHomePin\"]],[[[1,\"              \"],[11,\"button\"],[24,0,\"isbf-feed-card__pin-action\"],[16,\"disabled\",[30,0,[\"isPinning\"]]],[24,\"role\",\"menuitem\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"openHomePin\"]]],null],[12],[1,[28,[32,4],[\"thumbtack\"],null]],[1,[28,[32,5],[[28,[32,6],[[52,[30,0,[\"showHomePin\"]],\"isbf_v2.pin_update\",\"isbf_v2.pin\"]],null]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"showHomePin\"]],[[[1,\"                \"],[11,\"button\"],[24,0,\"isbf-feed-card__pin-action\"],[16,\"disabled\",[30,0,[\"isPinning\"]]],[24,\"role\",\"menuitem\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"cancelHomePin\"]]],null],[12],[1,[28,[32,4],[\"thumbtack\"],null]],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.pin_cancel\"],null]],null]],[13],[1,\"\\n\"]],[]],null]],[]],null],[1,\"            \"],[41,[30,0,[\"canFlag\"]],[[[11,\"button\"],[16,\"disabled\",[30,0,[\"isFlagging\"]]],[24,\"role\",\"menuitem\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"flag\"]]],null],[12],[1,[28,[32,4],[\"flag\"],null]],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.report\"],null]],null]],[13]],[]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n    \"],[41,[30,0,[\"displayTitle\"]],[[[10,3],[14,0,\"isbf-feed-card__title\"],[15,6,[30,0,[\"topicUrl\"]]],[12],[1,[30,0,[\"displayTitle\"]]],[13]],[]],null],[1,\"\\n    \"],[10,0],[15,0,[52,[30,0,[\"expanded\"]],\"isbf-feed-card__body is-expanded\",\"isbf-feed-card__body\"]],[12],[41,[30,0,[\"hidden\"]],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.report_hidden\"],null]],null]]],[]],[[[8,[32,7],null,[[\"@className\",\"@html\",\"@preservePointerTarget\"],[\"isbf-content-images\",[30,0,[\"bodyHtml\"]],true]],null]],[]]],[13],[1,\"\\n    \"],[41,[30,0,[\"bodyFailed\"]],[[[10,3],[14,0,\"isbf-feed-card__fallback\"],[15,6,[30,0,[\"topicUrl\"]]],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.view_post\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"showExpand\"]],[[[11,\"button\"],[24,0,\"isbf-feed-card__expand\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggleExpanded\"]]],null],[12],[1,[28,[32,5],[[28,[32,6],[[52,[30,0,[\"expanded\"]],\"isbf_v2.show_less\",\"isbf_v2.show_more\"]],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"pollContent\",\"polls\",\"length\"]],[[[1,\"      \"],[8,[32,8],null,[[\"@cooked\",\"@measureOnly\",\"@postId\",\"@topicUrl\"],[[30,0,[\"body\"]],[30,2],[30,1,[\"first_post_id\"]],[30,0,[\"topicUrl\"]]]],null],[1,\"\\n\"]],[]],null],[41,[51,[30,0,[\"hidden\"]]],[[[41,[30,0,[\"officialLayout\"]],[[[1,\"        \"],[8,[32,9],null,[[\"@campusIds\",\"@items\",\"@topicTitle\"],[[30,1,[\"isbf_official_campuses\"]],[30,1,[\"isbf_official_calendar_items\"]],[30,1,[\"title\"]]]],null],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,10],null,[[\"@items\",\"@readOnly\"],[[30,1,[\"isbf_official_calendar_items\"]],true]],null],[1,\"\\n\"]],[]]]],[]],null],[1,\"    \"],[41,[51,[30,0,[\"hidden\"]]],[[[8,[32,11],null,[[\"@metadata\"],[[30,1,[\"isbf_marketplace\"]]]],null],[8,[32,12],null,[[\"@metadata\"],[[30,1,[\"isbf_careers\"]]]],null]],[]],null],[1,\"\\n    \"],[10,\"footer\"],[14,0,\"isbf-feed-card__actions\"],[12],[1,\"\\n      \"],[11,\"button\"],[16,\"aria-label\",[28,[32,5],[[28,[32,6],[\"isbf_v2.reply\"],null]],null]],[16,\"disabled\",[30,0,[\"isReplying\"]]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"reply\"]]],null],[12],[1,[28,[32,4],[\"comment\"],null]],[41,[30,0,[\"formattedReplyCount\"]],[[[10,1],[12],[1,[30,0,[\"formattedReplyCount\"]]],[13]],[]],null],[13],[1,\"\\n      \"],[11,\"button\"],[16,\"aria-label\",[28,[32,5],[[28,[32,6],[\"isbf_v2.repost\"],null]],null]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"repost\"]]],null],[12],[1,[28,[32,4],[\"retweet\"],null]],[41,[30,0,[\"formattedRepostCount\"]],[[[10,1],[12],[1,[30,0,[\"formattedRepostCount\"]]],[13]],[]],null],[13],[1,\"\\n      \"],[11,\"button\"],[16,\"aria-label\",[28,[32,5],[[28,[32,6],[\"isbf_v2.like\"],null]],null]],[16,0,[52,[30,0,[\"liked\"]],\"is-liked\"]],[16,\"disabled\",[30,0,[\"isLiking\"]]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggleLike\"]]],null],[12],[1,[28,[32,4],[\"heart\"],null]],[41,[30,0,[\"formattedLikeCount\"]],[[[10,1],[12],[1,[30,0,[\"formattedLikeCount\"]]],[13]],[]],null],[13],[1,\"\\n      \"],[10,1],[15,\"aria-label\",[30,0,[\"viewLabel\"]]],[14,0,\"isbf-feed-card__views\"],[12],[1,[28,[32,4],[\"chart-bar\"],null]],[41,[30,0,[\"formattedViewCount\"]],[[[10,1],[12],[1,[30,0,[\"formattedViewCount\"]]],[13]],[]],null],[13],[1,\"\\n      \"],[11,\"button\"],[16,\"aria-label\",[28,[32,5],[[28,[32,6],[\"isbf_v2.bookmark_action\"],null]],null]],[16,0,[52,[30,0,[\"bookmarked\"]],\"is-bookmarked\"]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggleBookmark\"]]],null],[12],[1,[28,[32,4],[\"bookmark\"],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@topic\",\"@measureOnly\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        on,
        PluginOutlet,
        lazyHash,
        dIcon,
        i18n,
        themePrefix,
        DDecoratedHtml,
        ISBFPollPreviews,
        ISBFOfficialActivitySummary,
        ISBFOfficialCalendarItems,
        ISBFMarketplacePrice,
        ISBFCareersSalary
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-feed-card", ISBFV2FeedCard);
var Mod12 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2FeedCard
});
class ISBFExploreGroup extends Component {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (dt7948.i(this, "expanded"), void 0);
  static {
    dt7948.g(this.prototype, "hasLoaded", [tracked], function () {
      return false;
    });
  }
  #hasLoaded = (dt7948.i(this, "hasLoaded"), void 0);
  static {
    dt7948.g(this.prototype, "isLoading", [tracked], function () {
      return false;
    });
  }
  #isLoading = (dt7948.i(this, "isLoading"), void 0);
  static {
    dt7948.g(this.prototype, "loadFailed", [tracked], function () {
      return false;
    });
  }
  #loadFailed = (dt7948.i(this, "loadFailed"), void 0);
  static {
    dt7948.g(this.prototype, "previewComplete", [tracked], function () {
      return false;
    });
  }
  #previewComplete = (dt7948.i(this, "previewComplete"), void 0);
  static {
    dt7948.g(this.prototype, "previewCount", [tracked], function () {
      return 0;
    });
  }
  #previewCount = (dt7948.i(this, "previewCount"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  static {
    dt7948.g(this.prototype, "topicList", [tracked], function () {
      return null;
    });
  }
  #topicList = (dt7948.i(this, "topicList"), void 0);
  #frame;
  #heights = new Map();
  #intersectionObserver;
  #mutationObserver;
  #observedCards = new Set();
  #requestNumber = 0;
  #resizeObserver;
  #root;
  willDestroy() {
    super.willDestroy(...arguments);
    this.#requestNumber += 1;
    this.#intersectionObserver?.disconnect();
    this.#mutationObserver?.disconnect();
    this.#resizeObserver?.disconnect();
    window.cancelAnimationFrame(this.#frame);
    window.removeEventListener("resize", this.scheduleMeasurement);
    window.visualViewport?.removeEventListener("resize", this.scheduleMeasurement);
  }
  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }
  get candidateTopic() {
    return !this.expanded && !this.previewComplete ? this.topics[this.previewCount] : null;
  }
  get renderedTopics() {
    return this.expanded ? this.topics : this.topics.slice(0, this.previewCount);
  }
  async load() {
    if (this.isLoading) {
      return;
    }
    const request = ++this.#requestNumber;
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const list = await enqueueExploreQuery(() => this.store.findFiltered("topicList", {
        filter: "filter",
        params: {
          q: this.args.query
        }
      }), () => this.#isCurrent(request));
      if (!this.#isCurrent(request) || !list) {
        return;
      }
      this.topicList = list;
      this.topics = uniqueTopicList(list.topics);
      this.hasLoaded = true;
      this.#heights.clear();
      this.previewCount = 0;
      this.previewComplete = false;
      this.#scheduleAfterRender();
    } catch {
      if (this.#isCurrent(request)) {
        this.loadFailed = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.isLoading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async loadMore() {
    if (!this.expanded || this.isLoading || !this.canLoadMore) {
      return;
    }
    const request = ++this.#requestNumber;
    const list = this.topicList;
    this.isLoading = true;
    this.loadFailed = false;
    try {
      await enqueueExploreQuery(() => list.loadMore(), () => this.#isCurrent(request) && this.expanded);
      if (this.#isCurrent(request)) {
        this.topics = uniqueTopicList(list.topics);
        this.#scheduleAfterRender();
      }
    } catch {
      if (this.#isCurrent(request)) {
        this.loadFailed = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.isLoading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }
  static {
    dt7948.n(this.prototype, "navigateToTopic", [action]);
  }
  observe(element) {
    this.#root = element;
    this.#resizeObserver = new ResizeObserver(this.scheduleMeasurement);
    this.#resizeObserver.observe(element);
    this.#mutationObserver = new MutationObserver(this.scheduleMeasurement);
    this.#mutationObserver.observe(element, {
      attributeFilter: ["data-content-ready"],
      attributes: true,
      childList: true,
      subtree: true
    });
    this.#intersectionObserver = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.#intersectionObserver.disconnect();
        void this.load();
      }
    }, {
      rootMargin: "480px 0px"
    });
    this.#intersectionObserver.observe(element);
    window.addEventListener("resize", this.scheduleMeasurement);
    window.visualViewport?.addEventListener("resize", this.scheduleMeasurement);
  }
  static {
    dt7948.n(this.prototype, "observe", [action]);
  }
  retry() {
    if (this.hasLoaded && this.expanded && this.canLoadMore) {
      void this.loadMore();
    } else {
      void this.load();
    }
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  scheduleMeasurement() {
    if (this.#frame || this.isDestroying) {
      return;
    }
    this.#frame = window.requestAnimationFrame(() => {
      this.#frame = null;
      if (!this.isDestroying) {
        this.#measurePreview();
      }
    });
  }
  static {
    dt7948.n(this.prototype, "scheduleMeasurement", [action]);
  }
  toggleExpanded() {
    this.#measurePreview();
    this.expanded = !this.expanded;
    this.#scheduleAfterRender();
  }
  static {
    dt7948.n(this.prototype, "toggleExpanded", [action]);
  }
  #isCurrent(request) {
    return request === this.#requestNumber && !this.isDestroying;
  }
  #measurePreview() {
    if (!this.#root || !this.hasLoaded) {
      return;
    }
    const topicContainer = this.#root.querySelector(".isbf-explore-group__topics");
    const width = topicContainer.getBoundingClientRect().width;
    if (width <= 0) {
      return;
    }
    const cards = new Map();
    const rendered = this.renderedTopics;
    topicContainer.querySelectorAll(":scope > .isbf-feed-card").forEach((card, index) => cards.set(card, rendered[index]));
    const candidate = this.#root.querySelector(".isbf-explore-group__measure > .isbf-feed-card");
    if (candidate && this.candidateTopic) {
      cards.set(candidate, this.candidateTopic);
    }
    for (const oldCard of this.#observedCards) {
      if (!cards.has(oldCard)) {
        this.#resizeObserver.unobserve(oldCard);
      }
    }
    this.#observedCards = new Set(cards.keys());
    for (const [card, topic] of cards) {
      this.#resizeObserver.observe(card);
      if (topic && card.dataset.contentReady === "true") {
        const rect = card.getBoundingClientRect();
        if (rect.height > 0 && Math.abs(rect.width - width) < 1) {
          this.#heights.set(topic.id, {
            height: rect.height,
            width
          });
        }
      }
    }
    const heights = this.topics.map(topic => {
      const measurement = this.#heights.get(topic.id);
      return measurement && Math.abs(measurement.width - width) < 1 ? measurement.height : null;
    });
    const preview = previewForHeights(heights, explorePreviewBudget(this.#root));
    if (this.previewCount !== preview.count || this.previewComplete !== preview.complete) {
      this.previewCount = preview.count;
      this.previewComplete = preview.complete;
      this.#scheduleAfterRender();
    }
  }
  #scheduleAfterRender() {
    scheduleOnce("afterRender", this, this.scheduleMeasurement);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <section class="isbf-explore-group" {{didInsert this.observe}}>
      <header class="isbf-explore-group__header">
        <h2 class="isbf-explore-group__title">
          {{#if @category}}{{dCategoryBadge
              @category
              allowUncategorized=true
            }}{{else}}{{@label}}{{/if}}
        </h2>
      </header>
      <div class="isbf-explore-group__topics">
        {{#each this.renderedTopics key="id" as |topic|}}
          <ISBFV2FeedCard
            @navigateToTopic={{this.navigateToTopic}}
            @topic={{topic}}
          />
        {{/each}}
      </div>
      {{#if this.candidateTopic}}
        <div
          aria-hidden="true"
          class="isbf-explore-group__measure"
          data-has-previous={{if this.previewCount "true" "false"}}
          inert
        >
          <ISBFV2FeedCard
            @measureOnly={{true}}
            @navigateToTopic={{this.navigateToTopic}}
            @topic={{this.candidateTopic}}
          />
        </div>
      {{/if}}
      {{#if this.loadFailed}}
        <div class="isbf-explore-group__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_load_error")}}</span>
          <button type="button" {{on "click" this.retry}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if this.isLoading}}
        <p class="isbf-explore-group__empty" role="status">{{i18n
            (themePrefix "isbf_v2.explore_loading")
          }}</p>
      {{else if this.hasLoaded}}
        {{#unless this.topics.length}}<p
            class="isbf-explore-group__empty"
          >{{i18n (themePrefix "isbf_v2.explore_empty")}}</p>{{/unless}}
      {{else}}
        <p class="isbf-explore-group__empty" role="status">{{i18n
            (themePrefix "isbf_v2.explore_loading")
          }}</p>
      {{/if}}
      <footer class="isbf-explore-group__footer">
        <button
          aria-expanded={{if this.expanded "true" "false"}}
          class="isbf-explore-group__toggle"
          disabled={{eq this.topics.length 0}}
          type="button"
          {{on "click" this.toggleExpanded}}
        >{{i18n
            (themePrefix
              (if
                this.expanded
                "isbf_v2.explore_collapse"
                "isbf_v2.explore_expand"
              )
            )
          }}</button>
        {{#if this.expanded}}
          {{#if this.canLoadMore}}
            <button
              class="isbf-explore-group__more"
              disabled={{this.isLoading}}
              type="button"
              {{on "click" this.loadMore}}
            >{{i18n (themePrefix "isbf_v2.explore_load_more")}}</button>
          {{else if this.hasLoaded}}
            <span>{{i18n (themePrefix "isbf_v2.explore_end")}}</span>
          {{/if}}
        {{/if}}
      </footer>
    </section>
    */
    {
      "id": null,
      "block": "[[[11,\"section\"],[24,0,\"isbf-explore-group\"],[4,[32,0],[[30,0,[\"observe\"]]],null],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-explore-group__header\"],[12],[1,\"\\n    \"],[10,\"h2\"],[14,0,\"isbf-explore-group__title\"],[12],[1,\"\\n      \"],[41,[30,1],[[[1,[28,[32,1],[[30,1]],[[\"allowUncategorized\"],[true]]]]],[]],[[[1,[30,2]]],[]]],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[10,0],[14,0,\"isbf-explore-group__topics\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"renderedTopics\"]]],null]],null],\"id\",[[[1,\"      \"],[8,[32,2],null,[[\"@navigateToTopic\",\"@topic\"],[[30,0,[\"navigateToTopic\"]],[30,3]]],null],[1,\"\\n\"]],[3]],null],[1,\"  \"],[13],[1,\"\\n\"],[41,[30,0,[\"candidateTopic\"]],[[[1,\"    \"],[10,0],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-explore-group__measure\"],[15,\"data-has-previous\",[52,[30,0,[\"previewCount\"]],\"true\",\"false\"]],[14,\"inert\",\"\"],[12],[1,\"\\n      \"],[8,[32,2],null,[[\"@measureOnly\",\"@navigateToTopic\",\"@topic\"],[true,[30,0,[\"navigateToTopic\"]],[30,0,[\"candidateTopic\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"loadFailed\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-explore-group__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n      \"],[10,1],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_load_error\"],null]],null]],[13],[1,\"\\n      \"],[11,\"button\"],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"retry\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_retry\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isLoading\"]],[[[1,\"    \"],[10,2],[14,0,\"isbf-explore-group__empty\"],[14,\"role\",\"status\"],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"hasLoaded\"]],[[[1,\"    \"],[41,[51,[30,0,[\"topics\",\"length\"]]],[[[10,2],[14,0,\"isbf-explore-group__empty\"],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_empty\"],null]],null]],[13]],[]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,2],[14,0,\"isbf-explore-group__empty\"],[14,\"role\",\"status\"],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_loading\"],null]],null]],[13],[1,\"\\n  \"]],[]]]],[]]]],[]]],[1,\"  \"],[10,\"footer\"],[14,0,\"isbf-explore-group__footer\"],[12],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-expanded\",[52,[30,0,[\"expanded\"]],\"true\",\"false\"]],[24,0,\"isbf-explore-group__toggle\"],[16,\"disabled\",[28,[32,6],[[30,0,[\"topics\",\"length\"]],0],null]],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"toggleExpanded\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[[52,[30,0,[\"expanded\"]],\"isbf_v2.explore_collapse\",\"isbf_v2.explore_expand\"]],null]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"expanded\"]],[[[41,[30,0,[\"canLoadMore\"]],[[[1,\"        \"],[11,\"button\"],[24,0,\"isbf-explore-group__more\"],[16,\"disabled\",[30,0,[\"isLoading\"]]],[24,4,\"button\"],[4,[32,5],[\"click\",[30,0,[\"loadMore\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_load_more\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"hasLoaded\"]],[[[1,\"        \"],[10,1],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_end\"],null]],null]],[13],[1,\"\\n      \"]],[]],null]],[]]]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[13]],[\"@category\",\"@label\",\"topic\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        dCategoryBadge,
        ISBFV2FeedCard,
        i18n,
        themePrefix,
        __keyword__on: on,
        __keyword__eq: eq$1
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-explore-group", ISBFExploreGroup);
var Mod38 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFExploreGroup
});
let nextPickerId = 0;
class ISBFExplorePicker extends Component {
  static {
    dt7948.g(this.prototype, "isOpen", [tracked], function () {
      return false;
    });
  }
  #isOpen = (dt7948.i(this, "isOpen"), void 0);
  static {
    dt7948.g(this.prototype, "search", [tracked], function () {
      return "";
    });
  }
  #search = (dt7948.i(this, "search"), void 0);
  menuId = `isbf-explore-picker-${++nextPickerId}`;
  #root;
  willDestroy() {
    super.willDestroy(...arguments);
    this.#removeListeners();
  }
  get label() {
    const label = i18n(themePrefix(this.args.labelKey));
    return this.args.selectedIds.length ? i18n(themePrefix("isbf_v2.explore_selected_count"), {
      count: this.args.selectedIds.length,
      label
    }) : label;
  }
  get options() {
    const selected = new Set(this.args.selectedIds);
    const query = this.search.trim().toLocaleLowerCase();
    return this.args.items.filter(item => this.args.onSearch ? true : item.label.toLocaleLowerCase().includes(query)).map(item => ({
      ...item,
      selected: selected.has(item.id)
    }));
  }
  clear() {
    this.args.onClear();
  }
  static {
    dt7948.n(this.prototype, "clear", [action]);
  }
  createCategory() {
    this.#close();
    this.args.onCreateCategory?.();
  }
  static {
    dt7948.n(this.prototype, "createCategory", [action]);
  }
  focusSearch() {
    this.#root?.querySelector("input[type='search']")?.focus();
  }
  static {
    dt7948.n(this.prototype, "focusSearch", [action]);
  }
  observe(element) {
    this.#root = element;
  }
  static {
    dt7948.n(this.prototype, "observe", [action]);
  }
  onDocumentKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      this.#close();
    }
  }
  static {
    dt7948.n(this.prototype, "onDocumentKeydown", [action]);
  }
  onOutsidePointer(event) {
    if (!this.#root?.contains(event.target)) {
      this.#close();
    }
  }
  static {
    dt7948.n(this.prototype, "onOutsidePointer", [action]);
  }
  retrySearch() {
    this.args.onSearch?.(this.search);
  }
  static {
    dt7948.n(this.prototype, "retrySearch", [action]);
  }
  toggle() {
    if (this.isOpen) {
      this.#close();
      return;
    }
    this.isOpen = true;
    this.args.onSearch?.(this.search);
    document.addEventListener("pointerdown", this.onOutsidePointer, true);
    document.addEventListener("keydown", this.onDocumentKeydown, true);
    scheduleOnce("afterRender", this, this.focusSearch);
  }
  static {
    dt7948.n(this.prototype, "toggle", [action]);
  }
  toggleOption(item) {
    this.args.onToggle(item);
  }
  static {
    dt7948.n(this.prototype, "toggleOption", [action]);
  }
  updateSearch(event) {
    this.search = event.target.value;
    this.args.onSearch?.(this.search);
  }
  static {
    dt7948.n(this.prototype, "updateSearch", [action]);
  }
  #close() {
    this.isOpen = false;
    this.#removeListeners();
    this.#root?.querySelector(".isbf-explore-picker__trigger")?.focus();
  }
  #removeListeners() {
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onDocumentKeydown, true);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div class="isbf-explore-picker" {{didInsert this.observe}}>
      <button
        aria-controls={{this.menuId}}
        aria-expanded={{if this.isOpen "true" "false"}}
        class="isbf-explore-picker__trigger"
        disabled={{@disabled}}
        type="button"
        {{on "click" this.toggle}}
      >{{this.label}}{{dIcon "chevron-down"}}</button>
      {{#if this.isOpen}}
        <div
          aria-label={{i18n (themePrefix @labelKey)}}
          class="isbf-explore-picker__menu"
          id={{this.menuId}}
          role="group"
        >
          <input
            aria-label={{i18n (themePrefix @searchKey)}}
            class="isbf-explore-picker__search"
            placeholder={{i18n (themePrefix @searchKey)}}
            type="search"
            value={{this.search}}
            {{on "input" this.updateSearch}}
          />
          {{#if @loading}}<p role="status">{{i18n
                (themePrefix "isbf_v2.explore_loading")
              }}</p>{{/if}}
          {{#if @error}}
            <div class="isbf-explore-picker__error" role="alert">
              <span>{{i18n (themePrefix "isbf_v2.explore_search_error")}}</span>
              <button type="button" {{on "click" this.retrySearch}}>{{i18n
                  (themePrefix "isbf_v2.explore_retry")
                }}</button>
            </div>
          {{/if}}
          <div class="isbf-explore-picker__options">
            {{#each this.options key="id" as |item|}}
              <label class="isbf-explore-picker__option">
                <span class="isbf-explore-picker__label">{{item.label}}</span>
                <input
                  checked={{item.selected}}
                  class="isbf-explore-picker__checkbox"
                  disabled={{item.pending}}
                  type="checkbox"
                  {{on "change" (fn this.toggleOption item)}}
                />
              </label>
            {{else}}
              {{#unless @loading}}<p>{{i18n
                    (themePrefix "isbf_v2.explore_no_options")
                  }}</p>{{/unless}}
            {{/each}}
          </div>
          <div class="isbf-explore-picker__footer">
            <button
              class="isbf-explore-picker__clear"
              disabled={{eq @selectedIds.length 0}}
              type="button"
              {{on "click" this.clear}}
            >{{i18n (themePrefix "isbf_v2.explore_clear")}}</button>
            {{#if @canCreateCategory}}
              <button
                class="isbf-explore-picker__create"
                type="button"
                {{on "click" this.createCategory}}
              >{{i18n (themePrefix "isbf_v2.explore_create_category")}}</button>
            {{/if}}
          </div>
        </div>
      {{/if}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"isbf-explore-picker\"],[4,[32,0],[[30,0,[\"observe\"]]],null],[12],[1,\"\\n  \"],[11,\"button\"],[16,\"aria-controls\",[30,0,[\"menuId\"]]],[16,\"aria-expanded\",[52,[30,0,[\"isOpen\"]],\"true\",\"false\"]],[24,0,\"isbf-explore-picker__trigger\"],[16,\"disabled\",[30,1]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggle\"]]],null],[12],[1,[30,0,[\"label\"]]],[1,[28,[32,2],[\"chevron-down\"],null]],[13],[1,\"\\n\"],[41,[30,0,[\"isOpen\"]],[[[1,\"    \"],[10,0],[15,\"aria-label\",[28,[32,3],[[28,[32,4],[[30,2]],null]],null]],[14,0,\"isbf-explore-picker__menu\"],[15,1,[30,0,[\"menuId\"]]],[14,\"role\",\"group\"],[12],[1,\"\\n      \"],[11,\"input\"],[16,\"aria-label\",[28,[32,3],[[28,[32,4],[[30,3]],null]],null]],[24,0,\"isbf-explore-picker__search\"],[16,\"placeholder\",[28,[32,3],[[28,[32,4],[[30,3]],null]],null]],[16,2,[30,0,[\"search\"]]],[24,4,\"search\"],[4,[32,1],[\"input\",[30,0,[\"updateSearch\"]]],null],[12],[13],[1,\"\\n      \"],[41,[30,4],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,5],[[[1,\"        \"],[10,0],[14,0,\"isbf-explore-picker__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n          \"],[10,1],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_search_error\"],null]],null]],[13],[1,\"\\n          \"],[11,\"button\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"retrySearch\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_retry\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,0],[14,0,\"isbf-explore-picker__options\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"options\"]]],null]],null],\"id\",[[[1,\"          \"],[10,\"label\"],[14,0,\"isbf-explore-picker__option\"],[12],[1,\"\\n            \"],[10,1],[14,0,\"isbf-explore-picker__label\"],[12],[1,[30,6,[\"label\"]]],[13],[1,\"\\n            \"],[11,\"input\"],[16,\"checked\",[30,6,[\"selected\"]]],[24,0,\"isbf-explore-picker__checkbox\"],[16,\"disabled\",[30,6,[\"pending\"]]],[24,4,\"checkbox\"],[4,[32,1],[\"change\",[28,[32,5],[[30,0,[\"toggleOption\"]],[30,6]],null]],null],[12],[13],[1,\"\\n          \"],[13],[1,\"\\n\"]],[6]],[[[1,\"          \"],[41,[51,[30,4]],[[[10,2],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_no_options\"],null]],null]],[13]],[]],null],[1,\"\\n\"]],[]]],[1,\"      \"],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-explore-picker__footer\"],[12],[1,\"\\n        \"],[11,\"button\"],[24,0,\"isbf-explore-picker__clear\"],[16,\"disabled\",[28,[32,6],[[30,7,[\"length\"]],0],null]],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"clear\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_clear\"],null]],null]],[13],[1,\"\\n\"],[41,[30,8],[[[1,\"          \"],[11,\"button\"],[24,0,\"isbf-explore-picker__create\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"createCategory\"]]],null],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.explore_create_category\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"@disabled\",\"@labelKey\",\"@searchKey\",\"@loading\",\"@error\",\"item\",\"@selectedIds\",\"@canCreateCategory\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        __keyword__on: on,
        dIcon,
        i18n,
        themePrefix,
        __keyword__fn: fn,
        __keyword__eq: eq$1
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-explore-picker", ISBFExplorePicker);
var Mod39 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFExplorePicker
});
class ISBFExplore extends Component {
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "preferences", [tracked], function () {
      return normalizeExplorePreferences();
    });
  }
  #preferences = (dt7948.i(this, "preferences"), void 0);
  static {
    dt7948.g(this.prototype, "preferencesReady", [tracked], function () {
      return false;
    });
  }
  #preferencesReady = (dt7948.i(this, "preferencesReady"), void 0);
  static {
    dt7948.g(this.prototype, "restoreFailed", [tracked], function () {
      return false;
    });
  }
  #restoreFailed = (dt7948.i(this, "restoreFailed"), void 0);
  static {
    dt7948.g(this.prototype, "saveState", [tracked], function () {
      return "idle";
    });
  }
  #saveState = (dt7948.i(this, "saveState"), void 0);
  static {
    dt7948.g(this.prototype, "resolvingTagIds", [tracked], function () {
      return [];
    });
  }
  #resolvingTagIds = (dt7948.i(this, "resolvingTagIds"), void 0);
  static {
    dt7948.g(this.prototype, "selectedTags", [tracked], function () {
      return [];
    });
  }
  #selectedTags = (dt7948.i(this, "selectedTags"), void 0);
  static {
    dt7948.g(this.prototype, "tagResults", [tracked], function () {
      return [];
    });
  }
  #tagResults = (dt7948.i(this, "tagResults"), void 0);
  static {
    dt7948.g(this.prototype, "tagSearchFailed", [tracked], function () {
      return false;
    });
  }
  #tagSearchFailed = (dt7948.i(this, "tagSearchFailed"), void 0);
  static {
    dt7948.g(this.prototype, "tagSearchLoading", [tracked], function () {
      return false;
    });
  }
  #tagSearchLoading = (dt7948.i(this, "tagSearchLoading"), void 0);
  #canonicalTags = new Map();
  #generation = 0;
  #ownerId;
  #searchNumber = 0;
  #searchTimer;
  #tagSelectionEpoch = 0;
  #writer;
  constructor() {
    super(...arguments);
    this.#initializeAccount();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation += 1;
    this.#writer?.cancel();
    clearTimeout(this.#searchTimer);
  }
  get accountReady() {
    return this.preferencesReady && (this.currentUser?.id || null) === this.#ownerId;
  }
  get categoryItems() {
    const categories = Array.from(this.site.categories || []);
    return categories.flatMap(category => {
      const id = categoryFilterId(category);
      return id ? [{
        category,
        id,
        label: category.name
      }] : [];
    });
  }
  get categoryFilterAvailable() {
    return this.site.isbf_explore_category_id_filter === true;
  }
  get filtersReady() {
    return this.accountReady && this.categoryFilterAvailable;
  }
  get showPreferenceStatus() {
    return !this.preferencesReady || this.saveState !== "idle";
  }
  get selectedCategory() {
    if (this.preferences.category_ids.length !== 1) {
      return null;
    }
    return this.categoryItems.find(item => item.id === this.preferences.category_ids[0])?.category;
  }
  get composeDisabled() {
    return !this.accountReady || Boolean(this.currentUser && this.selectedCategory?.canCreateTopic === false);
  }
  get composeTitle() {
    return this.currentUser && this.selectedCategory?.canCreateTopic === false ? i18n(themePrefix("isbf_v2.explore_create_restricted")) : null;
  }
  get groups() {
    if (!this.filtersReady) {
      return [];
    }
    const tags = this.selectedTags.map(tag => tag.name);
    const selected = new Set(this.preferences.category_ids);
    const categories = this.categoryItems.filter(item => selected.has(item.id));
    const groups = this.preferences.category_ids.length ? categories : [{
      id: "all",
      label: i18n(themePrefix(tags.length ? "isbf_v2.explore_matching_tags" : "isbf_v2.explore_all_topics"))
    }];
    return groups.map(group => {
      const query = buildExploreQuery({
        categoryId: group.category?.id,
        order: this.preferences.order,
        tags
      });
      return {
        category: group.category,
        key: `${this.currentUser?.id || "guest"}:${group.id}:${query}`,
        label: group.label,
        query
      };
    });
  }
  get tagItems() {
    const seen = new Set();
    return [...this.selectedTags, ...this.tagResults].flatMap(tag => {
      if (seen.has(tag.id)) {
        return [];
      }
      seen.add(tag.id);
      return [{
        ...tag,
        label: tag.text || tag.name,
        pending: this.resolvingTagIds.includes(tag.id)
      }];
    });
  }
  get tagsLoading() {
    return this.tagSearchLoading || this.resolvingTagIds.length > 0;
  }
  clearCategories() {
    this.#updatePreferences({
      category_ids: []
    });
  }
  static {
    dt7948.n(this.prototype, "clearCategories", [action]);
  }
  clearTags() {
    this.#tagSelectionEpoch += 1;
    this.resolvingTagIds = [];
    this.selectedTags = [];
    this.#updatePreferences({
      tag_ids: []
    });
  }
  static {
    dt7948.n(this.prototype, "clearTags", [action]);
  }
  newTopic() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    if (this.composeDisabled) {
      return;
    }
    this.composer.openNewTopic(this.selectedCategory?.canCreateTopic ? {
      category: this.selectedCategory
    } : {});
  }
  static {
    dt7948.n(this.prototype, "newTopic", [action]);
  }
  retryPreferences() {
    if (this.restoreFailed) {
      void this.#restorePreferences();
    } else {
      void this.#writer?.retry();
    }
  }
  static {
    dt7948.n(this.prototype, "retryPreferences", [action]);
  }
  searchTags(term) {
    clearTimeout(this.#searchTimer);
    const request = ++this.#searchNumber;
    const generation = this.#generation;
    this.tagSearchLoading = true;
    this.tagSearchFailed = false;
    this.#searchTimer = setTimeout(async () => {
      try {
        const result = await ajax("/tags/filter/search.json", {
          data: {
            limit: this.siteSettings.max_tag_search_results,
            q: term.trim()
          }
        });
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagResults = (result.results || []).map(tag => ({
            ...tag,
            id: Number(tag.id)
          }));
        }
      } catch {
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagSearchFailed = true;
        }
      } finally {
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagSearchLoading = false;
        }
      }
    }, 200);
  }
  static {
    dt7948.n(this.prototype, "searchTags", [action]);
  }
  syncAccount() {
    if ((this.currentUser?.id || null) !== this.#ownerId) {
      this.#initializeAccount();
    }
  }
  static {
    dt7948.n(this.prototype, "syncAccount", [action]);
  }
  toggleCategory(item) {
    const selected = this.preferences.category_ids;
    this.#updatePreferences({
      category_ids: selected.includes(item.id) ? selected.filter(id => id !== item.id) : [...selected, item.id]
    });
  }
  static {
    dt7948.n(this.prototype, "toggleCategory", [action]);
  }
  async toggleTag(item) {
    if (this.resolvingTagIds.includes(item.id)) {
      return;
    }
    if (this.preferences.tag_ids.includes(item.id)) {
      this.selectedTags = this.selectedTags.filter(tag => tag.id !== item.id);
      this.#updatePreferences({
        tag_ids: this.preferences.tag_ids.filter(id => id !== item.id)
      });
      return;
    }
    const generation = this.#generation;
    const selectionEpoch = this.#tagSelectionEpoch;
    this.resolvingTagIds = [...this.resolvingTagIds, item.id];
    try {
      let tag = this.#canonicalTags.get(item.id);
      if (!tag) {
        const result = await enqueueExploreQuery(() => ajax(`/tag/${item.id}/info.json`), () => this.#isCurrent(generation) && selectionEpoch === this.#tagSelectionEpoch);
        const name = result?.tag_info?.isbf_explore_filter_name;
        if (name) {
          tag = {
            ...item,
            name
          };
        }
      }
      if (!this.#isCurrent(generation) || selectionEpoch !== this.#tagSelectionEpoch) {
        return;
      }
      if (!tag?.name) {
        throw new Error("Missing visible tag");
      }
      this.#canonicalTags.set(item.id, tag);
      this.selectedTags = [...this.selectedTags, {
        ...tag,
        id: item.id
      }];
      this.#updatePreferences({
        tag_ids: [...this.preferences.tag_ids, item.id]
      });
    } catch {
      if (this.#isCurrent(generation) && selectionEpoch === this.#tagSelectionEpoch) {
        this.tagSearchFailed = true;
      }
    } finally {
      if (this.#isCurrent(generation) && selectionEpoch === this.#tagSelectionEpoch) {
        this.resolvingTagIds = this.resolvingTagIds.filter(id => id !== item.id);
      }
    }
  }
  static {
    dt7948.n(this.prototype, "toggleTag", [action]);
  }
  toggleOrder() {
    this.#updatePreferences({
      order: this.preferences.order === "hot" ? "activity" : "hot"
    });
  }
  static {
    dt7948.n(this.prototype, "toggleOrder", [action]);
  }
  #applyResponse(result) {
    const payload = result?.preferences;
    if (!Array.isArray(payload?.category_ids) || !Array.isArray(payload?.tag_ids) || !["activity", "hot"].includes(payload.order) || !Array.isArray(result.tags)) {
      throw new Error("Missing explore preferences");
    }
    const preferences = normalizeExplorePreferences(payload);
    const tags = result.tags.map(tag => ({
      ...tag,
      id: Number(tag.id)
    }));
    if (preferences.tag_ids.some(id => !tags.some(tag => tag.id === id && tag.name))) {
      throw new Error("Missing selected tag metadata");
    }
    this.preferences = preferences;
    this.selectedTags = preferences.tag_ids.map(id => tags.find(tag => tag.id === id));
    this.selectedTags.forEach(tag => this.#canonicalTags.set(tag.id, tag));
  }
  #initializeAccount() {
    this.#generation += 1;
    this.#ownerId = this.currentUser?.id || null;
    this.#searchNumber += 1;
    this.#tagSelectionEpoch += 1;
    this.#writer?.cancel();
    this.#writer = null;
    clearTimeout(this.#searchTimer);
    this.preferences = normalizeExplorePreferences();
    this.preferencesReady = !this.#ownerId;
    this.restoreFailed = false;
    this.saveState = "idle";
    this.selectedTags = [];
    this.tagResults = [];
    this.tagSearchFailed = false;
    this.tagSearchLoading = false;
    this.resolvingTagIds = [];
    this.#canonicalTags.clear();
    if (this.#ownerId) {
      void this.#restorePreferences();
    }
  }
  #isCurrent(generation) {
    return generation === this.#generation && (this.currentUser?.id || null) === this.#ownerId && !this.isDestroying;
  }
  async #restorePreferences() {
    const generation = ++this.#generation;
    this.preferencesReady = false;
    this.restoreFailed = false;
    try {
      const result = await ajax("/isbf/explore/preferences");
      if (!this.#isCurrent(generation)) {
        return;
      }
      this.#applyResponse(result);
      this.preferencesReady = true;
      this.#writer = createExplorePreferenceWriter({
        onSaved: (snapshot, response) => {
          if (this.#isCurrent(generation) && preferencesSignature(snapshot) === preferencesSignature(this.preferences)) {
            this.#applyResponse(response);
          }
        },
        onState: state => {
          if (this.#isCurrent(generation)) {
            this.saveState = state;
          }
        },
        save: preferences => {
          if (!this.#isCurrent(generation)) {
            throw new Error("Account changed");
          }
          return ajax("/isbf/explore/preferences", {
            contentType: "application/json",
            data: JSON.stringify(preferences),
            type: "PUT"
          });
        }
      });
    } catch {
      if (this.#isCurrent(generation)) {
        this.restoreFailed = true;
      }
    }
  }
  #updatePreferences(changes) {
    if (!this.filtersReady) {
      return;
    }
    this.preferences = normalizeExplorePreferences({
      ...this.preferences,
      ...changes
    });
    this.#writer?.update(this.preferences);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main
      class="isbf-explore"
      {{didUpdate this.syncAccount this.currentUser.id}}
    >
      {{#if this.accountReady}}
        <div class="isbf-explore__toolbar">
          <ISBFExplorePicker
            @canCreateCategory={{@canCreateCategory}}
            @disabled={{not this.filtersReady}}
            @items={{this.categoryItems}}
            @labelKey="isbf_v2.explore_categories"
            @onClear={{this.clearCategories}}
            @onCreateCategory={{@onCreateCategory}}
            @onToggle={{this.toggleCategory}}
            @searchKey="isbf_v2.explore_search_categories"
            @selectedIds={{this.preferences.category_ids}}
          />
          <ISBFExplorePicker
            @disabled={{not this.filtersReady}}
            @error={{this.tagSearchFailed}}
            @items={{this.tagItems}}
            @labelKey="isbf_v2.explore_tags"
            @loading={{this.tagsLoading}}
            @onClear={{this.clearTags}}
            @onSearch={{this.searchTags}}
            @onToggle={{this.toggleTag}}
            @searchKey="isbf_v2.explore_search_tags"
            @selectedIds={{this.preferences.tag_ids}}
          />
          <button
            aria-pressed={{if (eq this.preferences.order "hot") "true" "false"}}
            class="isbf-explore__order"
            disabled={{not this.filtersReady}}
            type="button"
            {{on "click" this.toggleOrder}}
          >{{i18n (themePrefix "isbf_v2.explore_hot")}}</button>
          <button
            class="isbf-explore__compose"
            disabled={{this.composeDisabled}}
            title={{this.composeTitle}}
            type="button"
            {{on "click" this.newTopic}}
          >{{i18n (themePrefix "isbf_v2.explore_new_topic")}}</button>
        </div>
      {{/if}}
      {{#unless this.categoryFilterAvailable}}
        <div class="isbf-explore__error" role="alert">
          {{i18n (themePrefix "isbf_v2.explore_filter_unavailable")}}
        </div>
      {{/unless}}
      {{#if this.restoreFailed}}
        <div class="isbf-explore__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_restore_error")}}</span>
          <button type="button" {{on "click" this.retryPreferences}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if (eq this.saveState "failed")}}
        <div class="isbf-explore__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_save_error")}}</span>
          <button type="button" {{on "click" this.retryPreferences}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if this.currentUser}}
        {{#if this.showPreferenceStatus}}
          <p class="isbf-explore__status" role="status">
            {{#if (eq this.saveState "saved")}}{{i18n
                (themePrefix "isbf_v2.explore_saved")
              }}{{else if (eq this.saveState "idle")}}
              {{#unless this.preferencesReady}}{{i18n
                  (themePrefix "isbf_v2.explore_loading")
                }}{{/unless}}
            {{else}}{{i18n (themePrefix "isbf_v2.explore_saving")}}{{/if}}
          </p>
        {{/if}}
      {{else}}
        <p class="isbf-explore__status">{{i18n
            (themePrefix "isbf_v2.explore_guest_preferences")
          }}</p>
      {{/if}}
      {{#if this.filtersReady}}
        {{#each this.groups key="key" as |group|}}
          <ISBFExploreGroup
            @category={{group.category}}
            @label={{group.label}}
            @query={{group.query}}
          />
        {{/each}}
      {{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[11,\"main\"],[24,0,\"isbf-explore\"],[4,[32,0],[[30,0,[\"syncAccount\"]],[30,0,[\"currentUser\",\"id\"]]],null],[12],[1,\"\\n\"],[41,[30,0,[\"accountReady\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-explore__toolbar\"],[12],[1,\"\\n      \"],[8,[32,1],null,[[\"@canCreateCategory\",\"@disabled\",\"@items\",\"@labelKey\",\"@onClear\",\"@onCreateCategory\",\"@onToggle\",\"@searchKey\",\"@selectedIds\"],[[30,1],[28,[32,2],[[30,0,[\"filtersReady\"]]],null],[30,0,[\"categoryItems\"]],\"isbf_v2.explore_categories\",[30,0,[\"clearCategories\"]],[30,2],[30,0,[\"toggleCategory\"]],\"isbf_v2.explore_search_categories\",[30,0,[\"preferences\",\"category_ids\"]]]],null],[1,\"\\n      \"],[8,[32,1],null,[[\"@disabled\",\"@error\",\"@items\",\"@labelKey\",\"@loading\",\"@onClear\",\"@onSearch\",\"@onToggle\",\"@searchKey\",\"@selectedIds\"],[[28,[32,2],[[30,0,[\"filtersReady\"]]],null],[30,0,[\"tagSearchFailed\"]],[30,0,[\"tagItems\"]],\"isbf_v2.explore_tags\",[30,0,[\"tagsLoading\"]],[30,0,[\"clearTags\"]],[30,0,[\"searchTags\"]],[30,0,[\"toggleTag\"]],\"isbf_v2.explore_search_tags\",[30,0,[\"preferences\",\"tag_ids\"]]]],null],[1,\"\\n      \"],[11,\"button\"],[16,\"aria-pressed\",[52,[28,[32,3],[[30,0,[\"preferences\",\"order\"]],\"hot\"],null],\"true\",\"false\"]],[24,0,\"isbf-explore__order\"],[16,\"disabled\",[28,[32,2],[[30,0,[\"filtersReady\"]]],null]],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"toggleOrder\"]]],null],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_hot\"],null]],null]],[13],[1,\"\\n      \"],[11,\"button\"],[24,0,\"isbf-explore__compose\"],[16,\"disabled\",[30,0,[\"composeDisabled\"]]],[16,\"title\",[30,0,[\"composeTitle\"]]],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"newTopic\"]]],null],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_new_topic\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[41,[51,[30,0,[\"categoryFilterAvailable\"]]],[[[1,\"    \"],[10,0],[14,0,\"isbf-explore__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n      \"],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_filter_unavailable\"],null]],null]],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"restoreFailed\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-explore__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n      \"],[10,1],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_restore_error\"],null]],null]],[13],[1,\"\\n      \"],[11,\"button\"],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"retryPreferences\"]]],null],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_retry\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],[[[41,[28,[32,3],[[30,0,[\"saveState\"]],\"failed\"],null],[[[1,\"    \"],[10,0],[14,0,\"isbf-explore__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n      \"],[10,1],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_save_error\"],null]],null]],[13],[1,\"\\n      \"],[11,\"button\"],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"retryPreferences\"]]],null],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_retry\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"currentUser\"]],[[[41,[30,0,[\"showPreferenceStatus\"]],[[[1,\"      \"],[10,2],[14,0,\"isbf-explore__status\"],[14,\"role\",\"status\"],[12],[1,\"\\n        \"],[41,[28,[32,3],[[30,0,[\"saveState\"]],\"saved\"],null],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_saved\"],null]],null]]],[]],[[[41,[28,[32,3],[[30,0,[\"saveState\"]],\"idle\"],null],[[[1,\"\\n          \"],[41,[51,[30,0,[\"preferencesReady\"]]],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_loading\"],null]],null]]],[]],null],[1,\"\\n        \"]],[]],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_saving\"],null]],null]]],[]]]],[]]],[1,\"      \"],[13],[1,\"\\n\"]],[]],null]],[]],[[[1,\"    \"],[10,2],[14,0,\"isbf-explore__status\"],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.explore_guest_preferences\"],null]],null]],[13],[1,\"\\n  \"]],[]]]],[]]]],[]]],[41,[30,0,[\"filtersReady\"]],[[[42,[28,[31,3],[[28,[31,3],[[30,0,[\"groups\"]]],null]],null],\"key\",[[[1,\"      \"],[8,[32,7],null,[[\"@category\",\"@label\",\"@query\"],[[30,3,[\"category\"]],[30,3,[\"label\"]],[30,3,[\"query\"]]]],null],[1,\"\\n\"]],[3]],null]],[]],null],[13]],[\"@canCreateCategory\",\"@onCreateCategory\",\"group\"],[\"if\",\"unless\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didUpdate,
        ISBFExplorePicker,
        __keyword__not: not$1,
        __keyword__eq: eq$1,
        __keyword__on: on,
        i18n,
        themePrefix,
        ISBFExploreGroup
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-explore", ISBFExplore);
var Mod40 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFExplore
});
function learningConfig(site) {
  const config = site?.isbf_learning;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && Array.isArray(config.grades) && config.grades.every(grade => Number.isSafeInteger(grade?.id) && grade.id >= 1 && grade.id <= 4 && typeof grade.label === "string") && new Set(config.grades.map(grade => grade.id)).size === config.grades.length ? config : null;
}
function learningResourceQuery(courseId, query, page = 0) {
  return query.trim() ? {
    q: query.trim(),
    page
  } : {
    course_id: courseId,
    page
  };
}
function learningFileSize(bytes) {
  const size = Number(bytes);
  if (!Number.isFinite(size) || size < 0) {
    return "";
  }
  return size >= 1048576 ? `${(size / 1048576).toFixed(1)} MB` : `${Math.ceil(size / 1024)} KB`;
}
function learningSafeUrl(value) {
  if (typeof value !== "string" || /[\\\u0000-\u0020]/.test(value)) {
    return null;
  }
  return /^(https?:\/\/|\/(?!\/))/i.test(value) ? value : null;
}
function learningEditableResource(resource) {
  return Number.isSafeInteger(resource?.id) && resource.id > 0 && resource.link_only === true && Array.isArray(resource.files) && resource.files.length === 0;
}
function learningEditDetails(topic, post, courseId, prefix = "isbf_learning") {
  const firstPost = Array.isArray(topic?.post_stream?.posts) ? topic.post_stream.posts.find(entry => entry.post_number === 1) : null;
  if (!Number.isSafeInteger(topic?.id) || topic.id <= 0 || !Number.isSafeInteger(firstPost?.id) || post?.id !== firstPost.id || post.topic_id !== topic.id || post.post_number !== 1 || post.can_edit !== true || typeof topic.title !== "string" || typeof post.raw !== "string" || !courseId || post[`${prefix}_${prefix === "isbf_library" ? "group_id" : "course_id"}`] !== courseId || !Array.isArray(post[`${prefix}_files`]) || post[`${prefix}_files`].length !== 0 || typeof post[`${prefix}_link`] !== "string" || !post[`${prefix}_link`].trim() || post[`${prefix}_description`] != null && typeof post[`${prefix}_description`] !== "string" || post[`${prefix}_contributor`] != null && typeof post[`${prefix}_contributor`] !== "string") {
    return null;
  }
  return {
    postId: post.id,
    topicId: topic.id,
    title: topic.title,
    raw: post.raw,
    link: post[`${prefix}_link`],
    description: post[`${prefix}_description`] ?? "",
    contributor: post[`${prefix}_contributor`]?.trim() || post.name || post.username || ""
  };
}
function learningLinkBody(title, link, description = "") {
  const escapeHTML = value => value.replace(/[&<>"']/g, character => {
    return {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;"
    }[character];
  });
  const label = escapeHTML(title).replace(/[\\\[\]]/g, "\\$&");
  const body = `[${label}](<${link}>)`;
  const introduction = description.replace(/\r\n?/g, "\n").trim();
  return introduction ? `${body}\n\n${escapeHTML(introduction.replace(/[\\`*_{}\[\]()#+.!|~:\/-]/g, "\\$&"))}` : body;
}
function libraryConfig(site) {
  const config = site?.isbf_library;
  return Number.isSafeInteger(config?.category_id) && config.category_id > 0 && config.category_id !== site?.isbf_learning?.category_id && config.link_sharing === true && config.catalog_requests === true ? config : null;
}
var Mod72 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  learningConfig: learningConfig,
  learningEditDetails: learningEditDetails,
  learningEditableResource: learningEditableResource,
  learningFileSize: learningFileSize,
  learningLinkBody: learningLinkBody,
  learningResourceQuery: learningResourceQuery,
  learningSafeUrl: learningSafeUrl,
  libraryConfig: libraryConfig
});
class ISBFLearningDirectoryDeletion extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked]);
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "plan", [tracked]);
  }
  #plan = (dt7948.i(this, "plan"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  static {
    dt7948.g(this.prototype, "step", [tracked], function () {
      return 1;
    });
  }
  #step = (dt7948.i(this, "step"), void 0);
  #closed = false;
  #requesting = false;
  constructor() {
    super(...arguments);
    this.loadPlan();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }
  get canManage() {
    return Boolean(this.currentUser && (get(this.currentUser, "admin") || get(this.currentUser, "academy_moderator_permissions.manage_resources")));
  }
  get endpoint() {
    return `/isbf/learning/${this.args.kind === "grade" ? "grades" : "courses"}/${encodeURIComponent(this.args.entry.id)}`;
  }
  get title() {
    return i18n(themePrefix(this.args.kind === "grade" ? "isbf_v2.learning_delete_grade" : "isbf_v2.learning_delete_course"));
  }
  get message() {
    return i18n(themePrefix(`isbf_v2.learning_delete_step_${this.step}`), {
      name: this.plan.name,
      courses: this.plan.course_count,
      resources: this.plan.resource_count
    });
  }
  get warning() {
    return i18n(themePrefix(this.args.kind === "grade" ? "isbf_v2.learning_delete_grade_warning" : "isbf_v2.learning_delete_course_warning"));
  }
  get confirmLabel() {
    return i18n(themePrefix(this.step === this.plan?.required_confirmations ? "isbf_v2.learning_confirm_delete" : "isbf_v2.learning_delete_continue"));
  }
  close() {
    if (!this.saving) {
      this.#closed = true;
      this.args.onClose();
    }
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  async loadPlan() {
    if (this.#closed || this.#requesting || !this.canManage) {
      return;
    }
    this.#requesting = true;
    this.loading = true;
    this.plan = null;
    this.step = 1;
    try {
      const plan = await ajax(`${this.endpoint}/deletion-plan`);
      if (![2, 3].includes(plan.required_confirmations) || !plan.confirmation_token) {
        throw new Error("Unexpected deletion plan");
      }
      if (!this.#closed) {
        this.plan = plan;
      }
    } catch {
      if (!this.#closed) {
        this.error = i18n(themePrefix("isbf_v2.learning_directory_delete_load_error"));
      }
    } finally {
      this.#requesting = false;
      if (!this.#closed) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadPlan", [action]);
  }
  async confirm() {
    if (this.#closed || this.saving || !this.plan || !this.canManage) {
      return;
    }
    if (this.step < this.plan.required_confirmations) {
      this.step++;
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const result = await ajax(this.endpoint, {
        type: "DELETE",
        data: {
          confirmation_token: this.plan.confirmation_token,
          confirmation_count: this.step,
          cascade: this.plan.has_children
        }
      });
      if (result.success !== true) {
        throw new Error("Unexpected directory deletion response");
      }
      if (!this.#closed) {
        this.#closed = true;
        this.args.onDeleted(result);
      }
    } catch (error) {
      if (!this.#closed) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || error?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.learning_directory_delete_error"));
        await this.loadPlan();
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "confirm", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-learning-share-dialog isbf-learning-directory-deletion"
      @closeModal={{this.close}}
      @inline={{true}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
        {{#if this.loading}}<p role="status">{{i18n
              (themePrefix "isbf_v2.learning_loading")
            }}</p>{{/if}}
        {{#if this.plan}}
          <p aria-live="polite">{{this.message}}</p>
          {{#if (eq this.step 3)}}
            <p><strong
                class="isbf-learning-directory-deletion__warning"
              >{{this.warning}}</strong></p>
          {{/if}}
        {{/if}}
        <div
          class="isbf-learning-share-dialog__actions isbf-learning-directory-deletion__actions"
        >
          <DButton
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n
              (themePrefix "isbf_v2.learning_delete_back")
            }}
          />
          {{#if this.plan}}
            <DButton
              class="btn-danger isbf-learning-directory-deletion__confirm"
              @action={{this.confirm}}
              @disabled={{if this.canManage this.saving true}}
              @translatedLabel={{this.confirmLabel}}
            />
          {{else}}
            <DButton
              @action={{this.loadPlan}}
              @disabled={{this.loading}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.learning_retry")}}
            />
          {{/if}}
        </div>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-learning-share-dialog isbf-learning-directory-deletion\"]],[[\"@closeModal\",\"@inline\",\"@submitOnEnter\",\"@title\"],[[30,0,[\"close\"]],true,false,[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"plan\"]],[[[1,\"      \"],[10,2],[14,\"aria-live\",\"polite\"],[12],[1,[30,0,[\"message\"]]],[13],[1,\"\\n\"],[41,[28,[32,3],[[30,0,[\"step\"]],3],null],[[[1,\"        \"],[10,2],[12],[10,\"strong\"],[14,0,\"isbf-learning-directory-deletion__warning\"],[12],[1,[30,0,[\"warning\"]]],[13],[13],[1,\"\\n\"]],[]],null]],[]],null],[1,\"    \"],[10,0],[14,0,\"isbf-learning-share-dialog__actions isbf-learning-directory-deletion__actions\"],[12],[1,\"\\n      \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_delete_back\"],null]],null]]],null],[1,\"\\n\"],[41,[30,0,[\"plan\"]],[[[1,\"        \"],[8,[32,4],[[24,0,\"btn-danger isbf-learning-directory-deletion__confirm\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"confirm\"]],[52,[30,0,[\"canManage\"]],[30,0,[\"saving\"]],true],[30,0,[\"confirmLabel\"]]]],null],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"loadPlan\"]],[30,0,[\"loading\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_retry\"],null]],null]]],null],[1,\"\\n\"]],[]]],[1,\"    \"],[13],[1,\"\\n  \"]],[]]]]]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        eq,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-learning-directory-deletion", ISBFLearningDirectoryDeletion);
var Mod180 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFLearningDirectoryDeletion
});
class ISBFLearningDirectoryEditor extends Component {
  static {
    dt7948.g(this.prototype, "error", [tracked]);
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  data;
  #closed = false;
  constructor() {
    super(...arguments);
    this.data = {
      name: this.args.entry.name || this.args.entry.label,
      grade: this.args.entry.grade
    };
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }
  get title() {
    return i18n(themePrefix(this.args.kind === "grade" ? "isbf_v2.learning_edit_grade" : "isbf_v2.learning_edit_course"));
  }
  close() {
    if (!this.saving) {
      this.args.onClose();
    }
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  async save(data) {
    if (this.saving || this.#closed) {
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const response = await ajax(`/isbf/learning/${this.args.kind === "grade" ? "grades" : "courses"}/${encodeURIComponent(this.args.entry.id)}`, {
        type: "PUT",
        data
      });
      if (response.success !== true) {
        throw new Error("Unexpected course directory response");
      }
      if (!this.#closed) {
        this.args.onSaved(response, this.args.kind === "grade" ? this.args.entry.id : Number(data.grade));
      }
    } catch (error) {
      if (!this.#closed) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.learning_course_save_error"));
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-learning-share-dialog"
      @closeModal={{this.close}}
      @inline={{true}}
      @title={{this.title}}
    >
      <:body>
        <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
          <form.Field
            @disabled={{this.saving}}
            @name="name"
            @title={{this.title}}
            @type="input"
            @validation="required"
            as |field|
          >
            <field.Control maxlength={{80}} />
          </form.Field>
          {{#unless (eq @kind "grade")}}
            <form.Field
              @disabled={{this.saving}}
              @name="grade"
              @title={{i18n (themePrefix "isbf_v2.learning_grade")}}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control as |select|>
                {{#each @grades as |grade|}}<select.Option
                    @value={{grade.id}}
                  >{{grade.label}}</select.Option>{{/each}}
              </field.Control>
            </form.Field>
          {{/unless}}
          {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
          <form.Actions>
            {{#if @onDelete}}
              <DButton
                class="btn-danger isbf-learning-directory-editor__delete"
                @action={{@onDelete}}
                @disabled={{this.saving}}
                @translatedLabel={{i18n
                  (themePrefix "isbf_v2.learning_confirm_delete")
                }}
              />
            {{/if}}
            <DButton
              @action={{this.close}}
              @disabled={{this.saving}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
            />
            <form.Submit
              @label={{themePrefix "isbf_v2.learning_save_changes"}}
            />
          </form.Actions>
        </Form>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-learning-share-dialog\"]],[[\"@closeModal\",\"@inline\",\"@title\"],[[30,0,[\"close\"]],true,[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[8,[32,1],null,[[\"@data\",\"@onSubmit\"],[[30,0,[\"data\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,1,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"name\",[30,0,[\"title\"]],\"input\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,2,[\"Control\"]],[[16,\"maxlength\",80]],null,null],[1,\"\\n      \"]],[2]]]]],[1,\"\\n\"],[41,[51,[28,[32,2],[[30,3],\"grade\"],null]],[[[1,\"        \"],[8,[30,1,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"grade\",[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_grade\"],null]],null],\"select\",\"required\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,4,[\"Control\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[42,[28,[31,2],[[28,[31,2],[[30,6]],null]],null],null,[[[8,[30,5,[\"Option\"]],null,[[\"@value\"],[[30,7,[\"id\"]]]],[[\"default\"],[[[[1,[30,7,[\"label\"]]]],[]]]]]],[7]],null],[1,\"\\n          \"]],[5]]]]],[1,\"\\n        \"]],[4]]]]],[1,\"\\n\"]],[]],null],[1,\"      \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n      \"],[8,[30,1,[\"Actions\"]],null,null,[[\"default\"],[[[[1,\"\\n\"],[41,[30,8],[[[1,\"          \"],[8,[32,5],[[24,0,\"btn-danger isbf-learning-directory-editor__delete\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,8],[30,0,[\"saving\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_confirm_delete\"],null]],null]]],null],[1,\"\\n\"]],[]],null],[1,\"        \"],[8,[32,5],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n        \"],[8,[30,1,[\"Submit\"]],null,[[\"@label\"],[[28,[32,4],[\"isbf_v2.learning_save_changes\"],null]]],null],[1,\"\\n      \"]],[]]]]],[1,\"\\n    \"]],[1]]]]],[1,\"\\n  \"]],[]]]]]],[\"form\",\"field\",\"@kind\",\"field\",\"select\",\"@grades\",\"grade\",\"@onDelete\"],[\"unless\",\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        Form,
        eq,
        i18n,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-learning-directory-editor", ISBFLearningDirectoryEditor);
var Mod178 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFLearningDirectoryEditor
});
const COLLECTION_URL = "https://f.wps.cn/g/wG6gL3Rz/";
class ISBFLearningManagementDialog extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked]);
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "lookupError", [tracked]);
  }
  #lookupError = (dt7948.i(this, "lookupError"), void 0);
  static {
    dt7948.g(this.prototype, "lookingUp", [tracked], function () {
      return false;
    });
  }
  #lookingUp = (dt7948.i(this, "lookingUp"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  static {
    dt7948.g(this.prototype, "selectedUser", [tracked]);
  }
  #selectedUser = (dt7948.i(this, "selectedUser"), void 0);
  static {
    dt7948.g(this.prototype, "studentNumber", [tracked], function () {
      return "";
    });
  }
  #studentNumber = (dt7948.i(this, "studentNumber"), void 0);
  static {
    dt7948.g(this.prototype, "users", [tracked], function () {
      return null;
    });
  }
  #users = (dt7948.i(this, "users"), void 0);
  collectionUrl = COLLECTION_URL;
  data;
  #closed = false;
  #lookupGeneration = 0;
  constructor() {
    super(...arguments);
    const resource = this.args.resource;
    this.studentNumber = resource?.student_number || "";
    this.selectedUser = resource?.contributor_user_id ? {
      id: resource.contributor_user_id
    } : null;
    this.data = {
      title: resource?.title || "",
      description: resource?.description || "",
      link: resource?.links?.[0] || "",
      contributor: resource?.contributor || this.currentUser?.name || this.currentUser?.username || "",
      student_number: this.studentNumber,
      course_id: resource?.course?.id || this.args.course?.id
    };
    if (this.selectedUser && this.studentNumber) {
      this.lookupUsers();
    }
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
    this.#lookupGeneration++;
  }
  get canManage() {
    return Boolean(this.currentUser?.admin || this.currentUser?.academy_moderator_permissions?.manage_resources);
  }
  get title() {
    return i18n(themePrefix(this.args.resource ? "isbf_v2.learning_edit" : "isbf_v2.learning_share"));
  }
  get selectedLabel() {
    return this.selectedUser?.name || this.selectedUser?.username || i18n(themePrefix("isbf_v2.learning_linked_user"));
  }
  get associationRequired() {
    return Boolean(this.studentNumber && !this.selectedUser);
  }
  get courses() {
    return (this.args.courses || []).map(course => ({
      ...course,
      label: i18n(themePrefix("isbf_v2.learning_course_option"), {
        grade: this.args.grades?.find(grade => grade.id === course.grade)?.label || "",
        name: course.name
      })
    }));
  }
  changeStudentNumber(value, {
    set
  }) {
    set("student_number", value);
    this.studentNumber = value?.trim() || "";
    this.selectedUser = null;
    this.users = null;
    this.lookupError = null;
    this.#lookupGeneration++;
    this.lookingUp = false;
  }
  static {
    dt7948.n(this.prototype, "changeStudentNumber", [action]);
  }
  async lookupUsers() {
    if (!this.canManage || !this.studentNumber || this.saving) {
      return;
    }
    const generation = ++this.#lookupGeneration;
    this.lookingUp = true;
    this.lookupError = null;
    try {
      const response = await ajax("/isbf/learning/contributor-users", {
        data: {
          student_number: this.studentNumber
        }
      });
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.users = response.users || [];
        if (this.selectedUser) {
          this.selectedUser = this.users.find(user => user.id === this.selectedUser.id) || this.selectedUser;
        }
      }
    } catch {
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.lookupError = i18n(themePrefix("isbf_v2.learning_lookup_error"));
      }
    } finally {
      if (!this.#closed && generation === this.#lookupGeneration) {
        this.lookingUp = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "lookupUsers", [action]);
  }
  selectUser(user) {
    this.selectedUser = user;
  }
  static {
    dt7948.n(this.prototype, "selectUser", [action]);
  }
  close() {
    if (!this.saving) {
      this.#closed = true;
      this.args.onClose();
    }
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  async save(data) {
    if (this.#closed || !this.canManage || this.saving || this.associationRequired) {
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const payload = {
        ...data,
        student_number: this.studentNumber,
        contributor_user_id: this.selectedUser?.id || ""
      };
      if (data.link?.trim()) {
        payload.link = data.link.trim();
      } else {
        delete payload.link;
      }
      const response = await ajax(`/isbf/learning/resources${this.args.resource ? `/${this.args.resource.id}` : ""}`, {
        type: this.args.resource ? "PUT" : "POST",
        data: payload
      });
      if (response?.success !== true || response.pending !== false) {
        throw new Error("Unexpected learning management response");
      }
      if (!this.#closed) {
        this.#closed = true;
        this.args.onSubmitted(response);
      }
    } catch (error) {
      if (!this.#closed) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.learning_edit_error"));
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-learning-share-dialog"
      @closeModal={{this.close}}
      @inline={{true}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        {{#if this.canManage}}
          <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
            <form.Field
              @name="title"
              @title={{i18n (themePrefix "isbf_v2.learning_resource_title")}}
              @type="input"
              @validation="required"
              as |field|
            >
              <field.Control
                disabled={{this.saving}}
                maxlength={{this.siteSettings.max_topic_title_length}}
                minlength={{this.siteSettings.min_topic_title_length}}
              />
            </form.Field>
            <form.Field
              @name="description"
              @title={{i18n
                (themePrefix "isbf_v2.learning_resource_description")
              }}
              @type="textarea"
              as |field|
            >
              <field.Control disabled={{this.saving}} maxlength={{300}} />
            </form.Field>
            <form.Field
              @name="link"
              @title={{i18n (themePrefix "isbf_v2.learning_resource_link")}}
              @type="input"
              @validation={{if @resource.files.length "" "required"}}
              as |field|
            >
              <field.Control
                disabled={{this.saving}}
                maxlength={{2048}}
                @type="url"
              />
            </form.Field>
            <form.Field
              @name="contributor"
              @title={{i18n
                (themePrefix "isbf_v2.learning_resource_contributor")
              }}
              @type="input"
              as |field|
            >
              <field.Control disabled={{this.saving}} />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @name="course_id"
              @title={{i18n (themePrefix "isbf_v2.learning_course_name")}}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control as |select|>
                {{#each this.courses as |course|}}<select.Option
                    @value={{course.id}}
                  >{{course.label}}</select.Option>{{/each}}
              </field.Control>
            </form.Field>
            <form.Field
              @name="student_number"
              @onSet={{this.changeStudentNumber}}
              @title={{i18n (themePrefix "isbf_v2.learning_student_number")}}
              @type="input"
              as |field|
            >
              <field.Control disabled={{this.saving}} maxlength={{64}} />
            </form.Field>
            <p class="isbf-learning-share-dialog__course">{{i18n
                (themePrefix "isbf_v2.learning_student_hint")
              }}</p>
            <DButton
              class="isbf-learning-share-dialog__find-user"
              @action={{this.lookupUsers}}
              @disabled={{this.lookingUp}}
              @translatedLabel={{i18n
                (themePrefix "isbf_v2.learning_find_user")
              }}
            />
            {{#if this.lookingUp}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_loading")
                }}</p>{{/if}}
            {{#each this.users as |user|}}
              <DButton
                class="isbf-learning-share-dialog__contributor-user"
                @action={{fn this.selectUser user}}
                @disabled={{this.saving}}
              >
                {{dAvatar user imageSize="small"}}
                <span>{{i18n
                    (themePrefix "isbf_v2.learning_user_option")
                    name=user.name
                    username=user.username
                  }}</span>
              </DButton>
            {{else}}
              {{#if this.users}}<p role="status">{{i18n
                    (themePrefix "isbf_v2.learning_no_user")
                  }}</p>{{/if}}
            {{/each}}
            {{#if this.selectedUser}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_selected_user")
                  user=this.selectedLabel
                }}</p>{{/if}}
            {{#if this.lookupError}}<p
                role="alert"
              >{{this.lookupError}}</p>{{/if}}
            {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
            <form.Actions>
              <DButton
                @action={{this.close}}
                @disabled={{this.saving}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
              />
              <form.Submit
                @disabled={{this.associationRequired}}
                @label={{themePrefix "isbf_v2.learning_save"}}
              />
            </form.Actions>
          </Form>
        {{else}}
          <p><a
              href={{this.collectionUrl}}
              rel="noopener noreferrer"
              target="_blank"
            >{{i18n (themePrefix "isbf_v2.learning_wps_collection")}}</a></p>
        {{/if}}
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-learning-share-dialog\"]],[[\"@closeModal\",\"@inline\",\"@submitOnEnter\",\"@title\"],[[30,0,[\"close\"]],true,false,[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n\"],[41,[30,0,[\"canManage\"]],[[[1,\"      \"],[8,[32,1],null,[[\"@data\",\"@onSubmit\"],[[30,0,[\"data\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\",\"@validation\"],[\"title\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_resource_title\"],null]],null],\"input\",\"required\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,2,[\"Control\"]],[[16,\"disabled\",[30,0,[\"saving\"]]],[16,\"maxlength\",[30,0,[\"siteSettings\",\"max_topic_title_length\"]]],[16,\"minlength\",[30,0,[\"siteSettings\",\"min_topic_title_length\"]]]],null,null],[1,\"\\n        \"]],[2]]]]],[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"description\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_resource_description\"],null]],null],\"textarea\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,3,[\"Control\"]],[[16,\"disabled\",[30,0,[\"saving\"]]],[16,\"maxlength\",300]],null,null],[1,\"\\n        \"]],[3]]]]],[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\",\"@validation\"],[\"link\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_resource_link\"],null]],null],\"input\",[52,[30,4,[\"files\",\"length\"]],\"\",\"required\"]]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,5,[\"Control\"]],[[16,\"disabled\",[30,0,[\"saving\"]]],[16,\"maxlength\",2048]],[[\"@type\"],[\"url\"]],null],[1,\"\\n        \"]],[5]]]]],[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"contributor\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_resource_contributor\"],null]],null],\"input\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,6,[\"Control\"]],[[16,\"disabled\",[30,0,[\"saving\"]]]],null,null],[1,\"\\n        \"]],[6]]]]],[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"course_id\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_course_name\"],null]],null],\"select\",\"required\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,7,[\"Control\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"courses\"]]],null]],null],null,[[[8,[30,8,[\"Option\"]],null,[[\"@value\"],[[30,9,[\"id\"]]]],[[\"default\"],[[[[1,[30,9,[\"label\"]]]],[]]]]]],[9]],null],[1,\"\\n          \"]],[8]]]]],[1,\"\\n        \"]],[7]]]]],[1,\"\\n        \"],[8,[30,1,[\"Field\"]],null,[[\"@name\",\"@onSet\",\"@title\",\"@type\"],[\"student_number\",[30,0,[\"changeStudentNumber\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_student_number\"],null]],null],\"input\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,10,[\"Control\"]],[[16,\"disabled\",[30,0,[\"saving\"]]],[16,\"maxlength\",64]],null,null],[1,\"\\n        \"]],[10]]]]],[1,\"\\n        \"],[10,2],[14,0,\"isbf-learning-share-dialog__course\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_student_hint\"],null]],null]],[13],[1,\"\\n        \"],[8,[32,4],[[24,0,\"isbf-learning-share-dialog__find-user\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"lookupUsers\"]],[30,0,[\"lookingUp\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_find_user\"],null]],null]]],null],[1,\"\\n        \"],[41,[30,0,[\"lookingUp\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"users\"]]],null]],null],null,[[[1,\"          \"],[8,[32,4],[[24,0,\"isbf-learning-share-dialog__contributor-user\"]],[[\"@action\",\"@disabled\"],[[28,[32,5],[[30,0,[\"selectUser\"]],[30,11]],null],[30,0,[\"saving\"]]]],[[\"default\"],[[[[1,\"\\n            \"],[1,[28,[32,6],[[30,11]],[[\"imageSize\"],[\"small\"]]]],[1,\"\\n            \"],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_user_option\"],null]],[[\"name\",\"username\"],[[30,11,[\"name\"]],[30,11,[\"username\"]]]]]],[13],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[11]],[[[1,\"          \"],[41,[30,0,[\"users\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_no_user\"],null]],null]],[13]],[]],null],[1,\"\\n\"]],[]]],[1,\"        \"],[41,[30,0,[\"selectedUser\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_selected_user\"],null]],[[\"user\"],[[30,0,[\"selectedLabel\"]]]]]],[13]],[]],null],[1,\"\\n        \"],[41,[30,0,[\"lookupError\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"lookupError\"]]],[13]],[]],null],[1,\"\\n        \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n        \"],[8,[30,1,[\"Actions\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n          \"],[8,[30,1,[\"Submit\"]],null,[[\"@disabled\",\"@label\"],[[30,0,[\"associationRequired\"]],[28,[32,3],[\"isbf_v2.learning_save\"],null]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n      \"]],[1]]]]],[1,\"\\n\"]],[]],[[[1,\"      \"],[10,2],[12],[10,3],[15,6,[30,0,[\"collectionUrl\"]]],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_wps_collection\"],null]],null]],[13],[13],[1,\"\\n\"]],[]]],[1,\"  \"]],[]]]]]],[\"form\",\"field\",\"field\",\"@resource\",\"field\",\"field\",\"field\",\"select\",\"course\",\"field\",\"user\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        Form,
        i18n,
        themePrefix,
        DButton,
        fn,
        dAvatar
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-learning-management-dialog", ISBFLearningManagementDialog);
var Mod179 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFLearningManagementDialog
});
class ISBFResourceParentPicker extends Component {
  get ariaLabel() {
    return this.args.label || i18n(themePrefix("isbf_v2.learning_grade"));
  }
  get label() {
    return this.args.grades.find(grade => grade.id === this.args.value)?.label || this.args.label;
  }
  async select(menu, id) {
    this.args.onChange(id);
    await menu.close();
  }
  static {
    dt7948.n(this.prototype, "select", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DMenu
      @ariaLabel={{this.ariaLabel}}
      @constrainHeightToViewport={{true}}
      @contentClass="isbf-learning-grade-menu"
      @crossAxisShift={{false}}
      @icon="chevron-down"
      @label={{this.label}}
      @matchTriggerMinWidth={{true}}
      @modalForMobile={{false}}
      @placement="bottom-start"
      @strategy="fixed"
      @title={{this.label}}
      @triggerClass="btn-flat isbf-learning__grade"
      @visibilityOptimizer="none"
    >
      <:content as |menu|>
        <DDropdownMenu as |dropdown|>
          {{#each @grades as |grade|}}
            <dropdown.item>
              <DButton
                @action={{fn this.select menu grade.id}}
                @translatedLabel={{grade.label}}
              />
            </dropdown.item>
          {{/each}}
        </DDropdownMenu>
      </:content>
    </DMenu>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@constrainHeightToViewport\",\"@contentClass\",\"@crossAxisShift\",\"@icon\",\"@label\",\"@matchTriggerMinWidth\",\"@modalForMobile\",\"@placement\",\"@strategy\",\"@title\",\"@triggerClass\",\"@visibilityOptimizer\"],[[30,0,[\"ariaLabel\"]],true,\"isbf-learning-grade-menu\",false,\"chevron-down\",[30,0,[\"label\"]],true,false,\"bottom-start\",\"fixed\",[30,0,[\"label\"]],\"btn-flat isbf-learning__grade\",\"none\"]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,1],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,3]],null]],null],null,[[[1,\"        \"],[8,[30,2,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,2],null,[[\"@action\",\"@translatedLabel\"],[[28,[32,3],[[30,0,[\"select\"]],[30,1],[30,4,[\"id\"]]],null],[30,4,[\"label\"]]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[4]],null],[1,\"    \"]],[2]]]]],[1,\"\\n  \"]],[1]]]]]],[\"menu\",\"dropdown\",\"@grades\",\"grade\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        DDropdownMenu,
        DButton,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-resource-parent-picker", ISBFResourceParentPicker);
var Mod126 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceParentPicker
});
const __discourseComponentClass$4 = setComponentTemplate(createTemplateFactory(
/*
  <aside aria-label={{@page.directoryLabel}} class="isbf-learning__courses">
  <div class="isbf-resource-parent">
    <div class="isbf-resource-parent__picker">
      <ISBFResourceParentPicker
        @grades={{@page.parents}}
        @label={{@page.parentLabel}}
        @onChange={{@page.changeGrade}}
        @value={{@page.grade}}
      />
    </div>
    {{#unless @page.isLibrary}}{{#if @page.canManageResources}}<DButton
          class="btn-flat isbf-learning__edit-grade"
          @action={{@page.editGrade}}
          @icon="pencil"
          @translatedTitle={{i18n
            (themePrefix "isbf_v2.learning_edit_grade")
          }}
        />{{/if}}{{/unless}}
    {{#if @page.isLibrary}}{{#if @page.canSubmitCourses}}<DButton
          class="btn-flat"
          @action={{fn @page.openCourseDialog "category"}}
          @icon="plus"
          @translatedTitle={{@page.categoryActionLabel}}
        />{{/if}}{{/if}}
  </div>
  {{#if @page.coursesLoading}}<p role="status">{{i18n
        (themePrefix "isbf_v2.learning_loading")
      }}</p>{{/if}}
  {{#if @page.coursesError}}
    <p role="alert">{{i18n (themePrefix "isbf_v2.learning_load_error")}}</p>
    <DButton
      @action={{@page.loadCourses}}
      @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
    />
  {{else}}
    <nav aria-label={{@page.directoryLabel}}>
      {{#each @page.courseItems as |course|}}
        <DButton
          class={{if
            course.selected
            "btn-flat isbf-learning__course is-active"
            "btn-flat isbf-learning__course"
          }}
          @action={{fn @page.selectCourse course.id}}
          @ariaPressed={{course.selected}}
          @translatedLabel={{course.name}}
        />
      {{else}}
        {{#unless @page.coursesLoading}}<p>{{i18n
              (themePrefix
                (if
                  @page.isLibrary
                  "isbf_v2.library_no_groups"
                  "isbf_v2.learning_no_courses"
                )
              )
            }}</p>{{/unless}}
      {{/each}}
    </nav>
  {{/if}}
  {{#if @page.canSubmitCourses}}<DButton
      class="btn-flat isbf-learning__add-course"
      @action={{@page.openCourseDialog}}
      @disabled={{@page.groupSubmitDisabled}}
      @icon="plus"
      @translatedLabel={{@page.courseActionLabel}}
    />{{/if}}
  {{#if @page.coursePending}}<p
      class="isbf-learning__notice"
      role="status"
    >{{i18n
        (themePrefix
          (if
            @page.isLibrary
            "isbf_v2.library_directory_pending"
            "isbf_v2.learning_course_pending"
          )
        )
      }}</p>{{/if}}
</aside>
*/
{
  "id": null,
  "block": "[[[10,\"aside\"],[15,\"aria-label\",[30,1,[\"directoryLabel\"]]],[14,0,\"isbf-learning__courses\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-resource-parent\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-resource-parent__picker\"],[12],[1,\"\\n      \"],[8,[32,0],null,[[\"@grades\",\"@label\",\"@onChange\",\"@value\"],[[30,1,[\"parents\"]],[30,1,[\"parentLabel\"]],[30,1,[\"changeGrade\"]],[30,1,[\"grade\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[41,[51,[30,1,[\"isLibrary\"]]],[[[41,[30,1,[\"canManageResources\"]],[[[8,[32,1],[[24,0,\"btn-flat isbf-learning__edit-grade\"]],[[\"@action\",\"@icon\",\"@translatedTitle\"],[[30,1,[\"editGrade\"]],\"pencil\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_edit_grade\"],null]],null]]],null]],[]],null]],[]],null],[1,\"\\n    \"],[41,[30,1,[\"isLibrary\"]],[[[41,[30,1,[\"canSubmitCourses\"]],[[[8,[32,1],[[24,0,\"btn-flat\"]],[[\"@action\",\"@icon\",\"@translatedTitle\"],[[28,[32,4],[[30,1,[\"openCourseDialog\"]],\"category\"],null],\"plus\",[30,1,[\"categoryActionLabel\"]]]],null]],[]],null]],[]],null],[1,\"\\n  \"],[13],[1,\"\\n  \"],[41,[30,1,[\"coursesLoading\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,1,[\"coursesError\"]],[[[1,\"    \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_load_error\"],null]],null]],[13],[1,\"\\n    \"],[8,[32,1],null,[[\"@action\",\"@translatedLabel\"],[[30,1,[\"loadCourses\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.explore_retry\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,\"nav\"],[15,\"aria-label\",[30,1,[\"directoryLabel\"]]],[12],[1,\"\\n\"],[42,[28,[31,3],[[28,[31,3],[[30,1,[\"courseItems\"]]],null]],null],null,[[[1,\"        \"],[8,[32,1],[[16,0,[52,[30,2,[\"selected\"]],\"btn-flat isbf-learning__course is-active\",\"btn-flat isbf-learning__course\"]]],[[\"@action\",\"@ariaPressed\",\"@translatedLabel\"],[[28,[32,4],[[30,1,[\"selectCourse\"]],[30,2,[\"id\"]]],null],[30,2,[\"selected\"]],[30,2,[\"name\"]]]],null],[1,\"\\n\"]],[2]],[[[1,\"        \"],[41,[51,[30,1,[\"coursesLoading\"]]],[[[10,2],[12],[1,[28,[32,2],[[28,[32,3],[[52,[30,1,[\"isLibrary\"]],\"isbf_v2.library_no_groups\",\"isbf_v2.learning_no_courses\"]],null]],null]],[13]],[]],null],[1,\"\\n\"]],[]]],[1,\"    \"],[13],[1,\"\\n\"]],[]]],[1,\"  \"],[41,[30,1,[\"canSubmitCourses\"]],[[[8,[32,1],[[24,0,\"btn-flat isbf-learning__add-course\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedLabel\"],[[30,1,[\"openCourseDialog\"]],[30,1,[\"groupSubmitDisabled\"]],\"plus\",[30,1,[\"courseActionLabel\"]]]],null]],[]],null],[1,\"\\n  \"],[41,[30,1,[\"coursePending\"]],[[[10,2],[14,0,\"isbf-learning__notice\"],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[[52,[30,1,[\"isLibrary\"]],\"isbf_v2.library_directory_pending\",\"isbf_v2.learning_course_pending\"]],null]],null]],[13]],[]],null],[1,\"\\n\"],[13]],[\"@page\",\"course\"],[\"unless\",\"if\",\"each\",\"-track-array\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    ISBFResourceParentPicker,
    DButton,
    i18n,
    themePrefix,
    fn
  }),
  "isStrictMode": true
}), templateOnly());
registerModuleForModifyClass("isbf-resource-catalog", __discourseComponentClass$4);
var Mod121 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass$4
});
class ISBFResourceDirectoryDialog extends Component {
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return null;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "grade", [tracked]);
  }
  #grade = (dt7948.i(this, "grade"), void 0);
  static {
    dt7948.g(this.prototype, "name", [tracked], function () {
      return "";
    });
  }
  #name = (dt7948.i(this, "name"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  #closed = false;
  constructor() {
    super(...arguments);
    this.grade = this.args.grade;
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }
  get endpoint() {
    return this.args.library ? `/isbf/library/${this.args.kind === "category" ? "categories" : "groups"}` : "/isbf/learning/courses";
  }
  get title() {
    return i18n(themePrefix(this.args.library ? `isbf_v2.library_${this.args.request ? "request" : "add"}_${this.args.kind}` : this.args.request ? "isbf_v2.learning_request_course" : "isbf_v2.learning_add_course"));
  }
  get submitLabel() {
    return i18n(themePrefix(this.args.request ? "isbf_v2.learning_submit_request" : "isbf_v2.learning_save"));
  }
  get saveDisabled() {
    const length = [...this.name.trim()].length;
    return this.saving || !length || length > 80 || this.args.library && this.args.kind === "group" && !this.grade;
  }
  changeGrade(id) {
    if (!this.saving) {
      this.grade = id;
    }
  }
  static {
    dt7948.n(this.prototype, "changeGrade", [action]);
  }
  changeName(event) {
    this.name = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "changeName", [action]);
  }
  close() {
    if (this.saving) {
      return;
    }
    this.#closed = true;
    this.args.onClose();
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  focusName(element) {
    element.focus();
  }
  static {
    dt7948.n(this.prototype, "focusName", [action]);
  }
  handleKeydown(event) {
    if (event.key === "Escape" && !this.saving) {
      event.stopPropagation();
      this.close();
    }
  }
  static {
    dt7948.n(this.prototype, "handleKeydown", [action]);
  }
  async save(event) {
    event.preventDefault();
    if (this.#closed || this.saveDisabled) {
      return;
    }
    this.error = null;
    this.saving = true;
    try {
      let response = await ajax(this.endpoint, {
        type: "POST",
        data: {
          name: this.name.trim(),
          ...(this.args.library ? this.args.kind === "group" ? {
            category_id: this.grade
          } : {} : {
            grade: this.grade
          })
        }
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (!this.args.request && !this.args.library && response?.course?.id && response.success === undefined && response.pending === undefined) {
        response = {
          ...response,
          success: true,
          pending: false
        };
      }
      if (response?.success !== true || typeof response.pending !== "boolean" || (response.pending ? !response.reviewable_id : !(this.args.library ? response[this.args.kind]?.id : response.course?.id))) {
        throw new Error("Unexpected learning course response");
      }
      this.#closed = true;
      this.args.onSubmitted(response, this.args.library && this.args.kind === "category" && !response.pending ? response.category.id : this.grade);
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix(this.args.library ? "isbf_v2.library_directory_error" : "isbf_v2.learning_course_save_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <section
      aria-label={{this.title}}
      class="isbf-learning-course-dialog"
      role="dialog"
      tabindex="-1"
      {{on "keydown" this.handleKeydown}}
    >
      <h2>{{this.title}}</h2>
      <form {{on "submit" this.save}}>
        <label>
          <span>{{i18n
              (themePrefix
                (if
                  @library
                  "isbf_v2.library_directory_name"
                  "isbf_v2.learning_course_name"
                )
              )
            }}</span>
          <input
            disabled={{this.saving}}
            maxlength="80"
            required
            type="text"
            value={{this.name}}
            {{on "input" this.changeName}}
            {{didInsert this.focusName}}
          />
        </label>
        {{#unless @library}}<ISBFResourceParentPicker
            @grades={{@grades}}
            @onChange={{this.changeGrade}}
            @value={{this.grade}}
          />{{/unless}}
        {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
        <div class="isbf-learning-course-dialog__actions">
          <DButton
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
          />
          <DButton
            class="btn-primary"
            @disabled={{this.saveDisabled}}
            @translatedLabel={{this.submitLabel}}
            @type="submit"
          />
        </div>
      </form>
    </section>
    */
    {
      "id": null,
      "block": "[[[11,\"section\"],[16,\"aria-label\",[30,0,[\"title\"]]],[24,0,\"isbf-learning-course-dialog\"],[24,\"role\",\"dialog\"],[24,\"tabindex\",\"-1\"],[4,[32,0],[\"keydown\",[30,0,[\"handleKeydown\"]]],null],[12],[1,\"\\n  \"],[10,\"h2\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n  \"],[11,\"form\"],[4,[32,0],[\"submit\",[30,0,[\"save\"]]],null],[12],[1,\"\\n    \"],[10,\"label\"],[12],[1,\"\\n      \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[[52,[30,1],\"isbf_v2.library_directory_name\",\"isbf_v2.learning_course_name\"]],null]],null]],[13],[1,\"\\n      \"],[11,\"input\"],[16,\"disabled\",[30,0,[\"saving\"]]],[24,\"maxlength\",\"80\"],[24,\"required\",\"\"],[16,2,[30,0,[\"name\"]]],[24,4,\"text\"],[4,[32,0],[\"input\",[30,0,[\"changeName\"]]],null],[4,[32,3],[[30,0,[\"focusName\"]]],null],[12],[13],[1,\"\\n    \"],[13],[1,\"\\n    \"],[41,[51,[30,1]],[[[8,[32,4],null,[[\"@grades\",\"@onChange\",\"@value\"],[[30,2],[30,0,[\"changeGrade\"]],[30,0,[\"grade\"]]]],null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"isbf-learning-course-dialog__actions\"],[12],[1,\"\\n      \"],[8,[32,5],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n      \"],[8,[32,5],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@translatedLabel\",\"@type\"],[[30,0,[\"saveDisabled\"]],[30,0,[\"submitLabel\"]],\"submit\"]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@library\",\"@grades\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        on,
        i18n,
        themePrefix,
        didInsert,
        ISBFResourceParentPicker,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-resource-directory-dialog", ISBFResourceDirectoryDialog);
var Mod122 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceDirectoryDialog
});
class ISBFResourceItem extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "deleteError", [tracked], function () {
      return null;
    });
  }
  #deleteError = (dt7948.i(this, "deleteError"), void 0);
  static {
    dt7948.g(this.prototype, "deleting", [tracked], function () {
      return false;
    });
  }
  #deleting = (dt7948.i(this, "deleting"), void 0);
  static {
    dt7948.g(this.prototype, "menuPending", [tracked], function () {
      return false;
    });
  }
  #menuPending = (dt7948.i(this, "menuPending"), void 0);
  menuTriggers = ["click"];
  #closed = false;
  #hoverOpened = false;
  #menu;
  #opening = false;
  #pointerType;
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
    this.#menu = null;
  }
  get config() {
    return this.args.library ? this.site?.isbf_library : this.site?.isbf_learning;
  }
  get canDelete() {
    return Boolean((this.currentUser?.admin || !this.args.library && this.currentUser?.academy_moderator_permissions?.manage_resources) && this.config?.resource_admin_management === true && this.args.resource.can_delete === true);
  }
  get canEdit() {
    return this.args.library ? this.canDelete && learningEditableResource(this.args.resource) : this.canDelete && this.args.resource.can_edit === true;
  }
  get contributor() {
    return this.args.resource.contributor || this.args.resource.author?.name || this.args.resource.author?.username || i18n(themePrefix("isbf_v2.learning_unknown_contributor"));
  }
  get menuIdentifier() {
    return `isbf-learning-resource-more-${this.args.resource.id}`;
  }
  get createdAtLabel() {
    const date = new Date(this.args.resource.created_at);
    return Number.isNaN(date.getTime()) ? "" : new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium"
    }).format(date);
  }
  get contributionTimeLabel() {
    const date = new Date(this.args.resource.created_at);
    return Number.isNaN(date.getTime()) ? "" : new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(date);
  }
  get files() {
    return (this.args.resource.files || []).flatMap(file => {
      const url = learningSafeUrl(file.url);
      return url ? [{
        ...file,
        url,
        sizeLabel: learningFileSize(file.size),
        isImage: isImageAttachment(file)
      }] : [];
    });
  }
  get gradeLabel() {
    return (this.args.grades || []).find(grade => grade.id === this.args.resource.grade)?.label;
  }
  get links() {
    return (this.args.resource.links || []).filter(value => {
      if (!learningSafeUrl(value) || !/^https?:\/\//i.test(value)) {
        return false;
      }
      try {
        const url = new URL(value);
        return Boolean(url.hostname && !url.username && !url.password);
      } catch {
        return false;
      }
    });
  }
  get titleUrl() {
    return this.links[0];
  }
  get additionalLinks() {
    return this.args.resource.link_only ? [] : this.links;
  }
  registerMenu(menu) {
    this.#menu = menu;
  }
  static {
    dt7948.n(this.prototype, "registerMenu", [action]);
  }
  rememberPointer(event) {
    this.#pointerType = event.pointerType;
  }
  static {
    dt7948.n(this.prototype, "rememberPointer", [action]);
  }
  pinHoveredMenu(event) {
    if (this.#hoverOpened && this.#menu?.expanded && this.#pointerType === "mouse" && event.detail !== 0) {
      this.#hoverOpened = false;
      event.stopImmediatePropagation();
      event.stopPropagation();
    }
  }
  static {
    dt7948.n(this.prototype, "pinHoveredMenu", [action]);
  }
  async showForMouse(event) {
    if (event.pointerType !== "mouse" || this.#closed || this.isDestroying || this.deleting || this.menuPending || !this.canDelete || !this.#menu || this.#menu.expanded || this.#opening) {
      return;
    }
    this.#opening = true;
    this.#hoverOpened = true;
    try {
      await this.#menu.show();
    } finally {
      this.#opening = false;
    }
  }
  static {
    dt7948.n(this.prototype, "showForMouse", [action]);
  }
  async editFromMenu(menu) {
    if (this.#closed || this.isDestroying || this.menuPending || this.deleting || !this.canEdit) {
      return;
    }
    this.menuPending = true;
    try {
      await menu.close();
      if (!this.#closed && !this.isDestroying && this.canEdit) {
        this.args.onEdit(this.args.resource);
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.menuPending = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "editFromMenu", [action]);
  }
  async deleteFromMenu(menu) {
    if (this.#closed || this.isDestroying || this.menuPending || this.deleting || !this.canDelete) {
      return;
    }
    this.menuPending = true;
    try {
      await menu.close();
      await this.deleteResource();
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.menuPending = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "deleteFromMenu", [action]);
  }
  async deleteResource() {
    if (this.#closed || this.isDestroying || this.deleting || !this.canDelete) {
      return;
    }
    this.deleting = true;
    this.deleteError = null;
    try {
      const confirmed = await this.dialog.confirm({
        message: i18n(themePrefix(this.args.library ? "isbf_v2.library_delete_confirm" : "isbf_v2.learning_delete_confirm")),
        confirmButtonLabel: themePrefix("isbf_v2.learning_delete")
      });
      if (!confirmed || this.#closed || this.isDestroying || !this.canDelete) {
        return;
      }
      const response = await ajax(`/isbf/${this.args.library ? "library" : "learning"}/resources/${encodeURIComponent(this.args.resource.id)}`, {
        type: "DELETE"
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (response?.success !== true) {
        throw new Error("Unexpected learning delete response");
      }
      this.#closed = true;
      this.args.onDeleted();
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.deleteError = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix("isbf_v2.learning_delete_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.deleting = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "deleteResource", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <article class="isbf-learning-resource">
      <div class="isbf-learning-resource__header">
        <h3>{{#if this.titleUrl}}<a
              href={{this.titleUrl}}
              rel="noopener noreferrer"
              target="_blank"
            >{{@resource.title}}</a>{{else}}{{@resource.title}}{{/if}}</h3>
        <div class="isbf-learning-resource__metadata">
          <time datetime={{@resource.created_at}}>{{this.createdAtLabel}}</time>
          {{#if this.canDelete}}
            <DMenu
              @ariaLabel={{i18n "more"}}
              @autofocus={{false}}
              @contentClass="isbf-learning-resource-menu"
              @disabled={{this.deleting}}
              @icon="ellipsis"
              @identifier={{this.menuIdentifier}}
              @interactive={{true}}
              @modalForMobile={{false}}
              @onRegisterApi={{this.registerMenu}}
              @placement="bottom-end"
              @title={{i18n "more"}}
              @triggerClass="btn-flat isbf-learning-resource__more"
              @triggers={{this.menuTriggers}}
              @untriggers={{this.menuTriggers}}
              {{on "pointerenter" this.showForMouse}}
              {{on "pointerup" this.rememberPointer}}
              {{on "click" this.pinHoveredMenu capture=true}}
            >
              <:content as |menu|>
                <DDropdownMenu as |dropdown|>
                  {{#if this.canEdit}}
                    <dropdown.item>
                      <DButton
                        class="btn-flat isbf-learning-resource__edit"
                        @action={{fn this.editFromMenu menu}}
                        @disabled={{this.menuPending}}
                        @translatedLabel={{i18n
                          (themePrefix "isbf_v2.learning_edit")
                        }}
                      />
                    </dropdown.item>
                  {{/if}}
                  <dropdown.item>
                    <DButton
                      class="btn-flat isbf-learning-resource__delete"
                      @action={{fn this.deleteFromMenu menu}}
                      @disabled={{this.menuPending}}
                      @translatedLabel={{i18n
                        (themePrefix "isbf_v2.learning_delete")
                      }}
                    />
                  </dropdown.item>
                </DDropdownMenu>
              </:content>
            </DMenu>
          {{/if}}
        </div>
      </div>
      {{#if @resource.description}}<p
          class="isbf-learning-resource__description"
        >{{@resource.description}}</p>{{/if}}
      {{#if (or @searching @contributions)}}<p
          class="isbf-learning-resource__context"
        >{{#if @library}}{{@resource.category.name}}
            ·
            {{@resource.group.name}}{{else}}{{this.gradeLabel}}
            ·
            {{@resource.course.name}}{{/if}}</p>{{/if}}
      {{#if this.deleteError}}<p
          class="isbf-learning-resource__error"
          role="alert"
        >{{this.deleteError}}</p>{{/if}}
      {{#if this.files.length}}
        <ul
          aria-label={{i18n (themePrefix "isbf_v2.learning_files")}}
          class="isbf-learning-resource__attachments"
          {{contentImages}}
        >
          {{#each this.files as |file|}}
            <li>
              <a href={{file.url}}>{{file.name}}</a>
              <span>{{file.sizeLabel}}</span>
              {{#if file.isImage}}
                <a
                  aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
                  class="lightbox isbf-content-image-attachment"
                  href={{file.url}}
                >{{i18n (themePrefix "isbf_v2.preview_image")}}</a>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{/if}}
      {{#if @contributions}}
        {{#each this.links as |url|}}<p><a
              href={{url}}
              rel="noopener noreferrer"
              target="_blank"
            >{{url}}</a></p>{{/each}}
        <p class="isbf-learning-resource__context">{{i18n
            (themePrefix "isbf_v2.learning_library_time")
            time=this.contributionTimeLabel
          }}</p>
      {{/if}}
      {{#if this.additionalLinks.length}}
        <ul
          aria-label={{i18n (themePrefix "isbf_v2.learning_links")}}
          class="isbf-learning-resource__attachments"
        >
          {{#each this.additionalLinks as |url|}}<li><a
                href={{url}}
                rel="noopener noreferrer"
                target="_blank"
              >{{url}}</a></li>{{/each}}
        </ul>
      {{/if}}
      <p class="isbf-learning-resource__credit"><span>{{i18n
            (themePrefix "isbf_v2.learning_contributor_credit")
          }}</span>{{this.contributor}}</p>
    </article>
    */
    {
      "id": null,
      "block": "[[[10,\"article\"],[14,0,\"isbf-learning-resource\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-learning-resource__header\"],[12],[1,\"\\n    \"],[10,\"h3\"],[12],[41,[30,0,[\"titleUrl\"]],[[[10,3],[15,6,[30,0,[\"titleUrl\"]]],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[30,1,[\"title\"]]],[13]],[]],[[[1,[30,1,[\"title\"]]]],[]]],[13],[1,\"\\n    \"],[10,0],[14,0,\"isbf-learning-resource__metadata\"],[12],[1,\"\\n      \"],[10,\"time\"],[15,\"datetime\",[30,1,[\"created_at\"]]],[12],[1,[30,0,[\"createdAtLabel\"]]],[13],[1,\"\\n\"],[41,[30,0,[\"canDelete\"]],[[[1,\"        \"],[8,[32,0],[[4,[32,2],[\"pointerenter\",[30,0,[\"showForMouse\"]]],null],[4,[32,2],[\"pointerup\",[30,0,[\"rememberPointer\"]]],null],[4,[32,2],[\"click\",[30,0,[\"pinHoveredMenu\"]]],[[\"capture\"],[true]]]],[[\"@ariaLabel\",\"@autofocus\",\"@contentClass\",\"@disabled\",\"@icon\",\"@identifier\",\"@interactive\",\"@modalForMobile\",\"@onRegisterApi\",\"@placement\",\"@title\",\"@triggerClass\",\"@triggers\",\"@untriggers\"],[[28,[32,1],[\"more\"],null],false,\"isbf-learning-resource-menu\",[30,0,[\"deleting\"]],\"ellipsis\",[30,0,[\"menuIdentifier\"]],true,false,[30,0,[\"registerMenu\"]],\"bottom-end\",[28,[32,1],[\"more\"],null],\"btn-flat isbf-learning-resource__more\",[30,0,[\"menuTriggers\"]],[30,0,[\"menuTriggers\"]]]],[[\"content\"],[[[[1,\"\\n            \"],[8,[32,3],null,null,[[\"default\"],[[[[1,\"\\n\"],[41,[30,0,[\"canEdit\"]],[[[1,\"                \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n                  \"],[8,[32,4],[[24,0,\"btn-flat isbf-learning-resource__edit\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"editFromMenu\"]],[30,2]],null],[30,0,[\"menuPending\"]],[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_edit\"],null]],null]]],null],[1,\"\\n                \"]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"              \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n                \"],[8,[32,4],[[24,0,\"btn-flat isbf-learning-resource__delete\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"deleteFromMenu\"]],[30,2]],null],[30,0,[\"menuPending\"]],[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_delete\"],null]],null]]],null],[1,\"\\n              \"]],[]]]]],[1,\"\\n            \"]],[3]]]]],[1,\"\\n          \"]],[2]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[41,[30,1,[\"description\"]],[[[10,2],[14,0,\"isbf-learning-resource__description\"],[12],[1,[30,1,[\"description\"]]],[13]],[]],null],[1,\"\\n  \"],[41,[28,[32,7],[[30,4],[30,5]],null],[[[10,2],[14,0,\"isbf-learning-resource__context\"],[12],[41,[30,6],[[[1,[30,1,[\"category\",\"name\"]]],[1,\"\\n        ·\\n        \"],[1,[30,1,[\"group\",\"name\"]]]],[]],[[[1,[30,0,[\"gradeLabel\"]]],[1,\"\\n        ·\\n        \"],[1,[30,1,[\"course\",\"name\"]]]],[]]],[13]],[]],null],[1,\"\\n  \"],[41,[30,0,[\"deleteError\"]],[[[10,2],[14,0,\"isbf-learning-resource__error\"],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"deleteError\"]]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"files\",\"length\"]],[[[1,\"    \"],[11,\"ul\"],[16,\"aria-label\",[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_files\"],null]],null]],[24,0,\"isbf-learning-resource__attachments\"],[4,[32,8],null,null],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"files\"]]],null]],null],null,[[[1,\"        \"],[10,\"li\"],[12],[1,\"\\n          \"],[10,3],[15,6,[30,7,[\"url\"]]],[12],[1,[30,7,[\"name\"]]],[13],[1,\"\\n          \"],[10,1],[12],[1,[30,7,[\"sizeLabel\"]]],[13],[1,\"\\n\"],[41,[30,7,[\"isImage\"]],[[[1,\"            \"],[10,3],[15,\"aria-label\",[28,[32,1],[[28,[32,6],[\"isbf_v2.preview_image\"],null]],null]],[14,0,\"lightbox isbf-content-image-attachment\"],[15,6,[30,7,[\"url\"]]],[12],[1,[28,[32,1],[[28,[32,6],[\"isbf_v2.preview_image\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[13],[1,\"\\n\"]],[7]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[41,[30,5],[[[1,\"    \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"links\"]]],null]],null],null,[[[10,2],[12],[10,3],[15,6,[30,8]],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[30,8]],[13],[13]],[8]],null],[1,\"\\n    \"],[10,2],[14,0,\"isbf-learning-resource__context\"],[12],[1,[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_library_time\"],null]],[[\"time\"],[[30,0,[\"contributionTimeLabel\"]]]]]],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"additionalLinks\",\"length\"]],[[[1,\"    \"],[10,\"ul\"],[15,\"aria-label\",[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_links\"],null]],null]],[14,0,\"isbf-learning-resource__attachments\"],[12],[1,\"\\n      \"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"additionalLinks\"]]],null]],null],null,[[[10,\"li\"],[12],[10,3],[15,6,[30,9]],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[30,9]],[13],[13]],[9]],null],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[10,2],[14,0,\"isbf-learning-resource__credit\"],[12],[10,1],[12],[1,[28,[32,1],[[28,[32,6],[\"isbf_v2.learning_contributor_credit\"],null]],null]],[13],[1,[30,0,[\"contributor\"]]],[13],[1,\"\\n\"],[13]],[\"@resource\",\"menu\",\"dropdown\",\"@searching\",\"@contributions\",\"@library\",\"file\",\"url\",\"url\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        on,
        DDropdownMenu,
        DButton,
        fn,
        themePrefix,
        or,
        contentImages
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-resource-item", ISBFResourceItem);
var Mod123 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceItem
});
const __discourseComponentClass$3 = setComponentTemplate(createTemplateFactory(
/*
  <section
  aria-busy={{@page.resourcesLoading}}
  aria-label={{@page.contentTitle}}
  class="isbf-learning__content"
>
  <div class="isbf-learning__content-header">
    <h2>{{@page.contentTitle}}</h2>
    {{#unless @page.isLibrary}}{{#if @page.canManageResources}}{{#unless
          @page.myContributions
        }}{{#unless @page.searching}}{{#if @page.selectedCourse}}
              <DButton
                class="btn-flat isbf-learning__edit-course"
                @action={{fn @page.editCourse @page.selectedCourse}}
                @icon="pencil"
                @translatedLabel={{i18n
                  (themePrefix "isbf_v2.learning_edit_course")
                }}
              />
            {{/if}}{{/unless}}{{/unless}}{{/if}}{{/unless}}
    {{#unless @page.isLibrary}}<DButton
        class="btn-flat isbf-learning__contributions"
        @action={{@page.toggleContributions}}
        @ariaPressed={{@page.myContributions}}
        @translatedLabel={{i18n
          (themePrefix
            (if
              @page.myContributions
              "isbf_v2.learning_all_resources"
              "isbf_v2.learning_my_contributions"
            )
          )
        }}
      />{{/unless}}
    <DButton
      class="btn-primary isbf-learning__share"
      @action={{@page.share}}
      @disabled={{@page.shareDisabled}}
      @translatedLabel={{@page.shareLabel}}
    />
  </div>
  {{#unless @page.config.link_sharing}}<p
      class="isbf-learning__notice"
      role="status"
    >{{i18n
        (themePrefix "isbf_v2.learning_share_unavailable")
      }}</p>{{/unless}}
  {{#if @page.sharePending}}<p
      class="isbf-learning__notice"
      role="status"
    >{{i18n (themePrefix "isbf_v2.learning_share_pending")}}</p>{{/if}}
  {{#if @page.searching}}<p class="isbf-learning__hint">{{i18n
        (themePrefix
          (if
            @page.isLibrary
            "isbf_v2.library_search_hint"
            "isbf_v2.learning_search_hint"
          )
        )
      }}</p>{{/if}}
  {{#each @page.resources key="id" as |resource|}}<ISBFResourceItem
      @contributions={{@page.myContributions}}
      @grades={{@page.parents}}
      @library={{@page.isLibrary}}
      @onDeleted={{@page.resourceDeleted}}
      @onEdit={{@page.editResource}}
      @resource={{resource}}
      @searching={{@page.searching}}
    />{{/each}}
  {{#if @page.resourcesLoading}}<p
      class="isbf-learning__notice"
      role="status"
    >{{i18n (themePrefix "isbf_v2.learning_loading")}}</p>
  {{else if @page.resourcesError}}
    <p class="isbf-learning__notice" role="alert">{{i18n
        (themePrefix "isbf_v2.learning_load_error")
      }}</p>
    <DButton
      @action={{@page.retryResources}}
      @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
    />
  {{else if @page.resources.length}}
    {{#if @page.hasMore}}<DButton
        class="isbf-learning__load-more"
        @action={{@page.loadMore}}
        @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
      />{{/if}}
  {{else if @page.myContributions}}<p class="isbf-learning__notice">{{i18n
        (themePrefix "isbf_v2.learning_contributions_empty")
      }}</p>
  {{else}}<p class="isbf-learning__notice">{{i18n
        (themePrefix
          (if
            @page.isLibrary "isbf_v2.library_empty" "isbf_v2.learning_empty"
          )
        )
      }}</p>{{/if}}
</section>
*/
{
  "id": null,
  "block": "[[[10,\"section\"],[15,\"aria-busy\",[30,1,[\"resourcesLoading\"]]],[15,\"aria-label\",[30,1,[\"contentTitle\"]]],[14,0,\"isbf-learning__content\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-learning__content-header\"],[12],[1,\"\\n    \"],[10,\"h2\"],[12],[1,[30,1,[\"contentTitle\"]]],[13],[1,\"\\n    \"],[41,[51,[30,1,[\"isLibrary\"]]],[[[41,[30,1,[\"canManageResources\"]],[[[41,[51,[30,1,[\"myContributions\"]]],[[[41,[51,[30,1,[\"searching\"]]],[[[41,[30,1,[\"selectedCourse\"]],[[[1,\"\\n              \"],[8,[32,0],[[24,0,\"btn-flat isbf-learning__edit-course\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[28,[32,1],[[30,1,[\"editCourse\"]],[30,1,[\"selectedCourse\"]]],null],\"pencil\",[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_edit_course\"],null]],null]]],null],[1,\"\\n            \"]],[]],null]],[]],null]],[]],null]],[]],null]],[]],null],[1,\"\\n    \"],[41,[51,[30,1,[\"isLibrary\"]]],[[[8,[32,0],[[24,0,\"btn-flat isbf-learning__contributions\"]],[[\"@action\",\"@ariaPressed\",\"@translatedLabel\"],[[30,1,[\"toggleContributions\"]],[30,1,[\"myContributions\"]],[28,[32,2],[[28,[32,3],[[52,[30,1,[\"myContributions\"]],\"isbf_v2.learning_all_resources\",\"isbf_v2.learning_my_contributions\"]],null]],null]]],null]],[]],null],[1,\"\\n    \"],[8,[32,0],[[24,0,\"btn-primary isbf-learning__share\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,1,[\"share\"]],[30,1,[\"shareDisabled\"]],[30,1,[\"shareLabel\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n  \"],[41,[51,[30,1,[\"config\",\"link_sharing\"]]],[[[10,2],[14,0,\"isbf-learning__notice\"],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_share_unavailable\"],null]],null]],[13]],[]],null],[1,\"\\n  \"],[41,[30,1,[\"sharePending\"]],[[[10,2],[14,0,\"isbf-learning__notice\"],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_share_pending\"],null]],null]],[13]],[]],null],[1,\"\\n  \"],[41,[30,1,[\"searching\"]],[[[10,2],[14,0,\"isbf-learning__hint\"],[12],[1,[28,[32,2],[[28,[32,3],[[52,[30,1,[\"isLibrary\"]],\"isbf_v2.library_search_hint\",\"isbf_v2.learning_search_hint\"]],null]],null]],[13]],[]],null],[1,\"\\n  \"],[42,[28,[31,3],[[28,[31,3],[[30,1,[\"resources\"]]],null]],null],\"id\",[[[8,[32,4],null,[[\"@contributions\",\"@grades\",\"@library\",\"@onDeleted\",\"@onEdit\",\"@resource\",\"@searching\"],[[30,1,[\"myContributions\"]],[30,1,[\"parents\"]],[30,1,[\"isLibrary\"]],[30,1,[\"resourceDeleted\"]],[30,1,[\"editResource\"]],[30,2],[30,1,[\"searching\"]]]],null]],[2]],null],[1,\"\\n  \"],[41,[30,1,[\"resourcesLoading\"]],[[[10,2],[14,0,\"isbf-learning__notice\"],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,1,[\"resourcesError\"]],[[[1,\"    \"],[10,2],[14,0,\"isbf-learning__notice\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_load_error\"],null]],null]],[13],[1,\"\\n    \"],[8,[32,0],null,[[\"@action\",\"@translatedLabel\"],[[30,1,[\"retryResources\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.explore_retry\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[41,[30,1,[\"resources\",\"length\"]],[[[1,\"    \"],[41,[30,1,[\"hasMore\"]],[[[8,[32,0],[[24,0,\"isbf-learning__load-more\"]],[[\"@action\",\"@translatedLabel\"],[[30,1,[\"loadMore\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.load_more\"],null]],null]]],null]],[]],null],[1,\"\\n  \"]],[]],[[[41,[30,1,[\"myContributions\"]],[[[10,2],[14,0,\"isbf-learning__notice\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.learning_contributions_empty\"],null]],null]],[13],[1,\"\\n  \"]],[]],[[[10,2],[14,0,\"isbf-learning__notice\"],[12],[1,[28,[32,2],[[28,[32,3],[[52,[30,1,[\"isLibrary\"]],\"isbf_v2.library_empty\",\"isbf_v2.learning_empty\"]],null]],null]],[13]],[]]]],[]]]],[]]]],[]]],[13]],[\"@page\",\"resource\"],[\"unless\",\"if\",\"each\",\"-track-array\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    DButton,
    fn,
    i18n,
    themePrefix,
    ISBFResourceItem
  }),
  "isStrictMode": true
}), templateOnly());
registerModuleForModifyClass("isbf-resource-list", __discourseComponentClass$3);
var Mod124 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass$3
});
class ISBFResourceShareDialog extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "contributor", [tracked], function () {
      return null;
    });
  }
  #contributor = (dt7948.i(this, "contributor"), void 0);
  static {
    dt7948.g(this.prototype, "description", [tracked], function () {
      return "";
    });
  }
  #description = (dt7948.i(this, "description"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return null;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "editReady", [tracked], function () {
      return false;
    });
  }
  #editReady = (dt7948.i(this, "editReady"), void 0);
  static {
    dt7948.g(this.prototype, "loadError", [tracked], function () {
      return null;
    });
  }
  #loadError = (dt7948.i(this, "loadError"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "link", [tracked], function () {
      return "";
    });
  }
  #link = (dt7948.i(this, "link"), void 0);
  static {
    dt7948.g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (dt7948.i(this, "saving"), void 0);
  static {
    dt7948.g(this.prototype, "title", [tracked], function () {
      return "";
    });
  }
  #title = (dt7948.i(this, "title"), void 0);
  #closed = false;
  #loadGeneration = 0;
  #original = null;
  constructor() {
    super(...arguments);
    if (this.isEditing) {
      this.retryLoad();
    }
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }
  get config() {
    return this.args.library ? this.site?.isbf_library : this.site?.isbf_learning;
  }
  get fieldPrefix() {
    return this.args.library ? "isbf_library" : "isbf_learning";
  }
  get isEditing() {
    return Boolean(this.args.resource);
  }
  get editAllowed() {
    return this.canManageResources && this.config?.resource_admin_management === true && learningEditableResource(this.args.resource);
  }
  get fieldsDisabled() {
    return this.saving || this.isEditing && !this.editReady;
  }
  get contributorEnabled() {
    return this.config?.resource_contributor === true;
  }
  get contributorHint() {
    return i18n(themePrefix(this.isEditing ? "isbf_v2.learning_edit_contributor_hint" : "isbf_v2.learning_contributor_hint"));
  }
  get contributorValue() {
    return this.contributor ?? (this.isEditing ? "" : this.currentUser?.name || this.currentUser?.username || "");
  }
  get canManageResources() {
    return Boolean(this.currentUser?.admin || !this.args.library && this.currentUser?.academy_moderator_permissions?.manage_resources);
  }
  get shareLabel() {
    if (this.isEditing) {
      return i18n(themePrefix("isbf_v2.learning_edit"));
    }
    return i18n(themePrefix(this.config?.resource_admin_management === true && !this.canManageResources ? "isbf_v2.learning_apply_share" : "isbf_v2.learning_share"));
  }
  get submitLabel() {
    if (this.isEditing) {
      return i18n(themePrefix("isbf_v2.learning_save_changes"));
    }
    return this.config?.resource_admin_management === true && !this.canManageResources ? i18n(themePrefix("isbf_v2.learning_submit_request")) : this.shareLabel;
  }
  get descriptionEnabled() {
    return this.config?.resource_description === true;
  }
  get minimumTitleLength() {
    return this.siteSettings.min_topic_title_length;
  }
  get maximumTitleLength() {
    return this.siteSettings.max_topic_title_length;
  }
  get saveDisabled() {
    const length = [...this.title.trim()].length;
    return this.fieldsDisabled || this.isEditing && !this.editAllowed || !this.args.course?.id || length < this.minimumTitleLength || length > this.maximumTitleLength || !this.validLink || this.descriptionEnabled && [...this.description].length > 300 || this.contributorEnabled && this.contributor !== null && [...this.contributor.trim()].length > 15 && (!this.isEditing || this.contributor.trim() !== this.#original?.contributor);
  }
  get validLink() {
    const value = this.link.trim();
    if (value.length > 2048 || !/^https?:\/\//i.test(value) || /[\\\u0000-\u0020]/.test(value)) {
      return false;
    }
    try {
      const url = new URL(value);
      return Boolean(url.hostname && !url.username && !url.password);
    } catch {
      return false;
    }
  }
  changeContributor(event) {
    this.contributor = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "changeContributor", [action]);
  }
  changeDescription(event) {
    this.description = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "changeDescription", [action]);
  }
  changeLink(event) {
    this.link = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "changeLink", [action]);
  }
  changeTitle(event) {
    this.title = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "changeTitle", [action]);
  }
  close() {
    this.#closed = true;
    this.args.onClose();
  }
  static {
    dt7948.n(this.prototype, "close", [action]);
  }
  focusTitle(element) {
    element.focus();
  }
  static {
    dt7948.n(this.prototype, "focusTitle", [action]);
  }
  async retryLoad() {
    if (this.#closed || this.isDestroying || this.loading || this.saving) {
      return;
    }
    this.editReady = false;
    this.loadError = null;
    if (!this.editAllowed) {
      this.loadError = i18n(themePrefix("isbf_v2.learning_edit_unavailable"));
      return;
    }
    const generation = ++this.#loadGeneration;
    const topicId = this.args.resource.id;
    this.loading = true;
    try {
      const topic = await ajax(`/t/${topicId}.json`);
      if (this.#closed || this.isDestroying || generation !== this.#loadGeneration) {
        return;
      }
      const firstPost = topic?.post_stream?.posts?.find(post => post.post_number === 1);
      if (topic?.id !== topicId || !Number.isSafeInteger(firstPost?.id)) {
        throw new Error("Unexpected learning topic response");
      }
      const post = await ajax(`/posts/${firstPost.id}.json`);
      if (this.#closed || this.isDestroying || generation !== this.#loadGeneration) {
        return;
      }
      const details = learningEditDetails(topic, post, this.args.course?.id, this.fieldPrefix);
      if (!this.editAllowed || !details) {
        this.loadError = i18n(themePrefix("isbf_v2.learning_edit_unavailable"));
        return;
      }
      this.#original = details;
      this.title = details.title;
      this.link = details.link;
      this.description = details.description;
      this.contributor = details.contributor;
      this.editReady = true;
    } catch {
      if (!this.#closed && !this.isDestroying && generation === this.#loadGeneration) {
        this.loadError = i18n(themePrefix("isbf_v2.learning_edit_load_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying && generation === this.#loadGeneration) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "retryLoad", [action]);
  }
  async save(event) {
    event.preventDefault();
    if (this.#closed || this.saveDisabled) {
      return;
    }
    this.error = null;
    this.saving = true;
    try {
      const response = this.isEditing ? await this.#saveEdit() : await ajax(`/isbf/${this.args.library ? "library" : "learning"}/resources`, {
        type: "POST",
        data: {
          [this.args.library ? "group_id" : "course_id"]: this.args.course.id,
          title: this.title.trim(),
          link: this.link.trim(),
          ...(this.descriptionEnabled ? {
            description: this.description
          } : {}),
          ...(this.contributorEnabled ? {
            contributor: this.contributor?.trim() || ""
          } : {})
        }
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (response?.success !== true || typeof response.pending !== "boolean") {
        throw new Error("Unexpected learning resource response");
      }
      this.#closed = true;
      this.args.onSubmitted(response);
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix(this.isEditing ? "isbf_v2.learning_edit_error" : "isbf_v2.learning_share_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  async #saveEdit() {
    const original = this.#original;
    if (!this.editAllowed || !this.editReady || !original) {
      throw new Error("Learning resource is not editable");
    }
    const title = this.title.trim();
    const link = this.link.trim();
    const description = this.descriptionEnabled ? this.description.replace(/\r\n?/g, "\n").trim() : original.description;
    const raw = title === original.title && link === original.link && description === original.description ? original.raw : learningLinkBody(title, link, description);
    const response = await ajax(`/posts/${original.postId}.json`, {
      type: "PUT",
      data: {
        title,
        post: {
          raw,
          [`${this.fieldPrefix}_link`]: link,
          ...(this.descriptionEnabled ? {
            [`${this.fieldPrefix}_description`]: description
          } : {}),
          ...(this.contributorEnabled ? {
            [`${this.fieldPrefix}_contributor`]: this.contributor?.trim() || ""
          } : {})
        }
      }
    });
    if (response?.post?.id !== original.postId || response.post.topic_id !== original.topicId) {
      throw new Error("Unexpected learning edit response");
    }
    return {
      success: true,
      pending: false,
      edited: true
    };
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-learning-share-dialog"
      @closeModal={{this.close}}
      @submitOnEnter={{false}}
      @title={{this.shareLabel}}
    >
      <:body>
        <p class="isbf-learning-share-dialog__course">{{@course.name}}</p>
        {{#if this.loading}}
          <p role="status">{{i18n (themePrefix "isbf_v2.learning_loading")}}</p>
        {{/if}}
        {{#if this.loadError}}
          <p role="alert">{{this.loadError}}</p>
          <DButton
            @action={{this.retryLoad}}
            @disabled={{this.loading}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.learning_retry")}}
          />
        {{/if}}
        <form {{on "submit" this.save}}>
          <label>
            <span>{{i18n
                (themePrefix "isbf_v2.learning_resource_title")
              }}</span>
            <input
              disabled={{this.fieldsDisabled}}
              maxlength={{this.maximumTitleLength}}
              minlength={{this.minimumTitleLength}}
              required
              type="text"
              value={{this.title}}
              {{on "input" this.changeTitle}}
              {{didInsert this.focusTitle}}
            />
          </label>
          {{#if this.descriptionEnabled}}
            <label>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_resource_description")
                }}</span>
              <textarea
                disabled={{this.fieldsDisabled}}
                rows="3"
                value={{this.description}}
                {{on "input" this.changeDescription}}
              ></textarea>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_description_hint")
                }}</span>
            </label>
          {{/if}}
          <label>
            <span>{{i18n (themePrefix "isbf_v2.learning_resource_link")}}</span>
            <input
              disabled={{this.fieldsDisabled}}
              maxlength="2048"
              placeholder="https://"
              required
              type="url"
              value={{this.link}}
              {{on "input" this.changeLink}}
            />
          </label>
          {{#if this.contributorEnabled}}
            <label>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_resource_contributor")
                }}</span>
              <input
                disabled={{this.fieldsDisabled}}
                type="text"
                value={{this.contributorValue}}
                {{on "input" this.changeContributor}}
              />
              <span>{{this.contributorHint}}</span>
            </label>
          {{/if}}
          {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
          <div class="isbf-learning-share-dialog__actions">
            <DButton
              @action={{this.close}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
            />
            <DButton
              class="btn-primary"
              @disabled={{this.saveDisabled}}
              @translatedLabel={{this.submitLabel}}
              @type="submit"
            />
          </div>
        </form>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-learning-share-dialog\"]],[[\"@closeModal\",\"@submitOnEnter\",\"@title\"],[[30,0,[\"close\"]],false,[30,0,[\"shareLabel\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[10,2],[14,0,\"isbf-learning-share-dialog__course\"],[12],[1,[30,1,[\"name\"]]],[13],[1,\"\\n\"],[41,[30,0,[\"loading\"]],[[[1,\"      \"],[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"loadError\"]],[[[1,\"      \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"loadError\"]]],[13],[1,\"\\n      \"],[8,[32,3],null,[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"retryLoad\"]],[30,0,[\"loading\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_retry\"],null]],null]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[11,\"form\"],[4,[32,4],[\"submit\",[30,0,[\"save\"]]],null],[12],[1,\"\\n      \"],[10,\"label\"],[12],[1,\"\\n        \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_resource_title\"],null]],null]],[13],[1,\"\\n        \"],[11,\"input\"],[16,\"disabled\",[30,0,[\"fieldsDisabled\"]]],[16,\"maxlength\",[30,0,[\"maximumTitleLength\"]]],[16,\"minlength\",[30,0,[\"minimumTitleLength\"]]],[24,\"required\",\"\"],[16,2,[30,0,[\"title\"]]],[24,4,\"text\"],[4,[32,4],[\"input\",[30,0,[\"changeTitle\"]]],null],[4,[32,5],[[30,0,[\"focusTitle\"]]],null],[12],[13],[1,\"\\n      \"],[13],[1,\"\\n\"],[41,[30,0,[\"descriptionEnabled\"]],[[[1,\"        \"],[10,\"label\"],[12],[1,\"\\n          \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_resource_description\"],null]],null]],[13],[1,\"\\n          \"],[11,\"textarea\"],[16,\"disabled\",[30,0,[\"fieldsDisabled\"]]],[24,\"rows\",\"3\"],[16,2,[30,0,[\"description\"]]],[4,[32,4],[\"input\",[30,0,[\"changeDescription\"]]],null],[12],[13],[1,\"\\n          \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_description_hint\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,\"label\"],[12],[1,\"\\n        \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_resource_link\"],null]],null]],[13],[1,\"\\n        \"],[11,\"input\"],[16,\"disabled\",[30,0,[\"fieldsDisabled\"]]],[24,\"maxlength\",\"2048\"],[24,\"placeholder\",\"https://\"],[24,\"required\",\"\"],[16,2,[30,0,[\"link\"]]],[24,4,\"url\"],[4,[32,4],[\"input\",[30,0,[\"changeLink\"]]],null],[12],[13],[1,\"\\n      \"],[13],[1,\"\\n\"],[41,[30,0,[\"contributorEnabled\"]],[[[1,\"        \"],[10,\"label\"],[12],[1,\"\\n          \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_resource_contributor\"],null]],null]],[13],[1,\"\\n          \"],[11,\"input\"],[16,\"disabled\",[30,0,[\"fieldsDisabled\"]]],[16,2,[30,0,[\"contributorValue\"]]],[24,4,\"text\"],[4,[32,4],[\"input\",[30,0,[\"changeContributor\"]]],null],[12],[13],[1,\"\\n          \"],[10,1],[12],[1,[30,0,[\"contributorHint\"]]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[41,[30,0,[\"error\"]],[[[10,2],[14,\"role\",\"alert\"],[12],[1,[30,0,[\"error\"]]],[13]],[]],null],[1,\"\\n      \"],[10,0],[14,0,\"isbf-learning-share-dialog__actions\"],[12],[1,\"\\n        \"],[8,[32,3],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"close\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n        \"],[8,[32,3],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@translatedLabel\",\"@type\"],[[30,0,[\"saveDisabled\"]],[30,0,[\"submitLabel\"]],\"submit\"]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"]],[]]]]]],[\"@course\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        DButton,
        on,
        didInsert
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-resource-share-dialog", ISBFResourceShareDialog);
var Mod127 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceShareDialog
});
class ISBFResourcePage extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "isbfBackNavigation", [service]);
  }
  #isbfBackNavigation = (dt7948.i(this, "isbfBackNavigation"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "coursePending", [tracked], function () {
      return false;
    });
  }
  #coursePending = (dt7948.i(this, "coursePending"), void 0);
  static {
    dt7948.g(this.prototype, "courses", [tracked], function () {
      return [];
    });
  }
  #courses = (dt7948.i(this, "courses"), void 0);
  static {
    dt7948.g(this.prototype, "coursesError", [tracked], function () {
      return false;
    });
  }
  #coursesError = (dt7948.i(this, "coursesError"), void 0);
  static {
    dt7948.g(this.prototype, "coursesLoading", [tracked], function () {
      return false;
    });
  }
  #coursesLoading = (dt7948.i(this, "coursesLoading"), void 0);
  static {
    dt7948.g(this.prototype, "grade", [tracked], function () {
      return 1;
    });
  }
  #grade = (dt7948.i(this, "grade"), void 0);
  static {
    dt7948.g(this.prototype, "categories", [tracked], function () {
      return [];
    });
  }
  #categories = (dt7948.i(this, "categories"), void 0);
  static {
    dt7948.g(this.prototype, "directoryKind", [tracked], function () {
      return "group";
    });
  }
  #directoryKind = (dt7948.i(this, "directoryKind"), void 0);
  static {
    dt7948.g(this.prototype, "selectedCourseId", [tracked], function () {
      return null;
    });
  }
  #selectedCourseId = (dt7948.i(this, "selectedCourseId"), void 0);
  static {
    dt7948.g(this.prototype, "showCourseDialog", [tracked], function () {
      return false;
    });
  }
  #showCourseDialog = (dt7948.i(this, "showCourseDialog"), void 0);
  static {
    dt7948.g(this.prototype, "query", [tracked], function () {
      return "";
    });
  }
  #query = (dt7948.i(this, "query"), void 0);
  static {
    dt7948.g(this.prototype, "resources", [tracked], function () {
      return [];
    });
  }
  #resources = (dt7948.i(this, "resources"), void 0);
  static {
    dt7948.g(this.prototype, "resourcesError", [tracked], function () {
      return false;
    });
  }
  #resourcesError = (dt7948.i(this, "resourcesError"), void 0);
  static {
    dt7948.g(this.prototype, "resourcesLoading", [tracked], function () {
      return false;
    });
  }
  #resourcesLoading = (dt7948.i(this, "resourcesLoading"), void 0);
  static {
    dt7948.g(this.prototype, "hasMore", [tracked], function () {
      return false;
    });
  }
  #hasMore = (dt7948.i(this, "hasMore"), void 0);
  static {
    dt7948.g(this.prototype, "shareContext", [tracked], function () {
      return null;
    });
  }
  #shareContext = (dt7948.i(this, "shareContext"), void 0);
  static {
    dt7948.g(this.prototype, "sharePending", [tracked], function () {
      return false;
    });
  }
  #sharePending = (dt7948.i(this, "sharePending"), void 0);
  static {
    dt7948.g(this.prototype, "myContributions", [tracked], function () {
      return false;
    });
  }
  #myContributions = (dt7948.i(this, "myContributions"), void 0);
  static {
    dt7948.g(this.prototype, "grades", [tracked], function () {
      return [];
    });
  }
  #grades = (dt7948.i(this, "grades"), void 0);
  static {
    dt7948.g(this.prototype, "editingDirectory", [tracked], function () {
      return null;
    });
  }
  #editingDirectory = (dt7948.i(this, "editingDirectory"), void 0);
  static {
    dt7948.g(this.prototype, "deletingDirectory", [tracked], function () {
      return null;
    });
  }
  #deletingDirectory = (dt7948.i(this, "deletingDirectory"), void 0);
  #coursesRequest = 0;
  #courseTrigger;
  #page = 0;
  #resourcesRequest = 0;
  #searchTimer;
  #shareTrigger;
  constructor() {
    super(...arguments);
    if (this.config && this.currentUser) {
      this.loadCourses();
    }
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#coursesRequest++;
    this.#resourcesRequest++;
    clearTimeout(this.#searchTimer);
  }
  get config() {
    return this.isLibrary ? libraryConfig(this.site) : learningConfig(this.site);
  }
  get isLibrary() {
    return this.args.library === true;
  }
  get endpoint() {
    return this.isLibrary ? "/isbf/library" : "/isbf/learning";
  }
  get parents() {
    return this.isLibrary ? this.categories.map(category => ({
      ...category,
      label: category.name
    })) : this.grades;
  }
  get pageTitle() {
    return i18n(themePrefix(this.isLibrary ? "isbf_v2.workbench_library" : "isbf_v2.workbench_learning_resources"));
  }
  get parentLabel() {
    return i18n(themePrefix(this.isLibrary ? "isbf_v2.library_category" : "isbf_v2.learning_grade"));
  }
  get directoryLabel() {
    return i18n(themePrefix(this.isLibrary ? "isbf_v2.library_groups" : "isbf_v2.workbench_courses"));
  }
  get groupSubmitDisabled() {
    return this.isLibrary && !this.grade;
  }
  get categoryActionLabel() {
    return i18n(themePrefix(this.canManageCourses ? "isbf_v2.library_add_category" : "isbf_v2.library_request_category"));
  }
  get searchLabel() {
    return i18n(themePrefix(this.isLibrary ? "isbf_v2.library_search" : "isbf_v2.learning_search"));
  }
  get canManageCourses() {
    return Boolean(this.currentUser?.admin || (this.isLibrary ? this.currentUser?.moderator : this.currentUser?.academy_moderator_permissions?.manage_resources));
  }
  get canManageResources() {
    return Boolean(this.currentUser?.admin || !this.isLibrary && this.currentUser?.academy_moderator_permissions?.manage_resources);
  }
  get canSubmitResources() {
    if (this.isLibrary || !this.currentUser?.academy_moderator_role || this.currentUser?.admin) {
      return true;
    }
    return Boolean(this.site.categories?.find(category => category.id === this.config?.category_id)?.canCreateTopic);
  }
  get canSubmitCourses() {
    return Boolean(this.currentUser && this.canSubmitResources && (this.isLibrary || this.grade !== null) && (this.canManageCourses || (this.isLibrary ? this.config?.catalog_requests : this.config?.course_requests) === true));
  }
  get courseActionLabel() {
    return i18n(themePrefix(this.isLibrary ? this.canManageCourses ? "isbf_v2.library_add_group" : "isbf_v2.library_request_group" : this.canManageCourses ? "isbf_v2.learning_add_course" : "isbf_v2.learning_request_course"));
  }
  get courseItems() {
    return this.courses.filter(course => (this.isLibrary ? course.category_id : course.grade) === this.grade).map(course => ({
      ...course,
      selected: course.id === this.selectedCourseId
    }));
  }
  get selectedCourse() {
    return this.courses.find(course => course.id === this.selectedCourseId);
  }
  get shareLabel() {
    return i18n(themePrefix(this.config?.resource_admin_management === true && !this.canManageResources ? "isbf_v2.learning_apply_share" : "isbf_v2.learning_share"));
  }
  get shareDisabled() {
    if (!this.isLibrary && !this.canManageResources) {
      return false;
    }
    return !this.selectedCourse || !this.canSubmitResources || this.config?.link_sharing !== true;
  }
  get searching() {
    return Boolean(this.query.trim());
  }
  get contentTitle() {
    if (this.myContributions) {
      return i18n(themePrefix("isbf_v2.learning_my_contributions"));
    }
    return this.searching ? i18n(themePrefix("isbf_v2.learning_search_results")) : this.selectedCourse?.name || i18n(themePrefix(this.isLibrary ? "isbf_v2.library_select_group" : "isbf_v2.learning_select_course"));
  }
  get backHref() {
    return this.isbfBackNavigation.href("/isbf/workbench");
  }
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }
  static {
    dt7948.n(this.prototype, "goBack", [action]);
  }
  login() {
    this.appEvents.trigger("show-login");
  }
  static {
    dt7948.n(this.prototype, "login", [action]);
  }
  async loadCourses() {
    if (this.isDestroying) {
      return;
    }
    const request = ++this.#coursesRequest;
    this.coursesLoading = true;
    this.coursesError = false;
    try {
      const response = this.isLibrary ? await ajax(`${this.endpoint}/categories`) : await ajax(`${this.endpoint}/courses`);
      let groups;
      if (this.isLibrary && request === this.#coursesRequest) {
        groups = await ajax(`${this.endpoint}/groups`);
      }
      if (request !== this.#coursesRequest) {
        return;
      }
      if (this.isLibrary) {
        this.categories = response.categories || [];
        if (!this.categories.some(category => category.id === this.grade)) {
          this.grade = this.categories[0]?.id || null;
        }
      }
      this.courses = this.isLibrary ? groups.groups || [] : response.courses || [];
      if (!this.isLibrary) {
        this.grades = response.grades || this.config.grades;
        if (!this.grades.some(grade => grade.id === this.grade)) {
          this.grade = this.grades[0]?.id || null;
        }
      }
      this.#restoreCourse();
      this.#loadResources();
    } catch {
      if (request === this.#coursesRequest) {
        this.coursesError = true;
      }
    } finally {
      if (request === this.#coursesRequest) {
        this.coursesLoading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadCourses", [action]);
  }
  changeGrade(id) {
    this.myContributions = false;
    this.grade = id;
    this.#restoreCourse();
    if (!this.searching) {
      this.#loadResources();
    }
  }
  static {
    dt7948.n(this.prototype, "changeGrade", [action]);
  }
  selectCourse(id) {
    this.myContributions = false;
    this.selectedCourseId = id;
    if (!this.searching) {
      this.#loadResources();
    }
  }
  static {
    dt7948.n(this.prototype, "selectCourse", [action]);
  }
  changeQuery(event) {
    this.myContributions = false;
    this.query = event.target.value;
    clearTimeout(this.#searchTimer);
    this.#resourcesRequest++;
    this.resources = [];
    this.hasMore = false;
    this.resourcesError = false;
    this.resourcesLoading = true;
    this.#searchTimer = setTimeout(() => this.#loadResources(), 300);
  }
  static {
    dt7948.n(this.prototype, "changeQuery", [action]);
  }
  clearQuery() {
    clearTimeout(this.#searchTimer);
    this.query = "";
    this.#loadResources();
  }
  static {
    dt7948.n(this.prototype, "clearQuery", [action]);
  }
  retryResources() {
    this.#loadResources(this.resources.length > 0);
  }
  static {
    dt7948.n(this.prototype, "retryResources", [action]);
  }
  loadMore() {
    this.#loadResources(true);
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  toggleContributions() {
    clearTimeout(this.#searchTimer);
    this.myContributions = !this.myContributions;
    this.query = "";
    this.#loadResources();
  }
  static {
    dt7948.n(this.prototype, "toggleContributions", [action]);
  }
  editCourse(course) {
    if (!this.isLibrary && this.canManageResources) {
      this.#courseTrigger = document.activeElement;
      this.editingDirectory = {
        kind: "course",
        entry: course
      };
    }
  }
  static {
    dt7948.n(this.prototype, "editCourse", [action]);
  }
  editGrade() {
    const entry = this.parents.find(parent => parent.id === this.grade);
    if (!this.isLibrary && this.canManageResources && entry) {
      this.#courseTrigger = document.activeElement;
      this.editingDirectory = {
        kind: "grade",
        entry
      };
    }
  }
  static {
    dt7948.n(this.prototype, "editGrade", [action]);
  }
  closeDirectoryEditor() {
    this.editingDirectory = null;
    this.#courseTrigger?.focus();
  }
  static {
    dt7948.n(this.prototype, "closeDirectoryEditor", [action]);
  }
  deleteDirectory() {
    if (!this.isLibrary && this.canManageResources && this.editingDirectory) {
      this.deletingDirectory = this.editingDirectory;
      this.editingDirectory = null;
    }
  }
  static {
    dt7948.n(this.prototype, "deleteDirectory", [action]);
  }
  closeDirectoryDeletion() {
    this.deletingDirectory = null;
    this.#courseTrigger?.focus();
  }
  static {
    dt7948.n(this.prototype, "closeDirectoryDeletion", [action]);
  }
  directoryDeleted() {
    this.closeDirectoryDeletion();
    this.#resourcesRequest++;
    this.resources = [];
    this.loadCourses();
  }
  static {
    dt7948.n(this.prototype, "directoryDeleted", [action]);
  }
  directorySaved(response, grade) {
    this.closeDirectoryEditor();
    this.grade = grade;
    this.loadCourses();
  }
  static {
    dt7948.n(this.prototype, "directorySaved", [action]);
  }
  openCourseDialog(kind = "group") {
    if (!this.canSubmitCourses || this.showCourseDialog) {
      return;
    }
    this.directoryKind = typeof kind === "string" ? kind : "group";
    if (this.isLibrary && this.directoryKind === "group" && !this.grade) {
      return;
    }
    this.coursePending = false;
    this.#courseTrigger = document.activeElement;
    this.showCourseDialog = true;
  }
  static {
    dt7948.n(this.prototype, "openCourseDialog", [action]);
  }
  closeCourseDialog() {
    this.showCourseDialog = false;
    this.#courseTrigger?.focus();
  }
  static {
    dt7948.n(this.prototype, "closeCourseDialog", [action]);
  }
  courseSubmitted(response, grade) {
    if (this.isDestroying || !this.showCourseDialog) {
      return;
    }
    this.closeCourseDialog();
    this.coursePending = response.pending === true;
    if (!this.coursePending) {
      this.grade = grade;
      this.loadCourses();
    }
  }
  static {
    dt7948.n(this.prototype, "courseSubmitted", [action]);
  }
  share() {
    if (this.shareDisabled || this.shareContext) {
      return;
    }
    this.#shareTrigger = document.activeElement;
    this.sharePending = false;
    this.shareContext = {
      course: this.selectedCourse,
      selectedCourseId: this.selectedCourseId,
      query: this.query.trim(),
      coursesRequest: this.#coursesRequest,
      myContributions: this.myContributions
    };
  }
  static {
    dt7948.n(this.prototype, "share", [action]);
  }
  editResource(resource) {
    if (this.isDestroying || !this.canManageResources || this.config?.resource_admin_management !== true || this.shareContext || resource?.can_delete !== true || this.isLibrary && !learningEditableResource(resource) || !(this.isLibrary ? resource.group?.id : resource.course?.id)) {
      return;
    }
    this.#shareTrigger = document.activeElement;
    this.sharePending = false;
    this.shareContext = {
      course: this.isLibrary ? resource.group : resource.course,
      resource,
      selectedCourseId: this.selectedCourseId,
      query: this.query.trim(),
      coursesRequest: this.#coursesRequest,
      myContributions: this.myContributions
    };
  }
  static {
    dt7948.n(this.prototype, "editResource", [action]);
  }
  closeShareDialog() {
    this.shareContext = null;
    this.#shareTrigger?.focus();
  }
  static {
    dt7948.n(this.prototype, "closeShareDialog", [action]);
  }
  resourceSubmitted(response) {
    // Preserve both flags for this existing late submission callback guard.
    // eslint-disable-next-line discourse/no-redundant-destroyed-check
    if (this.isDestroying || this.isDestroyed || !this.shareContext) {
      return;
    }
    const context = this.shareContext;
    this.closeShareDialog();
    this.sharePending = response.pending === true;
    if (!this.sharePending && context.myContributions === this.myContributions && (context.selectedCourseId ?? context.course.id) === this.selectedCourseId && context.query === this.query.trim() && context.coursesRequest === this.#coursesRequest) {
      clearTimeout(this.#searchTimer);
      this.#loadResources();
    }
  }
  static {
    dt7948.n(this.prototype, "resourceSubmitted", [action]);
  }
  resourceDeleted() {
    if (this.isDestroying) {
      return;
    }
    clearTimeout(this.#searchTimer);
    this.#loadResources();
  }
  static {
    dt7948.n(this.prototype, "resourceDeleted", [action]);
  }
  #restoreCourse() {
    if (!this.courseItems.some(course => course.selected)) {
      this.selectedCourseId = this.courseItems[0]?.id || null;
    }
  }
  async #loadResources(append = false) {
    if (this.isDestroying) {
      return;
    }
    const request = ++this.#resourcesRequest;
    const page = append ? this.#page + 1 : 0;
    this.resourcesError = false;
    if (!append) {
      this.resources = [];
      this.hasMore = false;
    }
    if (!this.myContributions && !this.searching && !this.selectedCourseId) {
      this.resourcesLoading = false;
      return;
    }
    this.resourcesLoading = true;
    try {
      const response = await ajax(`${this.endpoint}/${this.myContributions ? "contributions" : "resources"}`, {
        data: this.myContributions ? {
          page
        } : this.isLibrary && !this.searching ? {
          group_id: this.selectedCourseId,
          page
        } : learningResourceQuery(this.selectedCourseId, this.query, page)
      });
      if (request !== this.#resourcesRequest) {
        return;
      }
      const resources = response.resources || [];
      this.resources = append ? [...this.resources, ...resources] : resources;
      this.hasMore = response.has_more === true;
      this.#page = page;
    } catch {
      if (request === this.#resourcesRequest) {
        this.resourcesError = true;
      }
    } finally {
      if (request === this.#resourcesRequest) {
        this.resourcesLoading = false;
      }
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-learning">
      <header class="isbf-learning__header">
        <a
          aria-label={{i18n "back_button"}}
          class="isbf-learning__back"
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >
          {{dIcon "arrow-left"}}
          <h1>{{this.pageTitle}}</h1>
        </a>
        {{#if this.currentUser}}
          {{#if this.config}}
            <div class="isbf-learning__search">
              <input
                aria-label={{this.searchLabel}}
                placeholder={{this.searchLabel}}
                type="search"
                value={{this.query}}
                {{on "input" this.changeQuery}}
              />
              {{#if this.query}}<DButton
                  class="btn-flat"
                  @action={{this.clearQuery}}
                  @icon="xmark"
                  @translatedTitle={{i18n
                    (themePrefix "isbf_v2.explore_clear")
                  }}
                />{{/if}}
            </div>
          {{/if}}
        {{/if}}
      </header>
      {{#if (not this.config)}}
        <p class="isbf-learning__notice">{{i18n
            (themePrefix
              (if
                this.isLibrary
                "isbf_v2.library_unavailable"
                "isbf_v2.learning_unavailable"
              )
            )
          }}</p>
      {{else if this.currentUser}}
        {{#if this.shareContext}}
          {{#if this.isLibrary}}<ISBFResourceShareDialog
              @course={{this.shareContext.course}}
              @library={{this.isLibrary}}
              @onClose={{this.closeShareDialog}}
              @onSubmitted={{this.resourceSubmitted}}
              @resource={{this.shareContext.resource}}
            />{{else}}<ISBFLearningManagementDialog
              @course={{this.shareContext.course}}
              @courses={{this.courses}}
              @grades={{this.parents}}
              @onClose={{this.closeShareDialog}}
              @onSubmitted={{this.resourceSubmitted}}
              @resource={{this.shareContext.resource}}
            />{{/if}}
        {{/if}}
        {{#if this.editingDirectory}}<ISBFLearningDirectoryEditor
            @entry={{this.editingDirectory.entry}}
            @grades={{this.parents}}
            @kind={{this.editingDirectory.kind}}
            @onClose={{this.closeDirectoryEditor}}
            @onDelete={{this.deleteDirectory}}
            @onSaved={{this.directorySaved}}
          />{{/if}}
        {{#if this.deletingDirectory}}<ISBFLearningDirectoryDeletion
            @entry={{this.deletingDirectory.entry}}
            @kind={{this.deletingDirectory.kind}}
            @onClose={{this.closeDirectoryDeletion}}
            @onDeleted={{this.directoryDeleted}}
          />{{/if}}
        {{#if this.showCourseDialog}}<ISBFResourceDirectoryDialog
            @grade={{this.grade}}
            @grades={{this.parents}}
            @kind={{this.directoryKind}}
            @library={{this.isLibrary}}
            @onClose={{this.closeCourseDialog}}
            @onSubmitted={{this.courseSubmitted}}
            @request={{not this.canManageCourses}}
          />{{/if}}
        <div class="isbf-learning__body">
          <ISBFResourceCatalog @page={{this}} />
          <ISBFResourceList @page={{this}} />
        </div>
      {{else}}
        <div class="isbf-learning__notice">
          <p>{{i18n
              (themePrefix
                (if
                  this.isLibrary
                  "isbf_v2.library_login_required"
                  "isbf_v2.learning_login_required"
                )
              )
            }}</p>
          <DButton
            class="btn-primary"
            @action={{this.login}}
            @translatedLabel={{i18n "log_in"}}
          />
        </div>
      {{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-learning\"],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-learning__header\"],[12],[1,\"\\n    \"],[11,3],[16,\"aria-label\",[28,[32,0],[\"back_button\"],null]],[24,0,\"isbf-learning__back\"],[16,6,[30,0,[\"backHref\"]]],[4,[32,1],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,\"\\n      \"],[1,[28,[32,2],[\"arrow-left\"],null]],[1,\"\\n      \"],[10,\"h1\"],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[41,[30,0,[\"config\"]],[[[1,\"        \"],[10,0],[14,0,\"isbf-learning__search\"],[12],[1,\"\\n          \"],[11,\"input\"],[16,\"aria-label\",[30,0,[\"searchLabel\"]]],[16,\"placeholder\",[30,0,[\"searchLabel\"]]],[16,2,[30,0,[\"query\"]]],[24,4,\"search\"],[4,[32,1],[\"input\",[30,0,[\"changeQuery\"]]],null],[12],[13],[1,\"\\n          \"],[41,[30,0,[\"query\"]],[[[8,[32,3],[[24,0,\"btn-flat\"]],[[\"@action\",\"@icon\",\"@translatedTitle\"],[[30,0,[\"clearQuery\"]],\"xmark\",[28,[32,0],[[28,[32,4],[\"isbf_v2.explore_clear\"],null]],null]]],null]],[]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[41,[28,[32,5],[[30,0,[\"config\"]]],null],[[[1,\"    \"],[10,2],[14,0,\"isbf-learning__notice\"],[12],[1,[28,[32,0],[[28,[32,4],[[52,[30,0,[\"isLibrary\"]],\"isbf_v2.library_unavailable\",\"isbf_v2.learning_unavailable\"]],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"currentUser\"]],[[[41,[30,0,[\"shareContext\"]],[[[1,\"      \"],[41,[30,0,[\"isLibrary\"]],[[[8,[32,6],null,[[\"@course\",\"@library\",\"@onClose\",\"@onSubmitted\",\"@resource\"],[[30,0,[\"shareContext\",\"course\"]],[30,0,[\"isLibrary\"]],[30,0,[\"closeShareDialog\"]],[30,0,[\"resourceSubmitted\"]],[30,0,[\"shareContext\",\"resource\"]]]],null]],[]],[[[8,[32,7],null,[[\"@course\",\"@courses\",\"@grades\",\"@onClose\",\"@onSubmitted\",\"@resource\"],[[30,0,[\"shareContext\",\"course\"]],[30,0,[\"courses\"]],[30,0,[\"parents\"]],[30,0,[\"closeShareDialog\"]],[30,0,[\"resourceSubmitted\"]],[30,0,[\"shareContext\",\"resource\"]]]],null]],[]]],[1,\"\\n\"]],[]],null],[1,\"    \"],[41,[30,0,[\"editingDirectory\"]],[[[8,[32,8],null,[[\"@entry\",\"@grades\",\"@kind\",\"@onClose\",\"@onDelete\",\"@onSaved\"],[[30,0,[\"editingDirectory\",\"entry\"]],[30,0,[\"parents\"]],[30,0,[\"editingDirectory\",\"kind\"]],[30,0,[\"closeDirectoryEditor\"]],[30,0,[\"deleteDirectory\"]],[30,0,[\"directorySaved\"]]]],null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"deletingDirectory\"]],[[[8,[32,9],null,[[\"@entry\",\"@kind\",\"@onClose\",\"@onDeleted\"],[[30,0,[\"deletingDirectory\",\"entry\"]],[30,0,[\"deletingDirectory\",\"kind\"]],[30,0,[\"closeDirectoryDeletion\"]],[30,0,[\"directoryDeleted\"]]]],null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"showCourseDialog\"]],[[[8,[32,10],null,[[\"@grade\",\"@grades\",\"@kind\",\"@library\",\"@onClose\",\"@onSubmitted\",\"@request\"],[[30,0,[\"grade\"]],[30,0,[\"parents\"]],[30,0,[\"directoryKind\"]],[30,0,[\"isLibrary\"]],[30,0,[\"closeCourseDialog\"]],[30,0,[\"courseSubmitted\"]],[28,[32,5],[[30,0,[\"canManageCourses\"]]],null]]],null]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"isbf-learning__body\"],[12],[1,\"\\n      \"],[8,[32,11],null,[[\"@page\"],[[30,0]]],null],[1,\"\\n      \"],[8,[32,12],null,[[\"@page\"],[[30,0]]],null],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,0],[14,0,\"isbf-learning__notice\"],[12],[1,\"\\n      \"],[10,2],[12],[1,[28,[32,0],[[28,[32,4],[[52,[30,0,[\"isLibrary\"]],\"isbf_v2.library_login_required\",\"isbf_v2.learning_login_required\"]],null]],null]],[13],[1,\"\\n      \"],[8,[32,3],[[24,0,\"btn-primary\"]],[[\"@action\",\"@translatedLabel\"],[[30,0,[\"login\"]],[28,[32,0],[\"log_in\"],null]]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"]],[]]]],[]]],[13]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        on,
        dIcon,
        DButton,
        themePrefix,
        not,
        ISBFResourceShareDialog,
        ISBFLearningManagementDialog,
        ISBFLearningDirectoryEditor,
        ISBFLearningDirectoryDeletion,
        ISBFResourceDirectoryDialog,
        ISBFResourceCatalog: __discourseComponentClass$4,
        ISBFResourceList: __discourseComponentClass$3
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-resource-page", ISBFResourcePage);
var Mod125 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourcePage
});
var Mod69 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourcePage
});
const __discourseComponentClass$2 = setComponentTemplate(createTemplateFactory(
/*
  <ISBFResourcePage @library={{true}} />
*/
{
  "id": null,
  "block": "[[[8,[32,0],null,[[\"@library\"],[true]],null]],[],[]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    ISBFResourcePage
  }),
  "isStrictMode": true
}), templateOnly());
registerModuleForModifyClass("isbf-library", __discourseComponentClass$2);
var Mod120 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass$2
});
class ISBFMarketplace extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "topicList", [tracked], function () {
      return null;
    });
  }
  #topicList = (dt7948.i(this, "topicList"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.load);
  }
  get config() {
    return marketplaceConfig(this.site);
  }
  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }
  get canCreate() {
    return Boolean(this.config?.publishing_enabled !== false && this.currentUser && this.site.categories?.find(category => category.id === this.config?.category_id)?.canCreateTopic);
  }
  login() {
    this.appEvents.trigger("show-login");
  }
  static {
    dt7948.n(this.prototype, "login", [action]);
  }
  create() {
    if (!this.canCreate) {
      return;
    }
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: Composer.NEW_TOPIC_KEY
    });
  }
  static {
    dt7948.n(this.prototype, "create", [action]);
  }
  async load() {
    if (!this.config || !this.currentUser || this.loading) {
      return;
    }
    this.loading = true;
    this.error = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: marketplaceQuery()
      });
      if (!this.isDestroying) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async loadMore() {
    if (this.loading || !this.canLoadMore) {
      return;
    }
    this.loading = true;
    this.error = false;
    const list = this.topicList;
    try {
      await list.loadMore();
      if (!this.isDestroying) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFWorkbenchTopicPage
      class="isbf-marketplace"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="marketplace"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFMarketplaceCard @topic={{topic}} />
      {{/each}}
    </ISBFWorkbenchTopicPage>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-marketplace\"]],[[\"@canCreate\",\"@canLoadMore\",\"@config\",\"@currentUser\",\"@error\",\"@hasTopics\",\"@kind\",\"@loading\",\"@onCreate\",\"@onLoadMore\",\"@onLogin\",\"@onRetry\"],[[30,0,[\"canCreate\"]],[30,0,[\"canLoadMore\"]],[30,0,[\"config\"]],[30,0,[\"currentUser\"]],[30,0,[\"error\"]],[30,0,[\"topics\",\"length\"]],\"marketplace\",[30,0,[\"loading\"]],[30,0,[\"create\"]],[30,0,[\"loadMore\"]],[30,0,[\"login\"]],[30,0,[\"retry\"]]]],[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"    \"],[8,[32,1],null,[[\"@topic\"],[[30,1]]],null],[1,\"\\n\"]],[1]],null]],[]]]]]],[\"topic\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFWorkbenchTopicPage,
        ISBFMarketplaceCard
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-marketplace", ISBFMarketplace);
var Mod95 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFMarketplace
});
class ISBFNotificationBell extends Component {
  static {
    dt7948.g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (dt7948.i(this, "isbfNotifications"), void 0);
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <span aria-hidden="true" class="isbf-notification-bell" ...attributes>
      {{dIcon "bell"}}
      {{#if this.isbfNotifications.unreadCount}}
        <span
          class={{dConcatClass
            "isbf-notification-bell__badge"
            (if this.isbfNotifications.dotStyle "--dot")
          }}
        >{{#unless
            this.isbfNotifications.dotStyle
          }}{{this.isbfNotifications.displayCount}}{{/unless}}</span>
      {{/if}}
    </span>
    */
    {
      "id": null,
      "block": "[[[11,1],[24,\"aria-hidden\",\"true\"],[24,0,\"isbf-notification-bell\"],[17,1],[12],[1,\"\\n  \"],[1,[28,[32,0],[\"bell\"],null]],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"unreadCount\"]],[[[1,\"    \"],[10,1],[15,0,[28,[32,1],[\"isbf-notification-bell__badge\",[52,[30,0,[\"isbfNotifications\",\"dotStyle\"]],\"--dot\"]],null]],[12],[41,[51,[30,0,[\"isbfNotifications\",\"dotStyle\"]]],[[[1,[30,0,[\"isbfNotifications\",\"displayCount\"]]]],[]],null],[13],[1,\"\\n\"]],[]],null],[13]],[\"&attrs\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dIcon,
        dConcatClass
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-notification-bell", ISBFNotificationBell);
var Mod174 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFNotificationBell
});
class ISBFNotificationEntry extends Component {
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  get useNativeSummary() {
    return this.args.standalone || !["liked", "reaction", "replied", "mentioned", "group_mentioned"].includes(this.args.entry.action);
  }
  get displayName() {
    const actor = this.args.entry.actor;
    if (!actor) {
      return null;
    }
    return displayIdentity({
      name: this.siteSettings.enable_names ? actor.name : null,
      username: actor.username
    });
  }
  open(event) {
    this.args.entry.item.onClick({
      event
    });
  }
  static {
    dt7948.n(this.prototype, "open", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{if
        @entry.notification.read
        "isbf-notification-entry"
        "isbf-notification-entry is-unread"
      }}
    >
      {{#if @entry.actor}}
        <span class="isbf-notification-entry__avatar">{{dAvatar
            @entry.actor
            imageSize="medium"
          }}</span>
      {{else}}
        <span
          aria-hidden="true"
          class="isbf-notification-entry__avatar isbf-notification-entry__system"
        >{{dIcon @entry.item.icon}}</span>
      {{/if}}
      <div class="isbf-notification-entry__content">
        {{#unless @entry.notification.read}}<span class="sr-only">{{i18n
              (themePrefix "isbf_v2.notifications_unread")
            }}</span>{{/unless}}
        {{#if this.useNativeSummary}}
          <ul class="isbf-notification-entry__native"><MenuItem
              @item={{@entry.item}}
            /></ul>
        {{else}}
          <a
            class="isbf-notification-entry__link"
            href={{@entry.item.linkHref}}
            title={{@entry.item.linkTitle}}
            {{on "click" this.open}}
          >
            {{#if @entry.actor}}<span
                class="isbf-notification-entry__name"
              >{{this.displayName}}</span>
            {{/if}}
            <span>{{@entry.actionLabel}}</span>
          </a>
        {{/if}}
        <span class="isbf-notification-entry__time"><DRelativeDate
            @date={{@entry.created_at}}
          /></span>
      </div>
    </div>
    */
    {
      "id": null,
      "block": "[[[10,0],[15,0,[52,[30,1,[\"notification\",\"read\"]],\"isbf-notification-entry\",\"isbf-notification-entry is-unread\"]],[12],[1,\"\\n\"],[41,[30,1,[\"actor\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__avatar\"],[12],[1,[28,[32,0],[[30,1,[\"actor\"]]],[[\"imageSize\"],[\"medium\"]]]],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-entry__avatar isbf-notification-entry__system\"],[12],[1,[28,[32,1],[[30,1,[\"item\",\"icon\"]]],null]],[13],[1,\"\\n\"]],[]]],[1,\"  \"],[10,0],[14,0,\"isbf-notification-entry__content\"],[12],[1,\"\\n    \"],[41,[51,[30,1,[\"notification\",\"read\"]]],[[[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications_unread\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"useNativeSummary\"]],[[[1,\"      \"],[10,\"ul\"],[14,0,\"isbf-notification-entry__native\"],[12],[8,[32,4],null,[[\"@item\"],[[30,1,[\"item\"]]]],null],[13],[1,\"\\n\"]],[]],[[[1,\"      \"],[11,3],[24,0,\"isbf-notification-entry__link\"],[16,6,[30,1,[\"item\",\"linkHref\"]]],[16,\"title\",[30,1,[\"item\",\"linkTitle\"]]],[4,[32,5],[\"click\",[30,0,[\"open\"]]],null],[12],[1,\"\\n        \"],[41,[30,1,[\"actor\"]],[[[10,1],[14,0,\"isbf-notification-entry__name\"],[12],[1,[30,0,[\"displayName\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,1],[12],[1,[30,1,[\"actionLabel\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]]],[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__time\"],[12],[8,[32,6],null,[[\"@date\"],[[30,1,[\"created_at\"]]]],null],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@entry\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dAvatar,
        dIcon,
        i18n,
        themePrefix,
        MenuItem,
        on,
        DRelativeDate
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-notification-entry", ISBFNotificationEntry);
var Mod21 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFNotificationEntry
});
const __discourseComponentClass$1 = setComponentTemplate(createTemplateFactory(
/*
  {{#if @unread}}
  <span aria-hidden="true" class="isbf-notification-unread"></span>
  <span class="sr-only">{{i18n
      (themePrefix "isbf_v2.notifications_unread")
    }}</span>
{{/if}}
*/
{
  "id": null,
  "block": "[[[41,[30,1],[[[1,\"  \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-unread\"],[12],[13],[1,\"\\n  \"],[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_unread\"],null]],null]],[13],[1,\"\\n\"]],[]],null]],[\"@unread\"],[\"if\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    i18n,
    themePrefix
  }),
  "isStrictMode": true
}), templateOnly());
registerModuleForModifyClass("isbf-notification-unread", __discourseComponentClass$1);
var Mod175 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass$1
});
class ISBFNotificationAction extends Component {
  static {
    dt7948.g(this.prototype, "entries", [tracked], function () {
      return [];
    });
  }
  #entries = (dt7948.i(this, "entries"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (dt7948.i(this, "expanded"), void 0);
  static {
    dt7948.g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (dt7948.i(this, "loaded"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "nextCursor", [tracked], function () {
      return null;
    });
  }
  #nextCursor = (dt7948.i(this, "nextCursor"), void 0);
  #generation = 0;
  get extraEntries() {
    return this.entries.filter(entry => entry.key !== this.args.group.latest.key);
  }
  get label() {
    const actionName = this.args.group.key;
    return i18n(themePrefix("isbf_v2.notification_action_count"), {
      action: this.args.actionLabel(actionName),
      count: this.args.group.count
    });
  }
  get showDetails() {
    return this.expanded && (this.extraEntries.length > 0 || this.error || Boolean(this.nextCursor));
  }
  async loadMore() {
    if (this.loading || this.loaded && !this.nextCursor) {
      return;
    }
    this.loading = true;
    this.error = false;
    const generation = this.#generation;
    try {
      const response = await ajax(this.args.group.detail_url, {
        data: {
          cursor: this.nextCursor,
          limit: 20
        }
      });
      if (this.isDestroying || generation !== this.#generation) {
        return;
      }
      const entries = await this.args.prepareEntries(response.entries);
      if (this.isDestroying || generation !== this.#generation) {
        return;
      }
      this.entries = mergeEntries(this.entries, entries);
      this.nextCursor = response.next_cursor;
      this.loaded = true;
    } catch {
      if (!this.isDestroying && generation === this.#generation) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying && generation === this.#generation) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  refresh() {
    this.#generation++;
    this.entries = [];
    this.nextCursor = null;
    this.loaded = false;
    this.loading = false;
    this.error = false;
    if (this.expanded) {
      this.loadMore();
    }
  }
  static {
    dt7948.n(this.prototype, "refresh", [action]);
  }
  toggle() {
    this.expanded = !this.expanded;
    if (this.expanded && !this.loaded) {
      this.loadMore();
    }
  }
  static {
    dt7948.n(this.prototype, "toggle", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <section
      class="isbf-notification-action"
      {{didUpdate this.refresh @revision}}
    >
      <button
        aria-busy={{if this.loading "true" "false"}}
        aria-expanded={{if this.expanded "true" "false"}}
        class="isbf-notification-action__toggle"
        type="button"
        {{on "click" this.toggle}}
      >
        <span class="isbf-notification-action__label">
          {{#if @group.latest.item.icon}}
            {{dIcon @group.latest.item.icon}}
          {{/if}}
          <span>{{this.label}}</span>
          <ISBFNotificationUnread @unread={{@group.unread}} />
        </span>
        {{dIcon (if this.expanded "chevron-down" "chevron-right")}}
      </button>
      <ISBFNotificationEntry @entry={{@group.latest}} />
      <span class="sr-only" role="status">{{#if this.loading}}{{i18n
            (themePrefix "isbf_v2.notifications_loading")
          }}{{/if}}</span>
      {{#if this.showDetails}}
        <div class="isbf-notification-action__details">
          {{#each this.extraEntries key="key" as |entry|}}
            <ISBFNotificationEntry @entry={{entry}} />
          {{/each}}
          {{#if this.error}}
            <p role="alert">{{i18n
                (themePrefix "isbf_v2.notifications_error")
              }}</p>
            <DButton
              @action={{this.loadMore}}
              @label={{themePrefix "isbf_v2.notifications_retry"}}
            />
          {{else if this.nextCursor}}
            <DButton
              @action={{this.loadMore}}
              @isLoading={{this.loading}}
              @label={{themePrefix "isbf_v2.load_more"}}
            />
          {{/if}}
        </div>
      {{/if}}
    </section>
    */
    {
      "id": null,
      "block": "[[[11,\"section\"],[24,0,\"isbf-notification-action\"],[4,[32,0],[[30,0,[\"refresh\"]],[30,1]],null],[12],[1,\"\\n  \"],[11,\"button\"],[16,\"aria-busy\",[52,[30,0,[\"loading\"]],\"true\",\"false\"]],[16,\"aria-expanded\",[52,[30,0,[\"expanded\"]],\"true\",\"false\"]],[24,0,\"isbf-notification-action__toggle\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggle\"]]],null],[12],[1,\"\\n    \"],[10,1],[14,0,\"isbf-notification-action__label\"],[12],[1,\"\\n\"],[41,[30,2,[\"latest\",\"item\",\"icon\"]],[[[1,\"        \"],[1,[28,[32,2],[[30,2,[\"latest\",\"item\",\"icon\"]]],null]],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,1],[12],[1,[30,0,[\"label\"]]],[13],[1,\"\\n      \"],[8,[32,3],null,[[\"@unread\"],[[30,2,[\"unread\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[1,[28,[32,2],[[52,[30,0,[\"expanded\"]],\"chevron-down\",\"chevron-right\"]],null]],[1,\"\\n  \"],[13],[1,\"\\n  \"],[8,[32,4],null,[[\"@entry\"],[[30,2,[\"latest\"]]]],null],[1,\"\\n  \"],[10,1],[14,0,\"sr-only\"],[14,\"role\",\"status\"],[12],[41,[30,0,[\"loading\"]],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.notifications_loading\"],null]],null]]],[]],null],[13],[1,\"\\n\"],[41,[30,0,[\"showDetails\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notification-action__details\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"extraEntries\"]]],null]],null],\"key\",[[[1,\"        \"],[8,[32,4],null,[[\"@entry\"],[[30,3]]],null],[1,\"\\n\"]],[3]],null],[41,[30,0,[\"error\"]],[[[1,\"        \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.notifications_error\"],null]],null]],[13],[1,\"\\n        \"],[8,[32,7],null,[[\"@action\",\"@label\"],[[30,0,[\"loadMore\"]],[28,[32,6],[\"isbf_v2.notifications_retry\"],null]]],null],[1,\"\\n\"]],[]],[[[41,[30,0,[\"nextCursor\"]],[[[1,\"        \"],[8,[32,7],null,[[\"@action\",\"@isLoading\",\"@label\"],[[30,0,[\"loadMore\"]],[30,0,[\"loading\"]],[28,[32,6],[\"isbf_v2.load_more\"],null]]],null],[1,\"\\n      \"]],[]],null]],[]]],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"@revision\",\"@group\",\"entry\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didUpdate,
        on,
        dIcon,
        ISBFNotificationUnread: __discourseComponentClass$1,
        ISBFNotificationEntry,
        i18n,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-notification-action", ISBFNotificationAction);
var Mod20 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFNotificationAction
});
let ISBFNotifications$1 = class ISBFNotifications extends Component {
  static {
    dt7948.g(this.prototype, "a11y", [service]);
  }
  #a11y = (dt7948.i(this, "a11y"), void 0);
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (dt7948.i(this, "isbfNotifications"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "groups", [tracked], function () {
      return [];
    });
  }
  #groups = (dt7948.i(this, "groups"), void 0);
  static {
    dt7948.g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (dt7948.i(this, "loaded"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "markingRead", [tracked], function () {
      return false;
    });
  }
  #markingRead = (dt7948.i(this, "markingRead"), void 0);
  static {
    dt7948.g(this.prototype, "markReadError", [tracked], function () {
      return false;
    });
  }
  #markReadError = (dt7948.i(this, "markReadError"), void 0);
  static {
    dt7948.g(this.prototype, "nextCursor", [tracked], function () {
      return null;
    });
  }
  #nextCursor = (dt7948.i(this, "nextCursor"), void 0);
  static {
    dt7948.g(this.prototype, "revision", [tracked], function () {
      return 0;
    });
  }
  #revision = (dt7948.i(this, "revision"), void 0);
  static {
    dt7948.g(this.prototype, "tab", [tracked], function () {
      return "all";
    });
  }
  #tab = (dt7948.i(this, "tab"), void 0);
  #generation = 0;
  #models = new Map();
  constructor() {
    super(...arguments);
    this.tab = consumeInitialNotificationTab();
    this.appEvents.on("isbf:notification-tab", this, this.selectTab);
    this.appEvents.on("isbf:notification-filter-changed", this, this.onFilterChange);
    this.appEvents.on("isbf:notifications-updated", this, this.onNotificationUpdate);
    scheduleOnce("afterRender", this, this.loadMore);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:notification-tab", this, this.selectTab);
    this.appEvents.off("isbf:notification-filter-changed", this, this.onFilterChange);
    this.appEvents.off("isbf:notifications-updated", this, this.onNotificationUpdate);
  }
  get allSelected() {
    return this.tab === "all";
  }
  get filter() {
    return this.isbfNotifications.filter;
  }
  get mentionsSelected() {
    return this.tab === "mentions";
  }
  get isEmpty() {
    return this.loaded && !this.groups.length;
  }
  get unreadOnly() {
    return this.filter === "unread";
  }
  actionLabel(actionName) {
    const known = ["liked", "reaction", "replied", "mentioned", "group_mentioned"];
    return i18n(themePrefix(`isbf_v2.notification_${known.includes(actionName) ? actionName : "activity"}`));
  }
  static {
    dt7948.n(this.prototype, "actionLabel", [action]);
  }
  loadMore() {
    return this.#loadGroups(false);
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  refresh() {
    return this.#loadGroups(true);
  }
  static {
    dt7948.n(this.prototype, "refresh", [action]);
  }
  onFilterChange() {
    this.#reset();
  }
  static {
    dt7948.n(this.prototype, "onFilterChange", [action]);
  }
  onNotificationUpdate(data) {
    for (const [id, read] of data?.recent || []) {
      this.#models.get(id)?.set("read", read);
    }
    scheduleOnce("afterRender", this, this.refresh);
  }
  static {
    dt7948.n(this.prototype, "onNotificationUpdate", [action]);
  }
  retryFilter(_value, event) {
    // Keep focus in the menu when the retry control disappears.
    event.target.closest(".isbf-notifications__menu")?.querySelector("summary")?.focus();
    return this.isbfNotifications.retryFilter();
  }
  static {
    dt7948.n(this.prototype, "retryFilter", [action]);
  }
  async prepareEntries(entries) {
    const generation = this.#generation;
    await this.#initializeModels(entries.map(entry => entry.notification), generation);
    if (this.#stale(generation)) {
      return [];
    }
    return entries.map(entry => this.prepareEntry(entry));
  }
  static {
    dt7948.n(this.prototype, "prepareEntries", [action]);
  }
  prepareEntry(entry) {
    const notification = this.#models.get(entry.notification.id);
    const item = new UserMenuNotificationItem({
      notification,
      appEvents: this.appEvents,
      currentUser: this.currentUser,
      site: this.site,
      siteSettings: this.siteSettings
    });
    return {
      ...entry,
      notification,
      item,
      actionLabel: this.actionLabel(entry.action)
    };
  }
  static {
    dt7948.n(this.prototype, "prepareEntry", [action]);
  }
  selectTab(tab) {
    if (this.tab === tab) {
      return;
    }
    this.tab = tab;
    this.#reset();
  }
  static {
    dt7948.n(this.prototype, "selectTab", [action]);
  }
  toggleUnreadOnly() {
    return this.isbfNotifications.saveFilter(this.unreadOnly ? "all" : "unread");
  }
  static {
    dt7948.n(this.prototype, "toggleUnreadOnly", [action]);
  }
  dismissNotifications() {
    const count = this.currentUser.unread_high_priority_notifications;
    if (count > 0) {
      this.modal.show(DismissNotificationConfirmationModal, {
        model: {
          confirmationMessage: i18n("notifications.dismiss_confirmation.body.default", {
            count
          }),
          dismissNotifications: this.markRead
        }
      });
    } else {
      this.markRead();
    }
  }
  static {
    dt7948.n(this.prototype, "dismissNotifications", [action]);
  }
  async markRead() {
    if (this.markingRead) {
      return;
    }
    this.markingRead = true;
    this.markReadError = false;
    const version = this.isbfNotifications.version;
    try {
      await ajax("/notifications/mark-read", {
        type: "PUT"
      });
      if (this.isDestroying) {
        return;
      }
      // A notification state received during this request may include a newer notice.
      if (this.isbfNotifications.version === version) {
        this.#models.forEach(notification => notification.set("read", true));
        this.currentUser.setProperties({
          grouped_unread_notifications: {},
          unread_high_priority_notifications: 0,
          unread_notifications: 0,
          all_unread_notifications_count: 0
        });
      }
      this.markReadError = false;
      this.refresh();
    } catch {
      if (!this.isDestroying) {
        this.markReadError = true;
        this.a11y.announce(i18n(themePrefix("isbf_v2.action_failed")), "assertive");
      }
    } finally {
      if (!this.isDestroying) {
        this.markingRead = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "markRead", [action]);
  }
  onMenuKeydown(event) {
    if (event.key === "Escape") {
      event.currentTarget.open = false;
      event.currentTarget.querySelector("summary")?.focus();
      event.preventDefault();
    }
  }
  static {
    dt7948.n(this.prototype, "onMenuKeydown", [action]);
  }
  topicTitle(title) {
    return isUntitledTopicTitle(title) ? i18n(themePrefix("isbf_v2.untitled_topic")) : title;
  }
  static {
    dt7948.n(this.prototype, "topicTitle", [action]);
  }
  async #initializeModels(raw, generation) {
    const missing = [...new Map(raw.filter(notification => !this.#models.has(notification.id)).map(notification => [notification.id, notification])).values()];
    const models = await Notification.initializeNotifications(missing);
    if (this.#stale(generation)) {
      return;
    }
    for (const model of models) {
      if (!this.#models.has(model.id)) {
        this.#models.set(model.id, model);
      }
    }
    for (const notification of raw) {
      this.#models.get(notification.id).setProperties(notification);
    }
  }
  async #loadGroups(refresh) {
    if (this.isDestroying || !refresh && (this.loading || this.loaded && !this.nextCursor)) {
      return;
    }
    if (refresh) {
      this.#generation++;
    }
    const generation = this.#generation;
    const target = refresh ? Math.max(this.groups.length, 20) : 0;
    let cursor = refresh ? null : this.nextCursor;
    const incoming = [];
    this.loading = true;
    this.error = false;
    try {
      do {
        const response = await ajax("/isbf/notifications/groups.json", {
          data: {
            tab: this.tab,
            filter: this.filter,
            cursor,
            limit: 20
          }
        });
        if (this.#stale(generation)) {
          return;
        }
        incoming.push(...response.groups);
        cursor = response.next_cursor;
      } while (refresh && cursor && incoming.length < target);
      await this.#initializeModels(incoming.flatMap(group => group.kind === "topic" ? group.actions.map(item => item.latest.notification) : [group.latest.notification]), generation);
      if (this.#stale(generation)) {
        return;
      }
      const existing = new Set(refresh ? [] : this.groups.map(group => group.key));
      const groups = incoming.filter(group => !existing.has(group.key)).map(group => ({
        ...group,
        ...(group.kind === "topic" ? {
          actions: group.actions.map(item => ({
            ...item,
            latest: this.prepareEntry(item.latest)
          }))
        } : {
          latest: this.prepareEntry(group.latest)
        })
      }));
      this.groups = refresh ? groups : [...this.groups, ...groups];
      this.nextCursor = cursor;
      this.loaded = true;
      if (this.unreadOnly && !this.groups.length) {
        this.a11y.announce(i18n(themePrefix("isbf_v2.notifications_unread_empty")));
      }
      if (refresh) {
        this.revision++;
      }
    } catch {
      if (!this.#stale(generation)) {
        this.error = true;
      }
    } finally {
      if (!this.#stale(generation)) {
        this.loading = false;
      }
    }
  }
  #reset() {
    this.#generation++;
    this.groups = [];
    this.nextCursor = null;
    this.loaded = false;
    this.loading = false;
    this.error = false;
    this.loadMore();
  }
  #stale(generation) {
    return this.isDestroying || generation !== this.#generation;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-notifications">
      <header class="isbf-notifications__heading">
        <h1>{{i18n (themePrefix "isbf_v2.notifications")}}</h1>
        <details
          class="isbf-notifications__menu"
          {{on "keydown" this.onMenuKeydown}}
        >
          <summary
            aria-label={{i18n (themePrefix "isbf_v2.notifications_menu")}}
          >{{dIcon "ellipsis"}}</summary>
          <div class="isbf-notifications__menu-items">
            <DButton
              @action={{this.dismissNotifications}}
              @disabled={{this.markingRead}}
              @label={{themePrefix "isbf_v2.notifications_mark_read"}}
            />
            <a href="/my/preferences/notifications">{{i18n
                (themePrefix "isbf_v2.notifications_settings")
              }}</a>
            <div class="isbf-notifications__filter">
              <DToggleSwitch
                disabled={{this.isbfNotifications.savingFilter}}
                @label={{themePrefix "isbf_v2.notifications_unread_only"}}
                @state={{this.unreadOnly}}
                {{on "click" this.toggleUnreadOnly}}
              />
            </div>
            {{#if this.isbfNotifications.filterError}}
              <div
                class="isbf-notifications__filter-error isbf-notifications__preference-error"
                role="alert"
              >
                <p>{{i18n
                    (themePrefix "isbf_v2.notifications_filter_error")
                  }}</p>
                <DButton
                  @action={{this.retryFilter}}
                  @disabled={{this.isbfNotifications.savingFilter}}
                  @forwardEvent={{true}}
                  @label={{themePrefix "isbf_v2.notifications_retry"}}
                />
              </div>
            {{/if}}
            <div
              aria-label={{i18n
                (themePrefix "isbf_v2.notifications_badge_style")
              }}
              class="isbf-notifications__badge-options"
              role="group"
            >
              <p>{{i18n (themePrefix "isbf_v2.notifications_badge_style")}}</p>
              <DButton
                @action={{fn this.isbfNotifications.saveBadgeStyle "number"}}
                @ariaPressed={{this.isbfNotifications.numberStyle}}
                @disabled={{this.isbfNotifications.savingStyle}}
                @label={{themePrefix "isbf_v2.notifications_badge_number"}}
              />
              <DButton
                @action={{fn this.isbfNotifications.saveBadgeStyle "dot"}}
                @ariaPressed={{this.isbfNotifications.dotStyle}}
                @disabled={{this.isbfNotifications.savingStyle}}
                @label={{themePrefix "isbf_v2.notifications_badge_dot"}}
              />
            </div>
            {{#if this.isbfNotifications.styleError}}
              <div class="isbf-notifications__preference-error" role="alert">
                <p>{{i18n
                    (themePrefix "isbf_v2.notifications_badge_error")
                  }}</p>
                <DButton
                  @action={{this.isbfNotifications.retryBadgeStyle}}
                  @disabled={{this.isbfNotifications.savingStyle}}
                  @label={{themePrefix "isbf_v2.notifications_retry"}}
                />
              </div>
            {{/if}}
          </div>
        </details>
      </header>
      <div
        aria-label={{i18n (themePrefix "isbf_v2.notifications_tabs")}}
        class="isbf-notifications__tabs"
        role="group"
      >
        <button
          aria-pressed={{if this.allSelected "true" "false"}}
          class={{if this.allSelected "is-active"}}
          type="button"
          {{on "click" (fn this.selectTab "all")}}
        >{{i18n (themePrefix "isbf_v2.notifications_all")}}</button>
        <button
          aria-pressed={{if this.mentionsSelected "true" "false"}}
          class={{if this.mentionsSelected "is-active"}}
          type="button"
          {{on "click" (fn this.selectTab "mentions")}}
        >{{i18n (themePrefix "isbf_v2.notifications_mentions")}}</button>
      </div>
      {{#if this.markReadError}}<div
          class="isbf-notifications__status"
          role="alert"
        ><p>{{i18n (themePrefix "isbf_v2.action_failed")}}</p><DButton
            @action={{this.markRead}}
            @label={{themePrefix "isbf_v2.notifications_retry"}}
          /></div>{{/if}}
      {{#if this.groups.length}}
        <div class="isbf-notifications__groups">
          {{#each this.groups key="key" as |group|}}
            {{#if group.topic}}
              <article class="isbf-notifications__topic">
                <h2 class="isbf-notifications__topic-title"><a
                    href={{group.topic.url}}
                  >{{this.topicTitle group.topic.title}}</a></h2>
                {{#each group.actions key="key" as |item|}}
                  <ISBFNotificationAction
                    @actionLabel={{this.actionLabel}}
                    @group={{item}}
                    @prepareEntries={{this.prepareEntries}}
                    @revision={{this.revision}}
                  />
                {{/each}}
              </article>
            {{else}}
              <article
                class="isbf-notifications__standalone"
              ><ISBFNotificationEntry
                  @entry={{group.latest}}
                  @standalone={{true}}
                /></article>
            {{/if}}
          {{/each}}
        </div>
      {{/if}}
      {{#if this.loading}}<p
          class="isbf-notifications__status"
          role="status"
        >{{i18n (themePrefix "isbf_v2.notifications_loading")}}</p>{{/if}}
      {{#if this.error}}
        <div class="isbf-notifications__status" role="alert"><p>{{i18n
              (themePrefix "isbf_v2.notifications_error")
            }}</p><DButton
            @action={{this.loadMore}}
            @label={{themePrefix "isbf_v2.notifications_retry"}}
          /></div>
      {{else if this.isEmpty}}<p class="isbf-notifications__status">{{i18n
            (themePrefix
              (if
                this.unreadOnly
                "isbf_v2.notifications_unread_empty"
                "isbf_v2.notifications_empty"
              )
            )
          }}</p>{{/if}}
      {{#if this.nextCursor}}<DButton
          class="isbf-notifications__more"
          @action={{this.loadMore}}
          @isLoading={{this.loading}}
          @label={{themePrefix "isbf_v2.load_more"}}
        />{{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-notifications\"],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-notifications__heading\"],[12],[1,\"\\n    \"],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications\"],null]],null]],[13],[1,\"\\n    \"],[11,\"details\"],[24,0,\"isbf-notifications__menu\"],[4,[32,2],[\"keydown\",[30,0,[\"onMenuKeydown\"]]],null],[12],[1,\"\\n      \"],[10,\"summary\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_menu\"],null]],null]],[12],[1,[28,[32,3],[\"ellipsis\"],null]],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-notifications__menu-items\"],[12],[1,\"\\n        \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"dismissNotifications\"]],[30,0,[\"markingRead\"]],[28,[32,1],[\"isbf_v2.notifications_mark_read\"],null]]],null],[1,\"\\n        \"],[10,3],[14,6,\"/my/preferences/notifications\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_settings\"],null]],null]],[13],[1,\"\\n        \"],[10,0],[14,0,\"isbf-notifications__filter\"],[12],[1,\"\\n          \"],[8,[32,5],[[16,\"disabled\",[30,0,[\"isbfNotifications\",\"savingFilter\"]]],[4,[32,2],[\"click\",[30,0,[\"toggleUnreadOnly\"]]],null]],[[\"@label\",\"@state\"],[[28,[32,1],[\"isbf_v2.notifications_unread_only\"],null],[30,0,[\"unreadOnly\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"filterError\"]],[[[1,\"          \"],[10,0],[14,0,\"isbf-notifications__filter-error isbf-notifications__preference-error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n            \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_filter_error\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@forwardEvent\",\"@label\"],[[30,0,[\"retryFilter\"]],[30,0,[\"isbfNotifications\",\"savingFilter\"]],true,[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_style\"],null]],null]],[14,0,\"isbf-notifications__badge-options\"],[14,\"role\",\"group\"],[12],[1,\"\\n          \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_style\"],null]],null]],[13],[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@ariaPressed\",\"@disabled\",\"@label\"],[[28,[32,6],[[30,0,[\"isbfNotifications\",\"saveBadgeStyle\"]],\"number\"],null],[30,0,[\"isbfNotifications\",\"numberStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_badge_number\"],null]]],null],[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@ariaPressed\",\"@disabled\",\"@label\"],[[28,[32,6],[[30,0,[\"isbfNotifications\",\"saveBadgeStyle\"]],\"dot\"],null],[30,0,[\"isbfNotifications\",\"dotStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_badge_dot\"],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"styleError\"]],[[[1,\"          \"],[10,0],[14,0,\"isbf-notifications__preference-error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n            \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_error\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"isbfNotifications\",\"retryBadgeStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_tabs\"],null]],null]],[14,0,\"isbf-notifications__tabs\"],[14,\"role\",\"group\"],[12],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-pressed\",[52,[30,0,[\"allSelected\"]],\"true\",\"false\"]],[16,0,[52,[30,0,[\"allSelected\"]],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,6],[[30,0,[\"selectTab\"]],\"all\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_all\"],null]],null]],[13],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-pressed\",[52,[30,0,[\"mentionsSelected\"]],\"true\",\"false\"]],[16,0,[52,[30,0,[\"mentionsSelected\"]],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,6],[[30,0,[\"selectTab\"]],\"mentions\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_mentions\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[41,[30,0,[\"markReadError\"]],[[[10,0],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"alert\"],[12],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.action_failed\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@label\"],[[30,0,[\"markRead\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"groups\",\"length\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notifications__groups\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"groups\"]]],null]],null],\"key\",[[[41,[30,1,[\"topic\"]],[[[1,\"          \"],[10,\"article\"],[14,0,\"isbf-notifications__topic\"],[12],[1,\"\\n            \"],[10,\"h2\"],[14,0,\"isbf-notifications__topic-title\"],[12],[10,3],[15,6,[30,1,[\"topic\",\"url\"]]],[12],[1,[28,[30,0,[\"topicTitle\"]],[[30,1,[\"topic\",\"title\"]]],null]],[13],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,1,[\"actions\"]]],null]],null],\"key\",[[[1,\"              \"],[8,[32,7],null,[[\"@actionLabel\",\"@group\",\"@prepareEntries\",\"@revision\"],[[30,0,[\"actionLabel\"]],[30,2],[30,0,[\"prepareEntries\"]],[30,0,[\"revision\"]]]],null],[1,\"\\n\"]],[2]],null],[1,\"          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,\"article\"],[14,0,\"isbf-notifications__standalone\"],[12],[8,[32,8],null,[[\"@entry\",\"@standalone\"],[[30,1,[\"latest\"]],true]],null],[13],[1,\"\\n\"]],[]]]],[1]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"status\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"alert\"],[12],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_error\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@label\"],[[30,0,[\"loadMore\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[13],[1,\"\\n  \"]],[]],[[[41,[30,0,[\"isEmpty\"]],[[[10,2],[14,0,\"isbf-notifications__status\"],[12],[1,[28,[32,0],[[28,[32,1],[[52,[30,0,[\"unreadOnly\"]],\"isbf_v2.notifications_unread_empty\",\"isbf_v2.notifications_empty\"]],null]],null]],[13]],[]],null]],[]]],[1,\"\\n  \"],[41,[30,0,[\"nextCursor\"]],[[[8,[32,4],[[24,0,\"isbf-notifications__more\"]],[[\"@action\",\"@isLoading\",\"@label\"],[[30,0,[\"loadMore\"]],[30,0,[\"loading\"]],[28,[32,1],[\"isbf_v2.load_more\"],null]]],null]],[]],null],[1,\"\\n\"],[13]],[\"group\",\"item\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        on,
        dIcon,
        DButton,
        DToggleSwitch,
        fn,
        ISBFNotificationAction,
        ISBFNotificationEntry
      }),
      "isStrictMode": true
    }), this);
  }
};
registerModuleForModifyClass("isbf-notifications", ISBFNotifications$1);
var Mod22 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFNotifications$1
});
class ISBFOfficialFeed extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "campus", [tracked], function () {
      return "";
    });
  }
  #campus = (dt7948.i(this, "campus"), void 0);
  static {
    dt7948.g(this.prototype, "type", [tracked], function () {
      return "";
    });
  }
  #type = (dt7948.i(this, "type"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "topicList", [tracked], function () {
      return null;
    });
  }
  #topicList = (dt7948.i(this, "topicList"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  #requests = new OfficialRequestGuard();
  constructor() {
    super(...arguments);
    this.appEvents.on("isbf:home-pins-changed", this.refreshHomePins);
    scheduleOnce("afterRender", this, this.load);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:home-pins-changed", this.refreshHomePins);
    this.#requests.next();
  }
  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }
  get isEmpty() {
    return this.topicList && !this.topics.length && !this.loading;
  }
  get campusSelections() {
    return this.campus ? [this.campus] : [];
  }
  get typeSelections() {
    return this.type ? [this.type] : [];
  }
  refreshHomePins() {
    if (!this.isDestroying && this.topicList) {
      sortHomePinList(this.topicList);
      this.topics = [...this.topicList.topics];
    }
  }
  static {
    dt7948.n(this.prototype, "refreshHomePins", [action]);
  }
  changeCampus(id) {
    this.campus = id;
    this.load();
  }
  static {
    dt7948.n(this.prototype, "changeCampus", [action]);
  }
  changeType(id) {
    this.type = id;
    this.load();
  }
  static {
    dt7948.n(this.prototype, "changeType", [action]);
  }
  async load() {
    const request = this.#requests.next();
    this.loading = true;
    this.error = false;
    this.topicList = null;
    this.topics = [];
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: {
          q: buildOfficialQuery(this.args.config, this.campus, this.type)
        }
      });
      if (this.#isCurrent(request)) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (this.#isCurrent(request)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async loadMore() {
    if (this.loading || !this.canLoadMore) {
      return;
    }
    const request = this.#requests.next();
    const list = this.topicList;
    this.loading = true;
    this.error = false;
    try {
      await list.loadMore();
      if (this.#isCurrent(request)) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (this.#isCurrent(request)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }
  static {
    dt7948.n(this.prototype, "navigateToTopic", [action]);
  }
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  #isCurrent(request) {
    return !this.isDestroying && this.#requests.isCurrent(request);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main aria-busy={{this.loading}} class="isbf-official-feed">
      <div class="isbf-official-feed__filters">
        <ISBFOfficialPicker
          @allKey="isbf_v2.official_all_campuses"
          @items={{@config.campuses}}
          @labelKey="isbf_v2.official_campus"
          @onSelect={{this.changeCampus}}
          @selectedIds={{this.campusSelections}}
        />
        <ISBFOfficialPicker
          @allKey="isbf_v2.official_all_types"
          @items={{@config.types}}
          @labelKey="isbf_v2.official_type"
          @onSelect={{this.changeType}}
          @selectedIds={{this.typeSelections}}
        />
      </div>
      {{#each this.topics key="id" as |topic|}}
        <ISBFV2FeedCard
          @navigateToTopic={{this.navigateToTopic}}
          @officialLayout={{true}}
          @topic={{topic}}
        />
      {{/each}}
      <div aria-live="polite" class="isbf-official-feed__status">
        {{#if this.loading}}
          <p role="status">{{i18n (themePrefix "isbf_v2.official_loading")}}</p>
        {{else if this.error}}
          <p role="alert">{{i18n
              (themePrefix "isbf_v2.official_load_error")
            }}</p>
          <button type="button" {{on "click" this.retry}}>{{i18n
              (themePrefix "isbf_v2.official_retry")
            }}</button>
        {{else if this.isEmpty}}
          <p>{{i18n (themePrefix "isbf_v2.official_empty")}}</p>
        {{/if}}
        {{#if this.canLoadMore}}
          {{#unless this.error}}
            <button
              disabled={{this.loading}}
              type="button"
              {{on "click" this.loadMore}}
            >{{i18n (themePrefix "isbf_v2.load_more")}}</button>
          {{/unless}}
        {{/if}}
      </div>
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[15,\"aria-busy\",[30,0,[\"loading\"]]],[14,0,\"isbf-official-feed\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-official-feed__filters\"],[12],[1,\"\\n    \"],[8,[32,0],null,[[\"@allKey\",\"@items\",\"@labelKey\",\"@onSelect\",\"@selectedIds\"],[\"isbf_v2.official_all_campuses\",[30,1,[\"campuses\"]],\"isbf_v2.official_campus\",[30,0,[\"changeCampus\"]],[30,0,[\"campusSelections\"]]]],null],[1,\"\\n    \"],[8,[32,0],null,[[\"@allKey\",\"@items\",\"@labelKey\",\"@onSelect\",\"@selectedIds\"],[\"isbf_v2.official_all_types\",[30,1,[\"types\"]],\"isbf_v2.official_type\",[30,0,[\"changeType\"]],[30,0,[\"typeSelections\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"    \"],[8,[32,1],null,[[\"@navigateToTopic\",\"@officialLayout\",\"@topic\"],[[30,0,[\"navigateToTopic\"]],true,[30,2]]],null],[1,\"\\n\"]],[2]],null],[1,\"  \"],[10,0],[14,\"aria-live\",\"polite\"],[14,0,\"isbf-official-feed__status\"],[12],[1,\"\\n\"],[41,[30,0,[\"loading\"]],[[[1,\"      \"],[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"error\"]],[[[1,\"      \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official_load_error\"],null]],null]],[13],[1,\"\\n      \"],[11,\"button\"],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"retry\"]]],null],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official_retry\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isEmpty\"]],[[[1,\"      \"],[10,2],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official_empty\"],null]],null]],[13],[1,\"\\n    \"]],[]],null]],[]]]],[]]],[41,[30,0,[\"canLoadMore\"]],[[[41,[51,[30,0,[\"error\"]]],[[[1,\"        \"],[11,\"button\"],[16,\"disabled\",[30,0,[\"loading\"]]],[24,4,\"button\"],[4,[32,4],[\"click\",[30,0,[\"loadMore\"]]],null],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.load_more\"],null]],null]],[13],[1,\"\\n\"]],[]],null]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[13]],[\"@config\",\"topic\"],[\"each\",\"-track-array\",\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFOfficialPicker,
        ISBFV2FeedCard,
        i18n,
        themePrefix,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-official-feed", ISBFOfficialFeed);
var Mod52 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFOfficialFeed
});
class ISBFTeamup extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "topicList", [tracked], function () {
      return null;
    });
  }
  #topicList = (dt7948.i(this, "topicList"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  #refreshPending = false;
  #retryLoadMore = false;
  constructor() {
    super(...arguments);
    this.appEvents.on("composer:created-post", this.refresh);
    this.appEvents.on("composer:edited-post", this.editRefresh);
    scheduleOnce("afterRender", this, this.load);
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("composer:created-post", this.refresh);
    this.appEvents.off("composer:edited-post", this.editRefresh);
  }
  get config() {
    return teamupConfig(this.site);
  }
  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }
  get canCreate() {
    return Boolean(this.config && this.config?.publishing_enabled !== false && this.currentUser && this.site.categories?.find(category => category.id === this.config?.category_id)?.canCreateTopic);
  }
  create() {
    if (!this.canCreate) {
      return;
    }
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: Composer.NEW_TOPIC_KEY
    });
  }
  static {
    dt7948.n(this.prototype, "create", [action]);
  }
  async load() {
    if (this.isDestroying || !this.config || !this.currentUser || this.loading) {
      return;
    }
    this.loading = true;
    this.error = false;
    this.#retryLoadMore = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: teamupQuery()
      });
      if (!this.isDestroying) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
        if (this.#refreshPending) {
          this.#refreshPending = false;
          this.load();
        }
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async loadMore() {
    if (this.isDestroying || this.loading || !this.canLoadMore) {
      return;
    }
    this.loading = true;
    this.error = false;
    this.#retryLoadMore = true;
    const list = this.topicList;
    try {
      await list.loadMore();
      if (!this.isDestroying) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
        if (this.#refreshPending) {
          this.#refreshPending = false;
          this.load();
        }
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  login() {
    this.appEvents.trigger("show-login");
  }
  static {
    dt7948.n(this.prototype, "login", [action]);
  }
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }
  static {
    dt7948.n(this.prototype, "navigateToTopic", [action]);
  }
  editRefresh() {
    if (this.isDestroying) {
      return;
    }
    this.topics = [];
    return this.refresh();
  }
  static {
    dt7948.n(this.prototype, "editRefresh", [action]);
  }
  refresh() {
    if (this.loading) {
      this.#refreshPending = true;
      return;
    }
    return this.load();
  }
  static {
    dt7948.n(this.prototype, "refresh", [action]);
  }
  retry() {
    return this.#retryLoadMore ? this.loadMore() : this.load();
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <ISBFWorkbenchTopicPage
      class="isbf-teamup"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="teamup"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFV2FeedCard
          @navigateToTopic={{this.navigateToTopic}}
          @topic={{topic}}
        />
      {{/each}}
    </ISBFWorkbenchTopicPage>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-teamup\"]],[[\"@canCreate\",\"@canLoadMore\",\"@config\",\"@currentUser\",\"@error\",\"@hasTopics\",\"@kind\",\"@loading\",\"@onCreate\",\"@onLoadMore\",\"@onLogin\",\"@onRetry\"],[[30,0,[\"canCreate\"]],[30,0,[\"canLoadMore\"]],[30,0,[\"config\"]],[30,0,[\"currentUser\"]],[30,0,[\"error\"]],[30,0,[\"topics\",\"length\"]],\"teamup\",[30,0,[\"loading\"]],[30,0,[\"create\"]],[30,0,[\"loadMore\"]],[30,0,[\"login\"]],[30,0,[\"retry\"]]]],[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"    \"],[8,[32,1],null,[[\"@navigateToTopic\",\"@topic\"],[[30,0,[\"navigateToTopic\"]],[30,1]]],null],[1,\"\\n\"]],[1]],null]],[]]]]]],[\"topic\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFWorkbenchTopicPage,
        ISBFV2FeedCard
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-teamup", ISBFTeamup);
var Mod110 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTeamup
});
class ISBFV2AccountMenu extends Component {
  static {
    dt7948.g(this.prototype, "a11y", [service]);
  }
  #a11y = (dt7948.i(this, "a11y"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "errorMessage", [tracked]);
  }
  #errorMessage = (dt7948.i(this, "errorMessage"), void 0);
  static {
    dt7948.g(this.prototype, "emailCodeSent", [tracked], function () {
      return false;
    });
  }
  #emailCodeSent = (dt7948.i(this, "emailCodeSent"), void 0);
  static {
    dt7948.g(this.prototype, "emailCodeExpiresIn", [tracked]);
  }
  #emailCodeExpiresIn = (dt7948.i(this, "emailCodeExpiresIn"), void 0);
  static {
    dt7948.g(this.prototype, "isBusy", [tracked], function () {
      return false;
    });
  }
  #isBusy = (dt7948.i(this, "isBusy"), void 0);
  static {
    dt7948.g(this.prototype, "isLinkFormOpen", [tracked], function () {
      return false;
    });
  }
  #isLinkFormOpen = (dt7948.i(this, "isLinkFormOpen"), void 0);
  static {
    dt7948.g(this.prototype, "isLinkedAccountsOpen", [tracked], function () {
      return false;
    });
  }
  #isLinkedAccountsOpen = (dt7948.i(this, "isLinkedAccountsOpen"), void 0);
  static {
    dt7948.g(this.prototype, "isOpen", [tracked], function () {
      return false;
    });
  }
  #isOpen = (dt7948.i(this, "isOpen"), void 0);
  static {
    dt7948.g(this.prototype, "isSwitchAccessDenied", [tracked], function () {
      return false;
    });
  }
  #isSwitchAccessDenied = (dt7948.i(this, "isSwitchAccessDenied"), void 0);
  static {
    dt7948.g(this.prototype, "linkedAccounts", [tracked], function () {
      return [];
    });
  }
  #linkedAccounts = (dt7948.i(this, "linkedAccounts"), void 0);
  static {
    dt7948.g(this.prototype, "requestedUsername", [tracked], function () {
      return "";
    });
  }
  #requestedUsername = (dt7948.i(this, "requestedUsername"), void 0);
  static {
    dt7948.g(this.prototype, "verificationData", [tracked], function () {
      return {};
    });
  }
  #verificationData = (dt7948.i(this, "verificationData"), void 0);
  static {
    dt7948.g(this.prototype, "verificationLinkId", [tracked]);
  }
  #verificationLinkId = (dt7948.i(this, "verificationLinkId"), void 0);
  #rootElement;
  willDestroy() {
    super.willDestroy(...arguments);
    this.#removeDocumentListeners();
  }
  get activeLinks() {
    return this.linkedAccounts.filter(link => ["pending_target", "pending_admin", "approved"].includes(link.status));
  }
  get avatarUrl() {
    return this.currentUser?.avatar_template?.replace("{size}", "96");
  }
  get canLinkAccounts() {
    return this.currentUser?.admin && this.siteSettings.isbf_account_switch_enabled;
  }
  get canSwitchAccounts() {
    return !this.isSwitchAccessDenied && this.siteSettings.isbf_account_switch_enabled && (this.currentUser?.admin || this.currentUser?.can_switch_linked_accounts);
  }
  get displayName() {
    return this.currentUser?.name || this.currentUser?.username;
  }
  get emailCodeSentMessage() {
    return i18n(themePrefix("isbf_v2.email_code_sent"), {
      minutes: Math.ceil(this.emailCodeExpiresIn / 60)
    });
  }
  get profileHref() {
    return `/u/${this.currentUser.username}`;
  }
  get showLinkedAccounts() {
    return this.canLinkAccounts || this.isLinkedAccountsOpen;
  }
  closeMenu() {
    this.isOpen = false;
    this.#resetForms();
    this.#removeDocumentListeners();
  }
  static {
    dt7948.n(this.prototype, "closeMenu", [action]);
  }
  async confirmLogout() {
    this.closeMenu();
    if (await this.dialog.confirm({
      message: i18n(themePrefix("isbf_v2.logout_confirm"), {
        username: this.currentUser.username
      }),
      confirmButtonLabel: themePrefix("isbf_v2.logout")
    })) {
      await this.#signOut();
    }
  }
  static {
    dt7948.n(this.prototype, "confirmLogout", [action]);
  }
  async createLink(event) {
    event.preventDefault();
    const username = this.requestedUsername.trim();
    if (!username) {
      return;
    }
    await this.#runRequest(async () => {
      await ajax("/isbf/account-switch/links", {
        type: "POST",
        data: {
          username
        }
      });
      this.requestedUsername = "";
      this.isLinkFormOpen = false;
      await this.#loadAccounts();
    });
  }
  static {
    dt7948.n(this.prototype, "createLink", [action]);
  }
  openMenu(event) {
    if (this.args.mobile || this.isOpen) {
      return;
    }
    this.#showMenu(event.currentTarget);
  }
  static {
    dt7948.n(this.prototype, "openMenu", [action]);
  }
  onFocusOut(event) {
    // Removing or disabling a focused control can leave no focus destination.
    if (event.relatedTarget && !event.currentTarget.contains(event.relatedTarget)) {
      this.closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "onFocusOut", [action]);
  }
  onKeyDown(event) {
    if (event.key === "Escape" && this.isOpen) {
      event.preventDefault();
      this.#rootElement?.querySelector(".isbf-v2-account-menu__trigger")?.focus();
      this.closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "onKeyDown", [action]);
  }
  onMouseLeave() {
    if (this.args.mobile) {
      return;
    }
    if (!this.#rootElement?.contains(document.activeElement)) {
      this.closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "onMouseLeave", [action]);
  }
  onOutsidePointer(event) {
    if (!this.#rootElement?.contains(event.target)) {
      this.closeMenu();
    }
  }
  static {
    dt7948.n(this.prototype, "onOutsidePointer", [action]);
  }
  selectVerification(link) {
    this.errorMessage = null;
    this.emailCodeSent = false;
    this.verificationData = {
      verificationMethod: "password",
      secondFactorMethod: "1"
    };
    this.verificationLinkId = link.id;
  }
  static {
    dt7948.n(this.prototype, "selectVerification", [action]);
  }
  async sendEmailCode(link) {
    if (this.isBusy) {
      return;
    }
    await this.#runRequest(async () => {
      const response = await ajax(`/isbf/account-switch/links/${link.id}/email-code`, {
        type: "POST"
      });
      this.emailCodeExpiresIn = response.expires_in;
      this.emailCodeSent = true;
      this.a11y.announce(this.emailCodeSentMessage, "polite");
    });
  }
  static {
    dt7948.n(this.prototype, "sendEmailCode", [action]);
  }
  async switchAccount(link) {
    if (!link.device_authorized) {
      this.selectVerification(link);
      return;
    }
    await this.#runRequest(async () => {
      const response = await ajax(`/isbf/account-switch/links/${link.id}/switch`, {
        type: "POST"
      });
      window.location.assign(response.redirect_url || "/");
    });
  }
  static {
    dt7948.n(this.prototype, "switchAccount", [action]);
  }
  toggleLinkForm() {
    this.errorMessage = null;
    if (this.canLinkAccounts) {
      this.isLinkFormOpen = !this.isLinkFormOpen;
    } else {
      this.isLinkedAccountsOpen = !this.isLinkedAccountsOpen;
    }
    this.verificationLinkId = null;
  }
  static {
    dt7948.n(this.prototype, "toggleLinkForm", [action]);
  }
  toggleMenu(event) {
    if (this.isOpen && this.args.mobile) {
      this.closeMenu();
    } else if (this.isOpen) {
      this.#rootElement?.querySelector(".isbf-v2-account-menu__panel button")?.focus();
    } else {
      this.#showMenu(event.currentTarget);
    }
  }
  static {
    dt7948.n(this.prototype, "toggleMenu", [action]);
  }
  updateRequestedUsername(event) {
    this.requestedUsername = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateRequestedUsername", [action]);
  }
  async verifyAndSwitch(link, formData) {
    const data = {
      verification_method: formData.verificationMethod,
      second_factor_method: formData.secondFactorMethod,
      second_factor_token: formData.secondFactorToken
    };
    if (formData.verificationMethod === "email_code") {
      data.email_code = formData.emailCode;
    } else {
      data.password = formData.password;
    }
    await this.#runRequest(async () => {
      const response = await ajax(`/isbf/account-switch/links/${link.id}/verify`, {
        type: "POST",
        data
      });
      window.location.assign(response.redirect_url || "/");
    });
  }
  static {
    dt7948.n(this.prototype, "verifyAndSwitch", [action]);
  }
  #errorText(error) {
    return error?.jqXHR?.responseJSON?.errors?.[0] || error?.jqXHR?.responseJSON?.error || i18n(themePrefix("isbf_v2.account_action_failed"));
  }
  async #loadAccounts() {
    if (!this.canSwitchAccounts) {
      return;
    }
    try {
      const response = await ajax("/isbf/account-switch/accounts");
      this.linkedAccounts = response.links || [];
    } catch (error) {
      if (error?.jqXHR?.status === 403 && !this.currentUser.admin) {
        this.isSwitchAccessDenied = true;
        this.linkedAccounts = [];
        this.currentUser.set("can_switch_linked_accounts", false);
        return;
      }
      if (error?.jqXHR?.status !== 404) {
        this.errorMessage = this.#errorText(error);
      }
    }
  }
  #removeDocumentListeners() {
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onKeyDown, true);
  }
  #resetForms() {
    this.errorMessage = null;
    this.isLinkFormOpen = false;
    this.isLinkedAccountsOpen = false;
    this.emailCodeSent = false;
    this.verificationData = {};
    this.requestedUsername = "";
    this.verificationLinkId = null;
  }
  async #runRequest(callback) {
    this.errorMessage = null;
    this.isBusy = true;
    try {
      await callback();
    } catch (error) {
      this.errorMessage = this.#errorText(error);
    } finally {
      this.isBusy = false;
    }
  }
  #showMenu(target) {
    this.#rootElement = target.closest(".isbf-v2-account-menu");
    this.isOpen = true;
    this.#loadAccounts();
    document.addEventListener("pointerdown", this.onOutsidePointer, true);
    document.addEventListener("keydown", this.onKeyDown, true);
  }
  async #signOut() {
    if (this.site.isReadOnly && !this.site.isStaffWritesOnly) {
      await this.dialog.alert(i18n("read_only_mode.logout_disabled"));
      return;
    }
    try {
      const pushSubscription = await getCurrentPushSubscription();
      const response = await this.currentUser.destroySession(pushSubscription);
      logout({
        redirect: response.redirect_url
      });
    } catch {
      await this.dialog.alert(i18n(themePrefix("isbf_v2.logout_failed")));
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.currentUser}}
      <div
        class={{if
          @mobile
          "isbf-v2-account-menu isbf-v2-account-menu--mobile"
          "isbf-v2-account-menu isbf-v2-account-menu--side"
        }}
        {{on "focusin" this.openMenu}}
        {{on "focusout" this.onFocusOut}}
        {{on "mouseenter" this.openMenu}}
        {{on "mouseleave" this.onMouseLeave}}
      >
        {{#unless @mobile}}
          <a
            class="isbf-v2-side__account"
            href={{this.profileHref}}
            {{on "click" this.closeMenu}}
          >
            <span class="isbf-avatar"><img
                alt=""
                height="40"
                src={{this.avatarUrl}}
                width="40"
              /><PluginOutlet
                @name="user-avatar-frame"
                @outletArgs={{lazyHash user=this.currentUser motion="static"}}
              /></span>
            <span>
              <b>{{this.displayName}}</b>
              <small>@{{this.currentUser.username}}</small>
            </span>
          </a>
        {{/unless}}
    
        <button
          aria-expanded={{if this.isOpen "true" "false"}}
          aria-label={{i18n (themePrefix "isbf_v2.account_actions")}}
          class="isbf-v2-account-menu__trigger"
          type="button"
          {{on "click" this.toggleMenu}}
        >
          {{#unless @mobile}}
            <span class="isbf-avatar isbf-v2-account-menu__compact-avatar"><img
                alt=""
                height="40"
                src={{this.avatarUrl}}
                width="40"
              /><PluginOutlet
                @name="user-avatar-frame"
                @outletArgs={{lazyHash user=this.currentUser motion="static"}}
              /></span>
          {{/unless}}
          {{dIcon "ellipsis"}}
        </button>
    
        {{#if this.isOpen}}
          <div
            aria-label={{i18n (themePrefix "isbf_v2.account_actions")}}
            class="isbf-v2-account-menu__panel"
            role="group"
          >
            {{#unless @mobile}}
              <a
                class="isbf-v2-account-menu__compact-profile"
                href={{this.profileHref}}
                {{on "click" this.closeMenu}}
              >
                {{i18n (themePrefix "isbf_v2.profile")}}
              </a>
            {{/unless}}
            <a href="/isbf-anonymous/posts" {{on "click" this.closeMenu}}>
              {{i18n (themePrefix "isbf_v2.my_anonymous_posts")}}
            </a>
    
            {{#if this.canSwitchAccounts}}
              {{#if this.showLinkedAccounts}}
                {{#each this.activeLinks as |link|}}
                  <div class="isbf-v2-account-menu__linked-account">
                    <span class="isbf-avatar"><img
                        alt=""
                        height="32"
                        src={{link.account.avatar_template}}
                        width="32"
                      /><PluginOutlet
                        @name="user-avatar-frame"
                        @outletArgs={{lazyHash
                          user=link.account
                          motion="static"
                        }}
                      /></span>
                    <span class="isbf-v2-account-menu__account-info">
                      <b class="isbf-v2-account-menu__account-name">
                        {{or link.account.name link.account.username}}
                      </b>
                      <small class="isbf-v2-account-menu__account-username">
                        @{{link.account.username}}
                      </small>
                    </span>
                    {{#if (eq link.status "approved")}}
                      <button
                        disabled={{this.isBusy}}
                        type="button"
                        {{on "click" (fn this.switchAccount link)}}
                      >
                        {{if
                          link.device_authorized
                          (i18n (themePrefix "isbf_v2.switch_now"))
                          (i18n (themePrefix "isbf_v2.verify_device"))
                        }}
                      </button>
                    {{else}}
                      <small class="isbf-v2-account-menu__status">
                        {{i18n (themePrefix "isbf_v2.account_link_pending")}}
                      </small>
                    {{/if}}
    
                    {{#if (eq this.verificationLinkId link.id)}}
                      <Form
                        class="isbf-v2-account-menu__verify"
                        @data={{this.verificationData}}
                        @onSubmit={{fn this.verifyAndSwitch link}}
                        as |form draft|
                      >
                        {{#if link.account.email_code_enabled}}
                          <form.Field
                            @disabled={{this.isBusy}}
                            @name="verificationMethod"
                            @title={{i18n
                              (themePrefix "isbf_v2.device_verification_method")
                            }}
                            @type="select"
                            @validation="required"
                            as |field|
                          >
                            <field.Control @includeNone={{false}} as |select|>
                              <select.Option @value="password">
                                {{i18n
                                  (themePrefix "isbf_v2.password_verification")
                                }}
                              </select.Option>
                              <select.Option @value="email_code">
                                {{i18n
                                  (themePrefix
                                    "isbf_v2.email_code_verification"
                                  )
                                }}
                              </select.Option>
                            </field.Control>
                          </form.Field>
                        {{/if}}
    
                        {{#if (eq draft.verificationMethod "email_code")}}
                          <DButton
                            class="isbf-v2-account-menu__send-code"
                            @action={{fn this.sendEmailCode link}}
                            @disabled={{this.isBusy}}
                            @translatedLabel={{if
                              this.emailCodeSent
                              (i18n (themePrefix "isbf_v2.resend_email_code"))
                              (i18n (themePrefix "isbf_v2.send_email_code"))
                            }}
                          />
                          {{#if this.emailCodeSent}}
                            <p class="isbf-v2-account-menu__code-status">
                              {{this.emailCodeSentMessage}}
                            </p>
                          {{/if}}
                          <form.Field
                            @disabled={{this.isBusy}}
                            @name="emailCode"
                            @title={{i18n
                              (themePrefix "isbf_v2.target_email_code")
                            }}
                            @type="input"
                            @validation="required|length:6,6"
                            as |field|
                          >
                            <field.Control
                              autocomplete="one-time-code"
                              inputmode="numeric"
                              maxlength="6"
                              pattern="[0-9]{6}"
                            />
                          </form.Field>
                        {{else}}
                          <form.Field
                            @disabled={{this.isBusy}}
                            @name="password"
                            @title={{i18n
                              (themePrefix "isbf_v2.target_password")
                            }}
                            @type="input-password"
                            @validation="required"
                            as |field|
                          >
                            <field.Control autocomplete="current-password" />
                          </form.Field>
                        {{/if}}
    
                        {{#if
                          (or
                            link.account.totp_enabled
                            link.account.backup_codes_enabled
                          )
                        }}
                          <form.Field
                            @description={{i18n
                              (themePrefix
                                (if
                                  (eq draft.secondFactorMethod "2")
                                  "isbf_v2.backup_code_help"
                                  "isbf_v2.authenticator_code_help"
                                )
                              )
                            }}
                            @disabled={{this.isBusy}}
                            @name="secondFactorToken"
                            @title={{i18n
                              (themePrefix "isbf_v2.second_factor_code")
                            }}
                            @type="input"
                            @validation="required"
                            as |field|
                          >
                            <field.Control autocomplete="one-time-code" />
                          </form.Field>
                        {{/if}}
                        {{#if link.account.backup_codes_enabled}}
                          <form.Field
                            @disabled={{this.isBusy}}
                            @name="secondFactorMethod"
                            @title={{i18n
                              (themePrefix "isbf_v2.second_factor_method")
                            }}
                            @type="select"
                            @validation="required"
                            as |field|
                          >
                            <field.Control @includeNone={{false}} as |select|>
                              <select.Option @value="1">
                                {{i18n
                                  (themePrefix "isbf_v2.authenticator_code")
                                }}
                              </select.Option>
                              <select.Option @value="2">
                                {{i18n (themePrefix "isbf_v2.backup_code")}}
                              </select.Option>
                            </field.Control>
                          </form.Field>
                        {{/if}}
                        <form.Submit
                          @disabled={{this.isBusy}}
                          @label={{themePrefix "isbf_v2.verify_and_switch"}}
                        />
                      </Form>
                    {{/if}}
                  </div>
                {{/each}}
              {{/if}}
    
              <button
                aria-expanded={{if
                  this.canLinkAccounts
                  (if this.isLinkFormOpen "true" "false")
                  (if this.isLinkedAccountsOpen "true" "false")
                }}
                class="isbf-v2-account-menu__link"
                type="button"
                {{on "click" this.toggleLinkForm}}
              >
                {{i18n (themePrefix "isbf_v2.link_account")}}
              </button>
    
              {{#if (and this.canLinkAccounts this.isLinkFormOpen)}}
                <form
                  class="isbf-v2-account-menu__link-form"
                  {{on "submit" this.createLink}}
                >
                  <label>
                    {{i18n (themePrefix "isbf_v2.account_username")}}
                    <input
                      autocomplete="username"
                      placeholder={{i18n
                        (themePrefix "isbf_v2.account_username_placeholder")
                      }}
                      required
                      type="text"
                      value={{this.requestedUsername}}
                      {{on "input" this.updateRequestedUsername}}
                    />
                  </label>
                  <button disabled={{this.isBusy}} type="submit">
                    {{i18n (themePrefix "isbf_v2.send_link_request")}}
                  </button>
                </form>
              {{/if}}
    
              {{#if this.errorMessage}}
                <p class="isbf-v2-account-menu__error" role="alert">
                  {{this.errorMessage}}
                </p>
              {{/if}}
            {{/if}}
    
            <button type="button" {{on "click" this.confirmLogout}}>
              {{i18n (themePrefix "isbf_v2.logout")}}
              @{{this.currentUser.username}}
            </button>
          </div>
        {{/if}}
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"currentUser\"]],[[[1,\"  \"],[11,0],[16,0,[52,[30,1],\"isbf-v2-account-menu isbf-v2-account-menu--mobile\",\"isbf-v2-account-menu isbf-v2-account-menu--side\"]],[4,[32,0],[\"focusin\",[30,0,[\"openMenu\"]]],null],[4,[32,0],[\"focusout\",[30,0,[\"onFocusOut\"]]],null],[4,[32,0],[\"mouseenter\",[30,0,[\"openMenu\"]]],null],[4,[32,0],[\"mouseleave\",[30,0,[\"onMouseLeave\"]]],null],[12],[1,\"\\n\"],[41,[51,[30,1]],[[[1,\"      \"],[11,3],[24,0,\"isbf-v2-side__account\"],[16,6,[30,0,[\"profileHref\"]]],[4,[32,0],[\"click\",[30,0,[\"closeMenu\"]]],null],[12],[1,\"\\n        \"],[10,1],[14,0,\"isbf-avatar\"],[12],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"40\"],[15,\"src\",[30,0,[\"avatarUrl\"]]],[14,\"width\",\"40\"],[12],[13],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,2],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n        \"],[10,1],[12],[1,\"\\n          \"],[10,\"b\"],[12],[1,[30,0,[\"displayName\"]]],[13],[1,\"\\n          \"],[10,\"small\"],[12],[1,\"@\"],[1,[30,0,[\"currentUser\",\"username\"]]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-expanded\",[52,[30,0,[\"isOpen\"]],\"true\",\"false\"]],[16,\"aria-label\",[28,[32,3],[[28,[32,4],[\"isbf_v2.account_actions\"],null]],null]],[24,0,\"isbf-v2-account-menu__trigger\"],[24,4,\"button\"],[4,[32,0],[\"click\",[30,0,[\"toggleMenu\"]]],null],[12],[1,\"\\n\"],[41,[51,[30,1]],[[[1,\"        \"],[10,1],[14,0,\"isbf-avatar isbf-v2-account-menu__compact-avatar\"],[12],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"40\"],[15,\"src\",[30,0,[\"avatarUrl\"]]],[14,\"width\",\"40\"],[12],[13],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,2],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[1,[28,[32,5],[\"ellipsis\"],null]],[1,\"\\n    \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"isOpen\"]],[[[1,\"      \"],[10,0],[15,\"aria-label\",[28,[32,3],[[28,[32,4],[\"isbf_v2.account_actions\"],null]],null]],[14,0,\"isbf-v2-account-menu__panel\"],[14,\"role\",\"group\"],[12],[1,\"\\n\"],[41,[51,[30,1]],[[[1,\"          \"],[11,3],[24,0,\"isbf-v2-account-menu__compact-profile\"],[16,6,[30,0,[\"profileHref\"]]],[4,[32,0],[\"click\",[30,0,[\"closeMenu\"]]],null],[12],[1,\"\\n            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.profile\"],null]],null]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[11,3],[24,6,\"/isbf-anonymous/posts\"],[4,[32,0],[\"click\",[30,0,[\"closeMenu\"]]],null],[12],[1,\"\\n          \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.my_anonymous_posts\"],null]],null]],[1,\"\\n        \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"canSwitchAccounts\"]],[[[41,[30,0,[\"showLinkedAccounts\"]],[[[42,[28,[31,3],[[28,[31,3],[[30,0,[\"activeLinks\"]]],null]],null],null,[[[1,\"              \"],[10,0],[14,0,\"isbf-v2-account-menu__linked-account\"],[12],[1,\"\\n                \"],[10,1],[14,0,\"isbf-avatar\"],[12],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"32\"],[15,\"src\",[30,2,[\"account\",\"avatar_template\"]]],[14,\"width\",\"32\"],[12],[13],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,2],null,[[\"user\",\"motion\"],[[30,2,[\"account\"]],\"static\"]]]]],null],[13],[1,\"\\n                \"],[10,1],[14,0,\"isbf-v2-account-menu__account-info\"],[12],[1,\"\\n                  \"],[10,\"b\"],[14,0,\"isbf-v2-account-menu__account-name\"],[12],[1,\"\\n                    \"],[1,[28,[32,6],[[30,2,[\"account\",\"name\"]],[30,2,[\"account\",\"username\"]]],null]],[1,\"\\n                  \"],[13],[1,\"\\n                  \"],[10,\"small\"],[14,0,\"isbf-v2-account-menu__account-username\"],[12],[1,\"\\n                    @\"],[1,[30,2,[\"account\",\"username\"]]],[1,\"\\n                  \"],[13],[1,\"\\n                \"],[13],[1,\"\\n\"],[41,[28,[32,7],[[30,2,[\"status\"]],\"approved\"],null],[[[1,\"                  \"],[11,\"button\"],[16,\"disabled\",[30,0,[\"isBusy\"]]],[24,4,\"button\"],[4,[32,0],[\"click\",[28,[32,8],[[30,0,[\"switchAccount\"]],[30,2]],null]],null],[12],[1,\"\\n                    \"],[1,[52,[30,2,[\"device_authorized\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.switch_now\"],null]],null],[28,[32,3],[[28,[32,4],[\"isbf_v2.verify_device\"],null]],null]]],[1,\"\\n                  \"],[13],[1,\"\\n\"]],[]],[[[1,\"                  \"],[10,\"small\"],[14,0,\"isbf-v2-account-menu__status\"],[12],[1,\"\\n                    \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.account_link_pending\"],null]],null]],[1,\"\\n                  \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[28,[32,7],[[30,0,[\"verificationLinkId\"]],[30,2,[\"id\"]]],null],[[[1,\"                  \"],[8,[32,9],[[24,0,\"isbf-v2-account-menu__verify\"]],[[\"@data\",\"@onSubmit\"],[[30,0,[\"verificationData\"]],[28,[32,8],[[30,0,[\"verifyAndSwitch\"]],[30,2]],null]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,2,[\"account\",\"email_code_enabled\"]],[[[1,\"                      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"isBusy\"]],\"verificationMethod\",[28,[32,3],[[28,[32,4],[\"isbf_v2.device_verification_method\"],null]],null],\"select\",\"required\"]],[[\"default\"],[[[[1,\"\\n                        \"],[8,[30,5,[\"Control\"]],null,[[\"@includeNone\"],[false]],[[\"default\"],[[[[1,\"\\n                          \"],[8,[30,6,[\"Option\"]],null,[[\"@value\"],[\"password\"]],[[\"default\"],[[[[1,\"\\n                            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.password_verification\"],null]],null]],[1,\"\\n                          \"]],[]]]]],[1,\"\\n                          \"],[8,[30,6,[\"Option\"]],null,[[\"@value\"],[\"email_code\"]],[[\"default\"],[[[[1,\"\\n                            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.email_code_verification\"],null]],null]],[1,\"\\n                          \"]],[]]]]],[1,\"\\n                        \"]],[6]]]]],[1,\"\\n                      \"]],[5]]]]],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,7],[[30,4,[\"verificationMethod\"]],\"email_code\"],null],[[[1,\"                      \"],[8,[32,10],[[24,0,\"isbf-v2-account-menu__send-code\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[28,[32,8],[[30,0,[\"sendEmailCode\"]],[30,2]],null],[30,0,[\"isBusy\"]],[52,[30,0,[\"emailCodeSent\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.resend_email_code\"],null]],null],[28,[32,3],[[28,[32,4],[\"isbf_v2.send_email_code\"],null]],null]]]],null],[1,\"\\n\"],[41,[30,0,[\"emailCodeSent\"]],[[[1,\"                        \"],[10,2],[14,0,\"isbf-v2-account-menu__code-status\"],[12],[1,\"\\n                          \"],[1,[30,0,[\"emailCodeSentMessage\"]]],[1,\"\\n                        \"],[13],[1,\"\\n\"]],[]],null],[1,\"                      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"isBusy\"]],\"emailCode\",[28,[32,3],[[28,[32,4],[\"isbf_v2.target_email_code\"],null]],null],\"input\",\"required|length:6,6\"]],[[\"default\"],[[[[1,\"\\n                        \"],[8,[30,7,[\"Control\"]],[[24,\"autocomplete\",\"one-time-code\"],[24,\"inputmode\",\"numeric\"],[24,\"maxlength\",\"6\"],[24,\"pattern\",\"[0-9]{6}\"]],null,null],[1,\"\\n                      \"]],[7]]]]],[1,\"\\n\"]],[]],[[[1,\"                      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"isBusy\"]],\"password\",[28,[32,3],[[28,[32,4],[\"isbf_v2.target_password\"],null]],null],\"input-password\",\"required\"]],[[\"default\"],[[[[1,\"\\n                        \"],[8,[30,8,[\"Control\"]],[[24,\"autocomplete\",\"current-password\"]],null,null],[1,\"\\n                      \"]],[8]]]]],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[28,[32,6],[[30,2,[\"account\",\"totp_enabled\"]],[30,2,[\"account\",\"backup_codes_enabled\"]]],null],[[[1,\"                      \"],[8,[30,3,[\"Field\"]],null,[[\"@description\",\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[28,[32,3],[[28,[32,4],[[52,[28,[32,7],[[30,4,[\"secondFactorMethod\"]],\"2\"],null],\"isbf_v2.backup_code_help\",\"isbf_v2.authenticator_code_help\"]],null]],null],[30,0,[\"isBusy\"]],\"secondFactorToken\",[28,[32,3],[[28,[32,4],[\"isbf_v2.second_factor_code\"],null]],null],\"input\",\"required\"]],[[\"default\"],[[[[1,\"\\n                        \"],[8,[30,9,[\"Control\"]],[[24,\"autocomplete\",\"one-time-code\"]],null,null],[1,\"\\n                      \"]],[9]]]]],[1,\"\\n\"]],[]],null],[41,[30,2,[\"account\",\"backup_codes_enabled\"]],[[[1,\"                      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"isBusy\"]],\"secondFactorMethod\",[28,[32,3],[[28,[32,4],[\"isbf_v2.second_factor_method\"],null]],null],\"select\",\"required\"]],[[\"default\"],[[[[1,\"\\n                        \"],[8,[30,10,[\"Control\"]],null,[[\"@includeNone\"],[false]],[[\"default\"],[[[[1,\"\\n                          \"],[8,[30,11,[\"Option\"]],null,[[\"@value\"],[\"1\"]],[[\"default\"],[[[[1,\"\\n                            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.authenticator_code\"],null]],null]],[1,\"\\n                          \"]],[]]]]],[1,\"\\n                          \"],[8,[30,11,[\"Option\"]],null,[[\"@value\"],[\"2\"]],[[\"default\"],[[[[1,\"\\n                            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.backup_code\"],null]],null]],[1,\"\\n                          \"]],[]]]]],[1,\"\\n                        \"]],[11]]]]],[1,\"\\n                      \"]],[10]]]]],[1,\"\\n\"]],[]],null],[1,\"                    \"],[8,[30,3,[\"Submit\"]],null,[[\"@disabled\",\"@label\"],[[30,0,[\"isBusy\"]],[28,[32,4],[\"isbf_v2.verify_and_switch\"],null]]],null],[1,\"\\n                  \"]],[3,4]]]]],[1,\"\\n\"]],[]],null],[1,\"              \"],[13],[1,\"\\n\"]],[2]],null]],[]],null],[1,\"\\n          \"],[11,\"button\"],[16,\"aria-expanded\",[52,[30,0,[\"canLinkAccounts\"]],[52,[30,0,[\"isLinkFormOpen\"]],\"true\",\"false\"],[52,[30,0,[\"isLinkedAccountsOpen\"]],\"true\",\"false\"]]],[24,0,\"isbf-v2-account-menu__link\"],[24,4,\"button\"],[4,[32,0],[\"click\",[30,0,[\"toggleLinkForm\"]]],null],[12],[1,\"\\n            \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.link_account\"],null]],null]],[1,\"\\n          \"],[13],[1,\"\\n\\n\"],[41,[28,[32,11],[[30,0,[\"canLinkAccounts\"]],[30,0,[\"isLinkFormOpen\"]]],null],[[[1,\"            \"],[11,\"form\"],[24,0,\"isbf-v2-account-menu__link-form\"],[4,[32,0],[\"submit\",[30,0,[\"createLink\"]]],null],[12],[1,\"\\n              \"],[10,\"label\"],[12],[1,\"\\n                \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.account_username\"],null]],null]],[1,\"\\n                \"],[11,\"input\"],[24,\"autocomplete\",\"username\"],[16,\"placeholder\",[28,[32,3],[[28,[32,4],[\"isbf_v2.account_username_placeholder\"],null]],null]],[24,\"required\",\"\"],[16,2,[30,0,[\"requestedUsername\"]]],[24,4,\"text\"],[4,[32,0],[\"input\",[30,0,[\"updateRequestedUsername\"]]],null],[12],[13],[1,\"\\n              \"],[13],[1,\"\\n              \"],[10,\"button\"],[15,\"disabled\",[30,0,[\"isBusy\"]]],[14,4,\"submit\"],[12],[1,\"\\n                \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.send_link_request\"],null]],null]],[1,\"\\n              \"],[13],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"errorMessage\"]],[[[1,\"            \"],[10,2],[14,0,\"isbf-v2-account-menu__error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n              \"],[1,[30,0,[\"errorMessage\"]]],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null]],[]],null],[1,\"\\n        \"],[11,\"button\"],[24,4,\"button\"],[4,[32,0],[\"click\",[30,0,[\"confirmLogout\"]]],null],[12],[1,\"\\n          \"],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.logout\"],null]],null]],[1,\"\\n          @\"],[1,[30,0,[\"currentUser\",\"username\"]]],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"@mobile\",\"link\",\"form\",\"draft\",\"field\",\"select\",\"field\",\"field\",\"field\",\"field\",\"select\"],[\"if\",\"unless\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        __keyword__on: on,
        PluginOutlet,
        lazyHash,
        i18n,
        themePrefix,
        dIcon,
        __keyword__or: or$1,
        __keyword__eq: eq$1,
        __keyword__fn: fn,
        Form,
        DButton,
        __keyword__and: and
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-account-menu", ISBFV2AccountMenu);
var Mod11 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2AccountMenu
});
class ISBFV2AnonymousPosts extends Component {
  static {
    dt7948.g(this.prototype, "posts", [tracked], function () {
      return [];
    });
  }
  #posts = (dt7948.i(this, "posts"), void 0);
  static {
    dt7948.g(this.prototype, "nextBeforeId", [tracked]);
  }
  #nextBeforeId = (dt7948.i(this, "nextBeforeId"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (dt7948.i(this, "loaded"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.loadMore);
  }
  get isEmpty() {
    return this.loaded && this.posts.length === 0;
  }
  get hasMore() {
    return Boolean(this.nextBeforeId);
  }
  async loadMore() {
    if (this.isDestroying || this.loading || this.loaded && !this.hasMore) {
      return;
    }
    this.loading = true;
    this.error = false;
    try {
      const response = await ajax("/isbf-anonymous/api/posts", {
        data: this.nextBeforeId ? {
          before_id: this.nextBeforeId
        } : {}
      });
      if (this.isDestroying) {
        return;
      }
      this.posts = [...this.posts, ...response.posts];
      this.nextBeforeId = response.next_before_id;
      this.loaded = true;
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadMore", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-v2-feature isbf-v2-anonymous-posts">
      <h1 class="sr-only">{{i18n
          (themePrefix "isbf_v2.my_anonymous_posts")
        }}</h1>
      {{#each this.posts as |post|}}
        <article class="isbf-v2-anonymous-posts__item">
          <a href={{post.url}}>{{post.title}}</a>
          <p>{{post.excerpt}}</p>
        </article>
      {{/each}}
      {{#if this.error}}
        <p role="alert">{{i18n
            (themePrefix "isbf_v2.anonymous_posts_load_error")
          }}</p>
      {{else if this.isEmpty}}
        <p>{{i18n (themePrefix "isbf_v2.anonymous_posts_empty")}}</p>
      {{/if}}
      {{#if this.hasMore}}
        <DButton
          class="isbf-v2-anonymous-posts__more"
          @action={{this.loadMore}}
          @isLoading={{this.loading}}
          @label={{themePrefix "isbf_v2.load_more"}}
        />
      {{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-v2-feature isbf-v2-anonymous-posts\"],[12],[1,\"\\n  \"],[10,\"h1\"],[14,0,\"sr-only\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.my_anonymous_posts\"],null]],null]],[13],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"posts\"]]],null]],null],null,[[[1,\"    \"],[10,\"article\"],[14,0,\"isbf-v2-anonymous-posts__item\"],[12],[1,\"\\n      \"],[10,3],[15,6,[30,1,[\"url\"]]],[12],[1,[30,1,[\"title\"]]],[13],[1,\"\\n      \"],[10,2],[12],[1,[30,1,[\"excerpt\"]]],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[1]],null],[41,[30,0,[\"error\"]],[[[1,\"    \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.anonymous_posts_load_error\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isEmpty\"]],[[[1,\"    \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.anonymous_posts_empty\"],null]],null]],[13],[1,\"\\n  \"]],[]],null]],[]]],[41,[30,0,[\"hasMore\"]],[[[1,\"    \"],[8,[32,2],[[24,0,\"isbf-v2-anonymous-posts__more\"]],[[\"@action\",\"@isLoading\",\"@label\"],[[30,0,[\"loadMore\"]],[30,0,[\"loading\"]],[28,[32,1],[\"isbf_v2.load_more\"],null]]],null],[1,\"\\n\"]],[]],null],[13]],[\"post\"],[\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-anonymous-posts", ISBFV2AnonymousPosts);
var Mod16 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2AnonymousPosts
});
class BrandImage extends Logo {
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <picture class="isbf-v2-brand__image" ...attributes>
      {{#if (and @darkUrl (notEq @url @darkUrl))}}
        <source media={{this.darkMediaQuery}} srcset={{getURL @darkUrl}} />
      {{/if}}
      <img alt="" class="isbf-v2-brand__logo" src={{getURL @url}} />
    </picture>
    */
    {
      "id": null,
      "block": "[[[11,\"picture\"],[24,0,\"isbf-v2-brand__image\"],[17,1],[12],[1,\"\\n\"],[41,[28,[32,0],[[30,2],[28,[32,1],[[30,3],[30,2]],null]],null],[[[1,\"    \"],[10,\"source\"],[15,\"media\",[30,0,[\"darkMediaQuery\"]]],[15,\"srcset\",[28,[32,2],[[30,2]],null]],[12],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[10,\"img\"],[14,\"alt\",\"\"],[14,0,\"isbf-v2-brand__logo\"],[15,\"src\",[28,[32,2],[[30,3]],null]],[12],[13],[1,\"\\n\"],[13]],[\"&attrs\",\"@darkUrl\",\"@url\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        and: and$1,
        notEq,
        getURL
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFV2Brand extends HomeLogo {
  static {
    dt7948.g(this.prototype, "capabilities", [service]);
  }
  #capabilities = (dt7948.i(this, "capabilities"), void 0);
  get isCompact() {
    return !this.args.mobile && (this.args.compact ?? !this.capabilities.viewport.lg);
  }
  get logoName() {
    if (this.args.mobile && this.mobileLogoUrl) {
      return "mobile_logo";
    }
    if (this.isCompact && this.logoSmallUrl) {
      return "logo_small";
    }
    return "logo";
  }
  get imageUrl() {
    return this.logoResolver(this.logoName);
  }
  get imageDarkUrl() {
    return this.logoResolver(this.logoName, {
      dark: this.darkModeAvailable
    });
  }
  get title() {
    return settings.brand_name || super.title;
  }
  get hasBrand() {
    return this.showLogo || this.showName;
  }
  get showLogo() {
    return settings.brand_show_logo && Boolean(this.imageUrl);
  }
  get showName() {
    return settings.brand_show_name;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.hasBrand}}
      <a
        aria-label={{this.title}}
        class={{dConcatClass "isbf-v2-brand" (if this.isCompact "--compact")}}
        href={{this.href}}
        ...attributes
        {{on "click" this.click}}
      >
        {{#if this.showLogo}}
          <BrandImage @darkUrl={{this.imageDarkUrl}} @url={{this.imageUrl}} />
        {{/if}}
        {{#if this.showName}}
          <span class="isbf-v2-brand__name">{{this.title}}</span>
        {{/if}}
      </a>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"hasBrand\"]],[[[1,\"  \"],[11,3],[16,\"aria-label\",[30,0,[\"title\"]]],[16,0,[28,[32,0],[\"isbf-v2-brand\",[52,[30,0,[\"isCompact\"]],\"--compact\"]],null]],[16,6,[30,0,[\"href\"]]],[17,1],[4,[32,1],[\"click\",[30,0,[\"click\"]]],null],[12],[1,\"\\n\"],[41,[30,0,[\"showLogo\"]],[[[1,\"      \"],[8,[32,2],null,[[\"@darkUrl\",\"@url\"],[[30,0,[\"imageDarkUrl\"]],[30,0,[\"imageUrl\"]]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"showName\"]],[[[1,\"      \"],[10,1],[14,0,\"isbf-v2-brand__name\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        on,
        BrandImage
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-brand", ISBFV2Brand);
var Mod91 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2Brand
});
class ISBFCalendarNoteEditor extends Component {
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  get formData() {
    return {
      note: this.args.model.entry.note || ""
    };
  }
  static {
    dt7948.n(this.prototype, "formData", [cached]);
  }
  async save(data) {
    this.error = false;
    try {
      const {
        entry
      } = await ajax(`/isbf/api/entries/${this.args.model.entry.id}.json`, {
        type: "PATCH",
        data: {
          entry: {
            note: data.note
          }
        }
      });
      this.args.model.onChanged(entry);
      this.args.closeModal();
    } catch {
      this.error = true;
    }
  }
  static {
    dt7948.n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-calendar-note-editor"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_edit_note")}}
    >
      <:body>
        <p>{{@model.entry.title}}</p>
        <Form @data={{this.formData}} @onSubmit={{this.save}} as |form|>
          <form.Field
            @name="note"
            @title={{i18n (themePrefix "isbf_v2.calendar_note")}}
            @type="textarea"
            as |field|
          >
            <field.Control maxlength="2000" rows="4" />
          </form.Field>
          {{#if this.error}}
            <p class="isbf-calendar-note-editor__error" role="alert">{{i18n
                (themePrefix "isbf_v2.schedule_note_error")
              }}</p>
          {{/if}}
          <form.Submit @label={{themePrefix "isbf_v2.calendar_save"}} />
        </Form>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-calendar-note-editor\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_edit_note\"],null]],null]]],[[\"body\"],[[[[1,\"\\n    \"],[10,2],[12],[1,[30,2,[\"entry\",\"title\"]]],[13],[1,\"\\n    \"],[8,[32,3],null,[[\"@data\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@name\",\"@title\",\"@type\"],[\"note\",[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_note\"],null]],null],\"textarea\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,4,[\"Control\"]],[[24,\"maxlength\",\"2000\"],[24,\"rows\",\"4\"]],null,null],[1,\"\\n      \"]],[4]]]]],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"        \"],[10,2],[14,0,\"isbf-calendar-note-editor__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_note_error\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[8,[30,3,[\"Submit\"]],null,[[\"@label\"],[[28,[32,2],[\"isbf_v2.calendar_save\"],null]]],null],[1,\"\\n    \"]],[3]]]]],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\",\"@model\",\"form\",\"field\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        Form
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-note-editor", ISBFCalendarNoteEditor);
var Mod62 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarNoteEditor
});
const PERSONAL_CALENDAR_FEED = "isbf_personal";
function calendarSubscriptionURL(url, origin, path) {
  if (!url) {
    return null;
  }
  try {
    const parsed = new URL(url);
    if (parsed.origin !== origin || parsed.protocol !== "https:" || parsed.pathname !== path || parsed.username || parsed.password || parsed.hash || !parsed.searchParams.get("user_api_key")) {
      return null;
    }
    return parsed.href;
  } catch {
    return null;
  }
}
function appleCalendarURL(url, origin, path) {
  return calendarSubscriptionURL(url, origin, path)?.replace(/^https:/, "webcal:") ?? null;
}
var Mod155 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  PERSONAL_CALENDAR_FEED: PERSONAL_CALENDAR_FEED,
  appleCalendarURL: appleCalendarURL,
  calendarSubscriptionURL: calendarSubscriptionURL
});
class ISBFCalendarProviderIcon extends Component {
  get isApple() {
    return this.args.provider === "apple";
  }
  get isGoogle() {
    return this.args.provider === "google";
  }
  get isOutlook() {
    return this.args.provider === "outlook";
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <svg
      aria-hidden="true"
      class="isbf-calendar-provider-icon"
      fill="none"
      focusable="false"
      height="20"
      viewBox="0 0 24 24"
      width="20"
    >
      {{#if this.isApple}}
        <path
          d="M17.05 12.54c.03 3.05 2.68 4.07 2.71 4.08-.02.07-.42 1.45-1.39 2.87-.84 1.23-1.71 2.45-3.08 2.48-1.34.03-1.78-.8-3.31-.8-1.54 0-2.02.77-3.29.83-1.32.05-2.33-1.33-3.18-2.56-1.73-2.5-3.05-7.07-1.28-10.15a4.94 4.94 0 0 1 4.18-2.54c1.31-.03 2.55.88 3.35.88.8 0 2.3-1.09 3.88-.93.66.03 2.5.27 3.68 2-.1.06-2.2 1.28-2.17 3.84ZM14.52 5.04c.7-.85 1.18-2.02 1.05-3.19-1.01.04-2.24.67-2.96 1.51-.65.75-1.22 1.95-1.07 3.09 1.13.09 2.28-.57 2.98-1.41Z"
          fill="currentColor"
        />
      {{else if this.isGoogle}}
        <path
          d="M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.6 4.6 0 0 1-2 3.02v2.51h3.25c1.9-1.75 2.97-4.33 2.97-7.36Z"
          fill="#4285f4"
        />
        <path
          d="M12 22c2.7 0 4.96-.9 6.62-2.41l-3.25-2.51c-.9.6-2.05.97-3.37.97-2.61 0-4.82-1.76-5.61-4.12H3.03v2.59A10 10 0 0 0 12 22Z"
          fill="#34a853"
        />
        <path
          d="M6.39 13.93a6.02 6.02 0 0 1 0-3.86V7.48H3.03a10 10 0 0 0 0 9.04l3.36-2.59Z"
          fill="#fbbc05"
        />
        <path
          d="M12 5.95c1.47 0 2.79.51 3.82 1.51l2.87-2.87A9.61 9.61 0 0 0 12 2a10 10 0 0 0-8.97 5.48l3.36 2.59C7.18 7.71 9.39 5.95 12 5.95Z"
          fill="#ea4335"
        />
      {{else if this.isOutlook}}
        <rect fill="#0078d4" height="17" rx="1.5" width="13" x="8" y="3" />
        <path d="M8 8h13v12H8Z" fill="#28a8ea" />
        <path
          d="m8 10 7 5 7-5v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1Z"
          fill="#1490df"
        />
        <path d="m8 10 7 5 7-5" stroke="#b3e1fa" stroke-width="1.2" />
        <rect fill="#0a5aa7" height="14" rx="1" width="12" x="1" y="6" />
        <path
          d="M7 9c-2.15 0-3.5 1.54-3.5 4s1.35 4 3.5 4 3.5-1.54 3.5-4S9.15 9 7 9Zm0 1.6c1.15 0 1.8.88 1.8 2.4s-.65 2.4-1.8 2.4-1.8-.88-1.8-2.4.65-2.4 1.8-2.4Z"
          fill="white"
          fill-rule="evenodd"
        />
      {{else}}
        <path
          d="m10 13 4-4m-6.5 2.5-2 2a4.24 4.24 0 0 0 6 6l2-2m-3-11 2-2a4.24 4.24 0 0 1 6 6l-2 2"
          stroke="currentColor"
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
        />
      {{/if}}
    </svg>
    */
    {
      "id": null,
      "block": "[[[10,\"svg\"],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-calendar-provider-icon\"],[14,\"fill\",\"none\"],[14,\"focusable\",\"false\"],[14,\"height\",\"20\"],[14,\"viewBox\",\"0 0 24 24\"],[14,\"width\",\"20\"],[12],[1,\"\\n\"],[41,[30,0,[\"isApple\"]],[[[1,\"    \"],[10,\"path\"],[14,\"d\",\"M17.05 12.54c.03 3.05 2.68 4.07 2.71 4.08-.02.07-.42 1.45-1.39 2.87-.84 1.23-1.71 2.45-3.08 2.48-1.34.03-1.78-.8-3.31-.8-1.54 0-2.02.77-3.29.83-1.32.05-2.33-1.33-3.18-2.56-1.73-2.5-3.05-7.07-1.28-10.15a4.94 4.94 0 0 1 4.18-2.54c1.31-.03 2.55.88 3.35.88.8 0 2.3-1.09 3.88-.93.66.03 2.5.27 3.68 2-.1.06-2.2 1.28-2.17 3.84ZM14.52 5.04c.7-.85 1.18-2.02 1.05-3.19-1.01.04-2.24.67-2.96 1.51-.65.75-1.22 1.95-1.07 3.09 1.13.09 2.28-.57 2.98-1.41Z\"],[14,\"fill\",\"currentColor\"],[12],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isGoogle\"]],[[[1,\"    \"],[10,\"path\"],[14,\"d\",\"M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.6 4.6 0 0 1-2 3.02v2.51h3.25c1.9-1.75 2.97-4.33 2.97-7.36Z\"],[14,\"fill\",\"#4285f4\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"M12 22c2.7 0 4.96-.9 6.62-2.41l-3.25-2.51c-.9.6-2.05.97-3.37.97-2.61 0-4.82-1.76-5.61-4.12H3.03v2.59A10 10 0 0 0 12 22Z\"],[14,\"fill\",\"#34a853\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"M6.39 13.93a6.02 6.02 0 0 1 0-3.86V7.48H3.03a10 10 0 0 0 0 9.04l3.36-2.59Z\"],[14,\"fill\",\"#fbbc05\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"M12 5.95c1.47 0 2.79.51 3.82 1.51l2.87-2.87A9.61 9.61 0 0 0 12 2a10 10 0 0 0-8.97 5.48l3.36 2.59C7.18 7.71 9.39 5.95 12 5.95Z\"],[14,\"fill\",\"#ea4335\"],[12],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isOutlook\"]],[[[1,\"    \"],[10,\"rect\"],[14,\"fill\",\"#0078d4\"],[14,\"height\",\"17\"],[14,\"rx\",\"1.5\"],[14,\"width\",\"13\"],[14,\"x\",\"8\"],[14,\"y\",\"3\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"M8 8h13v12H8Z\"],[14,\"fill\",\"#28a8ea\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"m8 10 7 5 7-5v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1Z\"],[14,\"fill\",\"#1490df\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"m8 10 7 5 7-5\"],[14,\"stroke\",\"#b3e1fa\"],[14,\"stroke-width\",\"1.2\"],[12],[13],[1,\"\\n    \"],[10,\"rect\"],[14,\"fill\",\"#0a5aa7\"],[14,\"height\",\"14\"],[14,\"rx\",\"1\"],[14,\"width\",\"12\"],[14,\"x\",\"1\"],[14,\"y\",\"6\"],[12],[13],[1,\"\\n    \"],[10,\"path\"],[14,\"d\",\"M7 9c-2.15 0-3.5 1.54-3.5 4s1.35 4 3.5 4 3.5-1.54 3.5-4S9.15 9 7 9Zm0 1.6c1.15 0 1.8.88 1.8 2.4s-.65 2.4-1.8 2.4-1.8-.88-1.8-2.4.65-2.4 1.8-2.4Z\"],[14,\"fill\",\"white\"],[14,\"fill-rule\",\"evenodd\"],[12],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,\"path\"],[14,\"d\",\"m10 13 4-4m-6.5 2.5-2 2a4.24 4.24 0 0 0 6 6l2-2m-3-11 2-2a4.24 4.24 0 0 1 6 6l-2 2\"],[14,\"stroke\",\"currentColor\"],[14,\"stroke-linecap\",\"round\"],[14,\"stroke-linejoin\",\"round\"],[14,\"stroke-width\",\"2\"],[12],[13],[1,\"\\n  \"]],[]]]],[]]]],[]]],[13]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-provider-icon", ISBFCalendarProviderIcon);
var Mod157 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarProviderIcon
});
class ISBFCalendarSubscription extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "copied", [tracked], function () {
      return false;
    });
  }
  #copied = (dt7948.i(this, "copied"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "hasSubscription", [tracked], function () {
      return false;
    });
  }
  #hasSubscription = (dt7948.i(this, "hasSubscription"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return true;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "ready", [tracked], function () {
      return false;
    });
  }
  #ready = (dt7948.i(this, "ready"), void 0);
  static {
    dt7948.g(this.prototype, "unavailable", [tracked], function () {
      return false;
    });
  }
  #unavailable = (dt7948.i(this, "unavailable"), void 0);
  static {
    dt7948.g(this.prototype, "url", [tracked], function () {
      return null;
    });
  }
  #url = (dt7948.i(this, "url"), void 0);
  #generation = 0;
  constructor() {
    super(...arguments);
    this.url = calendarSubscriptionURL(this.args.model.initialUrl, window.location.origin, getURL("/isbf/api/calendar.ics"));
    void this.load();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation++;
    this.url = null;
  }
  get provider() {
    const provider = this.args.model.provider;
    return ["apple", "google", "outlook", "link"].includes(provider) ? provider : "apple";
  }
  get isApple() {
    return this.provider === "apple";
  }
  get isGoogle() {
    return this.provider === "google";
  }
  get isOutlook() {
    return this.provider === "outlook";
  }
  get title() {
    return i18n(themePrefix(`isbf_v2.calendar_subscription_${this.provider}_title`));
  }
  get guide() {
    return i18n(themePrefix(`isbf_v2.calendar_subscription_${this.provider}_guide`));
  }
  get subscriptionURL() {
    if (!this.ready || !this.hasSubscription || this.unavailable || !this.#isCurrent()) {
      return null;
    }
    return calendarSubscriptionURL(this.url, window.location.origin, getURL("/isbf/api/calendar.ics"));
  }
  get webcalURL() {
    if (!this.isApple) {
      return null;
    }
    return appleCalendarURL(this.subscriptionURL, window.location.origin, getURL("/isbf/api/calendar.ics"));
  }
  async load() {
    if (this.loading && this.#generation > 0 || !this.#isCurrent()) {
      return;
    }
    const generation = ++this.#generation;
    this.loading = true;
    this.error = false;
    this.ready = false;
    try {
      const status = await ajax("/calendar-subscriptions.json");
      if (this.#isCurrent(generation)) {
        this.hasSubscription = status.has_subscription;
        this.unavailable = !status.feeds?.includes(PERSONAL_CALENDAR_FEED);
        if (!this.hasSubscription || this.unavailable || !status.generated_feeds?.includes(PERSONAL_CALENDAR_FEED)) {
          this.url = null;
          this.args.model.onURLChange?.(null);
        }
        this.ready = true;
      }
    } catch {
      if (this.#isCurrent(generation)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(generation)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "load", [action]);
  }
  async generate() {
    if (this.loading || !this.ready || this.unavailable || !this.#isCurrent()) {
      return;
    }
    this.loading = true;
    this.error = false;
    const generation = ++this.#generation;
    try {
      // Core regenerates one shared key for every calendar feed.
      if (this.hasSubscription && !(await this.dialog.confirm({
        message: i18n(themePrefix("isbf_v2.calendar_subscription_replace"))
      }))) {
        return;
      }
      if (!this.#isCurrent(generation)) {
        return;
      }
      const result = await ajax("/calendar-subscriptions.json", {
        type: "POST"
      });
      if (this.#isCurrent(generation)) {
        this.url = calendarSubscriptionURL(result.urls?.[PERSONAL_CALENDAR_FEED], window.location.origin, getURL("/isbf/api/calendar.ics"));
        this.hasSubscription = true;
        this.copied = false;
        this.error = !this.subscriptionURL;
        this.args.model.onURLChange?.(this.subscriptionURL);
      }
    } catch {
      if (this.#isCurrent(generation)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(generation)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "generate", [action]);
  }
  async copy() {
    const url = this.subscriptionURL;
    if (!url || this.loading || !this.#isCurrent()) {
      return;
    }
    const generation = this.#generation;
    this.copied = false;
    this.error = false;
    try {
      await clipboardCopy(url);
      if (this.#isCurrent(generation)) {
        this.copied = true;
      }
    } catch {
      if (this.#isCurrent(generation)) {
        this.error = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "copy", [action]);
  }
  async revoke() {
    if (this.loading || !this.hasSubscription || !this.#isCurrent()) {
      return;
    }
    this.loading = true;
    this.error = false;
    const generation = ++this.#generation;
    try {
      if (!(await this.dialog.confirm({
        message: i18n(themePrefix("isbf_v2.calendar_subscription_revoke_confirm"))
      })) || !this.#isCurrent(generation)) {
        return;
      }
      await ajax("/calendar-subscriptions.json", {
        type: "DELETE"
      });
      if (this.#isCurrent(generation)) {
        this.url = null;
        this.args.model.onURLChange?.(null);
        this.hasSubscription = false;
        this.copied = false;
      }
    } catch {
      if (this.#isCurrent(generation)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(generation)) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "revoke", [action]);
  }
  #isCurrent(generation = this.#generation) {
    return !this.isDestroying && generation === this.#generation && (this.args.model.isOwnerCurrent?.() ?? true) && this.currentUser?.id === this.args.model.userId;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-calendar-subscription"
      @closeModal={{@closeModal}}
      @title={{this.title}}
    >
      <:body>
        <p>{{i18n
            (themePrefix "isbf_v2.calendar_subscription_description")
          }}</p>
        <p class="isbf-calendar-subscription__note">{{i18n
            (themePrefix "isbf_v2.calendar_subscription_refresh")
          }}</p>
        <p class="isbf-calendar-subscription__guide">{{this.guide}}</p>
        {{#if this.isGoogle}}
          <a
            href="https://calendar.google.com/calendar/"
            rel="noopener noreferrer"
            target="_blank"
          >{{i18n
              (themePrefix "isbf_v2.calendar_subscription_open_google")
            }}</a>
        {{else if this.isOutlook}}
          <div class="isbf-calendar-subscription__actions">
            <a
              href="https://outlook.live.com/calendar/"
              rel="noopener noreferrer"
              target="_blank"
            >{{i18n
                (themePrefix
                  "isbf_v2.calendar_subscription_open_outlook_personal"
                )
              }}</a>
            <a
              href="https://outlook.office.com/calendar/"
              rel="noopener noreferrer"
              target="_blank"
            >{{i18n
                (themePrefix "isbf_v2.calendar_subscription_open_outlook_work")
              }}</a>
          </div>
        {{/if}}
        {{#if this.loading}}
          <p aria-live="polite" role="status">{{i18n
              (themePrefix "isbf_v2.calendar_subscription_loading")
            }}</p>
        {{/if}}
        {{#if this.unavailable}}
          <p role="status">{{i18n
              (themePrefix "isbf_v2.calendar_subscription_unavailable")
            }}</p>
        {{else if this.ready}}
          {{#if this.subscriptionURL}}
            <p>{{i18n
                (themePrefix "isbf_v2.calendar_subscription_private")
              }}</p>
            <label for="isbf-calendar-subscription-url">{{i18n
                (themePrefix "isbf_v2.calendar_subscription_url_label")
              }}</label>
            <input
              class="isbf-calendar-subscription__url"
              id="isbf-calendar-subscription-url"
              readonly
              type="text"
              value={{this.subscriptionURL}}
            />
            <div class="isbf-calendar-subscription__actions">
              {{#if this.isApple}}
                <a
                  class="btn btn-primary"
                  href={{this.webcalURL}}
                  rel="noreferrer"
                >{{dIcon "calendar-days"}}{{i18n
                    (themePrefix "isbf_v2.calendar_subscribe_apple")
                  }}</a>
              {{/if}}
              <DButton
                @action={{this.copy}}
                @disabled={{this.loading}}
                @icon={{if this.copied "check" "copy"}}
                @label={{themePrefix
                  (if
                    this.copied
                    "isbf_v2.calendar_subscription_copied"
                    "isbf_v2.calendar_subscription_copy"
                  )
                }}
              />
            </div>
          {{else}}
            {{#if this.hasSubscription}}
              <p>{{i18n
                  (themePrefix "isbf_v2.calendar_subscription_existing")
                }}</p>
            {{/if}}
            <DButton
              class="btn-primary"
              @action={{this.generate}}
              @disabled={{this.loading}}
              @icon="calendar-days"
              @label={{themePrefix
                (if
                  this.hasSubscription
                  "isbf_v2.calendar_subscription_regenerate"
                  "isbf_v2.calendar_subscription_generate"
                )
              }}
            />
          {{/if}}
          {{#if this.hasSubscription}}
            <DButton
              class="btn-flat isbf-calendar-subscription__revoke"
              @action={{this.revoke}}
              @disabled={{this.loading}}
              @label={{themePrefix "isbf_v2.calendar_subscription_revoke"}}
            />
          {{/if}}
        {{/if}}
        {{#if this.error}}
          <p class="isbf-calendar-subscription__error" role="alert">{{i18n
              (themePrefix "isbf_v2.calendar_subscription_error")
            }}</p>
          {{#unless this.ready}}
            <DButton
              @action={{this.load}}
              @disabled={{this.loading}}
              @label={{themePrefix "isbf_v2.official_retry"}}
            />
          {{/unless}}
        {{/if}}
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-calendar-subscription\"]],[[\"@closeModal\",\"@title\"],[[30,1],[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_description\"],null]],null]],[13],[1,\"\\n    \"],[10,2],[14,0,\"isbf-calendar-subscription__note\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_refresh\"],null]],null]],[13],[1,\"\\n    \"],[10,2],[14,0,\"isbf-calendar-subscription__guide\"],[12],[1,[30,0,[\"guide\"]]],[13],[1,\"\\n\"],[41,[30,0,[\"isGoogle\"]],[[[1,\"      \"],[10,3],[14,6,\"https://calendar.google.com/calendar/\"],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_open_google\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"isOutlook\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-calendar-subscription__actions\"],[12],[1,\"\\n        \"],[10,3],[14,6,\"https://outlook.live.com/calendar/\"],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_open_outlook_personal\"],null]],null]],[13],[1,\"\\n        \"],[10,3],[14,6,\"https://outlook.office.com/calendar/\"],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_open_outlook_work\"],null]],null]],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"]],[]],null]],[]]],[41,[30,0,[\"loading\"]],[[[1,\"      \"],[10,2],[14,\"aria-live\",\"polite\"],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_loading\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"unavailable\"]],[[[1,\"      \"],[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_unavailable\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"ready\"]],[[[41,[30,0,[\"subscriptionURL\"]],[[[1,\"        \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_private\"],null]],null]],[13],[1,\"\\n        \"],[10,\"label\"],[14,\"for\",\"isbf-calendar-subscription-url\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_url_label\"],null]],null]],[13],[1,\"\\n        \"],[10,\"input\"],[14,0,\"isbf-calendar-subscription__url\"],[14,1,\"isbf-calendar-subscription-url\"],[14,\"readonly\",\"\"],[15,2,[30,0,[\"subscriptionURL\"]]],[14,4,\"text\"],[12],[13],[1,\"\\n        \"],[10,0],[14,0,\"isbf-calendar-subscription__actions\"],[12],[1,\"\\n\"],[41,[30,0,[\"isApple\"]],[[[1,\"            \"],[10,3],[14,0,\"btn btn-primary\"],[15,6,[30,0,[\"webcalURL\"]]],[14,\"rel\",\"noreferrer\"],[12],[1,[28,[32,3],[\"calendar-days\"],null]],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscribe_apple\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"copy\"]],[30,0,[\"loading\"]],[52,[30,0,[\"copied\"]],\"check\",\"copy\"],[28,[32,2],[[52,[30,0,[\"copied\"]],\"isbf_v2.calendar_subscription_copied\",\"isbf_v2.calendar_subscription_copy\"]],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"hasSubscription\"]],[[[1,\"          \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_existing\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[8,[32,4],[[24,0,\"btn-primary\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@label\"],[[30,0,[\"generate\"]],[30,0,[\"loading\"]],\"calendar-days\",[28,[32,2],[[52,[30,0,[\"hasSubscription\"]],\"isbf_v2.calendar_subscription_regenerate\",\"isbf_v2.calendar_subscription_generate\"]],null]]],null],[1,\"\\n\"]],[]]],[41,[30,0,[\"hasSubscription\"]],[[[1,\"        \"],[8,[32,4],[[24,0,\"btn-flat isbf-calendar-subscription__revoke\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"revoke\"]],[30,0,[\"loading\"]],[28,[32,2],[\"isbf_v2.calendar_subscription_revoke\"],null]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"]],[]],null]],[]]],[41,[30,0,[\"error\"]],[[[1,\"      \"],[10,2],[14,0,\"isbf-calendar-subscription__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_error\"],null]],null]],[13],[1,\"\\n\"],[41,[51,[30,0,[\"ready\"]]],[[[1,\"        \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"load\"]],[30,0,[\"loading\"]],[28,[32,2],[\"isbf_v2.official_retry\"],null]]],null],[1,\"\\n\"]],[]],null]],[]],null],[1,\"  \"]],[]]]]]],[\"@closeModal\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        dIcon,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-subscription", ISBFCalendarSubscription);
var Mod153 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarSubscription
});
class ISBFCalendarSubscribe extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "opensUp", [tracked], function () {
      return false;
    });
  }
  #opensUp = (dt7948.i(this, "opensUp"), void 0);
  #cachedURL = null;
  #dialogModel = null;
  #opening = false;
  #ownerId = null;
  willDestroy() {
    this.#cachedURL = null;
    this.#ownerId = null;
    if (this.#dialogModel && this.modal.activeModal?.opts?.model === this.#dialogModel) {
      this.modal.close();
    }
    this.#dialogModel = null;
    super.willDestroy(...arguments);
  }
  get available() {
    this.#synchronizeOwner();
    return this.currentUser && this.site.isbf_calendar?.subscription_feed === PERSONAL_CALENDAR_FEED;
  }
  get providers() {
    return ["apple", "google", "outlook", "link"].map(id => ({
      id,
      label: i18n(themePrefix(`isbf_v2.calendar_subscription_${id}`))
    }));
  }
  registerMenu(menu) {
    // DMenu's argument allowlist omits this native positioning option.
    menu.options.allowedPlacements = ["top-end", "bottom-end"];
    Object.defineProperty(menu.options, "padding", {
      configurable: true,
      get: () => {
        const viewport = window.visualViewport;
        const viewportBottom = viewport ? viewport.offsetTop + viewport.height : window.innerHeight;
        const navigation = document.querySelector(".isbf-v2-mobile-nav")?.getBoundingClientRect();
        return {
          top: Math.max(12, headerOffset()),
          right: 12,
          bottom: Math.max(12, navigation?.width > 0 && navigation.height > 0 ? viewportBottom - navigation.top + 12 : 12),
          left: 12
        };
      }
    });
  }
  static {
    dt7948.n(this.prototype, "registerMenu", [action]);
  }
  positioned(content) {
    if (!this.isDestroying) {
      this.opensUp = content.dataset.placement.startsWith("top");
    }
  }
  static {
    dt7948.n(this.prototype, "positioned", [action]);
  }
  async open(provider, menu) {
    if (!this.available || this.#opening || !this.providers.some(item => item.id === provider)) {
      return;
    }
    const userId = this.#synchronizeOwner();
    this.#opening = true;
    try {
      await menu.close();
      if (this.isDestroying || !this.available || this.#synchronizeOwner() !== userId) {
        return;
      }
      this.#dialogModel = {
        userId,
        provider,
        initialUrl: this.#cachedURL,
        isOwnerCurrent: () => !this.isDestroying && this.#synchronizeOwner() === userId,
        onURLChange: url => this.#rememberURL(userId, url)
      };
      this.modal.show(ISBFCalendarSubscription, {
        model: this.#dialogModel
      });
    } finally {
      this.#opening = false;
    }
  }
  static {
    dt7948.n(this.prototype, "open", [action]);
  }
  #rememberURL(userId, url) {
    if (this.isDestroying || this.#synchronizeOwner() !== userId) {
      return;
    }
    this.#cachedURL = calendarSubscriptionURL(url, window.location.origin, getURL("/isbf/api/calendar.ics"));
  }
  #synchronizeOwner() {
    const userId = this.currentUser?.id ?? null;
    if (userId !== this.#ownerId) {
      this.#cachedURL = null;
      this.#ownerId = userId;
    }
    return userId;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.available}}
      <DMenu
        @ariaLabel={{i18n (themePrefix "isbf_v2.calendar_subscribe")}}
        @contentClass="isbf-calendar-subscription-menu"
        @identifier="isbf-calendar-subscription"
        @matchTriggerWidth={{true}}
        @maxWidth="none"
        @modalForMobile={{false}}
        @onPositioned={{this.positioned}}
        @onRegisterApi={{this.registerMenu}}
        @placement="bottom-end"
        @triggerClass="btn-default isbf-calendar-subscribe"
        @visibilityOptimizer="autoPlacement"
      >
        <:trigger as |menu|>
          {{dIcon "calendar-days"}}
          <span>{{i18n (themePrefix "isbf_v2.calendar_subscribe")}}</span>
          {{dIcon
            (if
              menu.expanded
              (if this.opensUp "chevron-up" "chevron-down")
              "chevron-down"
            )
          }}
        </:trigger>
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each this.providers key="id" as |provider|}}
              <dropdown.item>
                <DButton
                  class="btn-flat isbf-calendar-subscription-menu__item"
                  @action={{fn this.open provider.id menu}}
                >
                  <ISBFCalendarProviderIcon @provider={{provider.id}} />
                  <span>{{provider.label}}</span>
                </DButton>
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"available\"]],[[[1,\"  \"],[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@identifier\",\"@matchTriggerWidth\",\"@maxWidth\",\"@modalForMobile\",\"@onPositioned\",\"@onRegisterApi\",\"@placement\",\"@triggerClass\",\"@visibilityOptimizer\"],[[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscribe\"],null]],null],\"isbf-calendar-subscription-menu\",\"isbf-calendar-subscription\",true,\"none\",false,[30,0,[\"positioned\"]],[30,0,[\"registerMenu\"]],\"bottom-end\",\"btn-default isbf-calendar-subscribe\",\"autoPlacement\"]],[[\"trigger\",\"content\"],[[[[1,\"\\n      \"],[1,[28,[32,3],[\"calendar-days\"],null]],[1,\"\\n      \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscribe\"],null]],null]],[13],[1,\"\\n      \"],[1,[28,[32,3],[[52,[30,1,[\"expanded\"]],[52,[30,0,[\"opensUp\"]],\"chevron-up\",\"chevron-down\"],\"chevron-down\"]],null]],[1,\"\\n    \"]],[1]],[[[1,\"\\n      \"],[8,[32,4],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"providers\"]]],null]],null],\"id\",[[[1,\"          \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,5],[[24,0,\"btn-flat isbf-calendar-subscription-menu__item\"]],[[\"@action\"],[[28,[32,6],[[30,0,[\"open\"]],[30,4,[\"id\"]],[30,2]],null]]],[[\"default\"],[[[[1,\"\\n              \"],[8,[32,7],null,[[\"@provider\"],[[30,4,[\"id\"]]]],null],[1,\"\\n              \"],[10,1],[12],[1,[30,4,[\"label\"]]],[13],[1,\"\\n            \"]],[]]]]],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[4]],null],[1,\"      \"]],[3]]]]],[1,\"\\n    \"]],[2]]]]],[1,\"\\n\"]],[]],null]],[\"menu\",\"menu\",\"dropdown\",\"provider\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        themePrefix,
        dIcon,
        DDropdownMenu,
        DButton,
        fn,
        ISBFCalendarProviderIcon
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-subscribe", ISBFCalendarSubscribe);
var Mod152 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarSubscribe
});
class ISBFCalendarUpdateDialog extends Component {
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "isSaving", [tracked], function () {
      return false;
    });
  }
  #isSaving = (dt7948.i(this, "isSaving"), void 0);
  static {
    dt7948.g(this.prototype, "versionChanged", [tracked], function () {
      return false;
    });
  }
  #versionChanged = (dt7948.i(this, "versionChanged"), void 0);
  static {
    dt7948.g(this.prototype, "_refreshedEntry", [tracked], function () {
      return null;
    });
  }
  #_refreshedEntry = (dt7948.i(this, "_refreshedEntry"), void 0);
  get entry() {
    return this._refreshedEntry ?? this.args.model.entry;
  }
  get currentTime() {
    return officialTimeLabel(this.entry);
  }
  get latestTime() {
    return officialTimeLabel(this.entry.latest_source);
  }
  get canAccept() {
    return this.entry.needs_update && !this.entry.cancelled && !this.entry.source_unavailable;
  }
  accept() {
    return this.#respond(true);
  }
  static {
    dt7948.n(this.prototype, "accept", [action]);
  }
  dismiss() {
    return this.#respond(false);
  }
  static {
    dt7948.n(this.prototype, "dismiss", [action]);
  }
  async remove() {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      if (await this.args.model.onRemove(this.entry)) {
        this.args.closeModal();
      }
    } finally {
      if (!this.isDestroying) {
        this.isSaving = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "remove", [action]);
  }
  async #respond(accept) {
    if (this.isSaving || !this.entry.latest_source) {
      return;
    }
    this.isSaving = true;
    this.error = false;
    this.versionChanged = false;
    try {
      const response = await ajax(`/isbf/api/entries/${this.entry.id}/${accept ? "accept-update" : "dismiss-update"}.json`, {
        type: "POST",
        data: {
          revision: this.entry.latest_source.revision
        }
      });
      this.args.model.onChanged(response?.entry || this.entry, accept);
      this.args.closeModal();
    } catch (error) {
      if (error.jqXHR?.status === 409) {
        try {
          const {
            entry
          } = await ajax(`/isbf/api/entries/${this.entry.id}.json`);
          if (!this.isDestroying) {
            this._refreshedEntry = entry;
            this.versionChanged = true;
            this.args.model.onChanged(entry);
          }
        } catch {
          this.error = true;
        }
      } else {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.isSaving = false;
      }
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-calendar-update-dialog"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_review")}}
    >
      <:body>
        <div class="isbf-calendar-update-dialog__snapshot">
          <h3>{{i18n (themePrefix "isbf_v2.schedule_current")}}</h3>
          <strong>{{this.entry.title}}</strong>
          <p>{{this.currentTime}}</p>
          {{#if this.entry.note}}<p>{{this.entry.note}}</p>{{/if}}
        </div>
        <div class="isbf-calendar-update-dialog__latest">
          <h3>{{i18n (themePrefix "isbf_v2.schedule_latest")}}</h3>
          {{#if this.entry.cancelled}}
            <p>{{i18n (themePrefix "isbf_v2.schedule_cancelled_hint")}}</p>
          {{else if this.entry.source_unavailable}}
            <p>{{i18n (themePrefix "isbf_v2.schedule_unavailable")}}</p>
          {{else}}
            <strong>{{this.entry.latest_source.title}}</strong>
            <p>{{this.latestTime}}</p>
          {{/if}}
          {{#if this.entry.source_url}}<a href={{this.entry.source_url}}>{{i18n
                (themePrefix "isbf_v2.schedule_source")
              }}</a>{{/if}}
        </div>
        {{#if this.versionChanged}}<p role="status">{{i18n
              (themePrefix "isbf_v2.schedule_version_changed")
            }}</p>{{/if}}
        {{#if this.error}}<p
            class="isbf-calendar-update-dialog__error"
            role="alert"
          >{{i18n (themePrefix "isbf_v2.schedule_update_error")}}</p>{{/if}}
      </:body>
      <:footer>
        {{#if this.canAccept}}<DButton
            class="btn-primary isbf-calendar-update-dialog__accept"
            @action={{this.accept}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.schedule_accept"}}
          />{{/if}}
        {{#if this.entry.needs_update}}<DButton
            class="isbf-calendar-update-dialog__dismiss"
            @action={{this.dismiss}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.schedule_keep"}}
          />{{/if}}
        {{#if this.entry.cancelled}}<DButton
            class="btn-danger isbf-calendar-update-dialog__remove"
            @action={{this.remove}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.calendar_delete"}}
          />{{/if}}
      </:footer>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-calendar-update-dialog\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_review\"],null]],null]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[10,0],[14,0,\"isbf-calendar-update-dialog__snapshot\"],[12],[1,\"\\n      \"],[10,\"h3\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_current\"],null]],null]],[13],[1,\"\\n      \"],[10,\"strong\"],[12],[1,[30,0,[\"entry\",\"title\"]]],[13],[1,\"\\n      \"],[10,2],[12],[1,[30,0,[\"currentTime\"]]],[13],[1,\"\\n      \"],[41,[30,0,[\"entry\",\"note\"]],[[[10,2],[12],[1,[30,0,[\"entry\",\"note\"]]],[13]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[10,0],[14,0,\"isbf-calendar-update-dialog__latest\"],[12],[1,\"\\n      \"],[10,\"h3\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_latest\"],null]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"entry\",\"cancelled\"]],[[[1,\"        \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_cancelled_hint\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"entry\",\"source_unavailable\"]],[[[1,\"        \"],[10,2],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_unavailable\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"strong\"],[12],[1,[30,0,[\"entry\",\"latest_source\",\"title\"]]],[13],[1,\"\\n        \"],[10,2],[12],[1,[30,0,[\"latestTime\"]]],[13],[1,\"\\n      \"]],[]]]],[]]],[1,\"      \"],[41,[30,0,[\"entry\",\"source_url\"]],[[[10,3],[15,6,[30,0,[\"entry\",\"source_url\"]]],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_source\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[41,[30,0,[\"versionChanged\"]],[[[10,2],[14,\"role\",\"status\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_version_changed\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"error\"]],[[[10,2],[14,0,\"isbf-calendar-update-dialog__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.schedule_update_error\"],null]],null]],[13]],[]],null],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[41,[30,0,[\"canAccept\"]],[[[8,[32,3],[[24,0,\"btn-primary isbf-calendar-update-dialog__accept\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"accept\"]],[30,0,[\"isSaving\"]],[28,[32,2],[\"isbf_v2.schedule_accept\"],null]]],null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"entry\",\"needs_update\"]],[[[8,[32,3],[[24,0,\"isbf-calendar-update-dialog__dismiss\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"dismiss\"]],[30,0,[\"isSaving\"]],[28,[32,2],[\"isbf_v2.schedule_keep\"],null]]],null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"entry\",\"cancelled\"]],[[[8,[32,3],[[24,0,\"btn-danger isbf-calendar-update-dialog__remove\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"remove\"]],[30,0,[\"isSaving\"]],[28,[32,2],[\"isbf_v2.calendar_delete\"],null]]],null]],[]],null],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        i18n,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-update-dialog", ISBFCalendarUpdateDialog);
var Mod63 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarUpdateDialog
});
const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
function dateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
function localDate(key) {
  return new Date(`${key}T12:00:00`);
}
function displayTime(value, allDay) {
  return allDay ? i18n(themePrefix("isbf_v2.calendar_all_day")) : new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(value));
}
class ISBFV2Calendar extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "visibleMonth", [tracked]);
  }
  #visibleMonth = (dt7948.i(this, "visibleMonth"), void 0);
  static {
    dt7948.g(this.prototype, "selectedDate", [tracked]);
  }
  #selectedDate = (dt7948.i(this, "selectedDate"), void 0);
  static {
    dt7948.g(this.prototype, "filter", [tracked], function () {
      return "all";
    });
  }
  #filter = (dt7948.i(this, "filter"), void 0);
  static {
    dt7948.g(this.prototype, "personalEntries", [tracked], function () {
      return [];
    });
  }
  #personalEntries = (dt7948.i(this, "personalEntries"), void 0);
  static {
    dt7948.g(this.prototype, "communityEvents", [tracked], function () {
      return [];
    });
  }
  #communityEvents = (dt7948.i(this, "communityEvents"), void 0);
  static {
    dt7948.g(this.prototype, "pendingUpdates", [tracked], function () {
      return [];
    });
  }
  #pendingUpdates = (dt7948.i(this, "pendingUpdates"), void 0);
  static {
    dt7948.g(this.prototype, "updatesError", [tracked], function () {
      return false;
    });
  }
  #updatesError = (dt7948.i(this, "updatesError"), void 0);
  static {
    dt7948.g(this.prototype, "focusedEntryId", [tracked], function () {
      return null;
    });
  }
  #focusedEntryId = (dt7948.i(this, "focusedEntryId"), void 0);
  static {
    dt7948.g(this.prototype, "isLoading", [tracked], function () {
      return false;
    });
  }
  #isLoading = (dt7948.i(this, "isLoading"), void 0);
  static {
    dt7948.g(this.prototype, "loadError", [tracked], function () {
      return false;
    });
  }
  #loadError = (dt7948.i(this, "loadError"), void 0);
  static {
    dt7948.g(this.prototype, "isEditing", [tracked], function () {
      return false;
    });
  }
  #isEditing = (dt7948.i(this, "isEditing"), void 0);
  static {
    dt7948.g(this.prototype, "editingId", [tracked], function () {
      return null;
    });
  }
  #editingId = (dt7948.i(this, "editingId"), void 0);
  static {
    dt7948.g(this.prototype, "title", [tracked], function () {
      return "";
    });
  }
  #title = (dt7948.i(this, "title"), void 0);
  static {
    dt7948.g(this.prototype, "note", [tracked], function () {
      return "";
    });
  }
  #note = (dt7948.i(this, "note"), void 0);
  static {
    dt7948.g(this.prototype, "startInput", [tracked], function () {
      return "";
    });
  }
  #startInput = (dt7948.i(this, "startInput"), void 0);
  static {
    dt7948.g(this.prototype, "endInput", [tracked], function () {
      return "";
    });
  }
  #endInput = (dt7948.i(this, "endInput"), void 0);
  static {
    dt7948.g(this.prototype, "allDay", [tracked], function () {
      return false;
    });
  }
  #allDay = (dt7948.i(this, "allDay"), void 0);
  static {
    dt7948.g(this.prototype, "saveError", [tracked], function () {
      return false;
    });
  }
  #saveError = (dt7948.i(this, "saveError"), void 0);
  weekdays = WEEKDAYS.map(day => i18n(themePrefix(`isbf_v2.week_${day}`)));
  #requestNumber = 0;
  #updatesRequestNumber = 0;
  #focusRequestNumber = 0;
  #queryEntryId;
  constructor() {
    super(...arguments);
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    this.appEvents.on("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.on("routeDidChange", this.focusFromRoute);
    void this.reloadEntries();
    void this.focusFromRoute();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.off("routeDidChange", this.focusFromRoute);
  }
  get monthLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      year: "numeric",
      month: "long"
    }).format(this.visibleMonth);
  }
  get selectedLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      month: "long",
      day: "numeric",
      weekday: "long"
    }).format(localDate(this.selectedDate));
  }
  get canCreateCommunity() {
    return Boolean((this.currentUser?.admin || this.currentUser?.academy_moderator_permissions?.publish_activities) && this.currentUser?.can_create_discourse_post_event && Number(settings.calendar_category_id) > 0);
  }
  get communityComposeHref() {
    const slug = settings.calendar_category_path.split("/").filter(Boolean)[1];
    return `/new-topic?category=${encodeURIComponent(slug || "campus-events")}`;
  }
  get monthCells() {
    const first = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const cells = [];
    for (let index = 0; index < 42; index++) {
      const date = new Date(first.getFullYear(), first.getMonth(), index + 1 - offset);
      const key = dateKey(date);
      cells.push({
        day: date.getDate(),
        key,
        inMonth: date.getMonth() === first.getMonth(),
        isSelected: key === this.selectedDate,
        isToday: key === dateKey(new Date()),
        hasPersonal: this.personalEntries.some(entry => this.#occursOn(entry, key)),
        hasCommunity: this.communityEvents.some(event => this.#occursOn(event, key))
      });
    }
    return cells;
  }
  get selectedItems() {
    const entries = this.filter === "community" ? [] : this.personalEntries;
    const events = this.filter === "personal" ? [] : this.communityEvents;
    return [...entries, ...events].filter(item => this.#occursOn(item, this.selectedDate)).sort((a, b) => a.starts_at.localeCompare(b.starts_at)).map(item => ({
      ...item,
      isFocused: item.id === this.focusedEntryId && item.kind === "personal"
    }));
  }
  get updatesLabel() {
    return i18n(themePrefix("isbf_v2.schedule_pending_count"), {
      count: this.pendingUpdates.length
    });
  }
  reloadEntries() {
    return Promise.all([this.loadMonth(), this.loadUpdates()]);
  }
  static {
    dt7948.n(this.prototype, "reloadEntries", [action]);
  }
  async loadUpdates() {
    const request = ++this.#updatesRequestNumber;
    if (!this.currentUser) {
      return;
    }
    try {
      const {
        entries
      } = await ajax("/isbf/api/entry-updates.json");
      if (request === this.#updatesRequestNumber && !this.isDestroying) {
        this.pendingUpdates = entries;
        this.updatesError = false;
      }
    } catch {
      if (request === this.#updatesRequestNumber && !this.isDestroying) {
        this.updatesError = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadUpdates", [action]);
  }
  async focusFromRoute() {
    const id = new URLSearchParams(this.router.currentURL?.split("?")[1]).get("entry_id");
    if (!id || !/^\d+$/.test(id) || Number(id) <= 0 || id === this.#queryEntryId || !this.currentUser) {
      return;
    }
    this.#queryEntryId = id;
    const request = ++this.#focusRequestNumber;
    try {
      const {
        entry
      } = await ajax(`/isbf/api/entries/${id}.json`);
      if (request !== this.#focusRequestNumber || this.isDestroying) {
        return;
      }
      this.#selectEntry(entry);
      await this.loadMonth();
      scheduleOnce("afterRender", this, this.#focusEntry);
      if (entry.needs_update) {
        this.reviewUpdate(entry);
      }
    } catch {
      if (!this.isDestroying) {
        this.loadError = true;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "focusFromRoute", [action]);
  }
  entryUpdated(entry, accepted = false) {
    if (accepted) {
      this.#selectEntry(entry);
    }
    this.appEvents.trigger("isbf:calendar-entry-changed", entry);
  }
  static {
    dt7948.n(this.prototype, "entryUpdated", [action]);
  }
  reviewUpdate(entry) {
    this.modal.show(ISBFCalendarUpdateDialog, {
      model: {
        entry,
        onChanged: this.entryUpdated,
        onRemove: this.deleteEntry
      }
    });
  }
  static {
    dt7948.n(this.prototype, "reviewUpdate", [action]);
  }
  async loadMonth() {
    const request = ++this.#requestNumber;
    const first = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const from = new Date(first.getFullYear(), first.getMonth(), 1 - offset);
    const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + 42);
    const data = {
      from: from.toISOString(),
      to: to.toISOString()
    };
    const personalData = {
      from: new Date(from.getTime() - 86400000).toISOString(),
      to: new Date(to.getTime() + 86400000).toISOString()
    };
    this.isLoading = true;
    this.loadError = false;
    const [personal, community] = await Promise.allSettled([this.currentUser ? ajax("/isbf/api/entries.json", {
      data: personalData
    }) : Promise.resolve({
      entries: []
    }), Number(settings.calendar_category_id) > 0 ? ajax("/discourse-post-event/events.json", {
      data: {
        after: data.from,
        before: data.to,
        category_id: settings.calendar_category_id,
        limit: 200
      }
    }) : Promise.resolve({
      events: []
    })]);
    if (request !== this.#requestNumber || this.isDestroying) {
      return;
    }
    this.personalEntries = personal.status === "fulfilled" ? personal.value.entries.map(entry => ({
      ...entry,
      kind: "personal"
    })) : [];
    this.communityEvents = community.status === "fulfilled" ? community.value.events.flatMap(event => (event.occurrences || []).map(occurrence => {
      const end = occurrence.ends_at || (event.all_day ? occurrence.starts_at : new Date(new Date(occurrence.starts_at).getTime() + 3600000).toISOString());
      return {
        id: event.id,
        title: event.name || event.post?.topic?.title,
        starts_at: occurrence.starts_at,
        ends_at: event.all_day ? new Date(new Date(`${end.slice(0, 10)}T00:00:00.000Z`).getTime() + 86400000).toISOString() : end,
        all_day: event.all_day,
        href: event.post?.url,
        kind: "community"
      };
    })) : [];
    this.loadError = personal.status === "rejected" || community.status === "rejected";
    this.isLoading = false;
  }
  static {
    dt7948.n(this.prototype, "loadMonth", [action]);
  }
  previousMonth() {
    this.#changeMonth(-1);
  }
  static {
    dt7948.n(this.prototype, "previousMonth", [action]);
  }
  nextMonth() {
    this.#changeMonth(1);
  }
  static {
    dt7948.n(this.prototype, "nextMonth", [action]);
  }
  goToday() {
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    void this.loadMonth();
  }
  static {
    dt7948.n(this.prototype, "goToday", [action]);
  }
  selectDate(key) {
    this.selectedDate = key;
    const date = localDate(key);
    if (date.getMonth() !== this.visibleMonth.getMonth() || date.getFullYear() !== this.visibleMonth.getFullYear()) {
      this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
      void this.loadMonth();
    }
  }
  static {
    dt7948.n(this.prototype, "selectDate", [action]);
  }
  setFilter(filter) {
    this.filter = filter;
  }
  static {
    dt7948.n(this.prototype, "setFilter", [action]);
  }
  newEntry() {
    this.editingId = null;
    this.title = "";
    this.note = "";
    this.startInput = `${this.selectedDate}T09:00`;
    this.endInput = `${this.selectedDate}T10:00`;
    this.allDay = false;
    this.saveError = false;
    this.isEditing = true;
    scheduleOnce("afterRender", this, this.#focusEditor);
  }
  static {
    dt7948.n(this.prototype, "newEntry", [action]);
  }
  editEntry(entry) {
    if (entry.source_item_id) {
      this.modal.show(ISBFCalendarNoteEditor, {
        model: {
          entry,
          onChanged: this.entryUpdated
        }
      });
      return;
    }
    this.editingId = entry.id;
    this.title = entry.title;
    this.note = entry.note || "";
    this.allDay = entry.all_day;
    this.startInput = entry.all_day ? entry.starts_at.slice(0, 10) : this.#localInput(entry.starts_at);
    this.endInput = entry.all_day ? new Date(new Date(entry.ends_at).getTime() - 86400000).toISOString().slice(0, 10) : this.#localInput(entry.ends_at);
    this.saveError = false;
    this.isEditing = true;
    scheduleOnce("afterRender", this, this.#focusEditor);
  }
  static {
    dt7948.n(this.prototype, "editEntry", [action]);
  }
  closeEditor() {
    this.isEditing = false;
  }
  static {
    dt7948.n(this.prototype, "closeEditor", [action]);
  }
  editorKeydown(event) {
    if (event.key === "Escape") {
      this.closeEditor();
    }
  }
  static {
    dt7948.n(this.prototype, "editorKeydown", [action]);
  }
  updateTitle(event) {
    this.title = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateTitle", [action]);
  }
  updateNote(event) {
    this.note = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateNote", [action]);
  }
  updateStart(event) {
    this.startInput = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateStart", [action]);
  }
  updateEnd(event) {
    this.endInput = event.target.value;
  }
  static {
    dt7948.n(this.prototype, "updateEnd", [action]);
  }
  toggleAllDay(event) {
    this.allDay = event.target.checked;
    this.startInput = this.allDay ? this.startInput.slice(0, 10) : `${this.startInput.slice(0, 10)}T09:00`;
    this.endInput = this.allDay ? this.endInput.slice(0, 10) : `${this.endInput.slice(0, 10)}T10:00`;
  }
  static {
    dt7948.n(this.prototype, "toggleAllDay", [action]);
  }
  async saveEntry(event) {
    event.preventDefault();
    this.saveError = false;
    let startsAt;
    let endsAt;
    try {
      startsAt = this.allDay ? `${this.startInput}T00:00:00.000Z` : new Date(this.startInput).toISOString();
      endsAt = this.allDay ? new Date(new Date(`${this.endInput}T00:00:00.000Z`).getTime() + 86400000).toISOString() : new Date(this.endInput).toISOString();
    } catch {
      this.saveError = true;
      return;
    }
    if (!this.title.trim() || endsAt <= startsAt) {
      this.saveError = true;
      return;
    }
    try {
      await ajax(this.editingId ? `/isbf/api/entries/${this.editingId}.json` : "/isbf/api/entries.json", {
        type: this.editingId ? "PATCH" : "POST",
        data: {
          entry: {
            title: this.title.trim(),
            note: this.note.trim(),
            starts_at: startsAt,
            ends_at: endsAt,
            all_day: this.allDay
          }
        }
      });
      this.isEditing = false;
      await this.loadMonth();
    } catch {
      this.saveError = true;
    }
  }
  static {
    dt7948.n(this.prototype, "saveEntry", [action]);
  }
  async deleteEntry(entry) {
    if (!(await this.dialog.confirm({
      message: i18n(themePrefix("isbf_v2.calendar_delete_confirm"))
    }))) {
      return;
    }
    try {
      await ajax(`/isbf/api/entries/${entry.id}.json`, {
        type: "DELETE"
      });
      this.appEvents.trigger("isbf:calendar-entry-changed", {
        ...entry,
        removed: true
      });
      return true;
    } catch {
      this.loadError = true;
      return false;
    }
  }
  static {
    dt7948.n(this.prototype, "deleteEntry", [action]);
  }
  #selectEntry(entry) {
    const key = entry.source_item_id ? officialDateKey(entry.starts_at) : entry.all_day ? entry.starts_at.slice(0, 10) : dateKey(new Date(entry.starts_at));
    const date = localDate(key);
    this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
    this.selectedDate = key;
    this.focusedEntryId = entry.id;
    this.filter = "all";
  }
  #focusEntry() {
    document.querySelector(".isbf-v2-calendar__item.is-focused")?.focus();
  }
  #changeMonth(amount) {
    this.visibleMonth = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth() + amount, 1);
    this.selectedDate = dateKey(this.visibleMonth);
    void this.loadMonth();
  }
  #focusEditor() {
    document.querySelector(".isbf-v2-calendar__editor input[type=text]")?.focus();
  }
  #localInput(value) {
    const date = new Date(value);
    return `${dateKey(date)}T${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
  }
  #occursOn(item, key) {
    if (item.source_item_id) {
      return officialOccursOn(item, key);
    }
    if (item.all_day) {
      return item.starts_at.slice(0, 10) <= key && key < item.ends_at.slice(0, 10);
    }
    const dayStart = new Date(`${key}T00:00:00`).getTime();
    const nextDay = new Date(localDate(key).getFullYear(), localDate(key).getMonth(), localDate(key).getDate() + 1).getTime();
    return new Date(item.starts_at).getTime() < nextDay && new Date(item.ends_at).getTime() > dayStart;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-v2-feature isbf-v2-calendar">
      <div class="isbf-v2-calendar__heading">
        <div>
          <h1>{{i18n (themePrefix "isbf_v2.calendar")}}</h1>
        </div>
        <div class="isbf-v2-calendar__heading-actions">
          {{#if this.currentUser}}<button
              class="isbf-v2-calendar__primary"
              type="button"
              {{on "click" this.newEntry}}
            >{{dIcon "plus"}}
              {{i18n
                (themePrefix "isbf_v2.calendar_add_personal")
              }}</button>{{/if}}
        </div>
      </div>
    
      <div
        aria-label={{i18n (themePrefix "isbf_v2.calendar_filter_label")}}
        class="isbf-v2-calendar__filters"
        role="group"
      >
        <button
          class={{if (eq this.filter "all") "is-active"}}
          type="button"
          {{on "click" (fn this.setFilter "all")}}
        >{{i18n (themePrefix "isbf_v2.calendar_all")}}</button>
        {{#if this.currentUser}}<button
            class={{if (eq this.filter "personal") "is-active"}}
            type="button"
            {{on "click" (fn this.setFilter "personal")}}
          >{{i18n (themePrefix "isbf_v2.calendar_personal")}}</button>{{/if}}
        <button
          class={{if (eq this.filter "community") "is-active"}}
          type="button"
          {{on "click" (fn this.setFilter "community")}}
        >{{i18n (themePrefix "isbf_v2.calendar_community")}}</button>
      </div>
    
      {{#if this.updatesError}}
        <p class="isbf-calendar-updates__error" role="alert">{{i18n
            (themePrefix "isbf_v2.schedule_updates_error")
          }}</p>
        <DButton
          @action={{this.loadUpdates}}
          @label={{themePrefix "isbf_v2.official_retry"}}
        />
      {{/if}}
      {{#if this.pendingUpdates.length}}
        <section aria-label={{this.updatesLabel}} class="isbf-calendar-updates">
          <h2>{{this.updatesLabel}}</h2>
          <p>{{i18n (themePrefix "isbf_v2.schedule_pending_hint")}}</p>
          {{#each this.pendingUpdates key="id" as |entry|}}
            <div class="isbf-calendar-updates__item" data-entry-id={{entry.id}}>
              <span>{{entry.title}}
                ·
                {{i18n
                  (themePrefix
                    (if
                      entry.cancelled
                      "isbf_v2.schedule_cancelled"
                      "isbf_v2.schedule_changed"
                    )
                  )
                }}</span>
              <DButton
                @action={{fn this.reviewUpdate entry}}
                @label={{themePrefix "isbf_v2.schedule_review"}}
              />
            </div>
          {{/each}}
        </section>
      {{/if}}
    
      <div class="isbf-v2-calendar__layout">
        <section aria-label={{this.monthLabel}} class="isbf-v2-calendar__month">
          <div class="isbf-v2-calendar__month-toolbar">
            <h2>{{this.monthLabel}}</h2>
            <div>
              <button type="button" {{on "click" this.goToday}}>{{i18n
                  (themePrefix "isbf_v2.calendar_today")
                }}</button>
              <button
                aria-label={{i18n (themePrefix "isbf_v2.calendar_previous")}}
                type="button"
                {{on "click" this.previousMonth}}
              >{{dIcon "chevron-left"}}</button>
              <button
                aria-label={{i18n (themePrefix "isbf_v2.calendar_next")}}
                type="button"
                {{on "click" this.nextMonth}}
              >{{dIcon "chevron-right"}}</button>
            </div>
          </div>
          <div class="isbf-v2-calendar__weekdays">{{#each
              this.weekdays
              as |day|
            }}<span>{{day}}</span>{{/each}}</div>
          <div class="isbf-v2-calendar__days">
            {{#each this.monthCells as |cell|}}
              <button
                aria-label={{cell.key}}
                aria-pressed={{if cell.isSelected "true" "false"}}
                class="isbf-v2-calendar__day
                  {{if cell.inMonth '' 'is-outside'}}
                  {{if cell.isSelected 'is-selected'}}
                  {{if cell.isToday 'is-today'}}"
                type="button"
                {{on "click" (fn this.selectDate cell.key)}}
              >
                <span>{{cell.day}}</span><span
                  aria-hidden="true"
                  class="isbf-v2-calendar__dots"
                >{{#if cell.hasPersonal}}<i class="is-personal"></i>{{/if}}{{#if
                    cell.hasCommunity
                  }}<i class="is-community"></i>{{/if}}</span>
              </button>
            {{/each}}
          </div>
          <div class="isbf-v2-calendar__month-footer">
            <div class="isbf-v2-calendar__legend"><span><i
                  class="is-personal"
                ></i>{{i18n
                  (themePrefix "isbf_v2.calendar_personal")
                }}</span><span><i class="is-community"></i>{{i18n
                  (themePrefix "isbf_v2.calendar_community")
                }}</span></div>
            <ISBFCalendarSubscribe />
          </div>
        </section>
    
        <section
          aria-label={{this.selectedLabel}}
          class="isbf-v2-calendar__agenda"
        >
          <div class="isbf-v2-calendar__agenda-heading"><div><small>{{i18n
                  (themePrefix "isbf_v2.calendar_selected")
                }}</small><h2>{{this.selectedLabel}}</h2></div>{{#if
              this.canCreateCommunity
            }}<a href={{this.communityComposeHref}}>{{i18n
                  (themePrefix "isbf_v2.calendar_publish_event")
                }}</a>{{/if}}</div>
          {{#if this.isLoading}}<p class="isbf-v2-calendar__empty">{{i18n
                (themePrefix "isbf_v2.calendar_loading")
              }}</p>{{/if}}
          {{#if this.loadError}}<p
              class="isbf-v2-calendar__error"
              role="alert"
            >{{i18n (themePrefix "isbf_v2.calendar_load_error")}}</p>{{/if}}
          {{#unless this.isLoading}}
            {{#each this.selectedItems as |item|}}
              <article
                class="isbf-v2-calendar__item isbf-v2-calendar__item--{{item.kind}}
                  {{if item.isFocused 'is-focused'}}"
                data-entry-id={{item.id}}
                tabindex={{if item.isFocused "-1"}}
              >
                <div class="isbf-v2-calendar__item-top"><span>{{if
                      (eq item.kind "personal")
                      (i18n (themePrefix "isbf_v2.calendar_personal"))
                      (i18n (themePrefix "isbf_v2.calendar_community"))
                    }}</span><time>{{#if
                      item.source_item_id
                    }}{{officialTimeLabel item}}{{else}}{{displayTime
                        item.starts_at
                        item.all_day
                      }}{{/if}}</time></div>
                {{#if item.href}}<h3><a
                      href={{item.href}}
                    >{{item.title}}</a></h3>{{else}}<h3
                  >{{item.title}}</h3>{{/if}}
                {{#if item.note}}<p>{{item.note}}</p>{{/if}}
                {{#if item.source_item_id}}
                  <div class="isbf-v2-calendar__official">
                    <span>{{i18n
                        (themePrefix "isbf_v2.schedule_imported")
                      }}</span>
                    {{#if item.cancelled}}<strong>{{i18n
                          (themePrefix "isbf_v2.schedule_cancelled")
                        }}</strong>{{/if}}
                    {{#if item.source_url}}<a href={{item.source_url}}>{{i18n
                          (themePrefix "isbf_v2.schedule_source")
                        }}</a>{{else if item.source_unavailable}}<span>{{i18n
                          (themePrefix "isbf_v2.schedule_unavailable")
                        }}</span>{{/if}}
                    {{#if item.needs_update}}<DButton
                        @action={{fn this.reviewUpdate item}}
                        @label={{themePrefix "isbf_v2.schedule_review"}}
                      />{{/if}}
                  </div>
                {{/if}}
                {{#if (eq item.kind "personal")}}<div
                    class="isbf-v2-calendar__item-actions"
                  ><button
                      type="button"
                      {{on "click" (fn this.editEntry item)}}
                    >{{i18n
                        (themePrefix
                          (if
                            item.source_item_id
                            "isbf_v2.schedule_edit_note"
                            "isbf_v2.calendar_edit"
                          )
                        )
                      }}</button><button
                      type="button"
                      {{on "click" (fn this.deleteEntry item)}}
                    >{{i18n
                        (themePrefix "isbf_v2.calendar_delete")
                      }}</button></div>{{/if}}
              </article>
            {{else}}
              <p class="isbf-v2-calendar__empty">{{i18n
                  (themePrefix "isbf_v2.calendar_empty")
                }}</p>
            {{/each}}
          {{/unless}}
        </section>
      </div>
    
      {{#if this.isEditing}}
        <div
          aria-label={{i18n (themePrefix "isbf_v2.calendar_personal")}}
          aria-modal="true"
          class="isbf-v2-calendar__editor-backdrop"
          role="dialog"
          tabindex="-1"
          {{on "keydown" this.editorKeydown}}
        >
          <form class="isbf-v2-calendar__editor" {{on "submit" this.saveEntry}}>
            <div class="isbf-v2-calendar__editor-heading"><h2>{{i18n
                  (themePrefix "isbf_v2.calendar_personal")
                }}</h2><button
                aria-label={{i18n (themePrefix "isbf_v2.calendar_close")}}
                type="button"
                {{on "click" this.closeEditor}}
              >{{dIcon "xmark"}}</button></div>
            <label>{{i18n (themePrefix "isbf_v2.calendar_title")}}<input
                maxlength="120"
                required
                type="text"
                value={{this.title}}
                {{on "input" this.updateTitle}}
              /></label>
            <label class="isbf-v2-calendar__checkbox"><input
                checked={{this.allDay}}
                type="checkbox"
                {{on "change" this.toggleAllDay}}
              />{{i18n (themePrefix "isbf_v2.calendar_all_day")}}</label>
            <div class="isbf-v2-calendar__form-dates"><label>{{i18n
                  (themePrefix "isbf_v2.calendar_start")
                }}<input
                  required
                  type={{if this.allDay "date" "datetime-local"}}
                  value={{this.startInput}}
                  {{on "input" this.updateStart}}
                /></label><label>{{i18n
                  (themePrefix "isbf_v2.calendar_end")
                }}<input
                  required
                  type={{if this.allDay "date" "datetime-local"}}
                  value={{this.endInput}}
                  {{on "input" this.updateEnd}}
                /></label></div>
            <label>{{i18n (themePrefix "isbf_v2.calendar_note")}}<textarea
                maxlength="2000"
                rows="3"
                value={{this.note}}
                {{on "input" this.updateNote}}
              ></textarea></label>
            {{#if this.saveError}}<p
                class="isbf-v2-calendar__error"
                role="alert"
              >{{i18n (themePrefix "isbf_v2.calendar_save_error")}}</p>{{/if}}
            <div class="isbf-v2-calendar__form-actions"><button
                type="button"
                {{on "click" this.closeEditor}}
              >{{i18n (themePrefix "isbf_v2.calendar_cancel")}}</button><button
                class="isbf-v2-calendar__primary"
                type="submit"
              >{{i18n (themePrefix "isbf_v2.calendar_save")}}</button></div>
          </form>
        </div>
      {{/if}}
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-v2-feature isbf-v2-calendar\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-v2-calendar__heading\"],[12],[1,\"\\n    \"],[10,0],[12],[1,\"\\n      \"],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n    \"],[10,0],[14,0,\"isbf-v2-calendar__heading-actions\"],[12],[1,\"\\n      \"],[41,[30,0,[\"currentUser\"]],[[[11,\"button\"],[24,0,\"isbf-v2-calendar__primary\"],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"newEntry\"]]],null],[12],[1,[28,[32,3],[\"plus\"],null]],[1,\"\\n          \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_add_personal\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_filter_label\"],null]],null]],[14,0,\"isbf-v2-calendar__filters\"],[14,\"role\",\"group\"],[12],[1,\"\\n    \"],[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"all\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"all\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_all\"],null]],null]],[13],[1,\"\\n    \"],[41,[30,0,[\"currentUser\"]],[[[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"personal\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"personal\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"community\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"community\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"updatesError\"]],[[[1,\"    \"],[10,2],[14,0,\"isbf-calendar-updates__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_updates_error\"],null]],null]],[13],[1,\"\\n    \"],[8,[32,6],null,[[\"@action\",\"@label\"],[[30,0,[\"loadUpdates\"]],[28,[32,1],[\"isbf_v2.official_retry\"],null]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"pendingUpdates\",\"length\"]],[[[1,\"    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"updatesLabel\"]]],[14,0,\"isbf-calendar-updates\"],[12],[1,\"\\n      \"],[10,\"h2\"],[12],[1,[30,0,[\"updatesLabel\"]]],[13],[1,\"\\n      \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_pending_hint\"],null]],null]],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"pendingUpdates\"]]],null]],null],\"id\",[[[1,\"        \"],[10,0],[14,0,\"isbf-calendar-updates__item\"],[15,\"data-entry-id\",[30,1,[\"id\"]]],[12],[1,\"\\n          \"],[10,1],[12],[1,[30,1,[\"title\"]]],[1,\"\\n            ·\\n            \"],[1,[28,[32,0],[[28,[32,1],[[52,[30,1,[\"cancelled\"]],\"isbf_v2.schedule_cancelled\",\"isbf_v2.schedule_changed\"]],null]],null]],[13],[1,\"\\n          \"],[8,[32,6],null,[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"reviewUpdate\"]],[30,1]],null],[28,[32,1],[\"isbf_v2.schedule_review\"],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[1]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n  \"],[10,0],[14,0,\"isbf-v2-calendar__layout\"],[12],[1,\"\\n    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"monthLabel\"]]],[14,0,\"isbf-v2-calendar__month\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__month-toolbar\"],[12],[1,\"\\n        \"],[10,\"h2\"],[12],[1,[30,0,[\"monthLabel\"]]],[13],[1,\"\\n        \"],[10,0],[12],[1,\"\\n          \"],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"goToday\"]]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_today\"],null]],null]],[13],[1,\"\\n          \"],[11,\"button\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_previous\"],null]],null]],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"previousMonth\"]]],null],[12],[1,[28,[32,3],[\"chevron-left\"],null]],[13],[1,\"\\n          \"],[11,\"button\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_next\"],null]],null]],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"nextMonth\"]]],null],[12],[1,[28,[32,3],[\"chevron-right\"],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__weekdays\"],[12],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"weekdays\"]]],null]],null],null,[[[10,1],[12],[1,[30,2]],[13]],[2]],null],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__days\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"monthCells\"]]],null]],null],null,[[[1,\"          \"],[11,\"button\"],[16,\"aria-label\",[30,3,[\"key\"]]],[16,\"aria-pressed\",[52,[30,3,[\"isSelected\"]],\"true\",\"false\"]],[16,0,[29,[\"isbf-v2-calendar__day\\n              \",[52,[30,3,[\"inMonth\"]],\"\",\"is-outside\"],\"\\n              \",[52,[30,3,[\"isSelected\"]],\"is-selected\"],\"\\n              \",[52,[30,3,[\"isToday\"]],\"is-today\"]]]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"selectDate\"]],[30,3,[\"key\"]]],null]],null],[12],[1,\"\\n            \"],[10,1],[12],[1,[30,3,[\"day\"]]],[13],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-v2-calendar__dots\"],[12],[41,[30,3,[\"hasPersonal\"]],[[[10,\"i\"],[14,0,\"is-personal\"],[12],[13]],[]],null],[41,[30,3,[\"hasCommunity\"]],[[[10,\"i\"],[14,0,\"is-community\"],[12],[13]],[]],null],[13],[1,\"\\n          \"],[13],[1,\"\\n\"]],[3]],null],[1,\"      \"],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__month-footer\"],[12],[1,\"\\n        \"],[10,0],[14,0,\"isbf-v2-calendar__legend\"],[12],[10,1],[12],[10,\"i\"],[14,0,\"is-personal\"],[12],[13],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[13],[10,1],[12],[10,\"i\"],[14,0,\"is-community\"],[12],[13],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]],[13],[13],[1,\"\\n        \"],[8,[32,7],null,null,null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"selectedLabel\"]]],[14,0,\"isbf-v2-calendar__agenda\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__agenda-heading\"],[12],[10,0],[12],[10,\"small\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_selected\"],null]],null]],[13],[10,\"h2\"],[12],[1,[30,0,[\"selectedLabel\"]]],[13],[13],[41,[30,0,[\"canCreateCommunity\"]],[[[10,3],[15,6,[30,0,[\"communityComposeHref\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_publish_event\"],null]],null]],[13]],[]],null],[13],[1,\"\\n      \"],[41,[30,0,[\"isLoading\"]],[[[10,2],[14,0,\"isbf-v2-calendar__empty\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_loading\"],null]],null]],[13]],[]],null],[1,\"\\n      \"],[41,[30,0,[\"loadError\"]],[[[10,2],[14,0,\"isbf-v2-calendar__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_load_error\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[51,[30,0,[\"isLoading\"]]],[[[42,[28,[31,2],[[28,[31,2],[[30,0,[\"selectedItems\"]]],null]],null],null,[[[1,\"          \"],[10,\"article\"],[15,0,[29,[\"isbf-v2-calendar__item isbf-v2-calendar__item--\",[30,4,[\"kind\"]],\"\\n              \",[52,[30,4,[\"isFocused\"]],\"is-focused\"]]]],[15,\"data-entry-id\",[30,4,[\"id\"]]],[15,\"tabindex\",[52,[30,4,[\"isFocused\"]],\"-1\"]],[12],[1,\"\\n            \"],[10,0],[14,0,\"isbf-v2-calendar__item-top\"],[12],[10,1],[12],[1,[52,[28,[32,4],[[30,4,[\"kind\"]],\"personal\"],null],[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null],[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]]],[13],[10,\"time\"],[12],[41,[30,4,[\"source_item_id\"]],[[[1,[28,[32,8],[[30,4]],null]]],[]],[[[1,[28,[32,9],[[30,4,[\"starts_at\"]],[30,4,[\"all_day\"]]],null]]],[]]],[13],[13],[1,\"\\n            \"],[41,[30,4,[\"href\"]],[[[10,\"h3\"],[12],[10,3],[15,6,[30,4,[\"href\"]]],[12],[1,[30,4,[\"title\"]]],[13],[13]],[]],[[[10,\"h3\"],[12],[1,[30,4,[\"title\"]]],[13]],[]]],[1,\"\\n            \"],[41,[30,4,[\"note\"]],[[[10,2],[12],[1,[30,4,[\"note\"]]],[13]],[]],null],[1,\"\\n\"],[41,[30,4,[\"source_item_id\"]],[[[1,\"              \"],[10,0],[14,0,\"isbf-v2-calendar__official\"],[12],[1,\"\\n                \"],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_imported\"],null]],null]],[13],[1,\"\\n                \"],[41,[30,4,[\"cancelled\"]],[[[10,\"strong\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_cancelled\"],null]],null]],[13]],[]],null],[1,\"\\n                \"],[41,[30,4,[\"source_url\"]],[[[10,3],[15,6,[30,4,[\"source_url\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_source\"],null]],null]],[13]],[]],[[[41,[30,4,[\"source_unavailable\"]],[[[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_unavailable\"],null]],null]],[13]],[]],null]],[]]],[1,\"\\n                \"],[41,[30,4,[\"needs_update\"]],[[[8,[32,6],null,[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"reviewUpdate\"]],[30,4]],null],[28,[32,1],[\"isbf_v2.schedule_review\"],null]]],null]],[]],null],[1,\"\\n              \"],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[41,[28,[32,4],[[30,4,[\"kind\"]],\"personal\"],null],[[[10,0],[14,0,\"isbf-v2-calendar__item-actions\"],[12],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"editEntry\"]],[30,4]],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[[52,[30,4,[\"source_item_id\"]],\"isbf_v2.schedule_edit_note\",\"isbf_v2.calendar_edit\"]],null]],null]],[13],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"deleteEntry\"]],[30,4]],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_delete\"],null]],null]],[13],[13]],[]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[4]],[[[1,\"          \"],[10,2],[14,0,\"isbf-v2-calendar__empty\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_empty\"],null]],null]],[13],[1,\"\\n\"]],[]]]],[]],null],[1,\"    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"isEditing\"]],[[[1,\"    \"],[11,0],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[24,\"aria-modal\",\"true\"],[24,0,\"isbf-v2-calendar__editor-backdrop\"],[24,\"role\",\"dialog\"],[24,\"tabindex\",\"-1\"],[4,[32,2],[\"keydown\",[30,0,[\"editorKeydown\"]]],null],[12],[1,\"\\n      \"],[11,\"form\"],[24,0,\"isbf-v2-calendar__editor\"],[4,[32,2],[\"submit\",[30,0,[\"saveEntry\"]]],null],[12],[1,\"\\n        \"],[10,0],[14,0,\"isbf-v2-calendar__editor-heading\"],[12],[10,\"h2\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[13],[11,\"button\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_close\"],null]],null]],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"closeEditor\"]]],null],[12],[1,[28,[32,3],[\"xmark\"],null]],[13],[13],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_title\"],null]],null]],[11,\"input\"],[24,\"maxlength\",\"120\"],[24,\"required\",\"\"],[16,2,[30,0,[\"title\"]]],[24,4,\"text\"],[4,[32,2],[\"input\",[30,0,[\"updateTitle\"]]],null],[12],[13],[13],[1,\"\\n        \"],[10,\"label\"],[14,0,\"isbf-v2-calendar__checkbox\"],[12],[11,\"input\"],[16,\"checked\",[30,0,[\"allDay\"]]],[24,4,\"checkbox\"],[4,[32,2],[\"change\",[30,0,[\"toggleAllDay\"]]],null],[12],[13],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_all_day\"],null]],null]],[13],[1,\"\\n        \"],[10,0],[14,0,\"isbf-v2-calendar__form-dates\"],[12],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_start\"],null]],null]],[11,\"input\"],[24,\"required\",\"\"],[16,2,[30,0,[\"startInput\"]]],[16,4,[52,[30,0,[\"allDay\"]],\"date\",\"datetime-local\"]],[4,[32,2],[\"input\",[30,0,[\"updateStart\"]]],null],[12],[13],[13],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_end\"],null]],null]],[11,\"input\"],[24,\"required\",\"\"],[16,2,[30,0,[\"endInput\"]]],[16,4,[52,[30,0,[\"allDay\"]],\"date\",\"datetime-local\"]],[4,[32,2],[\"input\",[30,0,[\"updateEnd\"]]],null],[12],[13],[13],[13],[1,\"\\n        \"],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_note\"],null]],null]],[11,\"textarea\"],[24,\"maxlength\",\"2000\"],[24,\"rows\",\"3\"],[16,2,[30,0,[\"note\"]]],[4,[32,2],[\"input\",[30,0,[\"updateNote\"]]],null],[12],[13],[13],[1,\"\\n        \"],[41,[30,0,[\"saveError\"]],[[[10,2],[14,0,\"isbf-v2-calendar__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_save_error\"],null]],null]],[13]],[]],null],[1,\"\\n        \"],[10,0],[14,0,\"isbf-v2-calendar__form-actions\"],[12],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"closeEditor\"]]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_cancel\"],null]],null]],[13],[10,\"button\"],[14,0,\"isbf-v2-calendar__primary\"],[14,4,\"submit\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_save\"],null]],null]],[13],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"entry\",\"day\",\"cell\",\"item\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        on,
        dIcon,
        eq,
        fn,
        DButton,
        ISBFCalendarSubscribe,
        officialTimeLabel,
        displayTime
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-calendar", ISBFV2Calendar);
var Mod6 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2Calendar
});
const RECENT_WINDOW = 3 * 24 * 60 * 60 * 1000;
const TOPIC_LIMIT = 4;
async function loadRecentDiscussions({
  site,
  request = ajax,
  now = Date.now(),
  isStale = () => false
} = {}) {
  const categoryId = marketplaceConfig(site)?.category_id;
  const teamupId = teamupConfig(site)?.category_id;
  const careersId = careersConfig(site)?.category_id;
  const cutoff = now - RECENT_WINDOW;
  const topics = [];
  const seen = new Set();
  let page = 0;
  while (!isStale()) {
    const response = await request("/filter.json", {
      data: {
        q: "created-after:3 order:posts,created",
        page
      }
    });
    if (isStale()) {
      return [];
    }
    const list = response.topic_list;
    const candidates = list?.topics ?? [];
    let newIds = 0;
    for (const topic of candidates) {
      if (!Number.isSafeInteger(topic.id) || topic.id <= 0 || seen.has(topic.id)) {
        continue;
      }
      seen.add(topic.id);
      newIds += 1;
      const created = Date.parse(topic.created_at);
      if (!Number.isFinite(created) || created < cutoff || created > now) {
        continue;
      }
      // Native /filter does not apply the marketplace's home-feed exclusion.
      if ((Number(topic.category_id) === categoryId || topic.isbf_marketplace) && topic.isbf_marketplace?.show_on_home !== true) {
        continue;
      }
      if ((Number(topic.category_id) === teamupId || topic.isbf_teamup) && topic.isbf_teamup?.show_on_home === false) {
        continue;
      }
      if ((Number(topic.category_id) === careersId || topic.isbf_careers) && topic.isbf_careers?.show_on_home === false) {
        continue;
      }
      topics.push(topic);
      if (topics.length === TOPIC_LIMIT) {
        return topics;
      }
    }
    if (!newIds || !list?.more_topics_url) {
      break;
    }
    page += 1;
  }
  return isStale() ? [] : topics;
}
var Mod106 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  loadRecentDiscussions: loadRecentDiscussions
});
class ISBFV2RightRail extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "topics", [tracked], function () {
      return [];
    });
  }
  #topics = (dt7948.i(this, "topics"), void 0);
  #generation = 0;
  constructor() {
    super(...arguments);
    this.#loadTopics();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation += 1;
  }
  async #loadTopics() {
    const generation = ++this.#generation;
    const isStale = () => this.isDestroying || generation !== this.#generation;
    try {
      const topics = await loadRecentDiscussions({
        site: this.site,
        isStale
      });
      if (!isStale()) {
        this.topics = topics.map(topic => ({
          id: topic.id,
          title: topic.title,
          postId: topic.first_post_id,
          excerpt: topic.excerpt,
          href: `/t/${topic.slug}/${topic.id}`
        }));
      }
    } catch {
      // The navigation links below remain available while the feed is offline.
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <aside
      aria-label={{i18n (themePrefix "isbf_v2.rail_label")}}
      class="isbf-v2-rail"
    >
      <form
        action="/search"
        class="isbf-v2-rail__search"
        method="get"
        role="search"
      >
        {{dIcon "magnifying-glass"}}
        <label class="sr-only" for="isbf-v2-search">{{i18n
            (themePrefix "isbf_v2.search")
          }}</label>
        <input
          autocomplete="off"
          id="isbf-v2-search"
          name="q"
          placeholder={{i18n (themePrefix "isbf_v2.search_placeholder")}}
          type="search"
        />
      </form>
    
      <div class="isbf-v2-rail__content">
    
        {{#if this.topics.length}}
          <section
            aria-labelledby="isbf-v2-recent-title"
            class="isbf-v2-rail__panel"
          >
            <h2 id="isbf-v2-recent-title">{{i18n
                (themePrefix "isbf_v2.recent")
              }}</h2>
            {{#each this.topics key="id" as |topic|}}
              <ISBFPostPreview
                class="isbf-v2-rail__topic"
                @excerpt={{topic.excerpt}}
                @href={{topic.href}}
                @postId={{topic.postId}}
                @title={{topic.title}}
                @variant="rail"
              />
            {{/each}}
            <a class="isbf-v2-rail__more" href="/latest">{{i18n
                (themePrefix "isbf_v2.view_all")
              }}</a>
          </section>
        {{/if}}
    
        <section
          aria-labelledby="isbf-v2-links-title"
          class="isbf-v2-rail__panel"
        >
          <h2 id="isbf-v2-links-title">{{i18n
              (themePrefix "isbf_v2.rail_label")
            }}</h2>
          <a href={{settings.official_path}}><span>{{i18n
                (themePrefix "isbf_v2.official")
              }}</span>{{dIcon "chevron-right"}}</a>
          <a href="/categories"><span>{{i18n
                (themePrefix "isbf_v2.categories")
              }}</span>{{dIcon "chevron-right"}}</a>
          <a href="/top"><span>{{i18n
                (themePrefix "isbf_v2.top")
              }}</span>{{dIcon "chevron-right"}}</a>
        </section>
      </div>
    </aside>
    */
    {
      "id": null,
      "block": "[[[10,\"aside\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.rail_label\"],null]],null]],[14,0,\"isbf-v2-rail\"],[12],[1,\"\\n  \"],[10,\"form\"],[14,\"action\",\"/search\"],[14,0,\"isbf-v2-rail__search\"],[14,\"method\",\"get\"],[14,\"role\",\"search\"],[12],[1,\"\\n    \"],[1,[28,[32,2],[\"magnifying-glass\"],null]],[1,\"\\n    \"],[10,\"label\"],[14,0,\"sr-only\"],[14,\"for\",\"isbf-v2-search\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.search\"],null]],null]],[13],[1,\"\\n    \"],[10,\"input\"],[14,\"autocomplete\",\"off\"],[14,1,\"isbf-v2-search\"],[14,3,\"q\"],[15,\"placeholder\",[28,[32,0],[[28,[32,1],[\"isbf_v2.search_placeholder\"],null]],null]],[14,4,\"search\"],[12],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[14,0,\"isbf-v2-rail__content\"],[12],[1,\"\\n\\n\"],[41,[30,0,[\"topics\",\"length\"]],[[[1,\"      \"],[10,\"section\"],[14,\"aria-labelledby\",\"isbf-v2-recent-title\"],[14,0,\"isbf-v2-rail__panel\"],[12],[1,\"\\n        \"],[10,\"h2\"],[14,1,\"isbf-v2-recent-title\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.recent\"],null]],null]],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"          \"],[8,[32,3],[[24,0,\"isbf-v2-rail__topic\"]],[[\"@excerpt\",\"@href\",\"@postId\",\"@title\",\"@variant\"],[[30,1,[\"excerpt\"]],[30,1,[\"href\"]],[30,1,[\"postId\"]],[30,1,[\"title\"]],\"rail\"]],null],[1,\"\\n\"]],[1]],null],[1,\"        \"],[10,3],[14,0,\"isbf-v2-rail__more\"],[14,6,\"/latest\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.view_all\"],null]],null]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"section\"],[14,\"aria-labelledby\",\"isbf-v2-links-title\"],[14,0,\"isbf-v2-rail__panel\"],[12],[1,\"\\n      \"],[10,\"h2\"],[14,1,\"isbf-v2-links-title\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.rail_label\"],null]],null]],[13],[1,\"\\n      \"],[10,3],[15,6,[32,4,[\"official_path\"]]],[12],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.official\"],null]],null]],[13],[1,[28,[32,2],[\"chevron-right\"],null]],[13],[1,\"\\n      \"],[10,3],[14,6,\"/categories\"],[12],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.categories\"],null]],null]],[13],[1,[28,[32,2],[\"chevron-right\"],null]],[13],[1,\"\\n      \"],[10,3],[14,6,\"/top\"],[12],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.top\"],null]],null]],[13],[1,[28,[32,2],[\"chevron-right\"],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"topic\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        dIcon,
        ISBFPostPreview,
        settings
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-right-rail", ISBFV2RightRail);
var Mod2 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2RightRail
});
class ISBFV2AppearanceModal extends Component {
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "interfaceColor", [service]);
  }
  #interfaceColor = (dt7948.i(this, "interfaceColor"), void 0);
  get title() {
    return i18n(themePrefix("isbf_v2.appearance"));
  }
  get options() {
    const currentMode = this.interfaceColor.colorMode || "auto";
    return [{
      mode: "light",
      icon: "sun"
    }, {
      mode: "dark",
      icon: "moon"
    }, {
      mode: "auto",
      icon: "circle-half-stroke"
    }].map(option => ({
      ...option,
      label: i18n(themePrefix(`isbf_v2.appearance_${option.mode}`)),
      selected: currentMode === option.mode
    }));
  }
  async selectMode(mode) {
    if (!["light", "dark", "auto"].includes(mode)) {
      return;
    }
    if (!this.interfaceColor.selectorAvailable) {
      await this.dialog.alert(i18n(themePrefix("isbf_v2.appearance_unavailable")));
      return;
    }
    if (mode === "light") {
      this.interfaceColor.forceLightMode();
    } else if (mode === "dark") {
      this.interfaceColor.forceDarkMode();
    } else {
      this.interfaceColor.useAutoMode();
    }
    this.args.closeModal();
  }
  static {
    dt7948.n(this.prototype, "selectMode", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-v2-appearance-modal"
      @closeModal={{@closeModal}}
      @title={{this.title}}
    >
      <:body>
        <div class="isbf-v2-appearance-modal__options">
          {{#each this.options key="mode" as |option|}}
            <DButton
              aria-pressed={{option.selected}}
              class="btn-flat isbf-v2-appearance-modal__option"
              @action={{fn this.selectMode option.mode}}
            >
              {{dIcon option.icon}}
              <span>{{option.label}}</span>
              <span
                aria-hidden="true"
                class="isbf-v2-appearance-modal__selected"
              >
                {{#if option.selected}}{{dIcon "check"}}{{/if}}
              </span>
            </DButton>
          {{/each}}
        </div>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-v2-appearance-modal\"]],[[\"@closeModal\",\"@title\"],[[30,1],[30,0,[\"title\"]]]],[[\"body\"],[[[[1,\"\\n    \"],[10,0],[14,0,\"isbf-v2-appearance-modal__options\"],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"options\"]]],null]],null],\"mode\",[[[1,\"        \"],[8,[32,1],[[16,\"aria-pressed\",[30,2,[\"selected\"]]],[24,0,\"btn-flat isbf-v2-appearance-modal__option\"]],[[\"@action\"],[[28,[32,2],[[30,0,[\"selectMode\"]],[30,2,[\"mode\"]]],null]]],[[\"default\"],[[[[1,\"\\n          \"],[1,[28,[32,3],[[30,2,[\"icon\"]]],null]],[1,\"\\n          \"],[10,1],[12],[1,[30,2,[\"label\"]]],[13],[1,\"\\n          \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-v2-appearance-modal__selected\"],[12],[1,\"\\n            \"],[41,[30,2,[\"selected\"]],[[[1,[28,[32,3],[\"check\"],null]]],[]],null],[1,\"\\n          \"],[13],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[2]],null],[1,\"    \"],[13],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\",\"option\"],[\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        DButton,
        fn,
        dIcon
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-appearance-modal", ISBFV2AppearanceModal);
var Mod102 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2AppearanceModal
});
class ISBFV2UtilityActions extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "dialog", [service]);
  }
  #dialog = (dt7948.i(this, "dialog"), void 0);
  static {
    dt7948.g(this.prototype, "interfaceColor", [service]);
  }
  #interfaceColor = (dt7948.i(this, "interfaceColor"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get items() {
    return [{
      key: "settings",
      icon: "gear",
      label: i18n(themePrefix("isbf_v2.sidebar_settings")),
      action: this.openSettings
    }, {
      key: "appearance",
      icon: "circle-half-stroke",
      label: i18n(themePrefix("isbf_v2.appearance")),
      action: this.openAppearance
    }, {
      key: "feedback",
      icon: "comment",
      label: i18n(themePrefix("isbf_v2.feedback")),
      action: this.openFeedback
    }, {
      key: "join",
      icon: "user-group",
      label: i18n(themePrefix("isbf_v2.join_us")),
      action: this.openJoin
    }];
  }
  async openSettings() {
    await this.args.menu?.close();
    this.router.transitionTo(this.currentUser ? `/u/${encodeURIComponent(this.currentUser.username)}/preferences` : "/login");
  }
  static {
    dt7948.n(this.prototype, "openSettings", [action]);
  }
  async openAppearance() {
    await this.args.menu?.close();
    if (!this.interfaceColor.selectorAvailable) {
      await this.dialog.alert(i18n(themePrefix("isbf_v2.appearance_unavailable")));
      return;
    }
    this.modal.show(ISBFV2AppearanceModal);
  }
  static {
    dt7948.n(this.prototype, "openAppearance", [action]);
  }
  async openFeedback() {
    await this.args.menu?.close();
    const href = feedbackHref(feedbackCategory(this.site, settings.feedback_category_id));
    if (href) {
      this.router.transitionTo(href);
    } else {
      await this.dialog.alert(i18n(themePrefix("isbf_v2.feedback_unavailable")));
    }
  }
  static {
    dt7948.n(this.prototype, "openFeedback", [action]);
  }
  async openJoin() {
    await this.args.menu?.close();
    DiscourseURL.redirectTo("/join/");
  }
  static {
    dt7948.n(this.prototype, "openJoin", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DDropdownMenu as |dropdown|>
      {{#each this.items key="key" as |item|}}
        <dropdown.item>
          <DButton
            class="btn-flat isbf-v2-more-menu__item"
            @action={{item.action}}
            @icon={{item.icon}}
            @translatedLabel={{item.label}}
          />
        </dropdown.item>
      {{/each}}
    </DDropdownMenu>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"items\"]]],null]],null],\"key\",[[[1,\"    \"],[8,[30,1,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n      \"],[8,[32,1],[[24,0,\"btn-flat isbf-v2-more-menu__item\"]],[[\"@action\",\"@icon\",\"@translatedLabel\"],[[30,2,[\"action\"]],[30,2,[\"icon\"]],[30,2,[\"label\"]]]],null],[1,\"\\n    \"]],[]]]]],[1,\"\\n\"]],[2]],null]],[1]]]]]],[\"dropdown\",\"item\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DDropdownMenu,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-utility-actions", ISBFV2UtilityActions);
var Mod86 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2UtilityActions
});
class ISBFV2MoreMenu extends Component {
  fallbackPlacements = ["top-start", "top-end"];
  get contentClass() {
    return this.args.workbench ? "isbf-v2-more-menu isbf-v2-more-menu--workbench" : "isbf-v2-more-menu";
  }
  get identifier() {
    return this.args.workbench ? "isbf-v2-workbench-more" : "isbf-v2-sidebar-more";
  }
  get placement() {
    return this.args.workbench ? "top-end" : "top-start";
  }
  get triggerClass() {
    return this.args.workbench ? "btn-flat isbf-v2-workbench__more-trigger" : "btn-flat isbf-v2-side__more";
  }
  get visibilityOptimizer() {
    return this.args.workbench ? "none" : "flip";
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DMenu
      @ariaLabel={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @contentClass={{this.contentClass}}
      @fallbackPlacements={{this.fallbackPlacements}}
      @icon="ellipsis"
      @identifier={{this.identifier}}
      @label={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @modalForMobile={{false}}
      @placement={{this.placement}}
      @title={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @triggerClass={{this.triggerClass}}
      @visibilityOptimizer={{this.visibilityOptimizer}}
    >
      <:content as |menu|>
        <ISBFV2UtilityActions @menu={{menu}} />
      </:content>
    </DMenu>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@fallbackPlacements\",\"@icon\",\"@identifier\",\"@label\",\"@modalForMobile\",\"@placement\",\"@title\",\"@triggerClass\",\"@visibilityOptimizer\"],[[28,[32,1],[[28,[32,2],[\"isbf_v2.sidebar_more\"],null]],null],[30,0,[\"contentClass\"]],[30,0,[\"fallbackPlacements\"]],\"ellipsis\",[30,0,[\"identifier\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.sidebar_more\"],null]],null],false,[30,0,[\"placement\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.sidebar_more\"],null]],null],[30,0,[\"triggerClass\"]],[30,0,[\"visibilityOptimizer\"]]]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,3],null,[[\"@menu\"],[[30,1]]],null],[1,\"\\n  \"]],[1]]]]]],[\"menu\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        themePrefix,
        ISBFV2UtilityActions
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-more-menu", ISBFV2MoreMenu);
var Mod48 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2MoreMenu
});
class ISBFV2SideNav extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (dt7948.i(this, "isbfNotifications"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get composeHref() {
    const category = feedbackCategory(this.site, settings.feedback_category_id);
    return isFeedbackPath(this.router.currentURL, category) ? feedbackComposeHref(category) : "/new-topic";
  }
  get bookmarksHref() {
    return this.currentUser ? `/u/${this.currentUser.username}/activity/bookmarks` : "/login";
  }
  get notificationsHref() {
    return this.currentUser ? `/u/${this.currentUser.username}/notifications` : "/login";
  }
  get profileHref() {
    return this.currentUser ? `/u/${this.currentUser.username}` : "/login";
  }
  get homeActive() {
    const path = this.router.currentURL ?? "";
    const officialPath = settings.official_path.split("/l/")[0];
    if (isFeedbackPath(path, feedbackCategory(this.site, settings.feedback_category_id))) {
      return false;
    }
    return path === "/" || path.startsWith("/latest") || path === officialPath || path.startsWith(`${officialPath}/`);
  }
  get exploreActive() {
    if (isFeedbackPath(this.router.currentURL, feedbackCategory(this.site, settings.feedback_category_id))) {
      return false;
    }
    return /^\/(search|categories|c|tag|tags)(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get notificationsActive() {
    return /\/notifications(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get calendarActive() {
    return (this.router.currentURL ?? "").startsWith("/isbf/calendar");
  }
  get workbenchActive() {
    return /^\/isbf\/(workbench|learning|alumni)(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get bookmarksActive() {
    return /\/activity\/bookmarks(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get profileActive() {
    const path = this.router.currentURL ?? "";
    return /^\/u\//.test(path) && !this.notificationsActive && !this.bookmarksActive;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <aside
      aria-label={{i18n (themePrefix "isbf_v2.navigation_label")}}
      class="isbf-v2-side"
    >
      <ISBFV2Brand />
    
      <nav class="isbf-v2-side__links">
        <a
          aria-current={{if this.homeActive "page"}}
          class={{if this.homeActive "is-active"}}
          href="/latest"
        >{{dIcon "house"}}<span>{{i18n (themePrefix "isbf_v2.home")}}</span></a>
        <a
          aria-current={{if this.exploreActive "page"}}
          class={{if this.exploreActive "is-active"}}
          href="/categories"
        >{{dIcon "magnifying-glass"}}<span>{{i18n
              (themePrefix "isbf_v2.explore")
            }}</span></a>
        <a
          aria-current={{if this.notificationsActive "page"}}
          aria-label={{this.isbfNotifications.linkLabel}}
          class={{if this.notificationsActive "is-active"}}
          href={{this.notificationsHref}}
        ><ISBFNotificationBell /><span>{{i18n
              (themePrefix "isbf_v2.notifications")
            }}</span></a>
        <a
          aria-current={{if this.calendarActive "page"}}
          class={{if this.calendarActive "is-active"}}
          href="/isbf/calendar"
        >{{dIcon "calendar-days"}}<span>{{i18n
              (themePrefix "isbf_v2.calendar")
            }}</span></a>
        <a
          aria-current={{if this.workbenchActive "page"}}
          class={{if this.workbenchActive "is-active"}}
          href="/isbf/workbench"
        >{{dIcon "table-cells-large"}}<span>{{i18n
              (themePrefix "isbf_v2.workbench")
            }}</span></a>
        <a
          aria-current={{if this.bookmarksActive "page"}}
          class={{if this.bookmarksActive "is-active"}}
          href={{this.bookmarksHref}}
        >{{dIcon "bookmark"}}<span>{{i18n
              (themePrefix "isbf_v2.bookmarks")
            }}</span></a>
        <a
          aria-current={{if this.profileActive "page"}}
          class={{if this.profileActive "is-active"}}
          href={{this.profileHref}}
        >{{dIcon "user"}}<span>{{i18n
              (themePrefix "isbf_v2.profile")
            }}</span></a>
        <ISBFV2MoreMenu />
      </nav>
    
      <a class="isbf-v2-side__compose" href={{this.composeHref}}>{{i18n
          (themePrefix "isbf_v2.compose")
        }}</a>
    
      {{#if this.currentUser.can_review}}
        <a
          aria-label={{i18n (themePrefix "isbf_v2.review")}}
          class="isbf-v2-side__review"
          href="/review"
        >{{i18n (themePrefix "isbf_v2.review")}}</a>
      {{/if}}
    
      {{#if this.currentUser}}
        <ISBFV2AccountMenu />
      {{/if}}
    </aside>
    */
    {
      "id": null,
      "block": "[[[10,\"aside\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.navigation_label\"],null]],null]],[14,0,\"isbf-v2-side\"],[12],[1,\"\\n  \"],[8,[32,2],null,null,null],[1,\"\\n\\n  \"],[10,\"nav\"],[14,0,\"isbf-v2-side__links\"],[12],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"homeActive\"]],\"page\"]],[15,0,[52,[30,0,[\"homeActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,3],[\"house\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"exploreActive\"]],\"page\"]],[15,0,[52,[30,0,[\"exploreActive\"]],\"is-active\"]],[14,6,\"/categories\"],[12],[1,[28,[32,3],[\"magnifying-glass\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.explore\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"notificationsActive\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"notificationsActive\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,4],null,null,null],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"calendarActive\"]],\"page\"]],[15,0,[52,[30,0,[\"calendarActive\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,3],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"workbenchActive\"]],\"page\"]],[15,0,[52,[30,0,[\"workbenchActive\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,3],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"bookmarksActive\"]],\"page\"]],[15,0,[52,[30,0,[\"bookmarksActive\"]],\"is-active\"]],[15,6,[30,0,[\"bookmarksHref\"]]],[12],[1,[28,[32,3],[\"bookmark\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.bookmarks\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"profileActive\"]],\"page\"]],[15,0,[52,[30,0,[\"profileActive\"]],\"is-active\"]],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,3],[\"user\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.profile\"],null]],null]],[13],[13],[1,\"\\n    \"],[8,[32,5],null,null,null],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,3],[14,0,\"isbf-v2-side__compose\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n\\n\"],[41,[30,0,[\"currentUser\",\"can_review\"]],[[[1,\"    \"],[10,3],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-side__review\"],[14,6,\"/review\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"    \"],[8,[32,6],null,null,null],[1,\"\\n\"]],[]],null],[13]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        ISBFV2Brand,
        dIcon,
        ISBFNotificationBell,
        ISBFV2MoreMenu,
        ISBFV2AccountMenu
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-side-nav", ISBFV2SideNav);
var Mod4 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2SideNav
});
const CARDS = [{
  key: "learning_resources",
  icon: "book-open",
  tone: "blue"
}, {
  key: "library",
  icon: "database",
  tone: "indigo"
}, {
  key: "courses",
  icon: "graduation-cap",
  tone: "violet"
}, {
  key: "careers",
  icon: "briefcase",
  tone: "amber"
}, {
  key: "resume",
  icon: "file-lines",
  tone: "mint"
}, {
  key: "campus_services",
  icon: "building-columns",
  tone: "sky"
}, {
  key: "student_identity",
  icon: "id-card",
  tone: "rose"
}, {
  key: "alumni",
  icon: "user-group",
  tone: "teal"
}, {
  key: "marketplace",
  icon: "bag-shopping",
  tone: "amber"
}, {
  key: "teamup",
  icon: "user-group",
  tone: "violet"
}];
class ISBFV2Workbench extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  get cards() {
    return CARDS.filter(card => card.key !== "alumni" || alumniConfig(this.site)).map(card => ({
      ...card,
      label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
      href: card.key === "learning_resources" && learningConfig(this.site) ? "/isbf/learning" : card.key === "library" && libraryConfig(this.site) ? "/isbf/library" : card.key === "careers" && careersConfig(this.site) ? "/isbf/careers" : card.key === "marketplace" && marketplaceConfig(this.site) ? "/isbf/marketplace" : card.key === "teamup" && teamupConfig(this.site) ? "/isbf/teamup" : card.key === "alumni" ? "/isbf/alumni" : card.key === "resume" && this.siteSettings.isbf_resume_enabled ? "/isbf/workbench/resume" : null
    }));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-v2-feature isbf-v2-workbench">
      <h1>{{i18n (themePrefix "isbf_v2.workbench")}}</h1>
      <section
        aria-label={{i18n (themePrefix "isbf_v2.workbench")}}
        class="isbf-v2-workbench__panel"
      >
        <div class="isbf-v2-workbench__grid">
          {{#each this.cards as |card|}}
            {{#if card.href}}
              <a class="isbf-v2-workbench__card" href={{card.href}}>
                <span
                  aria-hidden="true"
                  class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
                >{{dIcon card.icon}}</span>
                <span class="isbf-v2-workbench__name">{{card.label}}</span>
              </a>
            {{else}}
              <div class="isbf-v2-workbench__card">
                <span
                  aria-hidden="true"
                  class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
                >{{dIcon card.icon}}</span>
                <span class="isbf-v2-workbench__name">{{card.label}}</span>
              </div>
            {{/if}}
          {{/each}}
        </div>
      </section>
      <div class="isbf-v2-workbench__more">
        <div class="isbf-v2-workbench__more-control">
          <ISBFV2MoreMenu @workbench={{true}} />
        </div>
      </div>
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-v2-feature isbf-v2-workbench\"],[12],[1,\"\\n  \"],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.workbench\"],null]],null]],[13],[1,\"\\n  \"],[10,\"section\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.workbench\"],null]],null]],[14,0,\"isbf-v2-workbench__panel\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-v2-workbench__grid\"],[12],[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"cards\"]]],null]],null],null,[[[41,[30,1,[\"href\"]],[[[1,\"          \"],[10,3],[14,0,\"isbf-v2-workbench__card\"],[15,6,[30,1,[\"href\"]]],[12],[1,\"\\n            \"],[10,1],[14,\"aria-hidden\",\"true\"],[15,0,[29,[\"isbf-v2-workbench__icon isbf-v2-workbench__icon--\",[30,1,[\"tone\"]]]]],[12],[1,[28,[32,2],[[30,1,[\"icon\"]]],null]],[13],[1,\"\\n            \"],[10,1],[14,0,\"isbf-v2-workbench__name\"],[12],[1,[30,1,[\"label\"]]],[13],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,0],[14,0,\"isbf-v2-workbench__card\"],[12],[1,\"\\n            \"],[10,1],[14,\"aria-hidden\",\"true\"],[15,0,[29,[\"isbf-v2-workbench__icon isbf-v2-workbench__icon--\",[30,1,[\"tone\"]]]]],[12],[1,[28,[32,2],[[30,1,[\"icon\"]]],null]],[13],[1,\"\\n            \"],[10,1],[14,0,\"isbf-v2-workbench__name\"],[12],[1,[30,1,[\"label\"]]],[13],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]]],[1]],null],[1,\"    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[10,0],[14,0,\"isbf-v2-workbench__more\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-v2-workbench__more-control\"],[12],[1,\"\\n      \"],[8,[32,3],null,[[\"@workbench\"],[true]],null],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"card\"],[\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        dIcon,
        ISBFV2MoreMenu
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-workbench", ISBFV2Workbench);
var Mod7 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2Workbench
});
class ISBFV2Shell extends Component {
  static {
    dt7948.g(this.prototype, "categoryTypeChooser", [service]);
  }
  #categoryTypeChooser = (dt7948.i(this, "categoryTypeChooser"), void 0);
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "isbfBackNavigation", [service]);
  }
  #isbfBackNavigation = (dt7948.i(this, "isbfBackNavigation"), void 0);
  static {
    dt7948.g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (dt7948.i(this, "isbfNotifications"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  get path() {
    return (this.router.currentURL ?? "").split("?")[0];
  }
  get informationPage() {
    return this.path.split("#")[0].match(/^\/(about|faq|guidelines|tos|privacy|rules|conduct)\/?$/)?.[1] ?? null;
  }
  get pageKind() {
    const path = this.path;
    if (/^\/(admin|login|signup|session)(\/|$)/.test(path)) {
      return null;
    }
    const scope = frontendConsistencyScope(this.router.currentRouteName);
    if (/^\/g(\/|$)/.test(path) && scope?.id.startsWith("group")) {
      return "groups";
    }
    if (scope?.id === "search" || scope?.id === "tags") {
      return scope.id;
    }
    if (this.informationPage) {
      return "information";
    }
    if (/^\/t\//.test(path)) {
      return "topic";
    }
    if (path === "/isbf-anonymous/posts") {
      return "anonymous-posts";
    }
    if (path === "/isbf/calendar") {
      return "calendar";
    }
    if (/^\/isbf\/workbench\/resume(?:\/(?:generate|shares(?:\/(?:new|mine|review|\d+))?))?\/?$/.test(path) && this.siteSettings.isbf_resume_enabled) {
      return "resume";
    }
    if (path === "/isbf/workbench") {
      return "workbench";
    }
    if (path === "/isbf/alumni") {
      return "alumni";
    }
    if (path === "/isbf/careers") {
      return "careers";
    }
    if (path === "/isbf/marketplace") {
      return "marketplace";
    }
    if (path === "/isbf/teamup") {
      return "teamup";
    }
    if (path === "/isbf/library") {
      return "library";
    }
    if (path === "/isbf/learning") {
      return "learning";
    }
    if (/^\/u\/[^/]+\/notifications(\/|$)/.test(path)) {
      return "notifications";
    }
    if (/^\/u\/[^/]+\/activity\/bookmarks(\/|$)/.test(path)) {
      return "bookmarks";
    }
    if (/^\/u\/?$/.test(path)) {
      return "directory";
    }
    if (/^\/u\//.test(path)) {
      return "profile";
    }
    if (/^\/badges(\/|$)/.test(path)) {
      return "badges";
    }
    if (this.#isOfficialPath(path) || this.isFeedback) {
      return "feed";
    }
    if (/^\/(search|categories|c|tag|tags)(\/|$)/.test(path)) {
      return "explore";
    }
    if (/^\/(|latest|hot|top|new|unread|following|filter)(\/|$)/.test(path)) {
      return "feed";
    }
    return null;
  }
  get isFeed() {
    return this.pageKind === "feed";
  }
  get feedbackCategory() {
    return feedbackCategory(this.site, settings.feedback_category_id);
  }
  get isFeedback() {
    return isFeedbackPath(this.path, this.feedbackCategory);
  }
  get composePrompt() {
    return i18n(themePrefix(this.isFeedback ? "isbf_v2.feedback_prompt" : "isbf_v2.compose_prompt"));
  }
  get canCreateExploreCategory() {
    return Boolean(this.currentUser?.admin || this.currentUser?.moderator && this.siteSettings.moderators_manage_categories);
  }
  get showCustomExplore() {
    return this.path.replace(/\/$/, "") === "/categories" && this.siteSettings.isbf_explore_enabled;
  }
  get isNotifications() {
    return this.pageKind === "notifications";
  }
  get showGroupedNotifications() {
    return notificationsEnabled(this.path, this.currentUser, this.siteSettings);
  }
  get isAnonymousPosts() {
    return this.pageKind === "anonymous-posts";
  }
  get isCalendar() {
    return this.pageKind === "calendar";
  }
  get isWorkbench() {
    return ["workbench", "resume", "learning", "library", "alumni", "marketplace", "careers", "teamup"].includes(this.pageKind);
  }
  get isWorkbenchHome() {
    return this.pageKind === "workbench";
  }
  get isAlumni() {
    return this.pageKind === "alumni";
  }
  get isCareers() {
    return this.pageKind === "careers";
  }
  get isMarketplace() {
    return this.pageKind === "marketplace";
  }
  get isTeamup() {
    return this.pageKind === "teamup";
  }
  get isLibrary() {
    return this.pageKind === "library";
  }
  get isLearning() {
    return this.pageKind === "learning";
  }
  get showPageHeader() {
    return !this.isFeed && !["alumni", "calendar", "explore", "learning", "library", "marketplace", "careers", "notifications", "teamup", "workbench", "resume"].includes(this.pageKind);
  }
  get showSectionHeading() {
    return !this.showGroupedNotifications && ["bookmarks", "explore", "notifications"].includes(this.pageKind);
  }
  get showRightRail() {
    return settings.show_right_rail && !this.isCalendar && !this.isWorkbench && !this.isAnonymousPosts;
  }
  get isOwnProfile() {
    if (this.pageKind !== "profile" || !this.currentUser) {
      return false;
    }
    const profilePath = `/u/${encodeURIComponent(this.currentUser.username)}`.toLowerCase();
    const path = this.path.toLowerCase();
    return path === profilePath || path.startsWith(`${profilePath}/`);
  }
  get pageTitle() {
    if (this.informationPage) {
      return i18n(this.informationPage === "about" ? "about.simple_title" : this.informationPage);
    }
    if (this.pageKind === "badges") {
      return i18n("badges.title");
    }
    if (this.pageKind === "directory") {
      return i18n("directory.title");
    }
    const frontendTitles = {
      groups: "groups.index.all",
      search: "search.full_page_title",
      tags: "tagging.tags"
    };
    if (frontendTitles[this.pageKind]) {
      return i18n(frontendTitles[this.pageKind]);
    }
    const titles = {
      "anonymous-posts": "my_anonymous_posts",
      bookmarks: "bookmarks",
      calendar: "calendar",
      explore: "explore",
      notifications: "notifications",
      profile: "profile",
      topic: "topic",
      workbench: "workbench"
    };
    return i18n(themePrefix("isbf_v2." + titles[this.pageKind]));
  }
  get latestActive() {
    return this.path === "/" || this.path.startsWith("/latest");
  }
  get officialActive() {
    return this.#isOfficialPath(this.path);
  }
  get officialConfig() {
    return officialConfig(this.site);
  }
  get showOfficialFeed() {
    return this.officialActive && Boolean(this.officialConfig);
  }
  get canCompose() {
    if (this.isFeedback) {
      return !this.currentUser || this.feedbackCategory.canCreateTopic;
    }
    if (!this.officialActive) {
      return true;
    }
    return Boolean(this.currentUser?.academy_official_member && this.officialCategory?.canCreateTopic);
  }
  get officialCategory() {
    const categoryId = this.officialConfig?.category_id ?? Number(settings.official_path.split("/")[3]);
    return this.site.categories?.find(item => Number(item.id) === Number(categoryId));
  }
  get showMobileCompose() {
    return this.isFeed && this.canCompose;
  }
  get showMobileReview() {
    return this.isFeed && (this.latestActive || this.officialActive) && Boolean(this.currentUser?.can_review);
  }
  get composeHref() {
    if (this.isFeedback) {
      return feedbackComposeHref(this.feedbackCategory);
    }
    const categorySlug = settings.official_path.split("/")[2];
    return this.officialActive ? `/new-topic?category=${encodeURIComponent(categorySlug)}` : "/new-topic";
  }
  get topicController() {
    return getOwner(this).lookup("controller:topic");
  }
  get topicFeedStyle() {
    return isFeedStyleTopic(this.topicController.get("model"), this.path) || this.topicConversations;
  }
  get topicConversations() {
    return isConversationTopic(this.topicController.get("model"), this.path, this.siteSettings);
  }
  get shellClass() {
    const classes = ["isbf-v2-shell", `isbf-v2-shell--${this.pageKind}`];
    if (this.topicFeedStyle) {
      classes.push("isbf-v2-shell--topic-feed-style");
      if (this.topicConversations) {
        classes.push("isbf-v2-shell--topic-conversations");
      }
      if (this.topicController.get("editingTopic")) {
        classes.push("isbf-v2-shell--topic-editing");
      }
    }
    if (!this.isFeed && !this.showPageHeader) {
      classes.push("isbf-v2-shell--no-page-header");
    }
    if (this.showGroupedNotifications) {
      classes.push("isbf-v2-shell--grouped-notifications");
    }
    if (this.showCustomExplore) {
      classes.push("isbf-v2-shell--custom-explore");
    }
    if (this.showSectionHeading) {
      classes.push("isbf-v2-shell--section-heading");
    }
    if (this.showOfficialFeed) {
      classes.push("isbf-v2-shell--official-filtered");
    }
    if (this.officialActive) {
      classes.push("isbf-v2-shell--official");
    }
    if (this.isFeedback) {
      classes.push("isbf-v2-shell--feedback");
    }
    if (!this.canCompose) {
      classes.push("isbf-v2-shell--no-compose");
    }
    return classes.join(" ");
  }
  get profileHref() {
    return this.currentUser ? "/u/" + this.currentUser.username : "/login";
  }
  get notificationsHref() {
    return this.currentUser ? "/u/" + this.currentUser.username + "/notifications" : "/login";
  }
  get backHref() {
    return this.isbfBackNavigation.href("/latest");
  }
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }
  static {
    dt7948.n(this.prototype, "goBack", [action]);
  }
  openComposer(event) {
    if (!this.officialActive || !this.currentUser || event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
      return;
    }
    event.preventDefault();
    if (!this.canCompose) {
      return;
    }
    const category = this.officialCategory;
    return this.composer.openNewTopic({
      category
    }).then(result => {
      const model = this.composer.model;
      if (!this.isDestroying && model?.creatingTopic && Number(model.categoryId) === Number(category.id)) {
        this.composer.set("readOnlyCategoryId", category.id);
      }
      return result;
    });
  }
  static {
    dt7948.n(this.prototype, "openComposer", [action]);
  }
  createExploreCategory() {
    if (this.canCreateExploreCategory) {
      this.categoryTypeChooser.createCategory();
    }
  }
  static {
    dt7948.n(this.prototype, "createExploreCategory", [action]);
  }
  #isOfficialPath(path) {
    const categoryPath = settings.official_path.split("/l/")[0];
    return path === categoryPath || path.startsWith(`${categoryPath}/`);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.pageKind}}
      <div class={{this.shellClass}}>
        <ISBFV2SideNav />
        {{#if this.showRightRail}}<ISBFV2RightRail />{{/if}}
    
        {{#if this.isFeed}}
          {{#if this.isFeedback}}
            <header class="isbf-v2-feedback-header">
              <h1>{{i18n (themePrefix "isbf_v2.feedback")}}</h1>
            </header>
          {{else}}
            <header class="isbf-v2-feed-header">
              <div class="isbf-v2-feed-header__title">
                {{#if this.currentUser}}
                  <a
                    aria-label={{i18n (themePrefix "isbf_v2.profile")}}
                    class="isbf-v2-feed-header__avatar isbf-avatar"
                    href={{this.profileHref}}
                  >{{dAvatar this.currentUser imageSize="small"}}<PluginOutlet
                      @name="user-avatar-frame"
                      @outletArgs={{lazyHash
                        user=this.currentUser
                        motion="static"
                      }}
                    /></a>
                {{/if}}
                <span>{{i18n (themePrefix "isbf_v2.home")}}</span>
                <ISBFV2Brand
                  class="isbf-v2-feed-header__brand"
                  @mobile={{true}}
                />
                <a
                  aria-label={{i18n (themePrefix "isbf_v2.search")}}
                  class="isbf-v2-feed-header__search"
                  href="/search"
                >{{dIcon "magnifying-glass"}}</a>
              </div>
              <nav aria-label={{i18n (themePrefix "isbf_v2.feed_label")}}>
                <a
                  aria-current={{if this.latestActive "page"}}
                  class={{if this.latestActive "is-active"}}
                  href="/latest"
                >{{i18n (themePrefix "isbf_v2.latest")}}</a>
                <a
                  aria-current={{if this.officialActive "page"}}
                  class={{if this.officialActive "is-active"}}
                  href={{settings.official_path}}
                >{{i18n (themePrefix "isbf_v2.official")}}</a>
              </nav>
            </header>
          {{/if}}
    
          {{#if this.canCompose}}
            <div class="isbf-v2-compose">
              {{#if this.currentUser}}
                <a
                  aria-label={{this.currentUser.username}}
                  class="isbf-v2-compose__avatar isbf-avatar"
                  href={{this.profileHref}}
                >{{dAvatar this.currentUser imageSize="large"}}<PluginOutlet
                    @name="user-avatar-frame"
                    @outletArgs={{lazyHash
                      user=this.currentUser
                      motion="static"
                    }}
                  /></a>
              {{/if}}
              <a
                class="isbf-v2-compose__prompt"
                href={{this.composeHref}}
                {{on "click" this.openComposer}}
              >{{this.composePrompt}}</a>
              <a
                class="isbf-v2-compose__button"
                href={{this.composeHref}}
                {{on "click" this.openComposer}}
              >{{i18n (themePrefix "isbf_v2.compose")}}</a>
            </div>
          {{/if}}
        {{else if this.showPageHeader}}
          <header class="isbf-v2-page-header">
            <a
              aria-label={{i18n "back_button"}}
              class="isbf-v2-page-header__back"
              href={{this.backHref}}
              {{on "click" this.goBack}}
            >{{dIcon "arrow-left"}}</a>
            <span>{{this.pageTitle}}</span>
            {{#if this.isOwnProfile}}<ISBFV2AccountMenu
                @mobile={{true}}
              />{{/if}}
          </header>
        {{/if}}
    
        {{#if this.showSectionHeading}}
          <header class="isbf-v2-section-heading">
            <h1>{{this.pageTitle}}</h1>
          </header>
        {{/if}}
    
        {{#if this.showGroupedNotifications}}<ISBFNotifications />{{/if}}
    
        {{#if this.showCustomExplore}}<ISBFExplore
            @canCreateCategory={{this.canCreateExploreCategory}}
            @onCreateCategory={{this.createExploreCategory}}
          />{{/if}}
    
        {{#if this.showOfficialFeed}}<ISBFOfficialFeed
            @config={{this.officialConfig}}
          />{{/if}}
    
        {{#if this.isAnonymousPosts}}<ISBFV2AnonymousPosts />{{/if}}
        {{#if this.isCalendar}}<ISBFV2Calendar />{{/if}}
        {{#if this.isAlumni}}<ISBFAlumni />
        {{else if this.isCareers}}<ISBFCareers />
        {{else if this.isMarketplace}}<ISBFMarketplace />
        {{else if this.isTeamup}}<ISBFTeamup />
        {{else if this.isLibrary}}<ISBFLibrary />
        {{else if this.isLearning}}<ISBFLearning />
        {{else if this.isWorkbenchHome}}<ISBFV2Workbench />{{/if}}
    
        {{#if this.showMobileCompose}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.compose")}}
            class="isbf-v2-mobile-compose"
            href={{this.composeHref}}
            {{on "click" this.openComposer}}
          >{{dIcon "plus"}}</a>
        {{/if}}
    
        {{#if this.showMobileReview}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.review")}}
            class="isbf-v2-mobile-review"
            href="/review"
          >{{i18n (themePrefix "isbf_v2.review")}}</a>
        {{/if}}
    
        <nav
          aria-label={{i18n (themePrefix "isbf_v2.quick_label")}}
          class="isbf-v2-mobile-nav"
        >
          <a
            aria-current={{if this.isFeed "page"}}
            class={{if this.isFeed "is-active"}}
            href="/latest"
          >{{dIcon "house"}}<span>{{i18n
                (themePrefix "isbf_v2.home")
              }}</span></a>
          <a
            aria-current={{if this.isNotifications "page"}}
            aria-label={{this.isbfNotifications.linkLabel}}
            class={{if this.isNotifications "is-active"}}
            href={{this.notificationsHref}}
          ><ISBFNotificationBell /><span>{{i18n
                (themePrefix "isbf_v2.notifications")
              }}</span></a>
          <a
            aria-current={{if this.isCalendar "page"}}
            class={{if this.isCalendar "is-active"}}
            href="/isbf/calendar"
          >{{dIcon "calendar-days"}}<span>{{i18n
                (themePrefix "isbf_v2.calendar")
              }}</span></a>
          <a
            aria-current={{if this.isWorkbench "page"}}
            class={{if this.isWorkbench "is-active"}}
            href="/isbf/workbench"
          >{{dIcon "table-cells-large"}}<span>{{i18n
                (themePrefix "isbf_v2.workbench")
              }}</span></a>
        </nav>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"pageKind\"]],[[[1,\"  \"],[10,0],[15,0,[30,0,[\"shellClass\"]]],[12],[1,\"\\n    \"],[8,[32,0],null,null,null],[1,\"\\n    \"],[41,[30,0,[\"showRightRail\"]],[[[8,[32,1],null,null,null]],[]],null],[1,\"\\n\\n\"],[41,[30,0,[\"isFeed\"]],[[[41,[30,0,[\"isFeedback\"]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feedback-header\"],[12],[1,\"\\n          \"],[10,\"h1\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.feedback\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feed-header\"],[12],[1,\"\\n          \"],[10,0],[14,0,\"isbf-v2-feed-header__title\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"              \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.profile\"],null]],null]],[14,0,\"isbf-v2-feed-header__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"small\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,7],[[24,0,\"isbf-v2-feed-header__brand\"]],[[\"@mobile\"],[true]],null],[1,\"\\n            \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.search\"],null]],null]],[14,0,\"isbf-v2-feed-header__search\"],[14,6,\"/search\"],[12],[1,[28,[32,8],[\"magnifying-glass\"],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n          \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.feed_label\"],null]],null]],[12],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"latestActive\"]],\"page\"]],[15,0,[52,[30,0,[\"latestActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.latest\"],null]],null]],[13],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"officialActive\"]],\"page\"]],[15,0,[52,[30,0,[\"officialActive\"]],\"is-active\"]],[15,6,[32,9,[\"official_path\"]]],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official\"],null]],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[30,0,[\"canCompose\"]],[[[1,\"        \"],[10,0],[14,0,\"isbf-v2-compose\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"            \"],[10,3],[15,\"aria-label\",[30,0,[\"currentUser\",\"username\"]]],[14,0,\"isbf-v2-compose__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"large\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[11,3],[24,0,\"isbf-v2-compose__prompt\"],[16,6,[30,0,[\"composeHref\"]]],[4,[32,10],[\"click\",[30,0,[\"openComposer\"]]],null],[12],[1,[30,0,[\"composePrompt\"]]],[13],[1,\"\\n          \"],[11,3],[24,0,\"isbf-v2-compose__button\"],[16,6,[30,0,[\"composeHref\"]]],[4,[32,10],[\"click\",[30,0,[\"openComposer\"]]],null],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null]],[]],[[[41,[30,0,[\"showPageHeader\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-page-header\"],[12],[1,\"\\n        \"],[11,3],[16,\"aria-label\",[28,[32,2],[\"back_button\"],null]],[24,0,\"isbf-v2-page-header__back\"],[16,6,[30,0,[\"backHref\"]]],[4,[32,10],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,[28,[32,8],[\"arrow-left\"],null]],[13],[1,\"\\n        \"],[10,1],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n        \"],[41,[30,0,[\"isOwnProfile\"]],[[[8,[32,11],null,[[\"@mobile\"],[true]],null]],[]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"]],[]],null]],[]]],[1,\"\\n\"],[41,[30,0,[\"showSectionHeading\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-section-heading\"],[12],[1,\"\\n        \"],[10,\"h1\"],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"showGroupedNotifications\"]],[[[8,[32,12],null,null,null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showCustomExplore\"]],[[[8,[32,13],null,[[\"@canCreateCategory\",\"@onCreateCategory\"],[[30,0,[\"canCreateExploreCategory\"]],[30,0,[\"createExploreCategory\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showOfficialFeed\"]],[[[8,[32,14],null,[[\"@config\"],[[30,0,[\"officialConfig\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"isAnonymousPosts\"]],[[[8,[32,15],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isCalendar\"]],[[[8,[32,16],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isAlumni\"]],[[[8,[32,17],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isCareers\"]],[[[8,[32,18],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isMarketplace\"]],[[[8,[32,19],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isTeamup\"]],[[[8,[32,20],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isLibrary\"]],[[[8,[32,21],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isLearning\"]],[[[8,[32,22],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isWorkbenchHome\"]],[[[8,[32,23],null,null,null]],[]],null]],[]]]],[]]]],[]]]],[]]]],[]]]],[]]],[1,\"\\n\"],[41,[30,0,[\"showMobileCompose\"]],[[[1,\"      \"],[11,3],[16,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[24,0,\"isbf-v2-mobile-compose\"],[16,6,[30,0,[\"composeHref\"]]],[4,[32,10],[\"click\",[30,0,[\"openComposer\"]]],null],[12],[1,[28,[32,8],[\"plus\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"showMobileReview\"]],[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-mobile-review\"],[14,6,\"/review\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.quick_label\"],null]],null]],[14,0,\"isbf-v2-mobile-nav\"],[12],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isFeed\"]],\"page\"]],[15,0,[52,[30,0,[\"isFeed\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,8],[\"house\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isNotifications\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"isNotifications\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,24],null,null,null],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isCalendar\"]],\"page\"]],[15,0,[52,[30,0,[\"isCalendar\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,8],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isWorkbench\"]],\"page\"]],[15,0,[52,[30,0,[\"isWorkbench\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,8],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFV2SideNav,
        ISBFV2RightRail,
        i18n,
        themePrefix,
        dAvatar,
        PluginOutlet,
        lazyHash,
        ISBFV2Brand,
        dIcon,
        settings,
        on,
        ISBFV2AccountMenu,
        ISBFNotifications: ISBFNotifications$1,
        ISBFExplore,
        ISBFOfficialFeed,
        ISBFV2AnonymousPosts,
        ISBFV2Calendar,
        ISBFAlumni,
        ISBFCareers,
        ISBFMarketplace,
        ISBFTeamup,
        ISBFLibrary: __discourseComponentClass$2,
        ISBFLearning: ISBFResourcePage,
        ISBFV2Workbench,
        ISBFNotificationBell
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-shell", ISBFV2Shell);
var Mod3 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2Shell
});
function focusComposer() {
  document.querySelector("#reply-control.open.composer-action-create-topic .d-editor-input")?.focus();
}
var isbfCampusFeed = apiInitializer(api => {
  api.modifyClass("controller:user", {
    pluginId: "isbf-ui-profile-expanded",
    forceExpand: true
  });
  api.modifyClass("component:post-list/item", Superclass => class ISBFActivityPostListItem extends Superclass {
    static {
      dt7948.g(this.prototype, "router", [service]);
    }
    #router = (dt7948.i(this, "router"), void 0);
    get itemClasses() {
      return dConcatClass(super.itemClasses, this.args.additionalItemClasses === "user-stream-item" && isActivityPreview(this.args.post, this.router.currentURL) && "isbf-activity-item");
    }
  });
  api.renderInOutlet("user-stream-item-above", ISBFActivityPreview);
  api.renderInOutlet("user-summary-topic-title", ISBFSummaryTopicTitle);
  Composer.serializeOnCreate("isbf_repost_source_topic_id", "isbf_repost_source_topic_id");
  Composer.serializeToDraft("isbf_repost_source_topic_id", "isbf_repost_source_topic_id");
  Composer.serializeOnCreate("isbf_anonymous", "isbf_anonymous");
  Composer.serializeToDraft("isbf_anonymous", "isbf_anonymous");
  api.renderInOutlet("before-main-outlet", ISBFV2Shell);
  api.renderInOutlet("before-composer-controls", ISBFV2ComposerCancel);
  api.renderInOutlet("before-composer-fields", ISBFV2ComposerOptions);
  api.renderInOutlet("composer-fields", ISBFV2ComposerTitle);
  api.customizeComposerText({
    titlePlaceholder: model => isQuickPost(model) ? themePrefix("isbf_v2.optional_title") : null,
    actionTitle: model => isQuickPost(model) ? i18n(themePrefix("isbf_v2.quick_post")) : null,
    saveLabel: model => isQuickPost(model) ? themePrefix("isbf_v2.compose") : null
  });
  api.onAppEvent("composer:category-changed", model => {
    if (model.isbf_anonymous && !canPublishAnonymously(model, api.container.lookup("service:current-user"), api.container.lookup("service:site-settings"))) {
      model.set("isbf_anonymous", false);
    }
  });
  api.onAppEvent("composer:opened", () => {
    const model = api.container.lookup("service:composer").model;
    if (isQuickPost(model)) {
      prepareOptionalTopicTitle(model);
    }
    scheduleOnce("afterRender", focusComposer);
  });
  api.registerValueTransformer("composer-editor-reply-placeholder", ({
    value,
    context
  }) => {
    const model = context?.model?.model;
    return isQuickPost(model) && !model.requiredCategoryMissing ? themePrefix("isbf_v2.compose_prompt") : value;
  });
  api.registerValueTransformer("topic-list-class", ({
    value,
    context
  }) => {
    const listContext = context?.listContext;
    if (listContext !== "discovery" && listContext !== "suggested") {
      return value;
    }
    return [...value, "isbf-v2-topic-list", `--${listContext}`];
  });
  api.registerValueTransformer("topic-list-item-mobile-layout", ({
    value,
    context
  }) => context?.listContext === "discovery" ? true : value);
  api.registerValueTransformer("topic-list-item-class", ({
    value,
    context
  }) => {
    if (context?.listContext !== "discovery") {
      return value;
    }
    return value.includes("isbf-v2-topic") ? value : [...value, "isbf-v2-topic"];
  });
  api.registerValueTransformer("topic-list-item-expand-pinned", ({
    value,
    context
  }) => context?.listContext === "discovery" ? true : value);
});
var Mod1 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfCampusFeed
});
function quickPostText(reply) {
  const withoutQuotes = (reply ?? "").replace(/\[quote(?:=[^\]]+)?\][\s\S]*?\[\/quote\]/gi, " ");
  return withoutQuotes.replace(/!\[[^\]]*\]\([^)]+\)/g, "图片").replace(/\[([^\]]+)\]\([^)]+\)/g, "$1").replace(/https?:\/\/\S+/g, "链接").replace(/<[^>]+>/g, " ").replace(/[#>*_~`|]/g, " ").replace(/\s+/g, " ").trim();
}
function quickPostTitle(reply, minimumLength, maximumLength) {
  if (!reply?.trim()) {
    return "";
  }
  const text = quickPostText(reply);
  const minimum = Math.max(1, Number(minimumLength) || 1);
  const maximum = Math.max(minimum, Number(maximumLength) || 255);
  const limit = Math.min(maximum, 80);
  let title = (text || "引用转发").slice(0, limit);
  if (title.length < minimum) {
    title = `校园动态：${title}`.slice(0, maximum);
  }
  if (title.length < minimum) {
    const timestamp = new Date().toISOString().slice(0, 16).replace("T", " ");
    title = `${title} · ${timestamp} · 国金综合平台`.slice(0, maximum);
  }
  return title;
}
var Mod5 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  quickPostText: quickPostText,
  quickPostTitle: quickPostTitle
});
class ISBFFeedCardConnector extends Component {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get shouldRenderCard() {
    if (this.args.outletArgs.bulkSelectEnabled) {
      return false;
    }
    const path = (this.router.currentURL ?? "").split("?")[0];
    const officialPath = settings.official_path.split("/l/")[0];
    return path === "/" || path.startsWith("/latest") || isFeedbackPath(path, feedbackCategory(this.site, settings.feedback_category_id)) || path === officialPath || path.startsWith(`${officialPath}/`);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.shouldRenderCard}}
      <td class="isbf-feed-card-cell" colspan="6"><ISBFV2FeedCard
          @navigateToTopic={{@outletArgs.navigateToTopic}}
          @topic={{@outletArgs.topic}}
        /></td>
    {{else}}
      {{yield}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"shouldRenderCard\"]],[[[1,\"  \"],[10,\"td\"],[14,0,\"isbf-feed-card-cell\"],[14,\"colspan\",\"6\"],[12],[8,[32,0],null,[[\"@navigateToTopic\",\"@topic\"],[[30,1,[\"navigateToTopic\"]],[30,1,[\"topic\"]]]],null],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[18,2,null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&default\"],[\"if\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFV2FeedCard
      }),
      "isStrictMode": true
    }), this);
  }
}
var Mod13 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFFeedCardConnector
});
let ISBFTopicMore$1 = class ISBFTopicMore extends Component {
  static {
    dt7948.g(this.prototype, "site", [service]);
  }
  #site = (dt7948.i(this, "site"), void 0);
  get secondaryActions() {
    return (this.args.outletArgs.buttons ?? []).filter(button => button.id === "flag" || button.id === "defer");
  }
  get showMenu() {
    return this.site.desktopView && !this.args.outletArgs.topic?.is_nested_view && this.secondaryActions.length > 0;
  }
  async selectAction(button, menu) {
    await menu.close();
    return button.action();
  }
  static {
    dt7948.n(this.prototype, "selectAction", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.showMenu}}
      <DMenu
        class="isbf-v2-topic-more"
        @icon="ellipsis"
        @identifier="isbf-v2-topic-more"
        @label={{i18n "more"}}
        @modalForMobile={{true}}
        @triggerClass="btn-default topic-footer-button"
      >
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each this.secondaryActions key="id" as |button|}}
              <dropdown.item>
                <DButton
                  @action={{fn this.selectAction button menu}}
                  @disabled={{button.disabled}}
                  @icon={{button.icon}}
                  @translatedLabel={{button.label}}
                  @translatedTitle={{button.title}}
                />
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"showMenu\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"isbf-v2-topic-more\"]],[[\"@icon\",\"@identifier\",\"@label\",\"@modalForMobile\",\"@triggerClass\"],[\"ellipsis\",\"isbf-v2-topic-more\",[28,[32,1],[\"more\"],null],true,\"btn-default topic-footer-button\"]],[[\"content\"],[[[[1,\"\\n      \"],[8,[32,2],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"secondaryActions\"]]],null]],null],\"id\",[[[1,\"          \"],[8,[30,2,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,3],null,[[\"@action\",\"@disabled\",\"@icon\",\"@translatedLabel\",\"@translatedTitle\"],[[28,[32,4],[[30,0,[\"selectAction\"]],[30,3],[30,1]],null],[30,3,[\"disabled\"]],[30,3,[\"icon\"]],[30,3,[\"label\"]],[30,3,[\"title\"]]]],null],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[3]],null],[1,\"      \"]],[2]]]]],[1,\"\\n    \"]],[1]]]]],[1,\"\\n\"]],[]],null]],[\"menu\",\"dropdown\",\"button\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        DDropdownMenu,
        DButton,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
};
var Mod17 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTopicMore$1
});
var isbfNotifications$1 = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.container.lookup("service:current-user");
  const appEvents = api.container.lookup("service:app-events");
  router.on("routeWillChange", transition => {
    const name = transition.to?.name;
    if (!siteSettings.isbf_notifications_enabled || !currentUser || !name?.startsWith("userNotifications.") || name === "userNotifications.index") {
      return;
    }
    const userRoute = transition.to.find(route => Boolean(route.params.username));
    const username = userRoute?.params.username;
    if (username?.toLowerCase() !== currentUser.username.toLowerCase()) {
      return;
    }
    const child = name.split(".").pop();
    const tab = ["mentions", "responses", "reactionsReceived"].includes(child) ? "mentions" : "all";
    setInitialNotificationTab(tab);
    appEvents.trigger("isbf:notification-tab", tab);
    transition.abort();
    router.replaceWith(`/u/${encodeURIComponent(username)}/notifications`);
  });
  api.modifyClass("route:user-notifications", {
    pluginId: "isbf-notification-groups",
    model() {
      const username = this.modelFor("user").get("username");
      if (siteSettings.isbf_notifications_enabled && currentUser?.username?.toLowerCase() === username.toLowerCase()) {
        return {
          content: [],
          loading: false,
          loadingMore: false,
          loadMore() {}
        };
      }
      return this._super(...arguments);
    }
  });
});
var Mod19 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfNotifications$1
});
class ReplyNavigation {
  static {
    dt7948.g(this.prototype, "currentIndex", [tracked], function () {
      return 1;
    });
  }
  #currentIndex = (dt7948.i(this, "currentIndex"), void 0);
  static {
    dt7948.g(this.prototype, "lastReadIndex", [tracked], function () {
      return 0;
    });
  }
  #lastReadIndex = (dt7948.i(this, "lastReadIndex"), void 0);
  static {
    dt7948.g(this.prototype, "metadata", [tracked]);
  }
  #metadata = (dt7948.i(this, "metadata"), void 0);
  #appEvents;
  #entries = new Map();
  #generation = 0;
  #topic;
  #destroyed = false;
  constructor(topic, appEvents) {
    this.#topic = topic;
    this.#appEvents = appEvents;
    this.metadata = topic.reply_navigation || {
      root_count: 0,
      reply_count: 0
    };
    this.currentIndex = this.metadata.root_index || 1;
    for (const post of topic.postStream.posts) {
      if (post.root_index) {
        this.#entries.set(post.root_index, {
          root_post_number: post.post_number,
          root_created_at: post.created_at
        });
      }
    }
    if (topic.last_read_post_number > 1) {
      this.#fetch({
        post_number: topic.last_read_post_number
      }).then(data => {
        if (!this.#destroyed) {
          this.lastReadIndex = data.root_index;
          this.notify();
        }
      }).catch(() => {});
    }
  }
  get total() {
    return (this.#topic.reply_navigation || this.metadata).root_count;
  }
  get loadedAllPosts() {
    return true;
  }
  dateForIndex(index) {
    const date = this.#entries.get(index)?.root_created_at || this.#topic.postStream.posts.find(post => post.root_index === index)?.created_at;
    return date ? new Date(date) : null;
  }
  destroy() {
    this.#destroyed = true;
    this.#generation++;
  }
  excerpt() {
    return Promise.resolve(null);
  }
  label(index = this.currentIndex) {
    return i18n(themePrefix("isbf_v2.reply_conversations.progress"), {
      current: Math.min(index, this.total),
      total: this.total
    });
  }
  notify(index = this.currentIndex) {
    this.currentIndex = index;
    this.#appEvents.trigger("topic:group-scrolled", {
      postIndex: index,
      percent: index >= this.total ? 1 : (index - 1) / Math.max(this.total, 1)
    });
  }
  async jumpToIndex(index) {
    const generation = ++this.#generation;
    const data = await this.#fetch({
      root_index: index
    });
    if (this.#destroyed || generation !== this.#generation) {
      return;
    }
    this.jumpToPostNumber(data.root_post_number);
  }
  jumpToPostNumber(postNumber) {
    if (postNumber && !this.#destroyed) {
      DiscourseURL.routeTo(`${this.#topic.url}/${postNumber}`);
    }
  }
  async #fetch(query) {
    const data = await ajax(`/n/${this.#topic.slug}/${this.#topic.id}/navigation.json`, {
      data: query
    });
    if (!this.#destroyed) {
      this.#entries.set(data.root_index, data);
    }
    return data;
  }
}
var Mod160 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ReplyNavigation
});
class ISBFCloseOnClickOutside extends DCloseOnClickOutside {
  modify(element, args) {
    this.cleanup();
    super.modify(element, args);
    document.removeEventListener("pointerdown", this.check);

    // Dismiss before the native navigation queues a delayed close.
    document.addEventListener("pointerdown", this.check, {
      capture: true,
      passive: true
    });
  }
  cleanup() {
    super.cleanup();
    document.removeEventListener("pointerdown", this.check, true);
  }
}
var Mod139 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCloseOnClickOutside
});
function isReadingTopic(topic) {
  return !EmbedMode.enabled && topic?.archetype === "regular" && !topic.is_nested_view;
}
class ISBFTopicReading extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "menu", [service]);
  }
  #menu = (dt7948.i(this, "menu"), void 0);
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  static {
    dt7948.g(this.prototype, "hasProgress", [tracked], function () {
      return false;
    });
  }
  #hasProgress = (dt7948.i(this, "hasProgress"), void 0);
  static {
    dt7948.g(this.prototype, "header", [tracked], function () {
      return null;
    });
  }
  #header = (dt7948.i(this, "header"), void 0);
  syncLayout = modifier(element => {
    const navigation = element.closest(".topic-navigation");
    const posts = navigation?.closest(".container.posts, .nested-view");
    const header = document.querySelector(".isbf-v2-shell--topic-feed-style .isbf-v2-page-header");
    if (!navigation || !posts || !header) {
      return;
    }
    let frame;
    navigation.classList.add("isbf-topic-reading");
    posts.classList.add("has-isbf-topic-reading");
    const update = () => {
      // The navigation's class binding can overwrite the outlet's classes.
      navigation.classList.add("isbf-topic-reading");
      posts.classList.add("has-isbf-topic-reading");
      if (this.header !== header) {
        this.header = header;
      }
      const area = navigation.querySelector(".timeline-scrollarea-wrapper");
      const hasProgress = Boolean(area || navigation.querySelector("#topic-progress:not(.hidden)"));
      if (this.hasProgress !== hasProgress) {
        this.hasProgress = hasProgress;
      }
      if (this.#needsInitialCollapse) {
        this.#needsInitialCollapse = false;
        this.#closeProgress();
      }
    };
    const scheduleLayout = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    const observer = new ResizeObserver(scheduleLayout);
    observer.observe(navigation);
    document.addEventListener("keydown", this.onKeyDown);
    navigation.addEventListener("swipestart", this.#cancelSheetSwipe, true);
    navigation.addEventListener("swipecancel", this.#cancelSheetSwipe, true);
    scheduleLayout();
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      document.removeEventListener("keydown", this.onKeyDown);
      navigation.removeEventListener("swipestart", this.#cancelSheetSwipe, true);
      navigation.removeEventListener("swipecancel", this.#cancelSheetSwipe, true);
      navigation.classList.remove("isbf-topic-reading");
      posts.classList.remove("has-isbf-topic-reading");
    };
  });
  #cancelSheetSwipe = event => {
    event.preventDefault();
    event.stopImmediatePropagation();
  };
  // The navigation can survive a topic change while this outlet is recreated.
  #needsInitialCollapse = this.args.outletArgs.topicProgressExpanded;
  get isReadingTopic() {
    return isReadingTopic(this.args.outletArgs.topic) || Boolean(this.args.outletArgs.navigation);
  }
  get progressLabel() {
    if (this.args.outletArgs.navigation) {
      return this.args.outletArgs.navigation.label();
    }
    const topic = this.args.outletArgs.topic;
    const controller = getOwner(this).lookup("controller:topic");
    return i18n("topic.timeline.replies_short", {
      current: topic.postStream.progressIndexOfPostId({
        id: controller.get("currentPostId"),
        post_number: topic.get("currentPost")
      }) || 1,
      total: topic.postStream.filteredPostsCount
    });
  }
  closeOnClickOutside(event) {
    if (this.modal.activeModal || event.target.closest?.(".select-kit-body, .fk-d-menu, .fk-d-menu-modal")) {
      return;
    }
    this.#closeProgress();
  }
  static {
    dt7948.n(this.prototype, "closeOnClickOutside", [action]);
  }
  closeProgress() {
    this.#closeProgress();
    schedule("afterRender", () => {
      this.header?.querySelector(".isbf-topic-reading__toggle")?.focus();
    });
  }
  static {
    dt7948.n(this.prototype, "closeProgress", [action]);
  }
  onKeyDown(event) {
    if (event.key !== "Escape" || event.defaultPrevented || !this.args.outletArgs.topicProgressExpanded || this.modal.activeModal || [...this.menu.registeredMenus].some(menu => menu.expanded)) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    this.closeProgress();
  }
  static {
    dt7948.n(this.prototype, "onKeyDown", [action]);
  }
  onTogglePointerDown(event) {
    event.stopPropagation();
  }
  static {
    dt7948.n(this.prototype, "onTogglePointerDown", [action]);
  }
  toggleProgress() {
    this.appEvents.trigger("topic:toggle-progress-expansion");
  }
  static {
    dt7948.n(this.prototype, "toggleProgress", [action]);
  }
  #closeProgress() {
    if (this.header?.isConnected && this.args.outletArgs.topicProgressExpanded) {
      this.toggleProgress();
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.isReadingTopic}}
      <header
        class="isbf-topic-reading__heading"
        {{this.syncLayout
          @outletArgs.renderTimeline
          @outletArgs.topicProgressExpanded
        }}
        {{isbfCloseOnClickOutside
          this.closeOnClickOutside
          (hash
            targetSelector=".topic-navigation.isbf-topic-reading"
            secondaryTargetSelector=".isbf-topic-reading__toggle"
          )
        }}
      >
        <h2>{{i18n (themePrefix "isbf_v2.reading_progress")}}</h2>
        {{#if @outletArgs.topicProgressExpanded}}
          <DButton
            class="isbf-topic-reading__close btn-flat"
            @action={{this.closeProgress}}
            @icon="xmark"
            @title="close"
          />
        {{/if}}
      </header>
      {{#if this.header}}
        {{#in-element this.header insertBefore=null}}
          {{#if this.hasProgress}}
            {{! Exclude the detached trigger from native pointer dismissal before click. }}
            {{! eslint-disable ember/template-no-pointer-down-event-binding }}
            <DButton
              class="isbf-topic-reading__toggle"
              @action={{this.toggleProgress}}
              @ariaExpanded={{@outletArgs.topicProgressExpanded}}
              @translatedLabel={{this.progressLabel}}
              @translatedTitle={{i18n (themePrefix "isbf_v2.reading_progress")}}
              {{on "pointerdown" this.onTogglePointerDown}}
            />
            {{! eslint-enable ember/template-no-pointer-down-event-binding }}
          {{/if}}
        {{/in-element}}
      {{/if}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"isReadingTopic\"]],[[[1,\"  \"],[11,\"header\"],[24,0,\"isbf-topic-reading__heading\"],[4,[30,0,[\"syncLayout\"]],[[30,1,[\"renderTimeline\"]],[30,1,[\"topicProgressExpanded\"]]],null],[4,[32,0],[[30,0,[\"closeOnClickOutside\"]],[28,[32,1],null,[[\"targetSelector\",\"secondaryTargetSelector\"],[\".topic-navigation.isbf-topic-reading\",\".isbf-topic-reading__toggle\"]]]],null],[12],[1,\"\\n    \"],[10,\"h2\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.reading_progress\"],null]],null]],[13],[1,\"\\n\"],[41,[30,1,[\"topicProgressExpanded\"]],[[[1,\"      \"],[8,[32,4],[[24,0,\"isbf-topic-reading__close btn-flat\"]],[[\"@action\",\"@icon\",\"@title\"],[[30,0,[\"closeProgress\"]],\"xmark\",\"close\"]],null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[41,[30,0,[\"header\"]],[[[40,[[[41,[30,0,[\"hasProgress\"]],[[[1,\"        \"],[8,[32,4],[[24,0,\"isbf-topic-reading__toggle\"],[4,[32,5],[\"pointerdown\",[30,0,[\"onTogglePointerDown\"]]],null]],[[\"@action\",\"@ariaExpanded\",\"@translatedLabel\",\"@translatedTitle\"],[[30,0,[\"toggleProgress\"]],[30,1,[\"topicProgressExpanded\"]],[30,0,[\"progressLabel\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.reading_progress\"],null]],null]]],null],[1,\"\\n\"]],[]],null]],[]],\"%cursor:0%\",[28,[31,2],[[30,0,[\"header\"]]],null],null]],[]],null]],[]],null]],[\"@outletArgs\"],[\"if\",\"in-element\",\"-in-el-null\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        isbfCloseOnClickOutside: ISBFCloseOnClickOutside,
        hash,
        i18n,
        themePrefix,
        DButton,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFTopicReadingJump extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  get backIndex() {
    if (this.args.outletArgs.navigation) {
      const navigation = this.args.outletArgs.navigation;
      const index = navigation.lastReadIndex;
      return index > navigation.currentIndex + 3 && index > 3 && navigation.total - index > 1 ? index : 0;
    }
    const topic = this.args.outletArgs.model;
    if (!isReadingTopic(topic) || !topic.last_read_post_number) {
      return 0;
    }
    const stream = topic.postStream;
    const lastRead = stream.stream.indexOf(topic.last_read_post_id) + 1;
    const controller = getOwner(this).lookup("controller:topic");
    const current = stream.progressIndexOfPostId({
      id: controller.get("currentPostId"),
      post_number: topic.get("currentPost")
    }) || 1;
    const total = stream.filteredPostsCount;
    return lastRead > 3 && lastRead > current && lastRead - current > 3 && total - lastRead > 1 ? lastRead : 0;
  }
  get showBack() {
    return this.args.outletArgs.fullscreen && this.backIndex > 0;
  }
  get showJump() {
    return (isReadingTopic(this.args.outletArgs.model) || this.args.outletArgs.navigation) && !this.args.outletArgs.fullscreen;
  }
  goBack() {
    if (this.args.outletArgs.navigation) {
      this.args.outletArgs.navigation.jumpToPostNumber(this.args.outletArgs.model.last_read_post_number);
      return;
    }
    if (this.backIndex) {
      getOwner(this).lookup("controller:topic").send("jumpToIndex", this.backIndex);
    }
  }
  static {
    dt7948.n(this.prototype, "goBack", [action]);
  }
  jumpToPost() {
    this.appEvents.trigger("topic:keyboard-trigger", {
      type: "jump"
    });
  }
  static {
    dt7948.n(this.prototype, "jumpToPost", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.showBack}}
      <DButton
        class="isbf-topic-reading__back btn-default"
        @action={{this.goBack}}
        @label="topic.timeline.back"
        @title="topic.timeline.back_description"
      />
    {{/if}}
    {{#if this.showJump}}
      <DButton
        class="isbf-topic-reading__jump"
        @action={{this.jumpToPost}}
        @label="topic.progress.jump_prompt"
      />
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"showBack\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"isbf-topic-reading__back btn-default\"]],[[\"@action\",\"@label\",\"@title\"],[[30,0,[\"goBack\"]],\"topic.timeline.back\",\"topic.timeline.back_description\"]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"showJump\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"isbf-topic-reading__jump\"]],[[\"@action\",\"@label\"],[[30,0,[\"jumpToPost\"]],\"topic.progress.jump_prompt\"]],null],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-topic-reading", ISBFTopicReading);
var Mod37 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFTopicReadingJump: ISBFTopicReadingJump,
  default: ISBFTopicReading
});
class ISBFReplyNavigation extends Component {
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  navigation = isConversationTopic(this.args.outletArgs.topic, this.args.outletArgs.topic.url, this.siteSettings) ? new ReplyNavigation(this.args.outletArgs.topic, this.appEvents) : null;
  trackGroups = modifier(element => {
    let frame;
    const view = element.closest(".nested-view");
    const update = () => {
      const roots = [...(view?.querySelectorAll(".nested-post.--depth-0[data-root-index]") || [])];
      const current = roots.find(root => root.getBoundingClientRect().bottom > 60);
      const index = Number(current?.dataset.rootIndex);
      if (index) {
        this.navigation.notify(index);
      }
    };
    const schedule = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    const observer = new MutationObserver(schedule);
    const roots = view?.querySelector(".nested-view__roots");
    if (roots) {
      observer.observe(roots, {
        childList: true,
        subtree: true
      });
    }
    window.addEventListener("scroll", schedule, {
      passive: true
    });
    schedule();
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      window.removeEventListener("scroll", schedule);
    };
  });
  willDestroy() {
    super.willDestroy(...arguments);
    this.navigation?.destroy();
  }
  get enabled() {
    return isConversationTopic(this.args.outletArgs.topic, this.router.currentURL, this.siteSettings);
  }
  get enteredIndex() {
    return (this.navigation?.currentIndex || 1) - 1;
  }
  get nestedController() {
    return getOwner(this).lookup("controller:nested");
  }
  jumpToIndex(index) {
    this.navigation.jumpToIndex(index).catch(popupAjaxError);
  }
  static {
    dt7948.n(this.prototype, "jumpToIndex", [action]);
  }
  jumpToPost(number) {
    this.navigation.jumpToPostNumber(number);
  }
  static {
    dt7948.n(this.prototype, "jumpToPost", [action]);
  }
  jumpTop(event) {
    event?.preventDefault();
    this.jumpToPost(1);
  }
  static {
    dt7948.n(this.prototype, "jumpTop", [action]);
  }
  jumpEnd(event) {
    event?.preventDefault();
    this.jumpToIndex(this.navigation.total);
  }
  static {
    dt7948.n(this.prototype, "jumpEnd", [action]);
  }
  sendTopicAction(name, ...args) {
    return getOwner(this).lookup("controller:topic").send(name, ...args);
  }
  static {
    dt7948.n(this.prototype, "sendTopicAction", [action]);
  }
  jumpToDate(date) {
    return this.sendTopicAction("jumpToDate", date);
  }
  static {
    dt7948.n(this.prototype, "jumpToDate", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <TopicNavigation
        class="topic-navigation"
        @jumpToDate={{this.jumpToDate}}
        @jumpToIndex={{this.jumpToPost}}
        @postCount={{@outletArgs.topic.highest_post_number}}
        @topic={{@outletArgs.topic}}
        {{this.trackGroups @outletArgs.topic.reply_navigation}}
        as |info|
      >
        <ISBFTopicReading
          @outletArgs={{hash
            topic=@outletArgs.topic
            navigation=this.navigation
            renderTimeline=true
            topicProgressExpanded=info.topicProgressExpanded
          }}
        />
        <TopicTimeline
          @convertToPrivateMessage={{fn
            this.sendTopicAction
            "convertToPrivateMessage"
          }}
          @convertToPublicTopic={{fn
            this.sendTopicAction
            "convertToPublicTopic"
          }}
          @deleteTopic={{fn this.sendTopicAction "deleteTopic"}}
          @enteredIndex={{this.enteredIndex}}
          @fullscreen={{info.topicProgressExpanded}}
          @jumpBottom={{this.jumpEnd}}
          @jumpEnd={{this.jumpEnd}}
          @jumpToIndex={{this.jumpToIndex}}
          @jumpTop={{this.jumpTop}}
          @model={{@outletArgs.topic}}
          @navigation={{this.navigation}}
          @recoverTopic={{fn this.sendTopicAction "recoverTopic"}}
          @replyToPost={{this.nestedController.replyToPost}}
          @resetBumpDate={{fn this.sendTopicAction "resetBumpDate"}}
          @showChangeTimestamp={{fn this.sendTopicAction "showChangeTimestamp"}}
          @showFeatureTopic={{fn this.sendTopicAction "showFeatureTopic"}}
          @showTopicSlowModeUpdate={{fn
            this.sendTopicAction
            "showTopicSlowModeUpdate"
          }}
          @showTopicTimerModal={{fn this.sendTopicAction "showTopicTimerModal"}}
          @toggleArchived={{fn this.sendTopicAction "toggleArchived"}}
          @toggleClosed={{fn this.sendTopicAction "toggleClosed"}}
          @toggleMultiSelect={{fn this.sendTopicAction "toggleMultiSelect"}}
          @toggleVisibility={{fn this.sendTopicAction "toggleVisibility"}}
        />
      </TopicNavigation>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"topic-navigation\"],[4,[30,0,[\"trackGroups\"]],[[30,1,[\"topic\",\"reply_navigation\"]]],null]],[[\"@jumpToDate\",\"@jumpToIndex\",\"@postCount\",\"@topic\"],[[30,0,[\"jumpToDate\"]],[30,0,[\"jumpToPost\"]],[30,1,[\"topic\",\"highest_post_number\"]],[30,1,[\"topic\"]]]],[[\"default\"],[[[[1,\"\\n    \"],[8,[32,1],null,[[\"@outletArgs\"],[[28,[32,2],null,[[\"topic\",\"navigation\",\"renderTimeline\",\"topicProgressExpanded\"],[[30,1,[\"topic\"]],[30,0,[\"navigation\"]],true,[30,2,[\"topicProgressExpanded\"]]]]]]],null],[1,\"\\n    \"],[8,[32,3],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@enteredIndex\",\"@fullscreen\",\"@jumpBottom\",\"@jumpEnd\",\"@jumpToIndex\",\"@jumpTop\",\"@model\",\"@navigation\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\"],[[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"convertToPrivateMessage\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"convertToPublicTopic\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"deleteTopic\"],null],[30,0,[\"enteredIndex\"]],[30,2,[\"topicProgressExpanded\"]],[30,0,[\"jumpEnd\"]],[30,0,[\"jumpEnd\"]],[30,0,[\"jumpToIndex\"]],[30,0,[\"jumpTop\"]],[30,1,[\"topic\"]],[30,0,[\"navigation\"]],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"recoverTopic\"],null],[30,0,[\"nestedController\",\"replyToPost\"]],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"resetBumpDate\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showChangeTimestamp\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showFeatureTopic\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showTopicSlowModeUpdate\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showTopicTimerModal\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleArchived\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleClosed\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleMultiSelect\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleVisibility\"],null]]],null],[1,\"\\n  \"]],[2]]]]],[1,\"\\n\"]],[]],null]],[\"@outletArgs\",\"info\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        TopicNavigation,
        ISBFTopicReading,
        hash,
        TopicTimeline,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-reply-navigation", ISBFReplyNavigation);
var Mod159 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFReplyNavigation
});
const wrappers = new WeakMap();
const __discourseComponentClass = function solvedActionFor(NativeAction) {
  if (typeof NativeAction !== "function") {
    return null;
  }
  if (wrappers.has(NativeAction)) {
    return wrappers.get(NativeAction);
  }
  class ISBFSolvedAction extends NativeAction {
    static hidden() {
      return false;
    }
    static {
      dt7948.g(this.prototype, "router", [service]);
    }
    #router = (dt7948.i(this, "router"), void 0);
    static {
      dt7948.g(this.prototype, "siteSettings", [service]);
    }
    #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
    get accepted() {
      return Boolean(this.args.post.accepted_answer);
    }
    get enabled() {
      return Boolean(this.siteSettings.solved_enabled && this.args.post.post_number > 1 && isFeedStylePost(this.args.post, this.router.currentURL, this.args.state?.nestedReplyView) && (this.accepted || this.args.post.can_accept_answer));
    }
    get nativeAction() {
      return this.accepted ? this.unacceptAnswer : this.acceptAnswer;
    }
    get canAct() {
      return this.enabled && this.args.post.can_accept_answer && typeof this.nativeAction === "function";
    }
    get label() {
      return i18n(themePrefix(this.accepted ? "isbf_v2.solved_unaccept" : "isbf_v2.solved_accept"));
    }
    get title() {
      const username = this.accepted && this.siteSettings.show_who_marked_solved && this.answerInfo?.accepter_username;
      return username ? i18n(themePrefix("isbf_v2.solved_accepted_by"), {
        username
      }) : this.label;
    }
    async runNativeAction() {
      if (!this.canAct || this.saving || this.isDestroying || this.isDestroyed) {
        return;
      }
      await this.nativeAction();
    }
    static {
      dt7948.n(this.prototype, "runNativeAction", [action]);
    }
    static {
      setComponentTemplate(createTemplateFactory(
      /*
        {{#if this.enabled}}
        <div class="isbf-solved-action" ...attributes>
          {{#if this.accepted}}
            <span class="isbf-solved-action__status">
              {{dIcon "check"}}
              {{i18n (themePrefix "isbf_v2.solved_accepted")}}
            </span>
          {{/if}}
          {{#if this.canAct}}
            <DButton
              class="isbf-solved-action__button"
              @action={{this.runNativeAction}}
              @disabled={{this.saving}}
              @icon={{if this.accepted "square-check" "far-square-check"}}
              @translatedLabel={{this.label}}
              @translatedTitle={{this.title}}
            />
          {{/if}}
        </div>
      {{/if}}
      */
      {
        "id": null,
        "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-solved-action\"],[17,1],[12],[1,\"\\n\"],[41,[30,0,[\"accepted\"]],[[[1,\"      \"],[10,1],[14,0,\"isbf-solved-action__status\"],[12],[1,\"\\n        \"],[1,[28,[32,0],[\"check\"],null]],[1,\"\\n        \"],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.solved_accepted\"],null]],null]],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"canAct\"]],[[[1,\"      \"],[8,[32,3],[[24,0,\"isbf-solved-action__button\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedLabel\",\"@translatedTitle\"],[[30,0,[\"runNativeAction\"]],[30,0,[\"saving\"]],[52,[30,0,[\"accepted\"]],\"square-check\",\"far-square-check\"],[30,0,[\"label\"]],[30,0,[\"title\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"&attrs\"],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          dIcon,
          i18n,
          themePrefix,
          DButton
        }),
        "isStrictMode": true
      }), this);
    }
  }
  wrappers.set(NativeAction, ISBFSolvedAction);
  return ISBFSolvedAction;
};
registerModuleForModifyClass("isbf-solved-action", __discourseComponentClass);
var Mod141 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: __discourseComponentClass
});
class ISBFSolvedSummary extends Component {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  get answer() {
    return this.args.post.topic?.accepted_answers?.[0];
  }
  get answerUrl() {
    const answer = this.answer;
    if (!answer) {
      return null;
    }
    if (typeof answer.url === "string" && answer.url.startsWith("/t/")) {
      return answer.url;
    }
    const topic = this.args.post.topic;
    return Number.isInteger(answer.post_number) && answer.post_number > 1 ? topic.urlForPostNumber?.(answer.post_number) || null : null;
  }
  get enabled() {
    return Boolean(this.siteSettings.solved_enabled && this.args.post.post_number === 1 && isFeedStylePost(this.args.post, this.router.currentURL, this.args.decoratorState?.nestedReplyView) && this.answerUrl);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <a class="isbf-solved-summary" href={{this.answerUrl}}>
        {{dIcon "check"}}
        <span>{{i18n (themePrefix "isbf_v2.solved_view_answer")}}</span>
      </a>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,3],[14,0,\"isbf-solved-summary\"],[15,6,[30,0,[\"answerUrl\"]]],[12],[1,\"\\n    \"],[1,[28,[32,0],[\"check\"],null]],[1,\"\\n    \"],[10,1],[12],[1,[28,[32,1],[[28,[32,2],[\"isbf_v2.solved_view_answer\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dIcon,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-solved-summary", ISBFSolvedSummary);
var Mod142 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFSolvedSummary
});
class ISBFTopicReply extends Component {
  get count() {
    return compactNumber(cardReplyCount(this.args.post));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DButton
      class="isbf-topic-card__reply reply"
      ...attributes
      @action={{@buttonActions.replyToPost}}
      @disabled={{if @state.currentUser (if @state.canCreatePost false true)}}
      @icon="comment"
      @translatedAriaLabel={{i18n
        "post.sr_reply_to"
        post_number=@post.post_number
        username=@post.username
      }}
    >{{this.count}}</DButton>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-topic-card__reply reply\"],[17,1]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,2,[\"replyToPost\"]],[52,[30,3,[\"currentUser\"]],[52,[30,3,[\"canCreatePost\"]],false,true]],\"comment\",[28,[32,1],[\"post.sr_reply_to\"],[[\"post_number\",\"username\"],[[30,4,[\"post_number\"]],[30,4,[\"username\"]]]]]]],[[\"default\"],[[[[1,[30,0,[\"count\"]]]],[]]]]]],[\"&attrs\",\"@buttonActions\",\"@state\",\"@post\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        i18n
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFTopicRepost extends Component {
  static {
    dt7948.g(this.prototype, "composer", [service]);
  }
  #composer = (dt7948.i(this, "composer"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "busy", [tracked], function () {
      return false;
    });
  }
  #busy = (dt7948.i(this, "busy"), void 0);
  async repost() {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const post = this.args.post;
    try {
      await openQuotedRepost({
        composer: this.composer,
        router: this.router,
        currentUser: this.currentUser,
        topicId: post.topic.id,
        postNumber: post.post_number,
        username: post.username,
        cookedHtml: post.cooked,
        title: post.topic.title
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "repost", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DButton
      class="isbf-topic-card__repost"
      ...attributes
      @action={{this.repost}}
      @disabled={{this.busy}}
      @icon="retweet"
      @translatedAriaLabel={{i18n (themePrefix "isbf_v2.repost")}}
    />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-topic-card__repost\"],[17,1]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,0,[\"repost\"]],[30,0,[\"busy\"]],\"retweet\",[28,[32,1],[[28,[32,2],[\"isbf_v2.repost\"],null]],null]]],null]],[\"&attrs\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
const ISBFTopicLike = setComponentTemplate(createTemplateFactory(
/*
  <div class="isbf-topic-card__like" ...attributes>
  {{#if @post.showLike}}
    <PostMenuLikeButton
      @buttonActions={{@buttonActions}}
      @post={{@post}}
      @showLabel={{false}}
      @state={{@state}}
    />
  {{else if @post.likeCount}}
    <PostMenuLikeButton
      @buttonActions={{@buttonActions}}
      @post={{@post}}
      @showLabel={{false}}
      @state={{@state}}
    />
  {{else}}
    <DButton
      class="btn-flat"
      @disabled={{true}}
      @icon="heart"
      @title="post.controls.like"
    />
  {{/if}}
</div>
*/
{
  "id": null,
  "block": "[[[11,0],[24,0,\"isbf-topic-card__like\"],[17,1],[12],[1,\"\\n\"],[41,[30,2,[\"showLike\"]],[[[1,\"    \"],[8,[32,0],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,3],[30,2],false,[30,4]]],null],[1,\"\\n\"]],[]],[[[41,[30,2,[\"likeCount\"]],[[[1,\"    \"],[8,[32,0],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,3],[30,2],false,[30,4]]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[8,[32,1],[[24,0,\"btn-flat\"]],[[\"@disabled\",\"@icon\",\"@title\"],[true,\"heart\",\"post.controls.like\"]],null],[1,\"\\n  \"]],[]]]],[]]],[13]],[\"&attrs\",\"@post\",\"@buttonActions\",\"@state\"],[\"if\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    PostMenuLikeButton,
    DButton
  }),
  "isStrictMode": true
}), templateOnly());
class ISBFTopicBookmark extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "busy", [tracked], function () {
      return false;
    });
  }
  #busy = (dt7948.i(this, "busy"), void 0);
  get isFirstPost() {
    return this.args.post.post_number === 1;
  }
  get bookmarked() {
    return this.isFirstPost ? this.args.post.topic.bookmarked : this.args.post.bookmarked;
  }
  async bookmark() {
    if (!this.currentUser) {
      return this.router.transitionTo("login");
    }
    if (this.busy || !this.args.post.canBookmark) {
      return;
    }
    this.busy = true;
    const topic = this.args.post.topic;
    try {
      if (topic.bookmarked) {
        await ajax(`/t/${topic.id}/remove_bookmarks`, {
          type: "DELETE"
        });
        topic.set("bookmarked", false);
      } else {
        await ajax(`/t/${topic.id}/bookmark`, {
          type: "PUT"
        });
        topic.set("bookmarked", true);
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "bookmark", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{dConcatClass
        "isbf-topic-card__bookmark"
        (if this.bookmarked "bookmarked")
      }}
      ...attributes
    >
      {{#if this.isFirstPost}}
        <DButton
          class="btn-flat"
          @action={{this.bookmark}}
          @disabled={{this.busy}}
          @icon={{if this.bookmarked "bookmark" "far-bookmark"}}
          @translatedAriaLabel={{i18n (themePrefix "isbf_v2.bookmark_action")}}
        />
      {{else}}
        <PostMenuBookmarkButton
          @buttonActions={{@buttonActions}}
          @post={{@post}}
          @showLabel={{false}}
          @state={{@state}}
        />
      {{/if}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[28,[32,0],[\"isbf-topic-card__bookmark\",[52,[30,0,[\"bookmarked\"]],\"bookmarked\"]],null]],[17,1],[12],[1,\"\\n\"],[41,[30,0,[\"isFirstPost\"]],[[[1,\"    \"],[8,[32,1],[[24,0,\"btn-flat\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,0,[\"bookmark\"]],[30,0,[\"busy\"]],[52,[30,0,[\"bookmarked\"]],\"bookmark\",\"far-bookmark\"],[28,[32,2],[[28,[32,3],[\"isbf_v2.bookmark_action\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[8,[32,4],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,2],[30,3],false,[30,4]]],null],[1,\"\\n\"]],[]]],[13]],[\"&attrs\",\"@buttonActions\",\"@post\",\"@state\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        DButton,
        i18n,
        themePrefix,
        PostMenuBookmarkButton
      }),
      "isStrictMode": true
    }), this);
  }
}
var Mod25 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFTopicBookmark: ISBFTopicBookmark,
  ISBFTopicLike: ISBFTopicLike,
  ISBFTopicReply: ISBFTopicReply,
  ISBFTopicRepost: ISBFTopicRepost
});
class ISBFReplyContext extends Component {
  static {
    dt7948.g(this.prototype, "a11y", [service]);
  }
  #a11y = (dt7948.i(this, "a11y"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "store", [service]);
  }
  #store = (dt7948.i(this, "store"), void 0);
  static {
    dt7948.g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (dt7948.i(this, "expanded"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  static {
    dt7948.g(this.prototype, "parent", [tracked], function () {
      return null;
    });
  }
  #parent = (dt7948.i(this, "parent"), void 0);
  static {
    dt7948.g(this.prototype, "unavailable", [tracked], function () {
      return false;
    });
  }
  #unavailable = (dt7948.i(this, "unavailable"), void 0);
  get label() {
    const user = this.args.post.reply_to_user;
    const identity = displayIdentity({
      ...user,
      name: this.siteSettings.enable_names ? user?.name : null
    });
    return i18n(themePrefix("isbf_v2.reply_conversations.reply_to"), {
      name: identity || i18n(themePrefix("isbf_v2.reply_conversations.original_post")),
      number: this.args.post.reply_to_post_number
    });
  }
  get parentUrl() {
    return getURL(`${this.args.post.topic.url}/${this.args.post.reply_to_post_number}`);
  }
  async toggle() {
    if (this.loading) {
      return;
    }
    this.expanded = !this.expanded;
    if (!this.expanded || this.parent) {
      return;
    }
    this.loading = true;
    this.unavailable = false;
    const post = this.args.post;
    try {
      const data = await ajax(`/posts/by_number/${post.topic.id}/${post.reply_to_post_number}.json`);
      if (this.isDestroying || this.args.post !== post) {
        return;
      }
      if (data.deleted_at || data.deleted_post_placeholder || data.cooked_hidden || !data.cooked) {
        this.unavailable = true;
      } else {
        this.parent = this.store.createRecord("post", {
          ...data,
          topic: post.topic
        });
        this.a11y.announce(i18n(themePrefix("isbf_v2.reply_conversations.context_loaded")), "polite");
      }
    } catch {
      if (!this.isDestroying && this.args.post === post) {
        this.unavailable = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "toggle", [action]);
  }
  retry() {
    this.expanded = false;
    return this.toggle();
  }
  static {
    dt7948.n(this.prototype, "retry", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if @post.reply_to_post_number}}
      <div class="isbf-reply-context" ...attributes>
        <DButton
          class="btn-flat isbf-reply-context__toggle"
          @action={{this.toggle}}
          @ariaExpanded={{this.expanded}}
          @translatedLabel={{this.label}}
        />
        {{#if this.expanded}}
          <div class="isbf-reply-context__preview">
            <DConditionalLoadingSpinner @condition={{this.loading}}>
              {{#if this.parent}}
                <PostCookedHtml @post={{this.parent}} />
                <a
                  class="isbf-reply-context__link"
                  href={{this.parentUrl}}
                >{{i18n
                    (themePrefix "isbf_v2.reply_conversations.go_to_original")
                  }}</a>
              {{else if this.unavailable}}
                <p>{{i18n
                    (themePrefix
                      "isbf_v2.reply_conversations.context_unavailable"
                    )
                  }}</p>
                <DButton
                  class="btn-flat"
                  @action={{this.retry}}
                  @label="retry"
                />
              {{/if}}
            </DConditionalLoadingSpinner>
          </div>
        {{/if}}
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,1,[\"reply_to_post_number\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-reply-context\"],[17,2],[12],[1,\"\\n    \"],[8,[32,0],[[24,0,\"btn-flat isbf-reply-context__toggle\"]],[[\"@action\",\"@ariaExpanded\",\"@translatedLabel\"],[[30,0,[\"toggle\"]],[30,0,[\"expanded\"]],[30,0,[\"label\"]]]],null],[1,\"\\n\"],[41,[30,0,[\"expanded\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-reply-context__preview\"],[12],[1,\"\\n        \"],[8,[32,1],null,[[\"@condition\"],[[30,0,[\"loading\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,0,[\"parent\"]],[[[1,\"            \"],[8,[32,2],null,[[\"@post\"],[[30,0,[\"parent\"]]]],null],[1,\"\\n            \"],[10,3],[14,0,\"isbf-reply-context__link\"],[15,6,[30,0,[\"parentUrl\"]]],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.reply_conversations.go_to_original\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"unavailable\"]],[[[1,\"            \"],[10,2],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.reply_conversations.context_unavailable\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,0],[[24,0,\"btn-flat\"]],[[\"@action\",\"@label\"],[[30,0,[\"retry\"]],\"retry\"]],null],[1,\"\\n          \"]],[]],null]],[]]],[1,\"        \"]],[]]]]],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"@post\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        DConditionalLoadingSpinner,
        PostCookedHtml,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-reply-context", ISBFReplyContext);
var Mod158 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFReplyContext
});
class ISBFTopicMetadata extends Component {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  get enabled() {
    return isFeedStylePost(this.args.outletArgs.post, this.router.currentURL) || this.conversation;
  }
  get conversation() {
    return isConversationPost(this.args.outletArgs.post, this.router.currentURL, this.siteSettings);
  }
  get title() {
    const post = this.args.outletArgs.post;
    return post.post_number === 1 ? postCardTitle(post.topic.title, post.cooked) : null;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <div class="isbf-post-card-header">
        {{yield}}
        <DUserLink
          class="isbf-feed-card__username"
          @user={{@outletArgs.post.user}}
        >
          @{{@outletArgs.post.username}}
        </DUserLink>
      </div>
      {{#if this.conversation}}
        <ISBFReplyContext @post={{@outletArgs.post}} />
      {{/if}}
      {{#if this.title}}
        <h1
          class="isbf-feed-card__title isbf-topic-card__title"
        >{{this.title}}</h1>
      {{/if}}
    {{else}}
      {{yield}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-post-card-header\"],[12],[1,\"\\n    \"],[18,2,null],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-feed-card__username\"]],[[\"@user\"],[[30,1,[\"post\",\"user\"]]]],[[\"default\"],[[[[1,\"\\n      @\"],[1,[30,1,[\"post\",\"username\"]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"],[13],[1,\"\\n\"],[41,[30,0,[\"conversation\"]],[[[1,\"    \"],[8,[32,1],null,[[\"@post\"],[[30,1,[\"post\"]]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"title\"]],[[[1,\"    \"],[10,\"h1\"],[14,0,\"isbf-feed-card__title isbf-topic-card__title\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n\"]],[]],null]],[]],[[[1,\"  \"],[18,2,null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&default\"],[\"if\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DUserLink,
        ISBFReplyContext
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-topic-metadata", ISBFTopicMetadata);
var Mod27 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTopicMetadata
});
class ISBFTopicInfo extends Component {
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  get controller() {
    return getOwner(this).lookup("controller:topic");
  }
  async editTitle() {
    this.args.closeModal();
    await this.controller.editTopic();
    document.querySelector("#topic-title")?.scrollIntoView({
      block: "start"
    });
  }
  static {
    dt7948.n(this.prototype, "editTitle", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-topic-info"
      @closeModal={{@closeModal}}
      @title={{themePrefix "isbf_v2.topic_info"}}
    >
      <:body>
        <h2>{{@model.title}}</h2>
        <p>{{@model.category.name}}</p>
        {{#if @model.details.can_edit}}
          <DButton
            @action={{this.editTitle}}
            @icon="pencil"
            @translatedLabel={{i18n (themePrefix "isbf_v2.topic_edit_title")}}
          />
        {{/if}}
        <div class="topic-map">
          <TopicMap
            @cancelFilter={{this.controller.cancelFilter}}
            @model={{@model}}
            @postStream={{@model.postStream}}
            @showPMMap={{false}}
            @topicDetails={{@model.details}}
          />
        </div>
        {{#if this.currentUser}}
          <TopicFooterButtons
            @convertToPrivateMessage={{this.controller.convertToPrivateMessage}}
            @convertToPublicTopic={{this.controller.convertToPublicTopic}}
            @deferTopic={{this.controller.deferTopic}}
            @deleteTopic={{this.controller.deleteTopic}}
            @editFirstPost={{this.controller.editFirstPost}}
            @recoverTopic={{this.controller.recoverTopic}}
            @replyToPost={{this.controller.replyToPost}}
            @resetBumpDate={{this.controller.resetBumpDate}}
            @showChangeTimestamp={{routeAction "showChangeTimestamp"}}
            @showCreate={{false}}
            @showFeatureTopic={{routeAction "showFeatureTopic"}}
            @showFlagTopic={{routeAction "showFlagTopic"}}
            @showTopicSlowModeUpdate={{routeAction "showTopicSlowModeUpdate"}}
            @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
            @toggleArchived={{this.controller.toggleArchived}}
            @toggleBookmark={{this.controller.toggleBookmark}}
            @toggleClosed={{this.controller.toggleClosed}}
            @toggleFeaturedOnProfile={{this.controller.toggleFeaturedOnProfile}}
            @toggleMultiSelect={{this.controller.toggleMultiSelect}}
            @toggleVisibility={{this.controller.toggleVisibility}}
            @topic={{@model}}
          />
        {{/if}}
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-topic-info\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[\"isbf_v2.topic_info\"],null]]],[[\"body\"],[[[[1,\"\\n    \"],[10,\"h2\"],[12],[1,[30,2,[\"title\"]]],[13],[1,\"\\n    \"],[10,2],[12],[1,[30,2,[\"category\",\"name\"]]],[13],[1,\"\\n\"],[41,[30,2,[\"details\",\"can_edit\"]],[[[1,\"      \"],[8,[32,2],null,[[\"@action\",\"@icon\",\"@translatedLabel\"],[[30,0,[\"editTitle\"]],\"pencil\",[28,[32,3],[[28,[32,1],[\"isbf_v2.topic_edit_title\"],null]],null]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[10,0],[14,0,\"topic-map\"],[12],[1,\"\\n      \"],[8,[32,4],null,[[\"@cancelFilter\",\"@model\",\"@postStream\",\"@showPMMap\",\"@topicDetails\"],[[30,0,[\"controller\",\"cancelFilter\"]],[30,2],[30,2,[\"postStream\"]],false,[30,2,[\"details\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"      \"],[8,[32,5],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deferTopic\",\"@deleteTopic\",\"@editFirstPost\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showCreate\",\"@showFeatureTopic\",\"@showFlagTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleBookmark\",\"@toggleClosed\",\"@toggleFeaturedOnProfile\",\"@toggleMultiSelect\",\"@toggleVisibility\",\"@topic\"],[[30,0,[\"controller\",\"convertToPrivateMessage\"]],[30,0,[\"controller\",\"convertToPublicTopic\"]],[30,0,[\"controller\",\"deferTopic\"]],[30,0,[\"controller\",\"deleteTopic\"]],[30,0,[\"controller\",\"editFirstPost\"]],[30,0,[\"controller\",\"recoverTopic\"]],[30,0,[\"controller\",\"replyToPost\"]],[30,0,[\"controller\",\"resetBumpDate\"]],[28,[32,6],[\"showChangeTimestamp\"],null],false,[28,[32,6],[\"showFeatureTopic\"],null],[28,[32,6],[\"showFlagTopic\"],null],[28,[32,6],[\"showTopicSlowModeUpdate\"],null],[28,[32,6],[\"showTopicTimerModal\"],null],[30,0,[\"controller\",\"toggleArchived\"]],[30,0,[\"controller\",\"toggleBookmark\"]],[30,0,[\"controller\",\"toggleClosed\"]],[30,0,[\"controller\",\"toggleFeaturedOnProfile\"]],[30,0,[\"controller\",\"toggleMultiSelect\"]],[30,0,[\"controller\",\"toggleVisibility\"]],[30,2]]],null],[1,\"\\n\"]],[]],null],[1,\"  \"]],[]]]]]],[\"@closeModal\",\"@model\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        themePrefix,
        DButton,
        i18n,
        TopicMap,
        TopicFooterButtons,
        routeAction
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-topic-info", ISBFTopicInfo);
var Mod26 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTopicInfo
});
class ISBFTopicMore extends Component {
  static shouldRender() {
    return true;
  }
  static extraControls() {
    return true;
  }
  static {
    dt7948.g(this.prototype, "modal", [service]);
  }
  #modal = (dt7948.i(this, "modal"), void 0);
  #menu;
  #openingEdit = false;
  get buttonActions() {
    return {
      ...this.args.buttonActions,
      editPost: this.editPost
    };
  }
  get buttons() {
    return secondaryMenuFor(this.args.post).map(([key, Button]) => new PostMenuButtonConfig({
      key,
      Component: Button,
      owner: getOwner(this),
      apiAdded: true,
      hidden: false,
      showLabel: true,
      position: {},
      replacementMap: new WeakMap()
    })).filter(button => button.shouldRender({
      post: this.args.post,
      state: this.args.state
    }));
  }
  get identifier() {
    return "isbf-topic-card-more-" + this.args.post.id;
  }
  get isFirstPost() {
    return this.args.post.post_number === 1;
  }
  registerMenu(menu) {
    this.#menu = menu;
  }
  static {
    dt7948.n(this.prototype, "registerMenu", [action]);
  }
  async editPost(...args) {
    if (this.#openingEdit || this.isDestroying) {
      return;
    }
    this.#openingEdit = true;
    try {
      await this.#menu?.close();
      if (!this.isDestroying) {
        return await this.args.buttonActions.editPost(...args);
      }
    } finally {
      this.#openingEdit = false;
    }
  }
  static {
    dt7948.n(this.prototype, "editPost", [action]);
  }
  async showTopicInfo(menu) {
    await menu.close();
    this.modal.show(ISBFTopicInfo, {
      model: this.args.post.topic
    });
  }
  static {
    dt7948.n(this.prototype, "showTopicInfo", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div class="isbf-topic-card__more-menu" ...attributes>
      <DMenu
        @ariaLabel={{i18n "more"}}
        @icon="ellipsis"
        @identifier={{this.identifier}}
        @modalForMobile={{true}}
        @onRegisterApi={{this.registerMenu}}
        @title={{i18n "more"}}
        @triggerClass="btn-flat isbf-topic-card__more show-more-actions"
      >
        <:content as |menu|>
          <DDropdownMenu class="isbf-topic-card__menu" as |dropdown|>
            {{#each this.buttons key="key" as |button|}}
              <dropdown.item>
                <PostMenuButtonWrapper
                  @buttonActions={{this.buttonActions}}
                  @buttonConfig={{button}}
                  @post={{@post}}
                  @state={{@state}}
                />
              </dropdown.item>
            {{/each}}
            {{#if this.isFirstPost}}
              <dropdown.item>
                <DButton
                  @action={{fn this.showTopicInfo menu}}
                  @icon="circle-info"
                  @translatedLabel={{i18n (themePrefix "isbf_v2.topic_info")}}
                />
              </dropdown.item>
            {{/if}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"isbf-topic-card__more-menu\"],[17,1],[12],[1,\"\\n  \"],[8,[32,0],null,[[\"@ariaLabel\",\"@icon\",\"@identifier\",\"@modalForMobile\",\"@onRegisterApi\",\"@title\",\"@triggerClass\"],[[28,[32,1],[\"more\"],null],\"ellipsis\",[30,0,[\"identifier\"]],true,[30,0,[\"registerMenu\"]],[28,[32,1],[\"more\"],null],\"btn-flat isbf-topic-card__more show-more-actions\"]],[[\"content\"],[[[[1,\"\\n      \"],[8,[32,2],[[24,0,\"isbf-topic-card__menu\"]],null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,0,[\"buttons\"]]],null]],null],\"key\",[[[1,\"          \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,3],null,[[\"@buttonActions\",\"@buttonConfig\",\"@post\",\"@state\"],[[30,0,[\"buttonActions\"]],[30,4],[30,5],[30,6]]],null],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[4]],null],[41,[30,0,[\"isFirstPost\"]],[[[1,\"          \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,4],null,[[\"@action\",\"@icon\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"showTopicInfo\"]],[30,2]],null],\"circle-info\",[28,[32,1],[[28,[32,6],[\"isbf_v2.topic_info\"],null]],null]]],null],[1,\"\\n          \"]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"      \"]],[3]]]]],[1,\"\\n    \"]],[2]]]]],[1,\"\\n\"],[13]],[\"&attrs\",\"menu\",\"dropdown\",\"button\",\"@post\",\"@state\"],[\"each\",\"-track-array\",\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        DDropdownMenu,
        PostMenuButtonWrapper,
        DButton,
        fn,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-topic-more", ISBFTopicMore);
var Mod28 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTopicMore
});
class ISBFTopicViews extends Component {
  static shouldRender({
    post
  }) {
    return post.post_type === 1 && post.post_number >= 1;
  }
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "count", [tracked], function () {
      return null;
    });
  }
  #count = (dt7948.i(this, "count"), void 0);
  #observer;
  #pending = false;
  #visible = false;
  get countLabel() {
    return this.count === null ? "" : this.count === 0 ? "0" : compactNumber(this.count);
  }
  get label() {
    return this.count === null ? i18n(themePrefix("isbf_v2.views")) : i18n(themePrefix("isbf_v2.views_count"), {
      count: this.count
    });
  }
  observe(element) {
    if (!this.currentUser || !this.siteSettings.isbf_views_enabled) {
      return;
    }
    this.#observer = new IntersectionObserver(entries => {
      this.#visible = entries.some(entry => entry.isIntersecting);
      this.onVisibilityChange();
    }, {
      rootMargin: "0px",
      threshold: 0
    });
    this.#observer.observe(element.closest(".isbf-topic-card__article") ?? element);
    document.addEventListener("visibilitychange", this.onVisibilityChange);
  }
  static {
    dt7948.n(this.prototype, "observe", [action]);
  }
  onVisibilityChange() {
    if (this.#visible && document.visibilityState === "visible") {
      this.#recordView();
    }
  }
  static {
    dt7948.n(this.prototype, "onVisibilityChange", [action]);
  }
  destroyObserver() {
    this.#observer?.disconnect();
    this.#visible = false;
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
  }
  static {
    dt7948.n(this.prototype, "destroyObserver", [action]);
  }
  async #recordView() {
    if (this.#pending) {
      return;
    }
    this.#pending = true;
    const post = this.args.post;
    const count = await (post.post_number === 1 ? recordVisibleView(post.topic.id, this.currentUser.id) : recordVisiblePostView(post.id, this.currentUser.id));
    if (!this.isDestroying) {
      this.count = count;
      if (count !== null) {
        this.destroyObserver();
      }
    }
    this.#pending = false;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <span
      aria-label={{this.label}}
      class="isbf-topic-card__views"
      title={{this.label}}
      ...attributes
      {{didInsert this.observe}}
      {{willDestroy this.destroyObserver}}
    >
      {{dIcon "chart-bar"}}{{this.countLabel}}
    </span>
    */
    {
      "id": null,
      "block": "[[[11,1],[16,\"aria-label\",[30,0,[\"label\"]]],[24,0,\"isbf-topic-card__views\"],[16,\"title\",[30,0,[\"label\"]]],[17,1],[4,[32,0],[[30,0,[\"observe\"]]],null],[4,[32,1],[[30,0,[\"destroyObserver\"]]],null],[12],[1,\"\\n  \"],[1,[28,[32,2],[\"chart-bar\"],null]],[1,[30,0,[\"countLabel\"]]],[1,\"\\n\"],[13]],[\"&attrs\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        willDestroy,
        dIcon
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-topic-views", ISBFTopicViews);
var Mod29 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTopicViews
});
const initializer = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  const siteSettings = api.container.lookup("service:site-settings");
  api.renderInOutlet("post-metadata", ISBFTopicMetadata);
  api.renderInOutlet("nested-topic-navigation", ISBFReplyNavigation);
  api.registerValueTransformer("post-meta-data-infos", ({
    value,
    context
  }) => {
    if (isConversationPost(context.post, router.currentURL, siteSettings)) {
      value.delete(context.metaDataInfoKeys.REPLY_TO_TAB);
    }
    return value;
  });
  api.renderAfterWrapperOutlet("post-content-cooked-html", ISBFSolvedSummary);
  for (const [name, className] of [["post-class", "isbf-topic-card"], ["post-article-class", "isbf-topic-card__article"]]) {
    api.registerValueTransformer(name, ({
      value,
      context
    }) => isFeedStylePost(context.post, router.currentURL, context.state?.nestedReplyView) ? [...value, className] : value);
  }
  api.registerValueTransformer("post-show-topic-map", ({
    value,
    context
  }) => isFeedStylePost(context.post, router.currentURL, context.state?.nestedReplyView) ? false : value);
  api.registerValueTransformer("topic-show-footer-buttons", ({
    value,
    context
  }) => isFeedStyleTopic(context.topic, router.currentURL) ? false : value);
  api.registerValueTransformer("post-menu-buttons", ({
    value,
    context
  }) => {
    if (!isFeedStylePost(context.post, router.currentURL, context.state.nestedReplyView) && !isConversationPost(context.post, router.currentURL, siteSettings)) {
      return;
    }
    const conversation = isConversationPost(context.post, router.currentURL, siteSettings);
    const {
      buttonKeys
    } = context;
    const primaryKeys = [buttonKeys.REPLY, buttonKeys.LIKE, buttonKeys.BOOKMARK, buttonKeys.SHOW_MORE];
    const entries = value.entries();
    const nativeSolved = siteSettings.solved_enabled ? entries.find(([key]) => key === "solved") : null;
    const SolvedAction = nativeSolved && !conversation ? __discourseComponentClass(nativeSolved[1]) : null;
    rememberSecondaryMenu(context.post, entries.filter(([key]) => !primaryKeys.includes(key) && !(SolvedAction && key === "solved")));
    entries.forEach(([key]) => value.delete(key));
    value.add("isbfReply", ISBFTopicReply, {
      before: "isbfRepost"
    });
    value.add("isbfRepost", ISBFTopicRepost, {
      after: "isbfReply",
      before: "isbfLike"
    });
    value.add("isbfLike", ISBFTopicLike, {
      after: "isbfRepost",
      before: "isbfViews"
    });
    value.add("isbfViews", ISBFTopicViews, {
      after: "isbfLike",
      before: "isbfBookmark"
    });
    value.add("isbfBookmark", ISBFTopicBookmark, {
      after: "isbfViews"
    });
    if (SolvedAction) {
      value.add("solved", SolvedAction, {
        after: "isbfBookmark"
      });
    }
    value.add(buttonKeys.SHOW_MORE, ISBFTopicMore);
  });
});
initializer.after = ["inject-objects", "extend-for-solved-button"];
var Mod24 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: initializer
});
const nativePlacement = new WeakMap();
var isbfComposerCategoryMenu = apiInitializer(api => {
  api.modifyClass("component:category-chooser", {
    pluginId: "isbf-ui-composer-category-menu",
    updateFloatingUiPosition() {
      const header = this.getHeader();
      const menu = this.selectKit.mainElement()?.querySelector(".select-kit-body");
      const composer = header?.closest("#reply-control.open");
      const scoped = window.matchMedia("(max-width: 600px)").matches && composer?.querySelector(".isbf-v2-composer");
      if (scoped && menu) {
        const options = this.selectKit.options;
        if (!nativePlacement.has(this)) {
          nativePlacement.set(this, {
            placement: options.placement,
            mobilePlacement: options.mobilePlacement,
            placementStrategy: options.placementStrategy
          });
        }
        options.setProperties({
          placement: "top-start",
          mobilePlacement: "top-start",
          placementStrategy: "fixed"
        });
        const viewportTop = window.visualViewport?.offsetTop || 0;
        const availableHeight = Math.max(0, header.getBoundingClientRect().top - viewportTop - 8);
        menu.classList.add("isbf-v2-composer-category-menu");
        menu.style.setProperty("--isbf-v2-category-menu-max-height", `${availableHeight}px`);
      } else {
        const original = nativePlacement.get(this);
        if (original) {
          this.selectKit.options.setProperties(original);
          nativePlacement.delete(this);
        }
        menu?.classList.remove("isbf-v2-composer-category-menu");
        menu?.style.removeProperty("--isbf-v2-category-menu-max-height");
      }
      return this._super(...arguments);
    }
  });
});
var Mod35 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfComposerCategoryMenu
});
var isbfTopicReading = apiInitializer(api => {
  api.renderInOutlet("topic-navigation", ISBFTopicReading);
  api.renderInOutlet("timeline-footer-controls-after", ISBFTopicReadingJump);
});
var Mod36 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfTopicReading
});
var isbfReporting = apiInitializer(api => {
  const appEvents = api.container.lookup("service:app-events");
  const siteSettings = api.container.lookup("service:site-settings");
  const site = api.container.lookup("service:site");
  const currentUser = api.container.lookup("service:current-user");
  const messageBus = api.container.lookup("service:message-bus");
  messageBus.subscribe("/isbf/moderation/posts", message => {
    if (typeof message.hidden === "boolean") {
      rememberHiddenPost(message.post_id, appEvents, message.hidden, message.hidden);
    }
  });
  api.registerValueTransformer("flag-button-render-decision", ({
    value,
    context
  }) => value || Boolean(currentUser && severeReportAvailable(context.post, siteSettings, site)));
  api.modifyClass("route:topic", Superclass => class extends Superclass {
    showFlags(post) {
      if (!this.currentUser || post.post_type !== 1 || post.topic?.archetype === "private_message") {
        return super.showFlags(...arguments);
      }
      return openPostReport({
        post,
        modal: this.modal,
        siteSettings,
        site,
        appEvents
      });
    }
    static {
      dt7948.n(this.prototype, "showFlags", [action]);
    }
  });
});
var Mod44 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfReporting
});
const SOURCE = Object.freeze({
  "type": "theme",
  "id": 4
});
function withPluginApi(...args) {
  // A leading string is the legacy version argument, which shifts opts along.
  const optsIndex = typeof args[0] === "string" ? 2 : 1;
  args[optsIndex] = {
    ...args[optsIndex],
    [_INTERNAL_SOURCE_KEY]: SOURCE
  };
  return withPluginApi$1(...args);
}
var isbfComposerOptionalTitle = {
  name: "isbf-composer-optional-title",
  before: "inject-discourse-objects",
  initialize() {
    withPluginApi(api => {
      api.addModelField("composer", "isbf_optional_title", {
        defaultValue: null
      });
      Composer.serializeToDraft("isbf_optional_title", "isbf_optional_title");
      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.set("isbf_optional_title", null);
        return result;
      });
    });
  }
};
var Mod47 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfComposerOptionalTitle
});
class ISBFV2JoinModal extends Component {
  get description() {
    return settings.join_us_description?.trim() || i18n(themePrefix("isbf_v2.join_us_pending"));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DModal
      class="isbf-v2-join-modal"
      @closeModal={{@closeModal}}
      @title={{themePrefix "isbf_v2.join_us"}}
    >
      <:body>
        <p class="isbf-v2-join-modal__description">{{this.description}}</p>
      </:body>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-v2-join-modal\"]],[[\"@closeModal\",\"@title\"],[[30,1],[28,[32,1],[\"isbf_v2.join_us\"],null]]],[[\"body\"],[[[[1,\"\\n    \"],[10,2],[14,0,\"isbf-v2-join-modal__description\"],[12],[1,[30,0,[\"description\"]]],[13],[1,\"\\n  \"]],[]]]]]],[\"@closeModal\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-v2-join-modal", ISBFV2JoinModal);
var Mod49 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFV2JoinModal
});
function extendComposerMethod(api, name, extension) {
  // Capture after proto() applies earlier plugin extensions, before replacing it.
  const original = Composer.proto()[name];
  api.addModelMethod("composer", name, function (...args) {
    return extension.call(this, original.bind(this), ...args);
  });
}
var Mod79 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  extendComposerMethod: extendComposerMethod
});
const configuredComposers = new WeakSet();
function setup(api) {
  if (configuredComposers.has(Composer)) {
    return;
  }
  const pendingSaves = new WeakMap();
  const epochs = new WeakMap();
  const invalidate = model => {
    epochs.set(model, (epochs.get(model) ?? 0) + 1);
    pendingSaves.delete(model);
    return epochs.get(model);
  };
  const refreshConfig = async (model, epoch) => {
    const data = await ajax("/site.json");
    if (epochs.get(model) !== epoch) {
      return null;
    }
    const config = officialConfig(data);
    if (!config) {
      throw new Error("Invalid official classification catalog");
    }
    model.site.set("isbf_official", data.isbf_official);
    return config;
  };
  OFFICIAL_FIELDS.forEach((field, index) => {
    const property = index === 0 ? "isbfOfficialCampusesPayload" : "isbfOfficialTypesPayload";
    api.addModelField("composer", field, {
      defaultValue: null
    });
    Composer.serializeOnCreate(field, property);
    Composer.serializeOnUpdate(field, property);
    Composer.serializeToDraft(field, field);
  });
  api.addModelGetter("composer", "isbfOfficialCampusesPayload", function () {
    return officialPayload(this, officialConfig(this.site), OFFICIAL_FIELDS[0]);
  });
  api.addModelGetter("composer", "isbfOfficialTypesPayload", function () {
    return officialPayload(this, officialConfig(this.site), OFFICIAL_FIELDS[1]);
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    invalidate(this);
    const result = next(...args);
    this.setProperties({
      isbf_official_campuses: null,
      isbf_official_types: null
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, ...args) {
    const epoch = invalidate(this);
    return next(...args).then(result => {
      if (epochs.get(this) === epoch) {
        restoreOfficialSelections(this, officialConfig(this.site));
      }
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (pendingSaves.has(this)) {
      return pendingSaves.get(this);
    }
    if (!isOfficialComposer(this, officialConfig(this.site))) {
      return next(...args);
    }
    const epoch = epochs.get(this);
    const pending = (async () => {
      let config;
      try {
        config = await refreshConfig(this, epoch);
      } catch {
        if (epochs.get(this) === epoch) {
          return this.dialog.alert(i18n(themePrefix("isbf_v2.official_refresh_error")));
        }
        return;
      }
      if (epochs.get(this) !== epoch || !isOfficialComposer(this, config)) {
        return;
      }
      if (!officialSelectionsAvailable(this, config)) {
        return this.dialog.alert(i18n(themePrefix("isbf_v2.official_classification_stale")));
      }
      if (!officialSelectionsComplete(this, config)) {
        return this.dialog.alert(i18n(themePrefix("isbf_v2.official_required")));
      }
      try {
        return await next(...args);
      } catch (error) {
        if (epochs.get(this) === epoch) {
          try {
            await refreshConfig(this, epoch);
          } catch {
            // Keep the native save error even when the catalog refresh fails.
          }
        }
        throw error;
      }
    })().finally(() => {
      if (pendingSaves.get(this) === pending) {
        pendingSaves.delete(this);
      }
    });
    pendingSaves.set(this, pending);
    return pending;
  });
  configuredComposers.add(Composer);
}
var Mod149 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  setup: setup
});
var isbfOfficialComposer = {
  name: "isbf-official-composer",
  after: "isbf-composer-optional-title",
  before: "inject-discourse-objects",
  initialize() {
    withPluginApi(api => setup(api));
  }
};
var Mod55 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfOfficialComposer
});
var isbfOfficialCalendar$1 = {
  name: "isbf-official-calendar",
  after: "isbf-official-composer",
  before: "inject-discourse-objects",
  initialize() {
    withPluginApi(api => {
      api.addModelField("composer", OFFICIAL_CALENDAR_FIELD, {
        defaultValue: null
      });
      api.addModelGetter("composer", "isbfOfficialCalendarPayload", function () {
        if (!isOfficialCalendarComposer(this, this.site) || officialCalendarNeedsTitle(this, this.site) && !officialCalendarTopicTitle(this)) {
          return;
        }
        return JSON.stringify(calendarItemsWithTopicTitle(this[OFFICIAL_CALENDAR_FIELD], officialCalendarTopicTitle(this)));
      });
      Composer.serializeOnCreate(OFFICIAL_CALENDAR_FIELD, "isbfOfficialCalendarPayload");
      Composer.serializeOnUpdate(OFFICIAL_CALENDAR_FIELD, "isbfOfficialCalendarPayload");
      Composer.serializeToDraft(OFFICIAL_CALENDAR_FIELD);
      extendComposerMethod(api, "serializeDraftData", function (next, ...args) {
        const data = next(...args);
        if (isOfficialCalendarComposer(this, this.site)) {
          data[OFFICIAL_CALENDAR_FIELD] = calendarItemsWithTopicTitle(this[OFFICIAL_CALENDAR_FIELD], officialCalendarTopicTitle(this), {
            draft: true
          });
        }
        return data;
      });
      extendComposerMethod(api, "save", function (next, ...args) {
        if (officialCalendarNeedsTitle(this, this.site) && !officialCalendarTopicTitle(this)) {
          return Promise.resolve(this.dialog.alert(i18n(themePrefix("isbf_v2.schedule_title_required")))).then(() => {
            if (!this.isDestroying && officialCalendarNeedsTitle(this, this.site) && !officialCalendarTopicTitle(this)) {
              const input = document.querySelector("#reply-control #isbf-optional-title") ?? document.querySelector("#reply-control .title-input input");
              input?.focus();
            }
          });
        }
        return next(...args);
      });
      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.set(OFFICIAL_CALENDAR_FIELD, null);
        return result;
      });
      const originalOpen = Composer.prototype.open;
      api.addModelMethod("composer", "open", function (...args) {
        return originalOpen.apply(this, args).then(result => {
          if (isOfficialCalendarComposer(this, this.site)) {
            const items = this[OFFICIAL_CALENDAR_FIELD] ?? (this.editingFirstPost ? this.post?.[OFFICIAL_CALENDAR_FIELD] ?? this.topic?.[OFFICIAL_CALENDAR_FIELD] ?? [] : []);
            this.set(OFFICIAL_CALENDAR_FIELD, calendarItemsWithTopicTitle(items, officialCalendarTopicTitle(this), {
              draft: true
            }));
          }
          return result;
        });
      });
    });
  }
};
var Mod57 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfOfficialCalendar$1
});
var isbfOfficialCalendar = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  const site = api.container.lookup("service:site");
  api.registerValueTransformer("post-article-class", ({
    value,
    context
  }) => isOfficialCalendarPost(context.post, site, router.currentURL, context.state?.nestedReplyView) ? [...value, "isbf-official-topic-card"] : value);
  api.renderAfterWrapperOutlet("post-content-cooked-html", ISBFOfficialCalendarItems);
  api.registerNotificationTypeRenderer("custom", () => class extends CustomNotification {
    get isCalendarChange() {
      return this.notification.data.message === "isbf_calendar.changed";
    }
    get description() {
      return this.isCalendarChange ? i18n("notifications.isbf_calendar.changed", {
        topic_title: this.notification.data.topic_title
      }) : super.description;
    }
    get icon() {
      return this.isCalendarChange ? "calendar-days" : super.icon;
    }
    get label() {
      return this.isCalendarChange ? null : super.label;
    }
    get linkHref() {
      return this.isCalendarChange ? `/isbf/calendar?entry_id=${encodeURIComponent(this.notification.data.entry_id)}` : super.linkHref;
    }
    get linkTitle() {
      return this.isCalendarChange ? this.description : super.linkTitle;
    }
  });
});
var Mod58 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfOfficialCalendar
});
const LEARNING_FIELDS = ["isbf_learning_course_id", "isbf_learning_files"];
function isLearningComposer(model) {
  return Boolean(model?.site?.isbf_learning?.category_id > 0 && Number(model.categoryId) === model.site.isbf_learning.category_id && (model.creatingTopic || model.editingPost && model.post?.post_number === 1));
}
function learningFileIds(value) {
  try {
    const ids = typeof value === "string" ? JSON.parse(value) : value;
    return Array.isArray(ids) ? [...new Set(ids.filter(id => /^[a-f0-9-]{36}$/.test(id)))].slice(0, 20) : [];
  } catch {
    return [];
  }
}
function restoreLearning(model, options = {}) {
  if (!isLearningComposer(model)) {
    return;
  }
  for (const field of LEARNING_FIELDS) {
    const value = options[field] ?? options.post?.[field] ?? model[field];
    model.set(field, field === LEARNING_FIELDS[1] ? JSON.stringify(learningFileIds(value)) : value || "");
  }
  model.set("isbf_anonymous", false);
}
function learningPayload(model, field) {
  if (!isLearningComposer(model)) {
    return;
  }
  return field === LEARNING_FIELDS[1] ? JSON.stringify(learningFileIds(model[field])) : model[field] || "";
}
var Mod71 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  LEARNING_FIELDS: LEARNING_FIELDS,
  isLearningComposer: isLearningComposer,
  learningFileIds: learningFileIds,
  learningPayload: learningPayload,
  restoreLearning: restoreLearning
});
class ISBFLearningComposer extends Component {
  static {
    dt7948.g(this.prototype, "courses", [tracked], function () {
      return [];
    });
  }
  #courses = (dt7948.i(this, "courses"), void 0);
  static {
    dt7948.g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (dt7948.i(this, "error"), void 0);
  static {
    dt7948.g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (dt7948.i(this, "loading"), void 0);
  constructor() {
    super(...arguments);
    this.loadCourses();
  }
  get model() {
    return this.args.outletArgs?.model;
  }
  get visible() {
    return isLearningComposer(this.model);
  }
  get options() {
    const labels = ["大一", "大二", "大三", "大四"];
    return this.courses.map(course => ({
      ...course,
      label: `${labels[course.grade - 1]} · ${course.name}`,
      selected: course.id === this.model?.isbf_learning_course_id
    }));
  }
  async loadCourses() {
    if (!this.visible || this.loading) {
      return;
    }
    this.loading = true;
    this.error = false;
    try {
      const data = await ajax("/isbf/learning/courses");
      if (!this.isDestroying && !this.isDestroyed) {
        this.courses = data.courses || [];
      }
    } catch {
      if (!this.isDestroying && !this.isDestroyed) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying && !this.isDestroyed) {
        this.loading = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "loadCourses", [action]);
  }
  selectCourse(event) {
    this.model.set("isbf_learning_course_id", event.target.value);
  }
  static {
    dt7948.n(this.prototype, "selectCourse", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-learning-composer" {{didInsert this.loadCourses}}>
        <label>课程
          <select disabled={{this.loading}} {{on "change" this.selectCourse}}>
            <option value="">请选择课程</option>
            {{#each this.options as |course|}}
              <option
                value={{course.id}}
                selected={{course.selected}}
              >{{course.label}}</option>
            {{/each}}
          </select>
        </label>
        <p
        >填写资料标题。说明可选；请上传资料文件或填写外部链接。普通用户投稿将在审核通过后展示。</p>
        {{#if this.error}}<DButton
            @action={{this.loadCourses}}
            @translatedLabel="加载课程失败，重试"
          />{{/if}}
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-learning-composer\"],[4,[32,0],[[30,0,[\"loadCourses\"]]],null],[12],[1,\"\\n    \"],[10,\"label\"],[12],[1,\"课程\\n      \"],[11,\"select\"],[16,\"disabled\",[30,0,[\"loading\"]]],[4,[32,1],[\"change\",[30,0,[\"selectCourse\"]]],null],[12],[1,\"\\n        \"],[10,\"option\"],[14,2,\"\"],[12],[1,\"请选择课程\"],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"options\"]]],null]],null],null,[[[1,\"          \"],[10,\"option\"],[15,2,[30,1,[\"id\"]]],[15,\"selected\",[30,1,[\"selected\"]]],[12],[1,[30,1,[\"label\"]]],[13],[1,\"\\n\"]],[1]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n    \"],[10,2],[12],[1,\"填写资料标题。说明可选；请上传资料文件或填写外部链接。普通用户投稿将在审核通过后展示。\"],[13],[1,\"\\n    \"],[41,[30,0,[\"error\"]],[[[8,[32,2],null,[[\"@action\",\"@translatedLabel\"],[[30,0,[\"loadCourses\"]],\"加载课程失败，重试\"]],null]],[]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[\"course\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didInsert,
        on,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-learning-composer", ISBFLearningComposer);
var Mod65 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFLearningComposer
});
const nativeEndpoints = new WeakMap();
function configurePrivateUploadEndpoint(uppy, composer) {
  const learning = isLearningComposer(composer);
  const marketplace = isMarketplaceComposer(composer);
  const uploader = uppy.getPlugin("XHRUpload");
  if (!uploader) {
    if (learning || marketplace) {
      throw new Error("私有上传需要登录后的文件传输。");
    }
    return;
  }
  // Both feature processors use one original endpoint, regardless of their order.
  if (!nativeEndpoints.has(uploader)) {
    nativeEndpoints.set(uploader, uploader.opts.endpoint);
  }
  uploader.setOptions({
    endpoint: learning ? getURL("/isbf/learning/uploads.json") : marketplace ? getURL("/isbf/marketplace/uploads.json") : nativeEndpoints.get(uploader)
  });
  if (learning && !composer.isbf_learning_course_id) {
    throw new Error("请先选择课程，再上传资料。");
  }
}
var Mod99 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  configurePrivateUploadEndpoint: configurePrivateUploadEndpoint
});
class LearningUpload extends UploadPreProcessorPlugin {
  static pluginId = "isbf-learning-private-upload";
  #process;
  constructor(uppy, options) {
    super(uppy, options);
    this.#process = this.process.bind(this);
  }
  install() {
    this._install(this.#process);
  }
  uninstall() {
    this._uninstall(this.#process);
  }
  process(ids) {
    configurePrivateUploadEndpoint(this.uppy, this.opts.composerModel);
    return this._emitAllComplete(ids, true);
  }
}
var Mod73 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: LearningUpload
});
var isbfLearning$1 = apiInitializer(api => {
  api.registerReviewableComponent("ReviewableIsbfLearningCourse", async () => (await Promise.resolve().then(function () {
    return Mod78;
  })).default);
  for (const [index, field] of LEARNING_FIELDS.entries()) {
    const property = index ? "isbfLearningFilesPayload" : "isbfLearningCoursePayload";
    Composer.serializeOnCreate(field, property);
    Composer.serializeOnUpdate(field, property);
    Composer.serializeToDraft(field, field);
  }
  api.addModelGetter("composer", "isbfLearningCoursePayload", function () {
    return learningPayload(this, LEARNING_FIELDS[0]);
  });
  api.addModelGetter("composer", "isbfLearningFilesPayload", function () {
    return learningPayload(this, LEARNING_FIELDS[1]);
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.setProperties({
      isbf_learning_course_id: null,
      isbf_learning_files: null
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then(result => {
      restoreLearning(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (isLearningComposer(this) && (!this.title?.trim() || this.title.includes("[isbf-untitled:") || !this.isbf_learning_course_id)) {
      return Promise.resolve(this.dialog.alert("请填写资料标题并选择课程。"));
    }
    return next(...args);
  });
  api.renderInOutlet("before-composer-fields", ISBFLearningComposer);
  api.addComposerUploadPreProcessor(LearningUpload, ({
    composerModel
  }) => ({
    composerModel
  }));
  api.addComposerUploadMarkdownResolver(upload => {
    if (!/^\/isbf\/learning\/files\/[a-f0-9-]{36}$/.test(upload.url || "")) {
      return;
    }
    const model = api.container.lookup("service:composer").model;
    if (!isLearningComposer(model)) {
      return;
    }
    model.set("isbf_learning_files", JSON.stringify([...new Set([...learningFileIds(model.isbf_learning_files), upload.id])]));
    const name = upload.original_filename.replace(/[\[\]|\n\r]/g, "");
    return `[${name}](${upload.url})`;
  });
});
var Mod64 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLearning$1
});
var Mod66 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceDirectoryDialog
});
var Mod67 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceParentPicker
});
var Mod68 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceItem
});
function isbfLearningRouteMap() {
  this.route("isbfLearning", {
    path: "/isbf/learning"
  });
}
var Mod70 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLearningRouteMap
});
class IsbfLearningRoute extends DiscourseRoute {}
var Mod74 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfLearningRoute
});
var isbfLearning = setComponentTemplate(createTemplateFactory(
/*
  
*/
{
  "id": null,
  "block": "[[],[],[]]",
  "moduleName": "(unknown template module)",
  "isStrictMode": true
}), templateOnly());
var Mod75 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLearning
});
var Mod76 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFResourceShareDialog
});
class ReviewableIsbfLearningCourse extends Component {
  get gradeLabel() {
    const grade = this.args.reviewable.payload?.grade;
    return [1, 2, 3, 4].includes(grade) ? i18n(themePrefix(`isbf_v2.learning_grade_${grade}`)) : "";
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <dl>
      <dt>{{i18n (themePrefix "isbf_v2.learning_course_name")}}</dt>
      <dd>{{@reviewable.payload.course_name}}</dd>
      <dt>{{i18n (themePrefix "isbf_v2.learning_grade")}}</dt>
      <dd>{{this.gradeLabel}}</dd>
    </dl>
    */
    {
      "id": null,
      "block": "[[[10,\"dl\"],[12],[1,\"\\n  \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.learning_course_name\"],null]],null]],[13],[1,\"\\n  \"],[10,\"dd\"],[12],[1,[30,1,[\"payload\",\"course_name\"]]],[13],[1,\"\\n  \"],[10,\"dt\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.learning_grade\"],null]],null]],[13],[1,\"\\n  \"],[10,\"dd\"],[12],[1,[30,0,[\"gradeLabel\"]]],[13],[1,\"\\n\"],[13]],[\"@reviewable\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("reviewable-isbf-learning-course", ReviewableIsbfLearningCourse);
var Mod78 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ReviewableIsbfLearningCourse
});
function isbfAlumniRouteMap() {
  this.route("isbfAlumni", {
    path: "/isbf/alumni"
  });
}
var Mod83 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfAlumniRouteMap
});
class IsbfAlumniRoute extends DiscourseRoute {}
var Mod85 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfAlumniRoute
});
class ISBFHomeDisplayOption extends Component {
  get checked() {
    return this.args.checked === true;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <label class="isbf-home-display-option" ...attributes>
      <input
        checked={{this.checked}}
        type="checkbox"
        {{on "change" @onChange}}
      />
      <span>{{@label}}</span>
    </label>
    */
    {
      "id": null,
      "block": "[[[11,\"label\"],[24,0,\"isbf-home-display-option\"],[17,1],[12],[1,\"\\n  \"],[11,\"input\"],[16,\"checked\",[30,0,[\"checked\"]]],[24,4,\"checkbox\"],[4,[32,0],[\"change\",[30,2]],null],[12],[13],[1,\"\\n  \"],[10,1],[12],[1,[30,3]],[13],[1,\"\\n\"],[13]],[\"&attrs\",\"@onChange\",\"@label\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-home-display-option", ISBFHomeDisplayOption);
var Mod108 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFHomeDisplayOption
});
class ISBFMarketplaceComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }
  get visible() {
    return isMarketplaceComposer(this.model);
  }
  changePrice(event) {
    this.model.set("isbf_marketplace_price", event.target.value);
  }
  static {
    dt7948.n(this.prototype, "changePrice", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-marketplace-composer">
        <label>{{i18n (themePrefix "isbf_v2.marketplace_price")}}
          <input
            inputmode="decimal"
            required
            type="text"
            value={{this.model.isbf_marketplace_price}}
            {{on "input" this.changePrice}}
          />
        </label>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-marketplace-composer\"],[12],[1,\"\\n    \"],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.marketplace_price\"],null]],null]],[1,\"\\n      \"],[11,\"input\"],[24,\"inputmode\",\"decimal\"],[24,\"required\",\"\"],[16,2,[30,0,[\"model\",\"isbf_marketplace_price\"]]],[24,4,\"text\"],[4,[32,2],[\"input\",[30,0,[\"changePrice\"]]],null],[12],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFMarketplaceHome extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }
  get visible() {
    return isMarketplaceComposer(this.model);
  }
  changeHome(event) {
    this.model.set("isbf_marketplace_home", event.target.checked);
  }
  static {
    dt7948.n(this.prototype, "changeHome", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-marketplace-composer-options">
        <ISBFHomeDisplayOption
          class="isbf-marketplace-composer__home"
          @checked={{this.model.isbf_marketplace_home}}
          @label={{i18n (themePrefix "isbf_v2.marketplace_home")}}
          @onChange={{this.changeHome}}
        />
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-marketplace-composer-options\"],[12],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-marketplace-composer__home\"]],[[\"@checked\",\"@label\",\"@onChange\"],[[30,0,[\"model\",\"isbf_marketplace_home\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.marketplace_home\"],null]],null],[30,0,[\"changeHome\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFHomeDisplayOption,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-marketplace-composer", ISBFMarketplaceComposer);
var Mod94 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFMarketplaceHome: ISBFMarketplaceHome,
  default: ISBFMarketplaceComposer
});
class MarketplaceUpload extends UploadPreProcessorPlugin {
  static pluginId = "isbf-marketplace-private-upload";
  #process;
  constructor(uppy, options) {
    super(uppy, options);
    this.#process = this.process.bind(this);
  }
  install() {
    this._install(this.#process);
  }
  uninstall() {
    this._uninstall(this.#process);
  }
  process(ids) {
    configurePrivateUploadEndpoint(this.uppy, this.opts.composerModel, this.opts.composerModel?.site);
    return this._emitAllComplete(ids, true);
  }
}
var Mod97 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: MarketplaceUpload
});
var isbfMarketplace$1 = apiInitializer(api => {
  const properties = ["isbfMarketplacePricePayload", "isbfMarketplaceImagesPayload", "isbfMarketplaceHomePayload"];
  MARKETPLACE_FIELDS.forEach((field, index) => {
    Composer.serializeOnCreate(field, properties[index]);
    Composer.serializeOnUpdate(field, properties[index]);
    Composer.serializeToDraft(field, field);
    api.addModelGetter("composer", properties[index], function () {
      return marketplacePayload(this, field);
    });
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.setProperties({
      isbf_marketplace_price: null,
      isbf_marketplace_images: null,
      isbf_marketplace_home: null
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then(result => {
      restoreMarketplace(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (isMarketplaceComposer(this) && (!this.title?.trim() || this.title.includes("[isbf-untitled:") || !this.reply?.trim() || !validMarketplacePrice(this.isbf_marketplace_price))) {
      return Promise.resolve(this.dialog.alert(i18n(themePrefix("isbf_v2.marketplace_validation"))));
    }
    return next(...args);
  });
  api.renderInOutlet("after-title-and-category", ISBFMarketplaceComposer);
  api.renderInOutlet("after-title-and-category", ISBFMarketplaceHome);
  api.customizeComposerText({
    titlePlaceholder: model => isMarketplaceComposer(model) ? themePrefix("isbf_v2.marketplace_name") : null
  });
  api.registerValueTransformer("composer-editor-reply-placeholder", ({
    value,
    context
  }) => isMarketplaceComposer(context?.model?.model) ? themePrefix("isbf_v2.marketplace_description") : value);
  api.renderAfterWrapperOutlet("post-metadata", ISBFMarketplacePrice);
  api.addComposerUploadPreProcessor(MarketplaceUpload, ({
    composerModel
  }) => ({
    composerModel
  }));
  api.addComposerUploadMarkdownResolver(upload => marketplaceUploadMarkdown(upload, api.container.lookup("service:composer").model));
});
var Mod92 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfMarketplace$1
});
function isbfMarketplaceRouteMap() {
  this.route("isbfMarketplace", {
    path: "/isbf/marketplace"
  });
}
var Mod96 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfMarketplaceRouteMap
});
class IsbfMarketplaceRoute extends DiscourseRoute {}
var Mod100 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfMarketplaceRoute
});
var isbfMarketplace = setComponentTemplate(createTemplateFactory(
/*
  
*/
{
  "id": null,
  "block": "[[],[],[]]",
  "moduleName": "(unknown template module)",
  "isStrictMode": true
}), templateOnly());
var Mod101 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfMarketplace
});
var isbfContentImages = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  const decorate = (element, helper) => {
    if (/^\/admin(?:\/|$)/.test(router.currentURL)) {
      return;
    }
    return decorateContentImages(element, {
      onError: popupAjaxError,
      post: helper?.model,
      previewLabel: i18n(themePrefix("isbf_v2.preview_image")),
      retryLabel: i18n(themePrefix("isbf_v2.image_retry"))
    });
  };
  api.decorateCookedElement(decorate, {
    id: "isbf-content-images"
  });
  api.decorateChatMessage?.(decorate, {
    id: "isbf-content-images"
  });
});
var Mod103 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfContentImages
});
class ISBFTeamupComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }
  get visible() {
    return isTeamupComposer(this.model);
  }
  changeHome(event) {
    this.model.set(TEAMUP_HOME_FIELD, event.target.checked);
  }
  static {
    dt7948.n(this.prototype, "changeHome", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-teamup-composer">
        <ISBFHomeDisplayOption
          @checked={{this.model.isbf_teamup_home}}
          @label={{i18n (themePrefix "isbf_v2.marketplace_home")}}
          @onChange={{this.changeHome}}
        />
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-teamup-composer\"],[12],[1,\"\\n    \"],[8,[32,0],null,[[\"@checked\",\"@label\",\"@onChange\"],[[30,0,[\"model\",\"isbf_teamup_home\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.marketplace_home\"],null]],null],[30,0,[\"changeHome\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFHomeDisplayOption,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-teamup-composer", ISBFTeamupComposer);
var Mod109 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFTeamupComposer
});
var isbfTeamup$1 = apiInitializer(api => {
  Composer.serializeOnCreate(TEAMUP_HOME_FIELD, "isbfTeamupHomePayload");
  Composer.serializeOnUpdate(TEAMUP_HOME_FIELD, "isbfTeamupHomePayload");
  Composer.serializeToDraft(TEAMUP_HOME_FIELD, TEAMUP_HOME_FIELD);
  api.addModelGetter("composer", "isbfTeamupHomePayload", function () {
    return teamupPayload(this);
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.set(TEAMUP_HOME_FIELD, null);
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then(result => {
      restoreTeamup(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (isTeamupComposer(this) && (!this.title?.trim() || isUntitledTopicTitle(this.title) || !this.reply?.trim())) {
      return Promise.resolve(this.dialog.alert(i18n(themePrefix("isbf_v2.teamup_validation"))));
    }
    return next(...args);
  });
  api.onAppEvent("composer:category-changed", model => {
    if (isTeamupCategory(model)) {
      if (model.creatingTopic && isUntitledTopicTitle(model.title)) {
        model.setProperties({
          title: "",
          isbf_optional_title: null
        });
      }
      restoreTeamup(model);
    } else if (model[TEAMUP_HOME_FIELD] !== null && model[TEAMUP_HOME_FIELD] !== undefined) {
      model.set(TEAMUP_HOME_FIELD, null);
      if (isQuickPost(model)) {
        prepareOptionalTopicTitle(model);
      }
    }
  });
  api.onAppEvent("composer:edited-post", () => {
    const model = api.container.lookup("service:composer").model;
    const id = Number(model?.post?.id);
    if (isTeamupComposer(model) && Number.isSafeInteger(id) && id > 0) {
      invalidateCookedPost(id, false);
    }
  });
  api.renderInOutlet("after-title-and-category", ISBFTeamupComposer);
});
var Mod107 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfTeamup$1
});
function isbfTeamupRouteMap() {
  this.route("isbfTeamup", {
    path: "/isbf/teamup"
  });
}
var Mod112 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfTeamupRouteMap
});
class IsbfTeamupRoute extends DiscourseRoute {}
var Mod114 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfTeamupRoute
});
var isbfTeamup = setComponentTemplate(createTemplateFactory(
/*
  
*/
{
  "id": null,
  "block": "[[],[],[]]",
  "moduleName": "(unknown template module)",
  "isStrictMode": true
}), templateOnly());
var Mod115 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfTeamup
});
function methodDescriptor(prototype, name) {
  while (prototype) {
    const descriptor = Object.getOwnPropertyDescriptor(prototype, name);
    if (descriptor) {
      return descriptor;
    }
    prototype = Object.getPrototypeOf(prototype);
  }
}
var isbfTopicPinning = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  const site = api.container.lookup("service:site");
  const siteSettings = api.container.lookup("service:site-settings");
  const appEvents = api.container.lookup("service:app-events");
  const scheduler = new PinExpiryScheduler({
    enabled: () => isPinningContext(router, site, siteSettings),
    onChange: () => appEvents.trigger("isbf:home-pins-changed")
  });
  const topicListClass = api.container.factoryFor("model:topic-list").class;
  const originalMunge = topicListClass.munge;
  topicListClass.munge = function (json, ...args) {
    const result = originalMunge.call(this, json, ...args);
    result.isbfHomePinScope = json.topic_list?.isbf_home_pinning_scope === true;
    return result;
  };
  api.registerValueTransformer("topic-list-topics-from", ({
    value,
    context
  }) => context.result.topic_list?.isbf_home_pinning_scope === true && (!context.opts.listKey || context.opts.listKey === "topics") ? [...value].sort((left, right) => compareHomeTopics(left, right)) : value);
  for (const name of ["init", "loadBefore", "loadMore", "willDestroy"]) {
    const descriptor = methodDescriptor(topicListClass.prototype, name);
    if (!descriptor) {
      continue;
    }
    const invoke = (instance, args) => {
      const original = descriptor.get ? descriptor.get.call(instance) : descriptor.value;
      return original.apply(instance, args);
    };
    if (name === "loadBefore" || name === "loadMore") {
      api.addModelMethod("topic-list", name, async function (...args) {
        const result = await invoke(this, args);
        if (!this.isDestroying && !this.isDestroyed) {
          scheduler.register(this);
          scheduler.refresh();
        }
        return result;
      });
    } else {
      api.addModelMethod("topic-list", name, function (...args) {
        if (name === "willDestroy") {
          scheduler.remove(this);
        }
        const result = invoke(this, args);
        if (name === "init") {
          scheduler.register(this);
        }
        return result;
      });
    }
  }
  appEvents.on("isbf:home-pin-saved", scheduler, "refresh");
  router.on("routeDidChange", scheduler, "refresh");
  registerDestructor(router, () => {
    scheduler.destroy();
    appEvents.off("isbf:home-pin-saved", scheduler, "refresh");
    router.off("routeDidChange", scheduler, "refresh");
  });
});
var Mod116 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfTopicPinning
});
var isbfLibrary$1 = apiInitializer(api => {
  api.registerReviewableComponent("ReviewableIsbfLibraryDirectory", async () => (await Promise.resolve().then(function () {
    return Mod128;
  })).default);
});
var Mod119 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLibrary$1
});
class ReviewableIsbfLibraryDirectory extends Component {
  get kindLabel() {
    return i18n(themePrefix(this.args.reviewable.payload.kind === "category" ? "isbf_v2.library_category" : "isbf_v2.library_groups"));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <p>{{this.kindLabel}}：{{@reviewable.payload.name}}</p>
    */
    {
      "id": null,
      "block": "[[[10,2],[12],[1,[30,0,[\"kindLabel\"]]],[1,\"：\"],[1,[30,1,[\"payload\",\"name\"]]],[13]],[\"@reviewable\"],[]]",
      "moduleName": "(unknown template module)",
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("reviewable-isbf-library-directory", ReviewableIsbfLibraryDirectory);
var Mod128 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ReviewableIsbfLibraryDirectory
});
function isbfLibraryRouteMap() {
  this.route("isbfLibrary", {
    path: "/isbf/library"
  });
}
var Mod129 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLibraryRouteMap
});
class IsbfLibraryRoute extends DiscourseRoute {}
var Mod130 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfLibraryRoute
});
var isbfLibrary = setComponentTemplate(createTemplateFactory(
/*
  
*/
{
  "id": null,
  "block": "[[],[],[]]",
  "moduleName": "(unknown template module)",
  "isStrictMode": true
}), templateOnly());
var Mod131 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfLibrary
});
class ISBFFrontendHeading extends Component {
  static {
    dt7948.g(this.prototype, "_router", [service("router")]);
  }
  #_router = (dt7948.i(this, "_router"), void 0);
  get title() {
    const route = normalizedRouteName(this._router.currentRouteName);
    const scope = frontendConsistencyScope(route);
    if (scope?.id === "directory") {
      return i18n("directory.title");
    }
    if (scope?.id === "groups" && route === "groups.index") {
      return i18n("groups.index.all");
    }
    if (scope?.id !== "preferences") {
      return null;
    }
    const child = route.split(".")[1];
    const overrides = {
      email: "user.email.title",
      "second-factor": "user.second_factor.title"
    };
    return i18n(overrides[child] ?? `user.preferences_nav.${child.replaceAll("-", "_")}`);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.title}}
      <h1 class="isbf-frontend__heading">{{this.title}}</h1>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"title\"]],[[[1,\"  \"],[10,\"h1\"],[14,0,\"isbf-frontend__heading\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-frontend-heading", ISBFFrontendHeading);
var Mod133 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFFrontendHeading
});
const INVITE_DIALOGS = new Set([CreateInvite, CreateInviteBulk, CreateInviteWithRoles]);
const PREFERENCE_DIALOGS = new Set([AvatarSelector, SecondFactorAddSecurityKey, SecondFactorAddTotp, SecondFactorBackupEdit, SecondFactorEdit, SecondFactorEditSecurityKey]);
const DIRECTORY_DIALOGS = new Set([EditUserDirectoryColumns]);
const BOOKMARK_DIALOGS = new Set([Bookmark]);
const DRAFT_DIALOGS = new Set([DiscardDraft]);
const GROUP_DIALOGS = new Set([GroupAddMembers, GroupDefaultNotifications, RequestGroupMembershipForm]);
const CONFIRMATION_SCOPES = new Set(["preferences", "invitations", "bookmarks", "drafts", "pending", "messages", "groups", "group", "group-manage", "group-messages"]);
function matchesComponent(component, candidates) {
  return [...candidates].some(candidate => candidate === component || component?.prototype && candidate.prototype && Object.prototype.isPrototypeOf.call(candidate.prototype, component.prototype));
}
class ISBFFrontendScope extends Component {
  static {
    dt7948.g(this.prototype, "_dialog", [service("dialog")]);
  }
  #_dialog = (dt7948.i(this, "_dialog"), void 0);
  static {
    dt7948.g(this.prototype, "_modal", [service("modal")]);
  }
  #_modal = (dt7948.i(this, "_modal"), void 0);
  static {
    dt7948.g(this.prototype, "_router", [service("router")]);
  }
  #_router = (dt7948.i(this, "_router"), void 0);
  get #scope() {
    return frontendConsistencyScope(this._router.currentRouteName);
  }
  get #dialogEnabled() {
    const component = this._modal.activeModal?.component;
    const route = normalizedRouteName(this._router.currentRouteName);
    if (get(this._dialog, "show") && CONFIRMATION_SCOPES.has(this.#scope?.id)) {
      return true;
    }
    if (matchesComponent(component, INVITE_DIALOGS)) {
      return this.#scope?.id === "invitations" || ["groups", "group", "group-manage"].includes(this.#scope?.id) || route === "new-invite" || route.startsWith("discovery.");
    }
    if (this.#scope?.id === "preferences") {
      return matchesComponent(component, PREFERENCE_DIALOGS);
    }
    if (this.#scope?.id === "bookmarks") {
      return matchesComponent(component, BOOKMARK_DIALOGS);
    }
    if (this.#scope?.id === "drafts") {
      return matchesComponent(component, DRAFT_DIALOGS);
    }
    if (["groups", "group", "group-manage", "group-messages"].includes(this.#scope?.id)) {
      return matchesComponent(component, GROUP_DIALOGS);
    }
    return this.#scope?.id === "directory" && matchesComponent(component, DIRECTORY_DIALOGS);
  }
  get bodyClasses() {
    if (!this.#scope && !this.#dialogEnabled) {
      return null;
    }
    const classes = ["isbf-frontend"];
    if (this.#scope) {
      classes.push(`is-frontend-${this.#scope.id}`);
      if (this.#scope.layout === "feature") {
        classes.push("has-frontend-feature");
      }
      if (this.#scope.userContent) {
        classes.push("has-frontend-user-content");
      } else {
        classes.push("has-frontend-page");
      }
    }
    if (this.#dialogEnabled) {
      classes.push("has-frontend-dialog");
    }
    return classes.join(" ");
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{bodyClass this.bodyClasses}}
    */
    {
      "id": null,
      "block": "[[[1,[28,[32,0],[[30,0,[\"bodyClasses\"]]],null]]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        bodyClass
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-frontend-scope", ISBFFrontendScope);
var Mod134 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFFrontendScope
});
var isbfFrontendConsistency = apiInitializer(api => {
  api.renderInOutlet("before-main-outlet", ISBFFrontendScope);
  api.renderInOutlet("users-top", ISBFFrontendHeading);
  api.renderInOutlet("above-user-preferences", ISBFFrontendHeading);
  api.renderInOutlet("before-groups-index-container", ISBFFrontendHeading);
});
var Mod132 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfFrontendConsistency
});
class GroupManageMembers extends GroupIndex {
  controllerName = "group.index";
  templateName = "group.index";
}
var Mod136 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: GroupManageMembers
});
var isbfUserDisplay = apiInitializer(api => {
  const router = api.container.lookup("service:router");
  api.modifyClass("component:post/meta-data/poster-name", Superclass => {
    return class extends Superclass {
      get name() {
        return isFeedStylePost(this.args.post, router.currentURL) ? displayName(this.user) : super.name;
      }
    };
  });
  api.modifyClass("component:user-menu/menu-item", Superclass => {
    return class extends Superclass {
      get label() {
        return this.args.item instanceof UserMenuNotificationItem ? notificationDisplayLabel(this.args.item, super.label) : super.label;
      }
    };
  });
});
var Mod138 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfUserDisplay
});
const initializedApis = new WeakSet();
const registeredToolbars = new WeakSet();
function pollBuilder() {
  try {
    return optionalRequire("discourse/plugins/poll/discourse/components/modal/poll-ui-builder");
  } catch {
    return null;
  }
}
var isbfPoll = apiInitializer(api => {
  if (initializedApis.has(api)) {
    return;
  }
  initializedApis.add(api);
  const siteSettings = api.container.lookup("service:site-settings");
  const composer = api.container.lookup("service:composer");
  const modal = api.container.lookup("service:modal");
  let opening = false;
  const canCreatePoll = () => {
    const currentUser = api.getCurrentUser();
    return Boolean(composer.model && !composer.model.isDestroyed && !composer.model.isDestroying && siteSettings.poll_enabled && pollBuilder() && (composer.model?.topic?.pm_with_non_human_user || currentUser && (currentUser.staff || currentUser.can_create_poll)));
  };
  api.onToolbarCreate(toolbar => {
    if (registeredToolbars.has(toolbar)) {
      return;
    }
    registeredToolbars.add(toolbar);
    toolbar.addButton({
      id: "isbf-poll",
      group: "extras",
      icon: "chart-bar",
      title: themePrefix("isbf_v2.poll_button_title"),
      translatedLabel: i18n(themePrefix("isbf_v2.poll_button")),
      condition: canCreatePoll,
      sendAction: async toolbarEvent => {
        const builder = pollBuilder();
        if (!builder || !toolbarEvent || !canCreatePoll() || opening || modal.activeModal?.component === builder) {
          return;
        }
        opening = true;
        try {
          await modal.show(builder, {
            model: {
              toolbarEvent
            }
          });
        } finally {
          opening = false;
        }
      }
    });
  });
});
var Mod140 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfPoll
});
const STORE_KEY = "isbfBackNavigation";
const MAX_ENTRIES = 100;
class BackNavigationHistory {
  #browser;
  #entries = [];
  #index = -1;
  #storage;
  constructor(storage, browser = window) {
    this.#browser = browser;
    this.#storage = storage;
    try {
      const saved = storage.getObject(STORE_KEY);
      if (Array.isArray(saved?.entries) && saved.entries.length <= MAX_ENTRIES && saved.entries.every(entry => this.#validEntry(entry))) {
        this.#entries = saved.entries;
      }
    } catch {}
    this.traverse();
  }
  get previousURL() {
    return this.#entries[this.#index - 1]?.url ?? null;
  }
  capture() {
    const entry = this.#currentEntry();
    if (!entry) {
      return;
    }
    if (this.#index < 0) {
      this.#entries = [entry];
      this.#index = 0;
    } else {
      this.#entries[this.#index] = entry;
    }
    this.#save();
  }
  commit(replace = false) {
    const entry = this.#currentEntry();
    if (!entry) {
      return;
    }
    if (replace || this.#index < 0 || this.#entries[this.#index]?.uuid === entry.uuid) {
      this.capture();
      return;
    }
    this.#entries = this.#entries.slice(0, this.#index + 1);
    this.#entries.push(entry);
    if (this.#entries.length > MAX_ENTRIES) {
      this.#entries.shift();
    }
    this.#index = this.#entries.length - 1;
    this.#save();
  }
  traverse() {
    const entry = this.#currentEntry();
    const index = entry ? this.#entries.findIndex(item => item.uuid === entry.uuid) : -1;
    if (index < 0) {
      this.#entries = entry ? [entry] : [];
      this.#index = this.#entries.length - 1;
    } else {
      this.#index = index;
      this.#entries[index] = entry;
    }
    this.#save();
  }
  #currentEntry() {
    const {
      history,
      location
    } = this.#browser;
    const entry = {
      uuid: history.state?.uuid,
      url: location.pathname + location.search + location.hash
    };
    return this.#validEntry(entry) ? entry : null;
  }
  #save() {
    try {
      this.#storage.setObject({
        key: STORE_KEY,
        value: {
          entries: this.#entries
        }
      });
    } catch {}
  }
  #validEntry(entry) {
    if (typeof entry?.uuid !== "string" || !entry.uuid || typeof entry.url !== "string" || !entry.url.startsWith("/")) {
      return false;
    }
    try {
      return new URL(entry.url, this.#browser.location.origin).origin === this.#browser.location.origin;
    } catch {
      return false;
    }
  }
}
var Mod144 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: BackNavigationHistory
});
class ISBFBackNavigation extends Service {
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  static {
    dt7948.g(this.prototype, "sessionStore", [service]);
  }
  #sessionStore = (dt7948.i(this, "sessionStore"), void 0);
  static {
    dt7948.g(this.prototype, "previousURL", [tracked], function () {
      return null;
    });
  }
  #previousURL = (dt7948.i(this, "previousURL"), void 0);
  #history;
  #onPopState = () => {
    this.#history.traverse();
    this.previousURL = this.#history.previousURL;
  };
  constructor() {
    super(...arguments);
    this.#history = new BackNavigationHistory(this.sessionStore);
    this.previousURL = this.#history.previousURL;
    this.router.on("routeWillChange", this.captureBrowserEntry);
    this.router.on("routeDidChange", this.recordTransition);
    window.addEventListener("popstate", this.#onPopState, true);
    // Topic scrolling replaces the history UUID without emitting route events.
    window.addEventListener("pagehide", this.captureBrowserEntry);
  }
  willDestroy() {
    this.router.off("routeWillChange", this.captureBrowserEntry);
    this.router.off("routeDidChange", this.recordTransition);
    window.removeEventListener("popstate", this.#onPopState, true);
    window.removeEventListener("pagehide", this.captureBrowserEntry);
    super.willDestroy(...arguments);
  }
  back(event) {
    if (wantsNewWindow(event) || event.altKey) {
      return;
    }
    this.captureBrowserEntry();
    if (this.previousURL) {
      event.preventDefault();
      window.history.back();
    }
  }
  href(fallback) {
    return this.previousURL ?? getURL(fallback);
  }
  captureBrowserEntry() {
    this.#history.capture();
    this.previousURL = this.#history.previousURL;
  }
  static {
    dt7948.n(this.prototype, "captureBrowserEntry", [bind]);
  }
  recordTransition(transition) {
    if (transition.isAborted) {
      return;
    }
    transition.then(() => {
      if (!this.isDestroying) {
        this.#history.commit(!transition.from || transition.urlMethod === "replace");
        this.previousURL = this.#history.previousURL;
      }
    }, () => {});
  }
  static {
    dt7948.n(this.prototype, "recordTransition", [bind]);
  }
}
var Mod145 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFBackNavigation
});
var isbfBackNavigation = apiInitializer(api => {
  const owner = getOwner(api.container.lookup("service:router"));
  if (!owner.hasRegistration("service:isbf-back-navigation")) {
    owner.register("service:isbf-back-navigation", ISBFBackNavigation);
  }
  owner.lookup("service:isbf-back-navigation");
});
var Mod143 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfBackNavigation
});
var isbfOfficialComposerControls = apiInitializer(api => {
  const composer = api.container.lookup("service:composer");
  const site = api.container.lookup("service:site");
  api.modifyClass("component:mini-tag-chooser", {
    pluginId: "isbf-ui-official-composer-tags",
    modifyNoSelection() {
      const original = this._super(...arguments);
      const config = officialConfig(site);
      const options = this.selectKit.options;
      if (!composer.isOpen || !isOfficialComposer(composer.model, config) || Number(options.categoryId) !== config.category_id || !options.prioritizeRecentTags || options.minimum > 0) {
        return original;
      }
      return this.defaultItem(null, i18n(themePrefix("isbf_v2.official_tags")));
    }
  });
});
var Mod147 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfOfficialComposerControls
});
var isbfOfficial = apiInitializer(setup);
var Mod148 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfOfficial
});
class ISBFCalendarSubscriptionFeed extends Component {
  get url() {
    return this.args.outletArgs?.urls?.isbf_personal;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.url}}
      <CalendarSubscriptionUrl
        @description={{i18n
          (themePrefix "isbf_v2.calendar_subscription_description")
        }}
        @label={{i18n (themePrefix "isbf_v2.calendar_subscription_name")}}
        @url={{this.url}}
      />
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"url\"]],[[[1,\"  \"],[8,[32,0],null,[[\"@description\",\"@label\",\"@url\"],[[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_description\"],null]],null],[28,[32,1],[[28,[32,2],[\"isbf_v2.calendar_subscription_name\"],null]],null],[30,0,[\"url\"]]]],null],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        CalendarSubscriptionUrl,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-calendar-subscription-feed", ISBFCalendarSubscriptionFeed);
var Mod154 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFCalendarSubscriptionFeed
});
var isbfCalendarSubscription = apiInitializer(api => {
  api.renderInOutlet("calendar-subscriptions-feeds", ISBFCalendarSubscriptionFeed);
});
var Mod156 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfCalendarSubscription
});
class ISBFCareersComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }
  get visible() {
    return isCareersComposer(this.model);
  }
  changeSalary(event) {
    this.model.set("isbf_careers_salary", event.target.value);
  }
  static {
    dt7948.n(this.prototype, "changeSalary", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-careers-composer">
        <label>{{i18n (themePrefix "isbf_v2.careers_salary")}}
          <input
            type="text"
            value={{this.model.isbf_careers_salary}}
            {{on "input" this.changeSalary}}
          />
        </label>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-careers-composer\"],[12],[1,\"\\n    \"],[10,\"label\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.careers_salary\"],null]],null]],[1,\"\\n      \"],[11,\"input\"],[16,2,[30,0,[\"model\",\"isbf_careers_salary\"]]],[24,4,\"text\"],[4,[32,2],[\"input\",[30,0,[\"changeSalary\"]]],null],[12],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
class ISBFCareersHome extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }
  get visible() {
    return isCareersComposer(this.model);
  }
  changeHome(event) {
    this.model.set("isbf_careers_home", event.target.checked);
  }
  static {
    dt7948.n(this.prototype, "changeHome", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.visible}}
      <div class="isbf-careers-composer-options">
        <ISBFHomeDisplayOption
          class="isbf-careers-composer__home"
          @checked={{this.model.isbf_careers_home}}
          @label={{i18n (themePrefix "isbf_v2.careers_home")}}
          @onChange={{this.changeHome}}
        />
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"visible\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-careers-composer-options\"],[12],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-careers-composer__home\"]],[[\"@checked\",\"@label\",\"@onChange\"],[[30,0,[\"model\",\"isbf_careers_home\"]],[28,[32,1],[[28,[32,2],[\"isbf_v2.careers_home\"],null]],null],[30,0,[\"changeHome\"]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFHomeDisplayOption,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-careers-composer", ISBFCareersComposer);
var Mod163 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  ISBFCareersHome: ISBFCareersHome,
  default: ISBFCareersComposer
});
var isbfCareers$1 = apiInitializer(api => {
  const properties = ["isbfCareersSalaryPayload", "isbfCareersHomePayload"];
  CAREERS_FIELDS.forEach((field, index) => {
    Composer.serializeOnCreate(field, properties[index]);
    Composer.serializeOnUpdate(field, properties[index]);
    Composer.serializeToDraft(field, field);
    api.addModelGetter("composer", properties[index], function () {
      return careersPayload(this, field);
    });
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.setProperties({
      isbf_careers_salary: null,
      isbf_careers_home: null
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then(result => {
      restoreCareers(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (isCareersComposer(this) && (!this.title?.trim() || isUntitledTopicTitle(this.title) || !this.reply?.trim() || !validCareersSalary(this.isbf_careers_salary))) {
      return Promise.resolve(this.dialog.alert(i18n(themePrefix("isbf_v2.careers_validation"))));
    }
    return next(...args);
  });
  api.onAppEvent("composer:category-changed", model => {
    if (isCareersCategory(model)) {
      if (model.creatingTopic && isUntitledTopicTitle(model.title)) {
        model.setProperties({
          title: "",
          isbf_optional_title: null
        });
      }
      restoreCareers(model);
    } else if (CAREERS_FIELDS.some(field => model[field] != null)) {
      CAREERS_FIELDS.forEach(field => model.set(field, null));
      if (isQuickPost(model)) {
        prepareOptionalTopicTitle(model);
      }
    }
  });
  api.onAppEvent("composer:edited-post", () => {
    const model = api.container.lookup("service:composer").model;
    const id = Number(model?.post?.id);
    if (isCareersComposer(model) && Number.isSafeInteger(id) && id > 0) {
      invalidateCookedPost(id, false);
    }
  });
  api.renderInOutlet("after-title-and-category", ISBFCareersComposer);
  api.renderInOutlet("after-title-and-category", ISBFCareersHome);
  api.customizeComposerText({
    titlePlaceholder: model => isCareersComposer(model) ? themePrefix("isbf_v2.careers_name") : null
  });
  api.registerValueTransformer("composer-editor-reply-placeholder", ({
    value,
    context
  }) => isCareersComposer(context?.model?.model) ? themePrefix("isbf_v2.careers_description") : value);
  api.renderAfterWrapperOutlet("post-metadata", ISBFCareersSalary);
});
var Mod161 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfCareers$1
});
function isbfCareersRouteMap() {
  this.route("isbfCareers", {
    path: "/isbf/careers"
  });
}
var Mod166 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfCareersRouteMap
});
class IsbfCareersRoute extends DiscourseRoute {}
var Mod168 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: IsbfCareersRoute
});
var isbfCareers = setComponentTemplate(createTemplateFactory(
/*
  
*/
{
  "id": null,
  "block": "[[],[],[]]",
  "moduleName": "(unknown template module)",
  "isStrictMode": true
}), templateOnly());
var Mod169 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfCareers
});
class ISBFContinueReadingFooter extends BrowseMore {
  get navigation() {
    const data = this.topicBrowseMoreData;
    const {
      category,
      latestUrl,
      newTopics,
      unreadTopics
    } = data;
    return {
      ...data,
      browseLabel: category ? i18n(themePrefix("isbf_v2.continue_reading.browse_category"), {
        category: category.name
      }) : i18n("topic.browse_latest_topics"),
      browseUrl: category ? getURL(`/c/${Category.slugFor(category)}/${category.id}`) : latestUrl,
      hasRemainingTopics: newTopics + unreadTopics > 0
    };
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#let this.navigation as |navigation|}}
      <nav
        aria-label={{i18n (themePrefix "isbf_v2.continue_reading.browse")}}
        class="isbf-continue-reading__footer"
        ...attributes
      >
        {{#if navigation.hasRemainingTopics}}
          <div class="isbf-continue-reading__remaining">
            {{#if (gt navigation.newTopics 0)}}
              <a href={{navigation.newUrl}}>
                {{i18n
                  (themePrefix "isbf_v2.continue_reading.remaining_new")
                  count=navigation.newTopics
                }}
              </a>
            {{/if}}
            {{#if (gt navigation.unreadTopics 0)}}
              <a href={{navigation.unreadUrl}}>
                {{i18n
                  (themePrefix "isbf_v2.continue_reading.remaining_unread")
                  count=navigation.unreadTopics
                }}
              </a>
            {{/if}}
          </div>
        {{/if}}
    
        <div class="isbf-continue-reading__browse">
          {{#unless navigation.hasRemainingTopics}}
            {{#if navigation.category}}
              <a href={{navigation.latestUrl}}>
                {{i18n "topic.browse_latest_topics"}}
              </a>
            {{else}}
              <a href={{navigation.categoriesUrl}}>
                {{i18n (themePrefix "isbf_v2.continue_reading.all_categories")}}
              </a>
            {{/if}}
          {{/unless}}
          <a
            class="isbf-continue-reading__browse-all"
            href={{navigation.browseUrl}}
            title={{navigation.browseLabel}}
          >{{i18n (themePrefix "isbf_v2.continue_reading.browse_all")}}</a>
        </div>
      </nav>
    {{/let}}
    */
    {
      "id": null,
      "block": "[[[44,[[30,0,[\"navigation\"]]],[[[1,\"  \"],[11,\"nav\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.browse\"],null]],null]],[24,0,\"isbf-continue-reading__footer\"],[17,2],[12],[1,\"\\n\"],[41,[30,1,[\"hasRemainingTopics\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-continue-reading__remaining\"],[12],[1,\"\\n\"],[41,[28,[32,2],[[30,1,[\"newTopics\"]],0],null],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"newUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.remaining_new\"],null]],[[\"count\"],[[30,1,[\"newTopics\"]]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[41,[28,[32,2],[[30,1,[\"unreadTopics\"]],0],null],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"unreadUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.remaining_unread\"],null]],[[\"count\"],[[30,1,[\"unreadTopics\"]]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"isbf-continue-reading__browse\"],[12],[1,\"\\n\"],[41,[51,[30,1,[\"hasRemainingTopics\"]]],[[[41,[30,1,[\"category\"]],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"latestUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[\"topic.browse_latest_topics\"],null]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"categoriesUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.all_categories\"],null]],null]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]]],[]],null],[1,\"      \"],[10,3],[14,0,\"isbf-continue-reading__browse-all\"],[15,6,[30,1,[\"browseUrl\"]]],[15,\"title\",[30,1,[\"browseLabel\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.browse_all\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[1]]]],[\"navigation\",\"&attrs\"],[\"let\",\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        gt
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-continue-reading-footer", ISBFContinueReadingFooter);
var Mod173 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFContinueReadingFooter
});
class ISBFContinueReadingItem extends TopicListItem {
  get defaultAvatarUrl() {
    return getURL("/images/avatar.png");
  }
  get hasEssentialStatus() {
    const topic = this.args.topic;
    return topic.closed || topic.archived || topic.invisible || topic.is_warning;
  }
  get hasUnread() {
    const topic = this.args.topic;
    return topic.is_nested_view ? Boolean(topic.has_new_replies) : topic.unread_posts > 0;
  }
  get showCategory() {
    const category = this.args.topic.category;
    return category && (category.id !== this.site.uncategorized_category_id || !this.siteSettings.suppress_uncategorized_badge);
  }
  get unreadLabel() {
    return this.args.topic.is_nested_view ? i18n("topic.has_new_replies") : i18n("topic.unread_posts", {
      count: this.args.topic.unread_posts
    });
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{! eslint-disable ember/template-no-invalid-interactive }}
    <li
      class={{dConcatClass
        "isbf-continue-reading__item topic-list-item"
        (if @topic.visited "visited")
        (if @topic.unseen "unseen-topic")
        (if this.hasUnread "unread-posts")
        this.additionalClasses
      }}
      data-topic-id={{@topic.id}}
      style={{this.style}}
      ...attributes
      {{this.highlightIfNeeded}}
      {{on "click" this.click}}
      {{on "auxclick" this.click}}
    >
      {{#if @topic.creator.username}}
        <DUserLink
          class="isbf-continue-reading__avatar"
          @user={{@topic.creator}}
        >
          {{#if @topic.creator.avatar_template}}
            {{dAvatar @topic.creator imageSize="large" loading="lazy"}}
          {{else}}
            <img alt="" height="36" src={{this.defaultAvatarUrl}} width="36" />
          {{/if}}
        </DUserLink>
      {{else}}
        <span class="isbf-continue-reading__avatar">
          <img alt="" height="36" src={{this.defaultAvatarUrl}} width="36" />
        </span>
      {{/if}}
    
      <div class="isbf-continue-reading__body">
        <div class="isbf-continue-reading__title-row main-link">
          {{#if this.hasEssentialStatus}}
            <TopicStatus @context="topic-list" @topic={{@topic}} />
          {{/if}}
          <TopicLink
            class="isbf-continue-reading__title raw-topic-link"
            @topic={{@topic}}
            {{on "keydown" this.keyDown}}
            {{on "focus" this.onTitleFocus}}
            {{on "blur" this.onTitleBlur}}
          />
          {{#if this.hasUnread}}
            <span
              class="isbf-continue-reading__unread"
              title={{this.unreadLabel}}
            >
              <span class="sr-only">{{this.unreadLabel}}</span>
            </span>
          {{/if}}
          {{#if @topic.unseen}}
            <span class="sr-only">{{i18n "topic.new"}}</span>
          {{/if}}
        </div>
    
        <div class="isbf-continue-reading__metadata">
          {{#if this.showCategory}}
            {{dCategoryLink @topic.category}}
            <span aria-hidden="true">·</span>
          {{/if}}
          <a
            class="isbf-continue-reading__time post-activity"
            href={{@topic.lastPostUrl}}
            title={{@topic.bumpedAtTitle}}
          >
            {{dFormatDate @topic.bumpedAt format="tiny" noTitle="true"}}
          </a>
        </div>
    
        <a
          aria-label={{i18n "topic.reply_count_link" count=@topic.replyCount}}
          class="isbf-continue-reading__replies badge-posts"
          href={{@topic.firstPostUrl}}
        >
          {{dIcon "comment"}}
          {{i18n
            (themePrefix "isbf_v2.continue_reading.replies")
            count=@topic.replyCount
          }}
        </a>
      </div>
    </li>
    */
    {
      "id": null,
      "block": "[[[11,\"li\"],[16,0,[28,[32,0],[\"isbf-continue-reading__item topic-list-item\",[52,[30,1,[\"visited\"]],\"visited\"],[52,[30,1,[\"unseen\"]],\"unseen-topic\"],[52,[30,0,[\"hasUnread\"]],\"unread-posts\"],[30,0,[\"additionalClasses\"]]],null]],[16,\"data-topic-id\",[30,1,[\"id\"]]],[16,5,[30,0,[\"style\"]]],[17,2],[4,[30,0,[\"highlightIfNeeded\"]],null,null],[4,[32,1],[\"click\",[30,0,[\"click\"]]],null],[4,[32,1],[\"auxclick\",[30,0,[\"click\"]]],null],[12],[1,\"\\n\"],[41,[30,1,[\"creator\",\"username\"]],[[[1,\"    \"],[8,[32,2],[[24,0,\"isbf-continue-reading__avatar\"]],[[\"@user\"],[[30,1,[\"creator\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"creator\",\"avatar_template\"]],[[[1,\"        \"],[1,[28,[32,3],[[30,1,[\"creator\"]]],[[\"imageSize\",\"loading\"],[\"large\",\"lazy\"]]]],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"36\"],[15,\"src\",[30,0,[\"defaultAvatarUrl\"]]],[14,\"width\",\"36\"],[12],[13],[1,\"\\n\"]],[]]],[1,\"    \"]],[]]]]],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,0,\"isbf-continue-reading__avatar\"],[12],[1,\"\\n      \"],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"36\"],[15,\"src\",[30,0,[\"defaultAvatarUrl\"]]],[14,\"width\",\"36\"],[12],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n  \"],[10,0],[14,0,\"isbf-continue-reading__body\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-continue-reading__title-row main-link\"],[12],[1,\"\\n\"],[41,[30,0,[\"hasEssentialStatus\"]],[[[1,\"        \"],[8,[32,4],null,[[\"@context\",\"@topic\"],[\"topic-list\",[30,1]]],null],[1,\"\\n\"]],[]],null],[1,\"      \"],[8,[32,5],[[24,0,\"isbf-continue-reading__title raw-topic-link\"],[4,[32,1],[\"keydown\",[30,0,[\"keyDown\"]]],null],[4,[32,1],[\"focus\",[30,0,[\"onTitleFocus\"]]],null],[4,[32,1],[\"blur\",[30,0,[\"onTitleBlur\"]]],null]],[[\"@topic\"],[[30,1]]],null],[1,\"\\n\"],[41,[30,0,[\"hasUnread\"]],[[[1,\"        \"],[10,1],[14,0,\"isbf-continue-reading__unread\"],[15,\"title\",[30,0,[\"unreadLabel\"]]],[12],[1,\"\\n          \"],[10,1],[14,0,\"sr-only\"],[12],[1,[30,0,[\"unreadLabel\"]]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[41,[30,1,[\"unseen\"]],[[[1,\"        \"],[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,6],[\"topic.new\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\\n    \"],[10,0],[14,0,\"isbf-continue-reading__metadata\"],[12],[1,\"\\n\"],[41,[30,0,[\"showCategory\"]],[[[1,\"        \"],[1,[28,[32,7],[[30,1,[\"category\"]]],null]],[1,\"\\n        \"],[10,1],[14,\"aria-hidden\",\"true\"],[12],[1,\"·\"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,3],[14,0,\"isbf-continue-reading__time post-activity\"],[15,6,[30,1,[\"lastPostUrl\"]]],[15,\"title\",[30,1,[\"bumpedAtTitle\"]]],[12],[1,\"\\n        \"],[1,[28,[32,8],[[30,1,[\"bumpedAt\"]]],[[\"format\",\"noTitle\"],[\"tiny\",\"true\"]]]],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n    \"],[10,3],[15,\"aria-label\",[28,[32,6],[\"topic.reply_count_link\"],[[\"count\"],[[30,1,[\"replyCount\"]]]]]],[14,0,\"isbf-continue-reading__replies badge-posts\"],[15,6,[30,1,[\"firstPostUrl\"]]],[12],[1,\"\\n      \"],[1,[28,[32,9],[\"comment\"],null]],[1,\"\\n      \"],[1,[28,[32,6],[[28,[32,10],[\"isbf_v2.continue_reading.replies\"],null]],[[\"count\"],[[30,1,[\"replyCount\"]]]]]],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@topic\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        on,
        DUserLink,
        dAvatar,
        TopicStatus,
        TopicLink,
        i18n,
        dCategoryLink,
        dFormatDate,
        dIcon,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-continue-reading-item", ISBFContinueReadingItem);
var Mod172 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFContinueReadingItem
});
class ISBFContinueReading extends Component {
  static {
    dt7948.g(this.prototype, "moreTopicsTabs", [service]);
  }
  #moreTopicsTabs = (dt7948.i(this, "moreTopicsTabs"), void 0);
  static {
    dt7948.g(this.prototype, "router", [service]);
  }
  #router = (dt7948.i(this, "router"), void 0);
  get topic() {
    return this.args.outletArgs.topic;
  }
  get listContext() {
    return this.moreTopicsTabs.selectedTab?.id === "suggested-topics" ? "suggested" : "related";
  }
  get shouldRender() {
    return !EmbedMode.enabled && /^\/t\//.test(this.router.currentURL ?? "") && this.topic.archetype === "regular" && this.topics?.length > 0;
  }
  get sourceTitle() {
    return this.listContext === "suggested" ? i18n(themePrefix("isbf_v2.continue_reading.suggested")) : i18n(themePrefix("isbf_v2.continue_reading.related"));
  }
  get topics() {
    switch (this.moreTopicsTabs.selectedTab?.id) {
      case "suggested-topics":
        return this.topic.suggestedTopics;
      case "related-topics":
        return this.topic.relatedTopics;
      default:
        return null;
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.shouldRender}}
      <section
        aria-labelledby="isbf-continue-reading-title"
        class="isbf-continue-reading"
        data-source={{this.listContext}}
        id={{this.moreTopicsTabs.selectedTab.id}}
        ...attributes
      >
        {{#if (eq this.listContext "suggested")}}
          <UserTip
            @contentText={{i18n "user_tips.suggested_topics.content"}}
            @id="suggested_topics"
            @placement="top-start"
            @priority={{700}}
            @titleText={{i18n "user_tips.suggested_topics.title"}}
          />
        {{/if}}
    
        <header class="isbf-continue-reading__header">
          <h3
            class="isbf-continue-reading__heading"
            id="isbf-continue-reading-title"
          >
            {{i18n (themePrefix "isbf_v2.continue_reading.title")}}
          </h3>
          <span
            class="isbf-continue-reading__source"
          >{{this.sourceTitle}}</span>
        </header>
    
        {{#if (gt this.moreTopicsTabs.tabs.length 1)}}
          <nav
            aria-label={{i18n (themePrefix "isbf_v2.continue_reading.sources")}}
            class="isbf-continue-reading__tabs"
          >
            {{#each this.moreTopicsTabs.tabs as |tab|}}
              <DButton
                aria-pressed={{this.moreTopicsTabs.isActiveTab tab}}
                class={{dConcatClass
                  "isbf-continue-reading__tab"
                  (if (this.moreTopicsTabs.isActiveTab tab) "is-active")
                }}
                @action={{fn this.moreTopicsTabs.selectTab tab}}
                @translatedLabel={{tab.name}}
              />
            {{/each}}
          </nav>
        {{/if}}
    
        <ul class="isbf-continue-reading__list" role="list">
          {{#each this.topics key="id" as |topic index|}}
            <ISBFContinueReadingItem
              @index={{index}}
              @listContext={{this.listContext}}
              @topic={{topic}}
            />
          {{/each}}
        </ul>
    
        {{#if this.topic.suggestedTopics.length}}
          <ISBFContinueReadingFooter @topic={{this.topic}} />
        {{/if}}
      </section>
    {{else}}
      {{yield}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"shouldRender\"]],[[[1,\"  \"],[11,\"section\"],[24,\"aria-labelledby\",\"isbf-continue-reading-title\"],[24,0,\"isbf-continue-reading\"],[16,\"data-source\",[30,0,[\"listContext\"]]],[16,1,[30,0,[\"moreTopicsTabs\",\"selectedTab\",\"id\"]]],[17,1],[12],[1,\"\\n\"],[41,[28,[32,0],[[30,0,[\"listContext\"]],\"suggested\"],null],[[[1,\"      \"],[8,[32,1],null,[[\"@contentText\",\"@id\",\"@placement\",\"@priority\",\"@titleText\"],[[28,[32,2],[\"user_tips.suggested_topics.content\"],null],\"suggested_topics\",\"top-start\",700,[28,[32,2],[\"user_tips.suggested_topics.title\"],null]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"header\"],[14,0,\"isbf-continue-reading__header\"],[12],[1,\"\\n      \"],[10,\"h3\"],[14,0,\"isbf-continue-reading__heading\"],[14,1,\"isbf-continue-reading-title\"],[12],[1,\"\\n        \"],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.continue_reading.title\"],null]],null]],[1,\"\\n      \"],[13],[1,\"\\n      \"],[10,1],[14,0,\"isbf-continue-reading__source\"],[12],[1,[30,0,[\"sourceTitle\"]]],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n\"],[41,[28,[32,4],[[30,0,[\"moreTopicsTabs\",\"tabs\",\"length\"]],1],null],[[[1,\"      \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.continue_reading.sources\"],null]],null]],[14,0,\"isbf-continue-reading__tabs\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"moreTopicsTabs\",\"tabs\"]]],null]],null],null,[[[1,\"          \"],[8,[32,5],[[16,\"aria-pressed\",[28,[30,0,[\"moreTopicsTabs\",\"isActiveTab\"]],[[30,2]],null]],[16,0,[28,[32,6],[\"isbf-continue-reading__tab\",[52,[28,[30,0,[\"moreTopicsTabs\",\"isActiveTab\"]],[[30,2]],null],\"is-active\"]],null]]],[[\"@action\",\"@translatedLabel\"],[[28,[32,7],[[30,0,[\"moreTopicsTabs\",\"selectTab\"]],[30,2]],null],[30,2,[\"name\"]]]],null],[1,\"\\n\"]],[2]],null],[1,\"      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"ul\"],[14,0,\"isbf-continue-reading__list\"],[14,\"role\",\"list\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"        \"],[8,[32,8],null,[[\"@index\",\"@listContext\",\"@topic\"],[[30,4],[30,0,[\"listContext\"]],[30,3]]],null],[1,\"\\n\"]],[3,4]],null],[1,\"    \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"topic\",\"suggestedTopics\",\"length\"]],[[[1,\"      \"],[8,[32,9],null,[[\"@topic\"],[[30,0,[\"topic\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[18,5,null],[1,\"\\n\"]],[]]]],[\"&attrs\",\"tab\",\"topic\",\"index\",\"&default\"],[\"if\",\"each\",\"-track-array\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        eq,
        UserTip,
        i18n,
        themePrefix,
        gt,
        DButton,
        dConcatClass,
        fn,
        ISBFContinueReadingItem,
        ISBFContinueReadingFooter
      }),
      "isStrictMode": true
    }), this);
  }
}
registerModuleForModifyClass("isbf-continue-reading", ISBFContinueReading);
var Mod171 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFContinueReading
});
var isbfContinueReading = apiInitializer(api => {
  api.renderInOutlet("more-topics-content", ISBFContinueReading);
});
var Mod170 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfContinueReading
});
class ISBFNotifications extends Service {
  static {
    dt7948.g(this.prototype, "a11y", [service]);
  }
  #a11y = (dt7948.i(this, "a11y"), void 0);
  static {
    dt7948.g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (dt7948.i(this, "appEvents"), void 0);
  static {
    dt7948.g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (dt7948.i(this, "currentUser"), void 0);
  static {
    dt7948.g(this.prototype, "messageBus", [service]);
  }
  #messageBus = (dt7948.i(this, "messageBus"), void 0);
  static {
    dt7948.g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (dt7948.i(this, "siteSettings"), void 0);
  static {
    dt7948.g(this.prototype, "filterError", [tracked], function () {
      return false;
    });
  }
  #filterError = (dt7948.i(this, "filterError"), void 0);
  static {
    dt7948.g(this.prototype, "savingFilter", [tracked], function () {
      return false;
    });
  }
  #savingFilter = (dt7948.i(this, "savingFilter"), void 0);
  static {
    dt7948.g(this.prototype, "savingStyle", [tracked], function () {
      return false;
    });
  }
  #savingStyle = (dt7948.i(this, "savingStyle"), void 0);
  static {
    dt7948.g(this.prototype, "styleError", [tracked], function () {
      return false;
    });
  }
  #styleError = (dt7948.i(this, "styleError"), void 0);
  version = 0;
  #channel;
  #requestedFilter;
  #requestedStyle;
  constructor() {
    super(...arguments);
    if (this.currentUser && this.siteSettings.isbf_notifications_enabled) {
      this.#channel = `/notification/${this.currentUser.id}`;
      this.messageBus.subscribe(this.#channel, this.onNotification);
      this.appEvents.on("user-menu:notification-click", this, this.onNotificationClick);
    }
  }
  willDestroy() {
    if (this.#channel) {
      this.messageBus.unsubscribe(this.#channel, this.onNotification);
      this.appEvents.off("user-menu:notification-click", this, this.onNotificationClick);
    }
    super.willDestroy(...arguments);
  }
  get displayCount() {
    return this.unreadCount > 99 ? "99+" : this.unreadCount;
  }
  get dotStyle() {
    return this.currentUser?.get("isbf_notification_badge_style") === "dot";
  }
  get filter() {
    return this.currentUser?.get("isbf_notification_filter") === "unread" ? "unread" : "all";
  }
  get linkLabel() {
    if (!this.unreadCount) {
      return i18n(themePrefix("isbf_v2.notifications"));
    }
    return i18n(themePrefix(this.unreadCount > 99 ? "isbf_v2.notifications_badge_many" : "isbf_v2.notifications_badge_count"), {
      count: this.unreadCount
    });
  }
  get numberStyle() {
    return !this.dotStyle;
  }
  get unreadCount() {
    if (!this.currentUser || !this.siteSettings.isbf_notifications_enabled) {
      return 0;
    }
    // The header's counters exclude notices seen in a menu but still unread.
    return Object.values(this.currentUser.get("grouped_unread_notifications") || {}).reduce((total, count) => total + Math.max(0, Number(count) || 0), 0);
  }
  onNotification(data) {
    this.version++;
    this.currentUser.set("grouped_unread_notifications", data.grouped_unread_notifications);
    this.appEvents.trigger("isbf:notifications-updated", data);
  }
  static {
    dt7948.n(this.prototype, "onNotification", [bind]);
  }
  onNotificationClick() {
    scheduleOnce("actions", this, this.#notifyLocalChange);
  }
  retryBadgeStyle() {
    return this.saveBadgeStyle(this.#requestedStyle);
  }
  static {
    dt7948.n(this.prototype, "retryBadgeStyle", [bind]);
  }
  retryFilter() {
    return this.saveFilter(this.#requestedFilter);
  }
  static {
    dt7948.n(this.prototype, "retryFilter", [bind]);
  }
  async saveBadgeStyle(style) {
    if (!this.currentUser || this.savingStyle || !["number", "dot"].includes(style)) {
      return;
    }
    const userId = this.currentUser.id;
    this.#requestedStyle = style;
    this.savingStyle = true;
    this.styleError = false;
    try {
      await ajax(`/u/${encodeURIComponent(this.currentUser.username)}.json`, {
        type: "PUT",
        data: {
          custom_fields: {
            isbf_notification_badge_style: style
          }
        }
      });
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.currentUser.set("isbf_notification_badge_style", style);
      }
    } catch {
      if (!this.isDestroying) {
        this.styleError = true;
        this.a11y.announce(i18n(themePrefix("isbf_v2.notifications_badge_error")), "assertive");
      }
    } finally {
      if (!this.isDestroying) {
        this.savingStyle = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "saveBadgeStyle", [bind]);
  }
  async saveFilter(filter) {
    if (!this.currentUser || this.savingFilter || !["all", "unread"].includes(filter)) {
      return;
    }
    const userId = this.currentUser.id;
    this.#requestedFilter = filter;
    this.savingFilter = true;
    this.filterError = false;
    try {
      await ajax(`/u/${encodeURIComponent(this.currentUser.username)}.json`, {
        type: "PUT",
        data: {
          custom_fields: {
            isbf_notification_filter: filter
          }
        }
      });
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.currentUser.set("isbf_notification_filter", filter);
        this.appEvents.trigger("isbf:notification-filter-changed");
      }
    } catch {
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.filterError = true;
        this.a11y.announce(i18n(themePrefix("isbf_v2.notifications_filter_error")), "assertive");
      }
    } finally {
      if (!this.isDestroying) {
        this.savingFilter = false;
      }
    }
  }
  static {
    dt7948.n(this.prototype, "saveFilter", [bind]);
  }
  #notifyLocalChange() {
    if (!this.isDestroying) {
      this.appEvents.trigger("isbf:notifications-updated");
    }
  }
}
var Mod177 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: ISBFNotifications
});
function initialize(_container, owner) {
  owner.register("service:isbf-notifications", ISBFNotifications);
}
var isbfNotifications = {
  name: "isbf-notification-state",
  after: "inject-objects",
  initialize
};
var Mod176 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  default: isbfNotifications,
  initialize: initialize
});
const compatModules = {
  "discourse/api-initializers/isbf-campus-feed": Mod1,
  "discourse/components/isbf-v2-right-rail": Mod2,
  "discourse/components/isbf-v2-shell": Mod3,
  "discourse/components/isbf-v2-side-nav": Mod4,
  "discourse/lib/quick-post-title": Mod5,
  "discourse/components/isbf-v2-calendar": Mod6,
  "discourse/components/isbf-v2-workbench": Mod7,
  "discourse/components/isbf-v2-composer-cancel": Mod8,
  "discourse/components/isbf-v2-composer-options": Mod9,
  "discourse/lib/quick-post-scope": Mod10,
  "discourse/components/isbf-v2-account-menu": Mod11,
  "discourse/components/isbf-v2-feed-card": Mod12,
  "discourse/connectors/topic-list-item/isbf-feed-card": Mod13,
  "discourse/lib/feed-post-loader": Mod14,
  "discourse/lib/anonymous-post-scope": Mod15,
  "discourse/components/isbf-v2-anonymous-posts": Mod16,
  "discourse/connectors/topic-footer-main-buttons-before-create/isbf-topic-more": Mod17,
  "discourse/lib/feed-view-tracker": Mod18,
  "discourse/api-initializers/isbf-notifications": Mod19,
  "discourse/components/isbf-notification-action": Mod20,
  "discourse/components/isbf-notification-entry": Mod21,
  "discourse/components/isbf-notifications": Mod22,
  "discourse/lib/notification-groups": Mod23,
  "discourse/api-initializers/isbf-topic-card": Mod24,
  "discourse/components/isbf-topic-actions": Mod25,
  "discourse/components/isbf-topic-info": Mod26,
  "discourse/components/isbf-topic-metadata": Mod27,
  "discourse/components/isbf-topic-more": Mod28,
  "discourse/components/isbf-topic-views": Mod29,
  "discourse/lib/post-card-helpers": Mod30,
  "discourse/lib/topic-card-scope": Mod31,
  "discourse/lib/view-tracker": Mod32,
  "discourse/components/isbf-v2-composer-title": Mod33,
  "discourse/lib/optional-topic-title": Mod34,
  "discourse/api-initializers/isbf-composer-category-menu": Mod35,
  "discourse/api-initializers/isbf-topic-reading": Mod36,
  "discourse/components/isbf-topic-reading": Mod37,
  "discourse/components/isbf-explore-group": Mod38,
  "discourse/components/isbf-explore-picker": Mod39,
  "discourse/components/isbf-explore": Mod40,
  "discourse/lib/explore-preferences": Mod41,
  "discourse/lib/explore-preview": Mod42,
  "discourse/lib/explore-query": Mod43,
  "discourse/api-initializers/isbf-reporting": Mod44,
  "discourse/components/isbf-flag-modal": Mod45,
  "discourse/lib/report-post": Mod46,
  "discourse/pre-initializers/isbf-composer-optional-title": Mod47,
  "discourse/components/isbf-v2-more-menu": Mod48,
  "discourse/components/isbf-v2-join-modal": Mod49,
  "discourse/lib/feedback-category": Mod50,
  "discourse/components/isbf-official-composer": Mod51,
  "discourse/components/isbf-official-feed": Mod52,
  "discourse/components/isbf-official-picker": Mod53,
  "discourse/lib/official-filters": Mod54,
  "discourse/pre-initializers/isbf-official-composer": Mod55,
  "discourse/lib/official-calendar": Mod56,
  "discourse/pre-initializers/isbf-official-calendar": Mod57,
  "discourse/api-initializers/isbf-official-calendar": Mod58,
  "discourse/components/isbf-official-calendar-composer": Mod59,
  "discourse/components/isbf-official-calendar-editor": Mod60,
  "discourse/components/isbf-official-calendar-items": Mod61,
  "discourse/components/isbf-calendar-note-editor": Mod62,
  "discourse/components/isbf-calendar-update-dialog": Mod63,
  "discourse/api-initializers/isbf-learning": Mod64,
  "discourse/components/isbf-learning-composer": Mod65,
  "discourse/components/isbf-learning-course-dialog": Mod66,
  "discourse/components/isbf-learning-grade-picker": Mod67,
  "discourse/components/isbf-learning-resource": Mod68,
  "discourse/components/isbf-learning": Mod69,
  "discourse/isbf-learning-route-map": Mod70,
  "discourse/lib/learning-composer": Mod71,
  "discourse/lib/learning-resources": Mod72,
  "discourse/lib/learning-upload": Mod73,
  "discourse/routes/isbf-learning": Mod74,
  "discourse/templates/isbf-learning": Mod75,
  "discourse/components/isbf-learning-share-dialog": Mod76,
  "discourse/components/isbf-official-activity-summary": Mod77,
  "discourse/components/reviewable-isbf-learning-course": Mod78,
  "discourse/lib/composer-model-extensions": Mod79,
  "discourse/components/isbf-alumni-map": Mod80,
  "discourse/components/isbf-alumni-profile": Mod81,
  "discourse/components/isbf-alumni": Mod82,
  "discourse/isbf-alumni-route-map": Mod83,
  "discourse/lib/alumni": Mod84,
  "discourse/routes/isbf-alumni": Mod85,
  "discourse/components/isbf-v2-utility-actions": Mod86,
  "discourse/lib/alumni-map-labels": Mod87,
  "discourse/components/isbf-post-preview": Mod88,
  "discourse/components/isbf-activity-preview": Mod89,
  "discourse/lib/post-preview": Mod90,
  "discourse/components/isbf-v2-brand": Mod91,
  "discourse/api-initializers/isbf-marketplace": Mod92,
  "discourse/components/isbf-marketplace-card": Mod93,
  "discourse/components/isbf-marketplace-composer": Mod94,
  "discourse/components/isbf-marketplace": Mod95,
  "discourse/isbf-marketplace-route-map": Mod96,
  "discourse/lib/marketplace-upload": Mod97,
  "discourse/lib/marketplace": Mod98,
  "discourse/lib/private-upload-endpoint": Mod99,
  "discourse/routes/isbf-marketplace": Mod100,
  "discourse/templates/isbf-marketplace": Mod101,
  "discourse/components/isbf-v2-appearance-modal": Mod102,
  "discourse/api-initializers/isbf-content-images": Mod103,
  "discourse/lib/content-images": Mod104,
  "discourse/modifiers/content-images": Mod105,
  "discourse/lib/recent-discussions": Mod106,
  "discourse/api-initializers/isbf-teamup": Mod107,
  "discourse/components/isbf-home-display-option": Mod108,
  "discourse/components/isbf-teamup-composer": Mod109,
  "discourse/components/isbf-teamup": Mod110,
  "discourse/components/isbf-workbench-topic-page": Mod111,
  "discourse/isbf-teamup-route-map": Mod112,
  "discourse/lib/teamup": Mod113,
  "discourse/routes/isbf-teamup": Mod114,
  "discourse/templates/isbf-teamup": Mod115,
  "discourse/api-initializers/isbf-topic-pinning": Mod116,
  "discourse/components/isbf-home-pin-dialog": Mod117,
  "discourse/lib/pinning": Mod118,
  "discourse/api-initializers/isbf-library": Mod119,
  "discourse/components/isbf-library": Mod120,
  "discourse/components/isbf-resource-catalog": Mod121,
  "discourse/components/isbf-resource-directory-dialog": Mod122,
  "discourse/components/isbf-resource-item": Mod123,
  "discourse/components/isbf-resource-list": Mod124,
  "discourse/components/isbf-resource-page": Mod125,
  "discourse/components/isbf-resource-parent-picker": Mod126,
  "discourse/components/isbf-resource-share-dialog": Mod127,
  "discourse/components/reviewable-isbf-library-directory": Mod128,
  "discourse/isbf-library-route-map": Mod129,
  "discourse/routes/isbf-library": Mod130,
  "discourse/templates/isbf-library": Mod131,
  "discourse/api-initializers/isbf-frontend-consistency": Mod132,
  "discourse/components/isbf-frontend-heading": Mod133,
  "discourse/components/isbf-frontend-scope": Mod134,
  "discourse/lib/frontend-consistency-scope": Mod135,
  "discourse/routes/group/manage/members": Mod136,
  "discourse/lib/user-display": Mod137,
  "discourse/api-initializers/isbf-user-display": Mod138,
  "discourse/modifiers/isbf-close-on-click-outside": Mod139,
  "discourse/api-initializers/isbf-poll": Mod140,
  "discourse/components/isbf-solved-action": Mod141,
  "discourse/components/isbf-solved-summary": Mod142,
  "discourse/api-initializers/isbf-back-navigation": Mod143,
  "discourse/lib/back-navigation-history": Mod144,
  "discourse/services/isbf-back-navigation": Mod145,
  "discourse/lib/official-topic-scope": Mod146,
  "discourse/api-initializers/isbf-official-composer-controls": Mod147,
  "discourse/api-initializers/isbf-official": Mod148,
  "discourse/lib/official-composer-setup": Mod149,
  "discourse/components/isbf-poll-previews": Mod150,
  "discourse/lib/poll-preview": Mod151,
  "discourse/components/isbf-calendar-subscribe": Mod152,
  "discourse/components/isbf-calendar-subscription": Mod153,
  "discourse/components/isbf-calendar-subscription-feed": Mod154,
  "discourse/lib/calendar-subscription": Mod155,
  "discourse/api-initializers/isbf-calendar-subscription": Mod156,
  "discourse/components/isbf-calendar-provider-icon": Mod157,
  "discourse/components/isbf-reply-context": Mod158,
  "discourse/components/isbf-reply-navigation": Mod159,
  "discourse/lib/reply-navigation": Mod160,
  "discourse/api-initializers/isbf-careers": Mod161,
  "discourse/components/isbf-careers-card": Mod162,
  "discourse/components/isbf-careers-composer": Mod163,
  "discourse/components/isbf-careers": Mod164,
  "discourse/components/isbf-workbench-listing-card": Mod165,
  "discourse/isbf-careers-route-map": Mod166,
  "discourse/lib/careers": Mod167,
  "discourse/routes/isbf-careers": Mod168,
  "discourse/templates/isbf-careers": Mod169,
  "discourse/api-initializers/isbf-continue-reading": Mod170,
  "discourse/components/isbf-continue-reading": Mod171,
  "discourse/components/isbf-continue-reading-item": Mod172,
  "discourse/components/isbf-continue-reading-footer": Mod173,
  "discourse/components/isbf-notification-bell": Mod174,
  "discourse/components/isbf-notification-unread": Mod175,
  "discourse/initializers/isbf-notifications": Mod176,
  "discourse/services/isbf-notifications": Mod177,
  "discourse/components/isbf-learning-directory-editor": Mod178,
  "discourse/components/isbf-learning-management-dialog": Mod179,
  "discourse/components/isbf-learning-directory-deletion": Mod180,
  "discourse/components/isbf-summary-topic-title": Mod181
};
export { compatModules, compatModules as default };
