import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AcademyActivityLevelsRoute extends DiscourseRoute {
  model() {
    return ajax("/academy-roles/admin/activity-levels");
  }
}
