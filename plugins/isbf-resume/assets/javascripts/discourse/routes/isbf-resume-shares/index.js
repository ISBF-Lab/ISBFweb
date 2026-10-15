import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfResumeSharesIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/isbf-resume/shares.json");
  }
}
