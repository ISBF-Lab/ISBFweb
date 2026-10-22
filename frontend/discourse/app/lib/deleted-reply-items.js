export default function deletedReplyItems(items) {
  const result = [];
  let group;

  for (const item of items) {
    const node = item.node;
    const post = node?.post;
    const value = (key) => (post?.get ? post.get(key) : post?.[key]);
    const eligible =
      value("deleted_post_placeholder") === true &&
      !(value("direct_reply_count") > 0) &&
      !(value("total_descendant_count") > 0) &&
      !node?.children?.length;
    const parent = post?.reply_to_post_number || 1;
    const rootIndex = value("root_index");
    const consecutive =
      !(group?.lastRootIndex > 0 && rootIndex > 0) ||
      rootIndex === group.lastRootIndex + 1;

    if (!eligible) {
      group = null;
      result.push(item);
    } else if (group && group.parent === parent && consecutive) {
      group.item.deletedPosts.push(post);
      group.lastRootIndex = rootIndex;
    } else {
      const entry = { ...item, deletedPosts: [post] };
      result.push(entry);
      group = { item: entry, parent, lastRootIndex: rootIndex };
    }
  }

  return result;
}
