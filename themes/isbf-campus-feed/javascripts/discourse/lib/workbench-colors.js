export function workbenchColor(value) {
  const color = typeof value === "string" ? value.trim() : "";
  return /^#[0-9a-f]{6}$/i.test(color) ? color.toLowerCase() : "";
}

export function workbenchColors(settings, mode, keys) {
  const fallback = workbenchColor(settings[`workbench_plate_color_${mode}`]);
  return {
    panel: workbenchColor(settings[`workbench_panel_color_${mode}`]),
    plates: keys.map(
      (key) =>
        workbenchColor(settings[`workbench_plate_${key}_color_${mode}`]) ||
        fallback
    ),
  };
}

export function workbenchInk(color) {
  const [red, green, blue] = color.slice(0, 3).map((channel) => {
    const value = channel / 255;
    return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  const luminance = red * 0.2126 + green * 0.7152 + blue * 0.0722;
  return luminance > 0.179
    ? "rgb(var(--always-black-rgb))"
    : "var(--token-color-text-inverse)";
}
