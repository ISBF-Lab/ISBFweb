export const TEAMUP_HOME_FIELD = "isbf_teamup_home";

export function teamupConfig(site) {
  const config = site?.isbf_teamup;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    config.version === 1 &&
    config.enabled !== false
    ? config
    : null;
}

export function isTeamupCategory(model) {
  const category =
    model?.action === "reply"
      ? (model.topic?.category_id ?? model.topic?.category?.id)
      : model?.categoryId;
  const id = teamupConfig(model?.site)?.category_id;
  return Boolean(id && Number(category) === id);
}

export function isTeamupComposer(model) {
  return Boolean(
    isTeamupCategory(model) &&
    (model.creatingTopic ||
      (model.editingPost && model.post?.post_number === 1)),
  );
}

export function teamupPayload(model) {
  return isTeamupComposer(model)
    ? model[TEAMUP_HOME_FIELD] === true
    : undefined;
}

export function restoreTeamup(model, options = {}) {
  if (!isTeamupCategory(model)) {
    return;
  }
  model.set("isbf_anonymous", false);
  if (!isTeamupComposer(model)) {
    return;
  }
  const metadata =
    options.post?.isbf_teamup ??
    model.post?.isbf_teamup ??
    model.topic?.isbf_teamup;
  model.set(
    TEAMUP_HOME_FIELD,
    (options[TEAMUP_HOME_FIELD] ??
      options.post?.[TEAMUP_HOME_FIELD] ??
      model[TEAMUP_HOME_FIELD] ??
      metadata?.show_on_home ??
      false) === true,
  );
}

export function teamupQuery() {
  return { q: "isbf-teamup:all order:created" };
}
