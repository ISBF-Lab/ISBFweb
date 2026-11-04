export function newLevel() {
  return {
    id: null,
    name: "",
    badge_id: null,
    period_days: 100,
    continuous_days: 0,
    max_check_gap_hours: 36,
    demotion_buffer_percent: 0,
    basic_conditions: [],
    advanced_conditions: [],
  };
}

export function isConditionGroup(catalog, metric, group) {
  return catalog.find((entry) => entry.key === metric)?.group === group;
}

export function configurationPayload(data, revision, confirmedDeletedIds) {
  return {
    revision,
    allow_demotion: data.allow_demotion,
    confirmed_deleted_ids: confirmedDeletedIds,
    cosmetics: {
      ...data.cosmetics,
      name_color_light: normalizePreset(data.cosmetics.name_color_light),
      name_color_dark: normalizePreset(data.cosmetics.name_color_dark),
    },
    levels: data.levels.map((level) => ({
      id: level.id || null,
      name: level.name,
      badge_id: level.badge_id ? Number(level.badge_id) : null,
      period_days: level.period_days,
      continuous_days: level.continuous_days,
      max_check_gap_hours: level.max_check_gap_hours,
      demotion_buffer_percent: level.demotion_buffer_percent,
      conditions: [...level.basic_conditions, ...level.advanced_conditions]
        .sort(
          (left, right) =>
            (left.original_index ?? Number.MAX_SAFE_INTEGER) -
            (right.original_index ?? Number.MAX_SAFE_INTEGER)
        )
        .map((condition) => {
          const value = { ...condition };
          delete value.original_index;
          return value;
        }),
    })),
  };
}

function normalizePreset(value) {
  return value ? `#${value.replace(/^#/, "").toLowerCase()}` : "";
}

export function conditionFor(definition) {
  const condition = {
    metric: definition.key,
    period: definition.periods[0],
    value: definition.maximum ? 0 : 1,
  };
  if (definition.percentage) {
    condition.cap = definition.key === "posts_read_percent" ? 2000 : 250;
  }
  if (definition.months) {
    condition.months = 6;
  }
  return condition;
}

export function formDataFor(model) {
  return {
    allow_demotion: model.allow_demotion,
    cosmetics: {
      avatar_minimum_level_id: "legacy-0",
      name_color_enabled: false,
      name_color_minimum_level_id: "legacy-0",
      name_color_light: "",
      name_color_dark: "",
      ...model.cosmetics,
    },
    levels: model.levels.map((level) => {
      const value = { ...level };
      // The backend qualification fingerprint includes condition order.
      const conditions = level.conditions.map((condition, original_index) => ({
        ...condition,
        original_index,
      }));
      value.basic_conditions = conditions.filter((condition) =>
        isConditionGroup(model.catalog, condition.metric, "basic")
      );
      value.advanced_conditions = conditions.filter((condition) =>
        isConditionGroup(model.catalog, condition.metric, "advanced")
      );
      delete value.conditions;
      return value;
    }),
  };
}
