import { i18n } from "discourse-i18n";

export function frameName(frame) {
  return frame.name_key ? i18n(frame.name_key) : frame.name;
}

export function availableFrames(catalog, keys) {
  const eligible = new Set(keys || []);
  return (catalog || [])
    .filter(
      (frame) => frame.access_mode === "public" || eligible.has(frame.key)
    )
    .map((frame) => ({ id: frame.key, name: frameName(frame) }));
}
