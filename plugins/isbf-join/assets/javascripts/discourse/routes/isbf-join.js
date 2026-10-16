import DiscourseURL from "discourse/lib/url";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfJoinRoute extends DiscourseRoute {
  beforeModel(transition) {
    transition.abort();
    DiscourseURL.redirectTo("/join/");
  }
}
