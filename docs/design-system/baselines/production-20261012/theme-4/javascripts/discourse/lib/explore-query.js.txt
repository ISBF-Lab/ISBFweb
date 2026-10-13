const queue = [];
let activeRequests = 0;

function runJob(job) {
  activeRequests += 1;
  Promise.resolve()
    .then(job.work)
    .then(job.resolve, job.reject)
    .finally(() => {
      activeRequests -= 1;
      runQueue();
    });
}

function runQueue() {
  while (activeRequests < 2 && queue.length) {
    const job = queue.shift();
    if (!job.isCurrent()) {
      job.resolve(null);
      continue;
    }
    runJob(job);
  }
}

export function enqueueExploreQuery(work, isCurrent = () => true) {
  return new Promise((resolve, reject) => {
    queue.push({ isCurrent, reject, resolve, work });
    runQueue();
  });
}

export function categoryFilterId(category) {
  const id = Number(category?.id);
  return Number.isInteger(id) && id > 0 && id <= 2147483647 ? id : null;
}

export function buildExploreQuery({
  categoryId,
  tags = [],
  order = "activity",
}) {
  const clauses = [];
  if (categoryId !== undefined) {
    const id = categoryFilterId({ id: categoryId });
    if (id === null) {
      throw new Error("Invalid explore category ID");
    }
    clauses.push(`isbf-category:${id}`);
  }
  if (tags.length) {
    clauses.push(`tag:${[...new Set(tags)].join(",")}`);
  }
  clauses.push(`order:${order === "hot" ? "hot" : "activity"}`);
  return clauses.join(" ");
}

export function uniqueTopicList(topics) {
  const seen = new Set();
  return Array.from(topics || []).filter((topic) => {
    if (seen.has(topic.id)) {
      return false;
    }
    seen.add(topic.id);
    return true;
  });
}
