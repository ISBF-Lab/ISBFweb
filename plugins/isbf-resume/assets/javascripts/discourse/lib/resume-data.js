import { RESUME_FIELDS } from "./resume-fields";

export function emptyResume() {
  return {
    version: 1,
    template: "blue-gold",
    ...Object.fromEntries(Object.keys(RESUME_FIELDS).map((name) => [name, {}])),
  };
}

export function newEntry() {
  return `entry_${crypto.randomUUID().replaceAll("-", "")}`;
}

export function exportPayload(draft, language = "zh_CN") {
  const payload = { version: 1, template: draft.template, language };
  for (const [name, section] of Object.entries(RESUME_FIELDS)) {
    const pick = (entry) =>
      Object.fromEntries(
        section.fields
          .filter((field) => entry?.[field.id] !== undefined)
          .map((field) => [field.id, entry[field.id]])
      );
    payload[name] = section.repeatable
      ? Object.values(draft[name] || {}).map(pick)
      : pick(draft[name]);
  }
  return payload;
}

export function fieldPath(path, draft) {
  const [section, index, field] = path.split(".");
  if (RESUME_FIELDS[section]?.repeatable && field) {
    const entryId = Object.keys(draft[section] || {})[Number(index)];
    return entryId ? `${section}.${entryId}.${field}` : section;
  }
  return path;
}
