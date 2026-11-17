import { apiInitializer } from "discourse/lib/api";
import ForumAssistantTopicStatus from "../components/forum-assistant-topic-status";

export default apiInitializer((api) => {
  api.renderInOutlet("topic-above-post-stream", ForumAssistantTopicStatus);
  const currentUser = api.container.lookup("service:current-user");
  api.modifyClass("route:topic.from-params", {
    pluginId: "forum-assistant-workspace",
    afterModel() {
      const topic = this.modelFor("topic");
      if (topic?.is_forum_assistant && topic.user_id === currentUser?.id) {
        return this.router.replaceWith("discourse-ai-bot-conversations", {
          queryParams: { conversation: topic.id },
        });
      }
      return this._super(...arguments);
    },
  });
});
