import { ajax } from "discourse/lib/ajax";

export function createViewTracker(endpoint, idParameter) {
  const counts = new Map();
  const requests = new Map();
  const pendingKeys = new Set();
  let timer;

  async function flush() {
    const keys = [...pendingKeys].slice(0, 50);
    keys.forEach((key) => pendingKeys.delete(key));
    timer = null;

    try {
      const result = await ajax(endpoint, {
        data: { [idParameter]: keys.map((key) => requests.get(key).id) },
        type: "POST",
      });
      keys.forEach((key) => {
        const request = requests.get(key);
        const value = result.counts?.[request.id];
        const count =
          typeof value === "number" && Number.isInteger(value) && value >= 0
            ? value
            : null;
        if (count !== null) {
          counts.set(key, count);
        }
        request.resolve(count);
        requests.delete(key);
      });
    } catch {
      keys.forEach((key) => {
        requests.get(key)?.resolve(null);
        requests.delete(key);
      });
    }

    if (pendingKeys.size) {
      timer = setTimeout(flush, 40);
    }
  }

  return function recordVisibleView(id, userId) {
    const key = userId + ":" + id;
    if (counts.has(key)) {
      return Promise.resolve(counts.get(key));
    }
    if (requests.has(key)) {
      return requests.get(key).promise;
    }

    let resolve;
    const promise = new Promise((done) => {
      resolve = done;
    });
    requests.set(key, { promise, resolve, id });
    pendingKeys.add(key);
    timer ??= setTimeout(flush, 40);
    return promise;
  };
}
