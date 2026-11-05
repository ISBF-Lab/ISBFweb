export const MBTI_DRAFT_KEY = "isbf_mbti_drafts";
export const MBTI_VARIANTS = ["28", "40", "93"];
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function mbtiConfig(site) {
  const config =
    typeof site?.get === "function" ? site.get("isbf_mbti") : site?.isbf_mbti;
  return config?.enabled === true ? config : null;
}

export function clearForeignMbtiDrafts(store, userId) {
  try {
    const saved = store.getObject(MBTI_DRAFT_KEY);
    if (saved && (!userId || saved.owner !== userId)) {
      store.remove(MBTI_DRAFT_KEY);
    }
  } catch {
    // An unavailable browser store must not prevent authentication or navigation.
  }
}

export function readMbtiDrafts(store, userId, questionnaires) {
  const drafts = {};
  let stale = false;
  try {
    const saved = store.getObject(MBTI_DRAFT_KEY);
    if (!saved || saved.owner !== userId) {
      clearForeignMbtiDrafts(store, userId);
      return { drafts, stale };
    }
    for (const meta of questionnaires) {
      const draft = saved.entries?.[meta.variant];
      if (!draft) {
        continue;
      }
      if (
        draft.variant !== meta.variant ||
        draft.version !== meta.version ||
        !UUID_PATTERN.test(draft.attempt_id) ||
        !Number.isInteger(draft.index) ||
        draft.index < 0 ||
        draft.index >= meta.question_count ||
        !draft.answers ||
        typeof draft.answers !== "object" ||
        Array.isArray(draft.answers) ||
        Object.entries(draft.answers).some(
          ([id, choice]) =>
            !/^\d+$/.test(id) ||
            Number(id) < 1 ||
            Number(id) > meta.question_count ||
            ![1, 2].includes(choice)
        )
      ) {
        stale = true;
        continue;
      }
      drafts[meta.variant] = draft;
    }
    return { drafts, stale };
  } catch {
    return { drafts, stale: true };
  }
}

export function saveMbtiDrafts(store, userId, drafts) {
  try {
    if (!Object.keys(drafts).length) {
      store.remove(MBTI_DRAFT_KEY);
      return true;
    }
    return (
      store.set({
        key: MBTI_DRAFT_KEY,
        value: JSON.stringify({ owner: userId, entries: drafts }),
      }) !== false
    );
  } catch {
    return false;
  }
}

export function newMbtiAttemptId() {
  return crypto.randomUUID();
}

export function mbtiError(error, fallback) {
  const errors =
    error?.jqXHR?.responseJSON?.errors || error?.responseJSON?.errors;
  return Array.isArray(errors) &&
    errors.every((message) => typeof message === "string")
    ? errors.join(" ")
    : fallback;
}
