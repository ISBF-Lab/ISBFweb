import {
  CHILDREN_PAGE_SIZE,
  REPLY_PREVIEW_COUNT,
} from "discourse/lib/flat-replies";

export function mergeFlatReplyPreload(previous, nodes, { page, count } = {}) {
  const preview = mergeFlatReplyPage(
    previous,
    nodes.slice(0, REPLY_PREVIEW_COUNT),
    { count }
  );
  return page == null
    ? preview
    : mergeFlatReplyPage(
        preview,
        page > 0 ? nodes.slice(REPLY_PREVIEW_COUNT) : nodes,
        { page, count }
      );
}

export function mergeFlatReplyPage(
  previous,
  nodes,
  { page, count = 0, saved = false } = {}
) {
  const byId = new Map(
    (previous?.childNodes || []).map((node) => [node.post.id, node])
  );
  const positions = { ...previous?.positions };
  const loadedPages = new Set(previous?.loadedPages || []);

  nodes.forEach((node, index) => {
    const id = node.post.id;
    if (!byId.has(id)) {
      byId.set(id, node);
    }
    if (page != null || positions[id] == null) {
      positions[id] = saved
        ? Math.max(count - 1, 0)
        : (page || 0) * CHILDREN_PAGE_SIZE + index;
    }
  });
  if (page != null) {
    loadedPages.add(page);
  }

  const childNodes = [...byId.values()].sort(
    (left, right) => left.post.post_number - right.post.post_number
  );
  const lastPosition = positions[childNodes.at(-1)?.post.id] ?? -1;
  return {
    childNodes,
    positions,
    loadedPages: [...loadedPages].sort((a, b) => a - b),
    page: loadedPages.size ? Math.max(...loadedPages) : 0,
    fetchedFromServer: loadedPages.size > 0,
    hasMore: lastPosition + 1 < count,
  };
}

export function flatReplyItems(entry) {
  const items = [];
  let previousPosition = -1;
  for (const node of entry.childNodes) {
    const position = entry.positions[node.post.id];
    if (position > previousPosition + 1) {
      const page = Math.floor((position - 1) / CHILDREN_PAGE_SIZE);
      items.push({ key: `gap-${page}`, gap: true, page });
    }
    items.push({ key: node.post.id, node });
    previousPosition = position;
  }
  return items;
}
