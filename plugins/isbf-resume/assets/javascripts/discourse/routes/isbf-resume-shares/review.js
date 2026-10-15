import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfResumeSharesReviewRoute extends DiscourseRoute {
  @service router;

  beforeModel() {
    return this.router.replaceWith("review.index", {
      queryParams: { type: "ReviewableIsbfResume" },
    });
  }
}
