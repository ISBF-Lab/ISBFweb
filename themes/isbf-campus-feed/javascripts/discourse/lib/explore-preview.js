export function previewForHeights(heights, budget) {
  let count = 0;
  let height = 0;
  for (const itemHeight of heights) {
    if (!Number.isFinite(itemHeight) || itemHeight <= 0) {
      return { complete: false, count };
    }
    if (count > 0 && height + itemHeight > Math.max(0, budget)) {
      return { complete: true, count };
    }
    count += 1;
    height += itemHeight;
  }
  return { complete: true, count };
}

export function explorePreviewBudget(root) {
  const viewport = window.visualViewport;
  const height = viewport?.height || window.innerHeight;
  const offset = viewport?.offsetTop || 0;
  const occupied = [];
  for (const element of document.querySelectorAll(
    ".d-header, .isbf-v2-feed-header, .isbf-v2-page-header, .isbf-v2-section-heading, .isbf-explore__toolbar, .isbf-explore__status, .isbf-explore__error, .isbf-v2-mobile-nav"
  )) {
    const rect = element.getBoundingClientRect();
    if (
      rect.width <= 0 ||
      rect.height <= 0 ||
      rect.bottom <= offset ||
      rect.top >= offset + height
    ) {
      continue;
    }
    occupied.push([
      Math.max(0, rect.top - offset),
      Math.min(height, rect.bottom - offset),
    ]);
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
  return Math.max(
    0,
    height -
      occupiedHeight -
      (header?.getBoundingClientRect().height || 0) -
      (footer?.getBoundingClientRect().height || 0)
  );
}
