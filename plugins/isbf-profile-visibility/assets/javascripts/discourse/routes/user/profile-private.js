import DiscourseRoute from "discourse/routes/discourse";

export default class UserProfilePrivate extends DiscourseRoute {
  model() {
    return this.modelFor("user");
  }
}
