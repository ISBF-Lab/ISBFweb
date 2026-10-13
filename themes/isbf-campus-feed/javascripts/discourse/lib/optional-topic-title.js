const UNTITLED_PATTERN = /^校园动态 \[isbf-untitled:[0-9a-f-]{36}\]$/;

export function isUntitledTopicTitle(title) {
  return typeof title === "string" && UNTITLED_PATTERN.test(title);
}

export function optionalTopicTitle(title) {
  return isUntitledTopicTitle(title) ? "" : (title ?? "");
}

export function setOptionalTopicTitle(model, value) {
  const explicitTitle = value ?? "";
  const title = explicitTitle.trim()
    ? explicitTitle
    : isUntitledTopicTitle(model.title)
      ? model.title
      : `校园动态 [isbf-untitled:${crypto.randomUUID()}]`;

  model.setProperties({ isbf_optional_title: explicitTitle, title });
}

export function prepareOptionalTopicTitle(model) {
  setOptionalTopicTitle(
    model,
    model.isbf_optional_title ?? optionalTopicTitle(model.title)
  );
}
