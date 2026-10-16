const topic = { id: 314, slug: "campus-open-day", url: "/t/campus-open-day/314", reply_navigation: { root_count: 2, root_index: 1, reply_count: 103 }, postStream: { posts: [] } };
const appEvents = { on() {}, off() {}, trigger() {} };
const services = {
  appEvents,
  siteSettings: { nested_replies_enabled: true, nested_replies_cap_nesting_depth: true, nested_replies_max_depth: 1, enable_names: true },
  store: { createRecord(_type, data) { return data; } },
  site: { mobileView: false },
  a11y: { announce() {} },
};
class Component {
  constructor(args) { this.args = args; Object.assign(this, services); }
  willDestroy() { this.isDestroying = true; }
}
const modifier = (callback) => callback;
const scheduleOnce = () => 0;
const themePrefix = (key) => key;
const getURL = (url) => url;
const displayIdentity = (user) => user?.name && user.username ? `${user.name} @${user.username}` : user?.name || user?.username;
const processNode = (_store, model, data) => ({ post: { ...data, topic: model }, children: [] });
const popupAjaxError = (error) => { throw error; };
const DiscourseURL = { routeTo(url) { window.fixtureRoutes.push(url); document.querySelector(`[data-post-number="${url.split("/").at(-1)}"]`)?.scrollIntoView({ block: "center" }); } };
window.fixtureRoutes = [];
window.fixtureRequests = [];
let failPrevious = false;
let hiddenContext = false;
let originalRequests = 0;
function i18n(key, values = {}) {
  let template = key.startsWith("nested_replies.") ? translations.nested[key.split(".").at(-1)] : translations.theme[key.split(".").at(-1)];
  if (typeof template === "object") template = template[values.count === 1 ? "one" : "other"];
  return String(template || key).replace(/%\{(\w+)\}/g, (_, name) => values[name]);
}
const users = [
  { name: "林溪", username: "linxi", letter: "林" },
  { name: "陈晨", username: "chenchen", letter: "陈" },
  { name: "李明", username: "liming", letter: "李" },
  { name: "张悦", username: "zhangyue", letter: "张" },
];
const messages = [
  "可以把校园导览安排在上午，下午留给社团体验。这样新同学也有时间自由交流。",
  "同意这个安排。我可以负责图书馆到教学楼这一段的路线介绍。",
  "那我们周五一起走一遍路线，确认集合点和每一站的时间。",
  "周五下午可以，我会先把路线图整理出来，发在这里供大家补充。",
];
function post(number, parent = number - 1) {
  const user = users[(number - 2 + users.length) % users.length];
  return { ...user, id: 1000 + number, topic_id: topic.id, topic, post_number: number, reply_to_post_number: parent, reply_to_user: parent === 1 ? users[0] : users[(parent - 2 + users.length) % users.length], created_at: "2026-10-15T02:00:00Z", cooked: messages[(number - 3 + messages.length) % messages.length], direct_reply_count: 0, total_descendant_count: 0 };
}
const rootPost = { ...post(2, 1), cooked: "建议安排校园导览和社团体验两个环节，大家觉得时间怎么分配比较合适？", direct_reply_count: 1, total_descendant_count: 100, root_index: 1 };
const allChildren = Array.from({ length: 100 }, (_, index) => post(index + 3));
topic.postStream.posts = [rootPost];
async function ajax(url, options) {
  window.fixtureRequests.push(url);
  await Promise.resolve();
  if (url.includes("/children/")) {
    const page = Number(new URL(url, "http://fixture").searchParams.get("page") || 0);
    if (failPrevious && page === 0) { failPrevious = false; throw new Error("Fixture unavailable"); }
    return { children: allChildren.slice(page * 50, (page + 1) * 50), page, has_more: page === 0 };
  }
  if (url.startsWith("/posts/by_number/")) {
    originalRequests++;
    return hiddenContext ? { cooked_hidden: true, cooked: "PRIVATE FIXTURE CONTENT" } : { ...rootPost, cooked: "我们先确认校园导览的路线和时间。报名后可以选择志愿者岗位，也欢迎大家补充活动建议。这是一段较长的原文，用于核对预览只显示两行内容，并保留打开原文的入口。" };
  }
  if (url.includes("/navigation")) {
    const index = options.data.root_index || (options.data.post_number > 102 ? 2 : 1);
    return { root_count: 2, root_index: index, root_post_number: index === 1 ? 2 : 103, root_created_at: "2026-10-15T02:00:00Z", reply_count: 103 };
  }
  throw new Error(`Unknown fixture request: ${url}`);
}

// SOURCE_CLASSES

let root;
let children;
const contexts = new Map();
const navigation = new ReplyNavigation(topic, appEvents);
function resetFixture(target = false) {
  contexts.clear();
  root = new NestedPost({ post: target ? { ...rootPost, target_post_number: 80 } : rootPost, depth: 0, children: [], topic, expansionState: new Map() });
  const args = { topic, parentPostNumber: 2, depth: 0, sort: "old", directReplyCount: 1, totalDescendantCount: 100, preloadedChildren: (target ? [...allChildren.slice(0, 3), ...allChildren.slice(50)] : allChildren.slice(0, 3)).map((item) => ({ post: item, children: [] })), initialPage: target ? 1 : undefined, fetchedChildrenCache: new Map(), toggleReplies() { root.toggleExpanded(); args.preview = root.previewChildren; } };
  args.preview = root.previewChildren;
  children = new NestedPostChildren(args);
  render();
  if (target) {
    const selected = document.querySelector('[data-post-number="80"]');
    selected.scrollIntoView({ block: "center" });
    selected.closest(".nested-post").classList.add("nested-post--highlighted");
  }
}
function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}
function button(className, label, action) {
  const node = element("button", `btn ${className}`, label);
  node.type = "button";
  node.addEventListener("click", async () => { const result = action(); render(); await result; render(); });
  return node;
}
function contextNode(item) {
  if (!contexts.has(item.post_number)) contexts.set(item.post_number, new ISBFReplyContext({ post: item }));
  const model = contexts.get(item.post_number);
  const wrapper = element("div", "isbf-reply-context");
  const toggle = button("btn-flat isbf-reply-context__toggle", model.label, () => model.toggle());
  toggle.setAttribute("aria-expanded", String(model.expanded));
  wrapper.append(toggle);
  if (model.expanded) {
    const preview = element("div", "isbf-reply-context__preview");
    if (model.loading) preview.append(element("span", "", "正在加载…"));
    else if (model.parent) {
      preview.append(element("div", "cooked", model.parent.cooked));
      const link = element("a", "isbf-reply-context__link", i18n("isbf_v2.reply_conversations.go_to_original"));
      link.href = model.parentUrl;
      link.addEventListener("click", (event) => { event.preventDefault(); DiscourseURL.routeTo(model.parentUrl); });
      preview.append(link);
    } else if (model.unavailable) {
      preview.append(element("p", "", i18n("isbf_v2.reply_conversations.context_unavailable")), button("btn-flat fixture-context-retry", "重试", () => model.retry()));
    }
    wrapper.append(preview);
  }
  return wrapper;
}
function postNode(item, depth = 1, showContext = true) {
  const wrapper = element("div", `nested-post --depth-${depth}`);
  const gutter = element("div", "nested-post__gutter");
  const avatar = element("div", "topic-avatar");
  avatar.append(element("div", "avatar fixture-avatar", item.letter));
  gutter.append(avatar);
  const main = element("div", "nested-post__main");
  const article = element("article", "nested-post__article boxed");
  article.dataset.postNumber = item.post_number;
  const header = element("div", "nested-post__header");
  const metadata = element("div", "isbf-post-card-header");
  const names = element("div", "names");
  const first = element("span", "first");
  const name = element("a", "", item.name); name.href = `#user-${item.username}`; first.append(name); names.append(first);
  metadata.append(names, element("span", "isbf-feed-card__username", `@${item.username}`), element("span", "post-infos post-date", `10月15日 · #${item.post_number}`));
  header.append(metadata);
  if (showContext) header.append(contextNode(item));
  const content = element("div", "nested-post__content regular");
  content.append(element("div", "cooked", item.cooked));
  const menu = element("section", "nested-post__menu post-menu-area");
  const controls = element("nav", "post-controls");
  const actions = element("div", "actions");
  actions.append(button("btn-flat", "♡", () => {}), button("btn-flat", "↪ 回复", () => {}), button("btn-flat", "↗", () => {}));
  controls.append(actions); menu.append(controls);
  article.append(header, content, menu); main.append(article); wrapper.append(gutter, main);
  return { wrapper, main };
}
function render() {
  const roots = document.querySelector(".nested-view__roots");
  roots.replaceChildren();
  const outer = postNode(rootPost, 0);
  const list = element("div", "nested-post-children");
  for (const item of children.displayItems) {
    if (item.gap) list.append(button("btn-flat nested-post-children__previous", i18n("nested_replies.load_previous_replies"), () => children.loadPrevious()));
    else list.append(postNode(item.node.post).wrapper);
  }
  if (children.error) list.append(element("p", "nested-post-children__error", i18n("nested_replies.replies_load_error")), button("btn-flat fixture-list-retry", "重试", () => children.retry()));
  if (children.canExpandPreview) list.append(button("btn-flat nested-post-children__expand", children.previewLabel, () => children.expandPreview()));
  else if (children.hasMore && !children.args.preview) list.append(button("btn-flat nested-post-children__load-more", children.loadMoreLabel, () => children.loadMore()));
  if (!children.args.preview) list.append(button("btn-flat nested-post-children__collapse", i18n("nested_replies.collapse"), () => children.args.toggleReplies()));
  outer.main.append(list); roots.append(outer.wrapper);
  roots.append(postNode({ ...post(103, 1), cooked: "志愿者报名表已经整理好了，周末有空的同学可以一起参与。" }, 0, false).wrapper);
  document.querySelector(".isbf-topic-reading__toggle").textContent = navigation.label();
  document.querySelector(".timeline-replies").textContent = navigation.label();
}
document.querySelector(".isbf-topic-reading__toggle").addEventListener("click", () => {
  const panel = document.querySelector(".topic-navigation");
  panel.classList.toggle("topic-progress-expanded");
  document.querySelector(".isbf-topic-reading__toggle").setAttribute("aria-expanded", String(panel.classList.contains("topic-progress-expanded")));
});
document.querySelector(".isbf-topic-reading__close").addEventListener("click", () => document.querySelector(".topic-navigation").classList.remove("topic-progress-expanded"));
document.querySelectorAll(".fixture-target").forEach((node) => node.addEventListener("click", () => resetFixture(true)));
document.querySelectorAll(".fixture-reset").forEach((node) => node.addEventListener("click", () => resetFixture(false)));
document.querySelectorAll(".fixture-mode").forEach((node) => node.addEventListener("click", () => document.documentElement.dataset.mode = document.documentElement.dataset.mode === "dark" ? "light" : "dark"));
window.fixture = {
  reset: resetFixture,
  get children() { return children; },
  get contexts() { return contexts; },
  get originalRequests() { return originalRequests; },
  failPrevious() { failPrevious = true; },
  hiddenContext(value) { hiddenContext = value; },
  navigation,
};
resetFixture();
