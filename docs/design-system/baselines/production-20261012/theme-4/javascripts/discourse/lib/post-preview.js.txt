const PUBLIC_ACTION_TYPES = new Set([1, 2, 4, 5, 6, 7, 9, 11, 17]);

export function isActivityPreview(item, path) {
  const pathname = (path ?? "").split(/[?#]/)[0];
  return (
    /^\/u\/[^/]+\/activity(?:\/|$)/.test(pathname) &&
    !/\/(?:drafts|bookmarks|pending|messages|notifications)(?:\/|$)/.test(
      pathname,
    ) &&
    Number(item?.post_id) > 0 &&
    PUBLIC_ACTION_TYPES.has(Number(item?.action_type)) &&
    (!item.post_type || Number(item.post_type) === 1) &&
    !item.draft_key
  );
}

export function postPreview(html) {
  const document = new DOMParser().parseFromString(html ?? "", "text/html");
  const body = document.body;
  body
    .querySelectorAll(
      "script, style, iframe, aside.quote, aside.onebox, .lightbox-wrapper .meta",
    )
    .forEach((element) => element.remove());

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
      if (
        ["https:", "http:"].includes(url.protocol) &&
        !sources.has(url.href)
      ) {
        images.push({ src: url.href });
        sources.add(url.href);
      }
    } catch {
      continue;
    }
    if (images.length === 3) {
      break;
    }
  }

  body.querySelectorAll("a.lightbox, img:not(.emoji)").forEach((element) => {
    element.remove();
  });
  body.querySelectorAll("img.emoji").forEach((image) => {
    image.replaceWith(document.createTextNode(image.getAttribute("alt") ?? ""));
  });
  body
    .querySelectorAll("p, div, br, li, blockquote, h1, h2, h3")
    .forEach((element) => {
      element.append(document.createTextNode(" "));
    });
  const text = body.textContent.replace(/\s+/g, " ").trim();
  const characters = Array.from(text);
  return {
    text:
      characters.length > 300 ? `${characters.slice(0, 300).join("")}…` : text,
    images,
  };
}
