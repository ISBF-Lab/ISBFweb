const secondaryMenus = new WeakMap();

export function isFeedStyleTopic(topic, path) {
  return (
    /^\/t\//.test(path ?? "") &&
    topic?.archetype === "regular" &&
    !topic.is_nested_view
  );
}

export function isFeedStylePost(post, path, nestedReplyView = false) {
  return (
    isFeedStyleTopic(post?.topic, path) &&
    post.post_type === 1 &&
    !nestedReplyView
  );
}

export function rememberSecondaryMenu(post, entries) {
  secondaryMenus.set(post, entries);
}

export function secondaryMenuFor(post) {
  return secondaryMenus.get(post) ?? [];
}

export function cardReplyCount(post) {
  return post.post_number === 1
    ? Math.max(0, Number(post.topic.replyCount) || 0)
    : Math.max(0, Number(post.reply_count) || 0);
}
