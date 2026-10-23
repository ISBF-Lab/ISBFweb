const STORE_KEY = "isbfBackNavigation";
const MAX_ENTRIES = 100;

export default class BackNavigationHistory {
  #browser;
  #entries = [];
  #index = -1;
  #storage;

  constructor(storage, browser = window) {
    this.#browser = browser;
    this.#storage = storage;

    try {
      const saved = storage.getObject(STORE_KEY);
      if (
        Array.isArray(saved?.entries) &&
        saved.entries.length <= MAX_ENTRIES &&
        saved.entries.every((entry) => this.#validEntry(entry))
      ) {
        this.#entries = saved.entries;
      }
    } catch {}

    this.traverse();
  }

  get previousURL() {
    return this.#entries[this.#index - 1]?.url ?? null;
  }

  capture() {
    const entry = this.#currentEntry();
    if (!entry) {
      return;
    }

    if (this.#index < 0) {
      this.#entries = [entry];
      this.#index = 0;
    } else {
      this.#entries[this.#index] = entry;
    }
    this.#save();
  }

  commit(replace = false) {
    const entry = this.#currentEntry();
    if (!entry) {
      return;
    }

    if (
      replace ||
      this.#index < 0 ||
      this.#entries[this.#index]?.uuid === entry.uuid
    ) {
      this.capture();
      return;
    }

    this.#entries = this.#entries.slice(0, this.#index + 1);
    this.#entries.push(entry);
    if (this.#entries.length > MAX_ENTRIES) {
      this.#entries.shift();
    }
    this.#index = this.#entries.length - 1;
    this.#save();
  }

  traverse() {
    const entry = this.#currentEntry();
    const index = entry
      ? this.#entries.findIndex((item) => item.uuid === entry.uuid)
      : -1;

    if (index < 0) {
      this.#entries = entry ? [entry] : [];
      this.#index = this.#entries.length - 1;
    } else {
      this.#index = index;
      this.#entries[index] = entry;
    }
    this.#save();
  }

  #currentEntry() {
    const { history, location } = this.#browser;
    const entry = {
      uuid: history.state?.uuid,
      url: location.pathname + location.search + location.hash,
    };
    return this.#validEntry(entry) ? entry : null;
  }

  #save() {
    try {
      this.#storage.setObject({
        key: STORE_KEY,
        value: { entries: this.#entries },
      });
    } catch {}
  }

  #validEntry(entry) {
    if (
      typeof entry?.uuid !== "string" ||
      !entry.uuid ||
      typeof entry.url !== "string" ||
      !entry.url.startsWith("/")
    ) {
      return false;
    }

    try {
      return (
        new URL(entry.url, this.#browser.location.origin).origin ===
        this.#browser.location.origin
      );
    } catch {
      return false;
    }
  }
}
