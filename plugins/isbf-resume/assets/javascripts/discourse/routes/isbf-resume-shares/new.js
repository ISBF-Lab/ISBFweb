import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfResumeSharesNewRoute extends DiscourseRoute {
  model() {
    return ajax("/isbf-resume/collection.json");
  }
}
