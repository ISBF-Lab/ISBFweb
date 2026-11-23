import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfModerationModesRoute extends DiscourseRoute {
  model() {
    return ajax("/isbf/moderation/admin/ai-moderation-modes.json");
  }
}
