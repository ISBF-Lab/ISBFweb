import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AcademyStudentInvitesIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/academy-roles/admin/student-invites");
  }
}
