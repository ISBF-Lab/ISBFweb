export const OFFICIAL_FIELDS = [
  "isbf_official_campuses",
  "isbf_official_types",
];

export function officialConfig(site) {
  const config = site?.get ? site.get("isbf_official") : site?.isbf_official;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    Array.isArray(config.campuses) &&
    Array.isArray(config.types) &&
    config.types.length > 0 &&
    (config.revision === undefined || Number.isSafeInteger(config.revision)) &&
    [...config.campuses, ...config.types].every(
      (item) =>
        item &&
        typeof item.id === "string" &&
        /^[a-z][a-z0-9-]*$/.test(item.id) &&
        typeof item.label === "string" &&
        (item.enabled === undefined || typeof item.enabled === "boolean")
    )
    ? config
    : null;
}

export function officialSelectionIds(values) {
  return Array.isArray(values)
    ? [...new Set(values.filter((id) => typeof id === "string"))]
    : [];
}

export function officialSelectionLimit(values) {
  return (
    Array.isArray(values) &&
    values.length <= 100 &&
    new TextEncoder().encode(JSON.stringify(values)).length <= 4096
  );
}

export function officialComposerItems(items, selectedIds) {
  const selected = new Set(officialSelectionIds(selectedIds));
  const known = new Set(items.map((item) => item.id));
  return [
    ...items.filter((item) => item.enabled !== false || selected.has(item.id)),
    ...[...selected]
      .filter((id) => !known.has(id))
      .map((id) => ({ id, label: id, enabled: false })),
  ];
}

export function officialSelectionsAvailable(model, config) {
  return OFFICIAL_FIELDS.every((field, index) => {
    const values = model[field] ?? [];
    const items = index === 0 ? config.campuses : config.types;
    const original = model.editingFirstPost
      ? officialSelectionIds(model.post?.[field] ?? model.topic?.[field])
      : [];
    return (
      officialSelectionLimit(values) &&
      values.every((id) =>
        items.some(
          (item) =>
            item.id === id && (item.enabled !== false || original.includes(id))
        )
      )
    );
  });
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
  OFFICIAL_FIELDS.forEach((field) => {
    if (model[field] === undefined || model[field] === null) {
      model.set(
        field,
        officialSelectionIds(
          model.editingFirstPost
            ? (model.post?.[field] ?? model.topic?.[field])
            : []
        )
      );
    }
  });
}

export function officialPayload(model, config, field) {
  if (!isOfficialComposer(model, config)) {
    return undefined;
  }
  return JSON.stringify(model[field] ?? []);
}

export function officialSelectionsComplete(model, config) {
  return (
    isOfficialComposer(model, config) &&
    officialSelections(model.isbf_official_types, config.types).length > 0
  );
}

export function officialLocationLabel(
  location,
  campusIds,
  config,
  separator = "、"
) {
  const campuses = config?.campuses ?? [];
  const selected = new Set(officialSelections(campusIds, campuses));
  const labels = campuses
    .filter((campus) => selected.has(campus.id))
    .map((campus) => campus.label)
    .join(separator);
  const address = typeof location === "string" ? location.trim() : "";
  return [labels, address].filter(Boolean).join(" · ");
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
