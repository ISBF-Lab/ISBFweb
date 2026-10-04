import DiscourseRoute from "discourse/routes/discourse";

export default class AcademyStudentInvitesIndexRoute extends DiscourseRoute {
  model() {
    return this.modelFor("adminPlugins.show.academy-student-invites");
  }
}
