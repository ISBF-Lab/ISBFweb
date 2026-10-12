export const LEARNING_FIELDS = [
  "isbf_learning_course_id",
  "isbf_learning_files",
];

export function isLearningComposer(model) {
  return Boolean(
    model?.site?.isbf_learning?.category_id > 0 &&
    Number(model.categoryId) === model.site.isbf_learning.category_id &&
    (model.creatingTopic ||
      (model.editingPost && model.post?.post_number === 1)),
  );
}

export function learningFileIds(value) {
  try {
    const ids = typeof value === "string" ? JSON.parse(value) : value;
    return Array.isArray(ids)
      ? [...new Set(ids.filter((id) => /^[a-f0-9-]{36}$/.test(id)))].slice(
          0,
          20,
        )
      : [];
  } catch {
    return [];
  }
}

export function restoreLearning(model, options = {}) {
  if (!isLearningComposer(model)) {
    return;
  }
  for (const field of LEARNING_FIELDS) {
    const value = options[field] ?? options.post?.[field] ?? model[field];
    model.set(
      field,
      field === LEARNING_FIELDS[1]
        ? JSON.stringify(learningFileIds(value))
        : value || "",
    );
  }
  model.set("isbf_anonymous", false);
}

export function learningPayload(model, field) {
  if (!isLearningComposer(model)) {
    return;
  }
  return field === LEARNING_FIELDS[1]
    ? JSON.stringify(learningFileIds(model[field]))
    : model[field] || "";
}
