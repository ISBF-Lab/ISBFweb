export function feedbackCategory(site, categoryId) {
  const id = Number(categoryId);
  if (!Number.isSafeInteger(id) || id <= 0) {
    return null;
  }
  return (
    site?.categories?.find((category) => Number(category.id) === id) ?? null
  );
}

export function isFeedbackPath(path, category) {
  if (!category) {
    return false;
  }
  const match = (path ?? "")
    .split("?")[0]
    .match(/^\/c\/(?:[^/]+\/)*?(\d+)(?:\/l\/[^/]+)?\/?$/);
  return Boolean(match && Number(match[1]) === Number(category.id));
}

export function feedbackHref(category) {
  if (!category) {
    return null;
  }
  const path = category.url || category.path || `/c/${category.id}`;
  return `${path.replace(/\/$/, "")}/l/latest`;
}

export function feedbackComposeHref(category) {
  return category ? `/new-topic?category_id=${category.id}` : "/new-topic";
}
