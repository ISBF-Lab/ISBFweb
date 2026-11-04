import { i18n } from "discourse-i18n";

export function frameName(frame) {
  return frame.name_key ? i18n(frame.name_key) : frame.name;
}

export function availableFrames(
  catalog,
  keys,
  ownedKeys = keys,
  globalMinimum = 0
) {
  const eligible = new Set(keys || []);
  const owned = new Set(ownedKeys || []);
  return (catalog || [])
    .filter((frame) => frame.access_mode === "public" || owned.has(frame.key))
    .map((frame) => ({
      id: frame.key,
      name: eligible.has(frame.key)
        ? frameName(frame)
        : i18n("avatar_frames.levels.locked_frame", {
            name: frameName(frame),
            level:
              frame.minimum_activity_level_id && !frame.minimum_activity_level
                ? "?"
                : Math.max(
                    frame.minimum_activity_level?.number || 0,
                    globalMinimum
                  ),
          }),
      disabled: !eligible.has(frame.key),
    }));
}
