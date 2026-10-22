import { get } from "@ember/object";
import { isValidHex, normalizeHex } from "discourse/lib/color-transformations";

export const NAME_COLOR_ENABLED = "academy_name_color_enabled";
export const NAME_COLOR = "academy_name_color";
const GRADIENT_COLOR =
  /^linear-gradient\((90|180)deg,\s*(#[0-9a-f]{3}(?:[0-9a-f]{3})?),\s*(#[0-9a-f]{3}(?:[0-9a-f]{3})?)\)$/i;

export function nameGradientStops(value) {
  return typeof value === "string" && value.length <= 80
    ? (GRADIENT_COLOR.exec(value)?.slice(2) ?? null)
    : null;
}

export function nameGradientDirection(value) {
  return nameGradientStops(value) ? GRADIENT_COLOR.exec(value)[1] : "90";
}

export function validNameColor(value) {
  if (!value) {
    return true;
  }
  if (typeof value !== "string") {
    return false;
  }
  if (nameGradientStops(value)) {
    return true;
  }
  const hex = value.replace(/^#/, "");
  return (hex.length === 3 || hex.length === 6) && isValidHex(hex);
}

export function normalizedNameColor(value) {
  const stops = nameGradientStops(value);
  if (stops) {
    return `linear-gradient(${nameGradientDirection(value)}deg, ${stops.map(normalizedNameColor).join(", ")})`;
  }
  return value && validNameColor(value)
    ? `#${normalizeHex(value).toLowerCase()}`
    : null;
}

export function nameColorFormData(model) {
  const draft = nameColorDraft(model);
  const stops = nameGradientStops(draft.color);
  return {
    ...draft,
    color: stops?.[0] ?? draft.color,
    endColor: stops?.[1] ?? "",
    direction: nameGradientDirection(draft.color),
    gradient: Boolean(stops),
  };
}

export function nameColorDraft(model) {
  const fields = get(model, "custom_fields") ?? {};
  const preferences = get(model, "academy_name_color_preferences") ?? {};
  return {
    enabled: Object.hasOwn(fields, NAME_COLOR_ENABLED)
      ? fields[NAME_COLOR_ENABLED] === true
      : preferences.enabled === true,
    color: Object.hasOwn(fields, NAME_COLOR)
      ? (fields[NAME_COLOR] ?? "")
      : (preferences.color ?? ""),
  };
}
