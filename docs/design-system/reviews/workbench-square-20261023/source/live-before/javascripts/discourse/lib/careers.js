export const CAREERS_FIELDS = ["isbf_careers_salary", "isbf_careers_home"];
export const CAREERS_SALARY_MAX_LENGTH = 120;

export function careersConfig(site) {
  const config = site?.isbf_careers;
  return Number.isSafeInteger(config?.category_id) &&
    config.category_id > 0 &&
    config.enabled === true &&
    config.version === 1
    ? config
    : null;
}

export function isCareersCategory(model) {
  const config = careersConfig(model?.site);
  const category =
    model?.action === "reply"
      ? (model.topic?.category_id ?? model.topic?.category?.id)
      : model?.categoryId;
  return Boolean(config && Number(category) === config.category_id);
}

export function isCareersComposer(model) {
  return Boolean(
    isCareersCategory(model) &&
    (model.creatingTopic ||
      (model.editingPost && model.post?.post_number === 1))
  );
}

export function careersSalary(value) {
  return typeof value === "string"
    ? value.replace(/^\p{White_Space}+|\p{White_Space}+$/gu, "")
    : "";
}

export function validCareersSalary(value) {
  return (
    (value == null ||
      (typeof value === "string" && !/[\p{Cc}\p{Cs}]/u.test(value))) &&
    Array.from(careersSalary(value)).length <= CAREERS_SALARY_MAX_LENGTH
  );
}

export function careersPayload(model, field) {
  if (!isCareersComposer(model)) {
    return;
  }
  if (field === CAREERS_FIELDS[0]) {
    return careersSalary(model[field]);
  }
  if (field === CAREERS_FIELDS[1]) {
    return model[field] === true;
  }
}

export function restoreCareers(model, options = {}) {
  if (!isCareersCategory(model)) {
    return;
  }
  model.set("isbf_anonymous", false);
  if (!isCareersComposer(model)) {
    return;
  }
  const metadata =
    options.post?.isbf_careers ??
    model.post?.isbf_careers ??
    model.topic?.isbf_careers;
  const values = [metadata?.salary, metadata?.show_on_home];
  CAREERS_FIELDS.forEach((field, index) => {
    const value =
      options[field] ?? options.post?.[field] ?? model[field] ?? values[index];
    model.set(field, index === 0 ? careersSalary(value) : value === true);
  });
}

export function careersQuery() {
  return { q: "isbf-careers:all order:created" };
}

export function careersImageUrl(value) {
  if (typeof value !== "string" || !value.trim()) {
    return null;
  }
  const url = value.trim();
  return /^(?:https?:\/\/|\/(?!\/))/i.test(url) && !/[\\\s]/.test(url)
    ? url
    : null;
}
