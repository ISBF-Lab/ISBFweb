import { ajax } from "discourse/lib/ajax";
import { marketplaceConfig } from "./marketplace";

const RECENT_WINDOW = 3 * 24 * 60 * 60 * 1000;
const TOPIC_LIMIT = 4;

export async function loadRecentDiscussions({
  site,
  request = ajax,
  now = Date.now(),
  isStale = () => false,
} = {}) {
  const categoryId = marketplaceConfig(site)?.category_id;
  const cutoff = now - RECENT_WINDOW;
  const topics = [];
  const seen = new Set();
  let page = 0;

  while (!isStale()) {
    const response = await request("/filter.json", {
      data: { q: "created-after:3 order:posts,created", page },
    });
    if (isStale()) {
      return [];
    }
    const list = response.topic_list;
    const candidates = list?.topics ?? [];
    let newIds = 0;
    for (const topic of candidates) {
      if (
        !Number.isSafeInteger(topic.id) ||
        topic.id <= 0 ||
        seen.has(topic.id)
      ) {
        continue;
      }
      seen.add(topic.id);
      newIds += 1;
      const created = Date.parse(topic.created_at);
      if (!Number.isFinite(created) || created < cutoff || created > now) {
        continue;
      }
      // Native /filter does not apply the marketplace's home-feed exclusion.
      if (
        (Number(topic.category_id) === categoryId || topic.isbf_marketplace) &&
        topic.isbf_marketplace?.show_on_home !== true
      ) {
        continue;
      }
      topics.push(topic);
      if (topics.length === TOPIC_LIMIT) {
        return topics;
      }
    }
    if (!newIds || !list?.more_topics_url) {
      break;
    }
    page += 1;
  }
  return isStale() ? [] : topics;
}
