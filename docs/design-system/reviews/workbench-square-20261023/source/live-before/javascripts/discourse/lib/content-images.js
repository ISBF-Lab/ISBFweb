import lightbox, { sortLightboxItems } from "discourse/lib/lightbox";

const controllers = new WeakMap();
const linkedPreviews = new WeakMap();
let activeViewer;

export function isImageAttachment(file) {
  return /\.(avif|bmp|gif|ico|jpe?g|png|svg|webp)$/i.test(file?.name || "");
}

export function contentImageUrl(value) {
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
  for (const [attribute, value] of [
    ["data-target-width", image.naturalWidth || image.getAttribute("width")],
    ["data-target-height", image.naturalHeight || image.getAttribute("height")],
  ]) {
    if (Number(value) > 0) {
      link.setAttribute(attribute, value);
    }
  }
}

export function prepareContentImages(element, previewLabel) {
  const added = [];
  for (const image of element.querySelectorAll("img")) {
    if (
      image.matches(".emoji, .avatar, .favicon, .site-logo") ||
      linkedPreviews.get(image)?.isConnected ||
      image.closest(
        ".lightbox, .spoiler, .spoiled, [data-isbf-image-preview-ignore]",
      )
    ) {
      continue;
    }
    const url = contentImageUrl(
      image.getAttribute("data-large-src") ||
        image.getAttribute("data-orig-src") ||
        image.getAttribute("src"),
    );
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
    added.push({ image, link, wrapped: !existingLink });
  }
  return () => {
    for (const { image, link, wrapped } of added) {
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
      origin.focus({ preventScroll: true });
    }
    afterClose?.();
  };
  const close = () => viewer?.querySelector(".pswp__button--close")?.click();
  const retry = (event) => {
    const button = event.currentTarget;
    const url = viewer.querySelector(".pswp__button--original-image")?.href;
    const target =
      [...controller.element.querySelectorAll(".lightbox")].find((item) => {
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
      viewer = [...doc.querySelectorAll(".pswp")].find(
        (candidate) => !existing.has(candidate),
      );
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
  observer.observe(doc.body, { childList: true, subtree: true });
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
    },
  };
  return true;
}

export function decorateContentImages(element, options = {}) {
  if (controllers.has(element)) {
    return () => {};
  }
  const restores = [prepareContentImages(element, options.previewLabel)];
  const controller = { element, destroyed: false };
  controllers.set(element, controller);
  let pending = false;
  const click = async (event) => {
    const target = event.target;
    if (target.matches?.("img")) {
      const ownedLink = target.closest(".isbf-content-image-link");
      if (ownedLink && ownedLink.contains(target)) {
        const source = contentImageUrl(
          target.getAttribute("data-large-src") ||
            target.getAttribute("data-orig-src") ||
            target.getAttribute("src"),
        );
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
    if (
      !item ||
      !element.contains(item) ||
      item.closest(".spoiler, .spoiled") ||
      event.button !== 0 ||
      event.altKey ||
      event.ctrlKey ||
      event.metaKey ||
      event.shiftKey
    ) {
      return;
    }
    event.preventDefault();
    event.stopImmediatePropagation();
    if (pending || activeViewer || controller.destroyed) {
      return;
    }
    pending = true;
    try {
      const items = sortLightboxItems(
        [...element.querySelectorAll(".lightbox")].filter(
          (entry) => !entry.closest(".spoiler, .spoiled"),
        ),
      );
      const sourceOf = (entry) =>
        [
          entry.href || entry.dataset.largeSrc,
          entry.querySelector("img")?.getAttribute("src"),
        ].join("|");
      const sources = items.map(sourceOf);
      const gallery = element.ownerDocument.createElement("div");
      const copies = items.map((entry) => {
        const copy = entry.cloneNode(true);
        // Native initialization is cached and does not expose teardown. A fresh
        // snapshot avoids stale galleries and duplicate handlers on rendered links.
        copy.closest = (selector) => entry.closest(selector);
        copy.getBoundingClientRect = () => entry.getBoundingClientRect();
        const image = copy.querySelector("img");
        const original = entry.querySelector("img");
        if (image && original) {
          image.getBoundingClientRect = () => original.getBoundingClientRect();
        }
        gallery.append(copy);
        return copy;
      });
      await lightbox(gallery, options.post ? { post: options.post } : {});
      if (
        controller.destroyed ||
        !element.isConnected ||
        !element.contains(item) ||
        items.some(
          (entry, index) =>
            !element.contains(entry) || sourceOf(entry) !== sources[index],
        )
      ) {
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
