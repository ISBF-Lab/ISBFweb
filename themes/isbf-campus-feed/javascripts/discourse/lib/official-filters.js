export const OFFICIAL_FIELDS = [
  "isbf_official_campuses",
  "isbf_official_types",
];

export function officialConfig(site) {
  const config = site?.isbf_official;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    Array.isArray(config.campuses) &&
    Array.isArray(config.types) &&
    config.campuses.length > 0 &&
    config.types.length > 0 &&
    [...config.campuses, ...config.types].every(
      (item) =>
        item &&
        typeof item.id === "string" &&
        /^[a-z][a-z0-9-]*$/.test(item.id) &&
        typeof item.label === "string"
    )
    ? config
    : null;
}

export function officialSelections(values, items) {
  const allowed = new Set(items.map((item) => item.id));
  return Array.isArray(values)
    ? [...new Set(values.filter((id) => allowed.has(id)))]
    : [];
}

export function buildOfficialQuery(config, campus = "", type = "") {
  return [
    `isbf-official:${config.category_id}`,
    officialSelections([campus], config.campuses)[0]
      ? `isbf-campus:${campus}`
      : null,
    officialSelections([type], config.types)[0]
      ? `isbf-official-type:${type}`
      : null,
    "order:activity",
  ]
    .filter(Boolean)
    .join(" ");
}

export function isOfficialComposer(model, config) {
  return Boolean(
    config &&
    model &&
    !model.privateMessage &&
    !model.creatingPrivateMessage &&
    model.archetypeId !== "private_message" &&
    model.topic?.archetype !== "private_message" &&
    Number(model.categoryId ?? model.topic?.category_id) ===
      config.category_id &&
    (model.creatingTopic || model.editingFirstPost)
  );
}

export function restoreOfficialSelections(model, config) {
  if (!isOfficialComposer(model, config)) {
    return;
  }
  OFFICIAL_FIELDS.forEach((field, index) => {
    if (model[field] === undefined || model[field] === null) {
      model.set(
        field,
        officialSelections(
          model.editingFirstPost
            ? (model.post?.[field] ?? model.topic?.[field])
            : [],
          index === 0 ? config.campuses : config.types
        )
      );
    }
  });
}

export function officialPayload(model, config, field) {
  if (!isOfficialComposer(model, config)) {
    return undefined;
  }
  return JSON.stringify(
    officialSelections(
      model[field],
      field === OFFICIAL_FIELDS[0] ? config.campuses : config.types
    )
  );
}

export function officialSelectionsComplete(model, config) {
  return OFFICIAL_FIELDS.every(
    (field) =>
      JSON.parse(officialPayload(model, config, field) ?? "[]").length > 0
  );
}

export class OfficialRequestGuard {
  #generation = 0;

  next() {
    return ++this.#generation;
  }

  isCurrent(generation) {
    return this.#generation === generation;
  }
}
