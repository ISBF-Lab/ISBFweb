import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfResumeSharesShowRoute extends DiscourseRoute {
  model({ id }) {
    return ajax(`/isbf-resume/shares/${id}.json`);
  }
}
