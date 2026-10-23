import { ajax } from "discourse/lib/ajax";

export function isPinningContext(router, site, siteSettings) {
  if (site?.isbf_pinning?.enabled !== true) {
    return false;
  }
  const path =
    (router?.currentURL || "").split(/[?#]/)[0].replace(/\/$/, "") || "/";
  if (path === "/" || path === "/latest") {
    return true;
  }
  const categoryId = Number(
    site.isbf_pinning.official_category_id ||
      siteSettings?.academy_official_category,
  );
  const match = path.match(/^\/c\/[^/]+\/(\d+)(?:\/l\/latest)?$/);
  return categoryId > 0 && Number(match?.[1]) === categoryId;
}

export function pinningMeta(topic, now = Date.now()) {
  const metadata = topic?.isbf_home_pinning;
  if (!metadata || typeof metadata !== "object") {
    return null;
  }
  return {
    ...metadata,
    active:
      metadata.scoped === true &&
      metadata.active === true &&
      Number.isFinite(Date.parse(metadata.pinned_at)) &&
      Date.parse(metadata.pinned_until) > now,
  };
}

export function pinDeadline(value) {
  if (typeof value !== "string") {
    return null;
  }
  const iso = value.replace(
    /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})\s?([+-]\d{2}:\d{2})$/,
    "$1T$2:00$3",
  );
  const parts = iso.match(
    /^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})$/,
  );
  if (
    !parts ||
    Number(parts[2]) > 23 ||
    Number(parts[3]) > 59 ||
    Number(parts[4] || 0) > 59
  ) {
    return null;
  }
  const calendar = new Date(`${parts[1]}T00:00:00Z`);
  if (
    !Number.isFinite(calendar.getTime()) ||
    calendar.toISOString().slice(0, 10) !== parts[1]
  ) {
    return null;
  }
  const timestamp = Date.parse(iso);
  return Number.isFinite(timestamp) ? new Date(timestamp) : null;
}

export async function saveHomePin(topic, { enabled, until }) {
  if (!Number.isSafeInteger(Number(topic?.id)) || Number(topic.id) <= 0) {
    throw new Error("Invalid topic");
  }
  if (
    enabled &&
    (!until ||
      !Number.isFinite(Date.parse(until)) ||
      Date.parse(until) <= Date.now())
  ) {
    throw new Error("Invalid pin deadline");
  }
  const result = await ajax(`/t/${topic.id}/status`, {
    type: "PUT",
    data: {
      status: "pinned_globally",
      enabled: Boolean(enabled),
      until: enabled ? new Date(until).toISOString() : null,
      isbf_home_pin: true,
    },
  });
  const metadata = result?.isbf_home_pinning;
  if (
    !metadata ||
    typeof metadata.scoped !== "boolean" ||
    typeof metadata.active !== "boolean"
  ) {
    throw new Error("Missing pin response");
  }
  if (topic.set) {
    topic.setProperties({
      isbf_home_pinning: metadata,
      ...(enabled
        ? {}
        : {
            pinned: false,
            pinned_at: null,
            pinned_until: null,
            latest_created_order_pinned_at: null,
          }),
    });
  } else {
    Object.assign(topic, {
      isbf_home_pinning: metadata,
      ...(enabled
        ? {}
        : {
            pinned: false,
            pinned_at: null,
            pinned_until: null,
            latest_created_order_pinned_at: null,
          }),
    });
  }
  return metadata;
}

function pinTime(topic, now) {
  const metadata = pinningMeta(topic, now);
  if (metadata?.scoped) {
    return metadata.active ? Date.parse(metadata.pinned_at) : 0;
  }
  return topic.pinned
    ? Date.parse(topic.latest_created_order_pinned_at) || 0
    : 0;
}

export function compareHomeTopics(left, right, now = Date.now()) {
  return (
    pinTime(right, now) - pinTime(left, now) ||
    (Date.parse(right.created_at ?? right.createdAt) || 0) -
      (Date.parse(left.created_at ?? left.createdAt) || 0) ||
    Number(right.id) - Number(left.id)
  );
}

export function sortHomePinList(list, now = Date.now()) {
  if (list?.isbfHomePinScope === true && Array.isArray(list.topics)) {
    const topics = [...list.topics].sort((left, right) =>
      compareHomeTopics(left, right, now),
    );
    if (list.set) {
      list.set("topics", topics);
    } else {
      list.topics = topics;
    }
  }
}

export class PinExpiryScheduler {
  #lists = new Map();
  #timer;
  #now;
  #setTimer;
  #clearTimer;
  #onChange;
  #enabled;

  constructor({
    onChange,
    enabled = () => true,
    now = Date.now,
    setTimer = (callback, delay) => globalThis.setTimeout(callback, delay),
    clearTimer = (timer) => globalThis.clearTimeout(timer),
  }) {
    this.#onChange = onChange;
    this.#enabled = enabled;
    this.#now = now;
    this.#setTimer = setTimer;
    this.#clearTimer = clearTimer;
  }

  register(list, onSorted) {
    if (list?.isbfHomePinScope === true) {
      this.#lists.set(list, onSorted);
      this.#schedule();
    }
  }

  remove(list) {
    this.#lists.delete(list);
    this.#schedule();
  }

  refresh() {
    const now = this.#now();
    if (this.#enabled()) {
      for (const [list, onSorted] of this.#lists) {
        if (!list.isDestroying && !list.isDestroyed) {
          sortHomePinList(list, now);
          onSorted?.(list);
        }
      }
      this.#onChange?.(now);
    }
    this.#schedule();
  }

  destroy() {
    this.#clearTimer(this.#timer);
    this.#timer = null;
    this.#lists.clear();
  }

  #schedule() {
    this.#clearTimer(this.#timer);
    this.#timer = null;
    if (!this.#enabled()) {
      return;
    }
    const now = this.#now();
    let next = Infinity;
    for (const list of this.#lists.keys()) {
      if (list.isDestroying || list.isDestroyed) {
        this.#lists.delete(list);
        continue;
      }
      for (const topic of list.topics || []) {
        const metadata = pinningMeta(topic, now);
        if (metadata?.active) {
          next = Math.min(next, Date.parse(metadata.pinned_until));
        }
      }
    }
    if (Number.isFinite(next)) {
      this.#timer = this.#setTimer(
        () => this.refresh(),
        Math.min(2147483647, Math.max(1, next - now + 1)),
      );
    }
  }
}
