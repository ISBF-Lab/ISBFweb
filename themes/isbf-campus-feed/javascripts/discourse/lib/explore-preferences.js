export function normalizeExplorePreferences(preferences = {}) {
  const ids = (values) =>
    [...new Set((values || []).map(Number))].filter(
      (id) => Number.isSafeInteger(id) && id > 0
    );
  return {
    category_ids: ids(preferences.category_ids),
    tag_ids: ids(preferences.tag_ids),
    order: preferences.order === "hot" ? "hot" : "activity",
  };
}

export function preferencesSignature(preferences) {
  return JSON.stringify(normalizeExplorePreferences(preferences));
}

export function createExplorePreferenceWriter({
  save,
  onSaved,
  onState,
  delay = 300,
}) {
  let cancelled = false;
  let failed = false;
  let pending = null;
  let saving = false;
  let timer;

  async function flush() {
    clearTimeout(timer);
    timer = null;
    if (cancelled || failed || saving || !pending) {
      return;
    }
    const snapshot = pending;
    pending = null;
    saving = true;
    onState("saving");
    try {
      const result = await save(snapshot);
      if (!cancelled) {
        onSaved?.(snapshot, result);
      }
    } catch {
      if (!cancelled) {
        pending ||= snapshot;
        failed = true;
        onState("failed");
      }
    } finally {
      saving = false;
      if (!cancelled && !failed) {
        if (pending) {
          timer = setTimeout(flush, delay);
        } else {
          onState("saved");
        }
      }
    }
  }

  return {
    cancel() {
      cancelled = true;
      pending = null;
      clearTimeout(timer);
    },
    retry() {
      failed = false;
      return flush();
    },
    update(preferences) {
      if (cancelled) {
        return;
      }
      pending = normalizeExplorePreferences(preferences);
      clearTimeout(timer);
      if (!failed && !saving) {
        onState("pending");
        timer = setTimeout(flush, delay);
      }
    },
  };
}
