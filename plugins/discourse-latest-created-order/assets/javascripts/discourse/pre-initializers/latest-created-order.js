import { withPluginApi } from "discourse/lib/plugin-api";

function compareTopics(left, right) {
  const leftPinnedAt = left.pinned && left.latest_created_order_pinned_at;
  const rightPinnedAt = right.pinned && right.latest_created_order_pinned_at;

  if (leftPinnedAt || rightPinnedAt) {
    if (!leftPinnedAt) {
      return 1;
    }
    if (!rightPinnedAt) {
      return -1;
    }
    return Date.parse(rightPinnedAt) - Date.parse(leftPinnedAt);
  }

  return (
    Date.parse(right.created_at) - Date.parse(left.created_at) ||
    right.id - left.id
  );
}

export default {
  name: "latest-created-order",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      const topicListClass = api.container.factoryFor("model:topic-list").class;

      for (const method of ["loadBefore", "loadMore"]) {
        const original = Object.getOwnPropertyDescriptor(
          topicListClass.prototype,
          method
        );

        api.addModelMethod("topic-list", method, async function (...args) {
          const originalMethod = original.get
            ? original.get.call(this)
            : original.value;
          const result = await originalMethod.apply(this, args);
          const order = this.params?.order;
          const latest =
            this.filter === "latest" || this.filter?.endsWith("/l/latest");

          if (
            siteSettings.latest_topics_order_by_created &&
            latest &&
            (!order || order === "default")
          ) {
            // Replies can introduce old topics before their page has been loaded.
            this.topics = [...this.topics].sort(compareTopics);
          }

          return result;
        });
      }
    });
  },
};
