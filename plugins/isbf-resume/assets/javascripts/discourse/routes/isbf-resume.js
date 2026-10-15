import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class IsbfResumeRoute extends DiscourseRoute {
  @service currentUser;
  @service router;
  @service siteSettings;

  beforeModel(transition) {
    if (!this.siteSettings.isbf_resume_enabled) {
      return this.router.replaceWith("unknown", { path: "/404" });
    }
    if (!this.currentUser) {
      return this.router.replaceWith("login");
    }
    if (transition.to.name === "isbfResume") {
      return this.router.replaceWith("isbfResumeShares.index");
    }
  }

  titleToken() {
    return i18n("isbf_resume.title");
  }
}
