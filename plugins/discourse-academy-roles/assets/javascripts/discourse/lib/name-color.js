import { isValidHex, normalizeHex } from "discourse/lib/color-transformations";

export const NAME_COLOR_ENABLED = "academy_name_color_enabled";
export const NAME_COLOR = "academy_name_color";

export function validNameColor(value) {
  if (!value) {
    return true;
  }
  if (typeof value !== "string") {
    return false;
  }
  const hex = value.replace(/^#/, "");
  return (hex.length === 3 || hex.length === 6) && isValidHex(hex);
}

export function normalizedNameColor(value) {
  return value && validNameColor(value)
    ? `#${normalizeHex(value).toLowerCase()}`
    : null;
}

export function nameColorDraft(model) {
  const fields = model.custom_fields ?? {};
  const preferences = model.academy_name_color_preferences ?? {};
  return {
    enabled: Object.hasOwn(fields, NAME_COLOR_ENABLED)
      ? fields[NAME_COLOR_ENABLED] === true
      : preferences.enabled === true,
    color: Object.hasOwn(fields, NAME_COLOR)
      ? (fields[NAME_COLOR] ?? "")
      : (preferences.color ?? ""),
  };
}
