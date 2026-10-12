import { ajax } from "discourse/lib/ajax";

const cache = new Map();
const pendingRequests = new Map();
const invalidatedPosts = new Set();
const generations = new Map();
const queue = [];
let activeRequests = 0;

function runQueue() {
  while (activeRequests < 4 && queue.length) {
    activeRequests += 1;
    runJob(queue.shift());
  }
}

function runJob(job) {
  const { generation, postId } = job;
  ajax(`/posts/${job.postId}/cooked`)
    .then((result) => {
      if (
        invalidatedPosts.has(postId) ||
        generation !== generations.get(postId)
      ) {
        job.resolve("");
      } else {
        cache.set(postId, result.cooked);
        if (cache.size > 50) {
          cache.delete(cache.keys().next().value);
        }
        job.resolve(result.cooked);
      }
    })
    .catch(job.reject)
    .finally(() => {
      if (pendingRequests.get(postId)?.promise === job.promise) {
        pendingRequests.delete(postId);
      }
      activeRequests -= 1;
      runQueue();
    });
}

export function loadCookedPost(postId) {
  postId = Number(postId);
  if (invalidatedPosts.has(postId)) {
    return Promise.resolve("");
  }
  if (cache.has(postId)) {
    const cooked = cache.get(postId);
    cache.delete(postId);
    cache.set(postId, cooked);
    return Promise.resolve(cooked);
  }
  const generation = generations.get(postId);
  const pending = pendingRequests.get(postId);
  if (pending && pending.generation === generation) {
    return pending.promise;
  }
  const job = { generation, postId };
  job.promise = new Promise((resolve, reject) => {
    Object.assign(job, { reject, resolve });
  });
  pendingRequests.set(postId, job);
  queue.push(job);
  runQueue();
  return job.promise;
}

export function invalidateCookedPost(postId, hidden = true) {
  const id = Number(postId);
  generations.set(id, (generations.get(id) || 0) + 1);
  if (hidden) {
    invalidatedPosts.add(id);
  } else {
    invalidatedPosts.delete(id);
  }
  cache.delete(id);
}

const countCache = new Map();
const pendingCountIds = new Set();
const countResolvers = new Map();
let countTimer;

async function flushCounts() {
  const ids = [...pendingCountIds].slice(0, 50);
  ids.forEach((id) => pendingCountIds.delete(id));
  countTimer = null;

  try {
    const result = await ajax("/isbf/reposts/counts", {
      data: { topic_ids: ids },
    });
    ids.forEach((id) => {
      const count = Number(result.counts?.[id] ?? 0);
      countCache.set(id, count);
      countResolvers.get(id)?.forEach((resolve) => resolve(count));
      countResolvers.delete(id);
    });
  } catch {
    ids.forEach((id) => {
      countResolvers.get(id)?.forEach((resolve) => resolve(null));
      countResolvers.delete(id);
    });
  }

  if (pendingCountIds.size) {
    countTimer = setTimeout(flushCounts, 40);
  }
}

export function loadRepostCount(topicId) {
  if (countCache.has(topicId)) {
    return Promise.resolve(countCache.get(topicId));
  }

  pendingCountIds.add(topicId);
  return new Promise((resolve) => {
    const resolvers = countResolvers.get(topicId) ?? [];
    resolvers.push(resolve);
    countResolvers.set(topicId, resolvers);
    countTimer ??= setTimeout(flushCounts, 40);
  });
}
