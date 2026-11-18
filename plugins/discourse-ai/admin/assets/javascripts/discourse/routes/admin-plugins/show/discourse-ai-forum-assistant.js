import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseAiForumAssistant extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/discourse-ai/forum-assistant.json");
  }
}
