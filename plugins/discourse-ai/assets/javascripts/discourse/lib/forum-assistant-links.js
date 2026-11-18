const FORUM_PATH =
  /(^|[\s([（【：:])(\/t\/(?:[\p{L}\p{N}%_-]+\/)?\d+(?:\/\d+)?)(?=$|[\s()\]（）【】。，、.,;；:：!?！？])/gu;

export default function linkForumPaths(element) {
  const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      return node.parentElement.closest("a, code, pre, script, style")
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  while (walker.nextNode()) {
    nodes.push(walker.currentNode);
  }
  for (const node of nodes) {
    const text = node.textContent;
    const matches = [...text.matchAll(FORUM_PATH)];
    if (!matches.length) {
      continue;
    }
    const fragment = document.createDocumentFragment();
    let offset = 0;
    for (const match of matches) {
      const start = match.index + match[1].length;
      fragment.append(document.createTextNode(text.slice(offset, start)));
      const link = document.createElement("a");
      link.setAttribute("href", match[2]);
      link.textContent = match[2];
      fragment.append(link);
      offset = start + match[2].length;
    }
    fragment.append(document.createTextNode(text.slice(offset)));
    node.replaceWith(fragment);
  }
}
