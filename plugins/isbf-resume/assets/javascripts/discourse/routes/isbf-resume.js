import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class IsbfResumeRoute extends DiscourseRoute {
  @service currentUser;
  @service siteSettings;

  beforeModel() {
    if (!this.siteSettings.isbf_resume_enabled) {
      return this.replaceWith("unknown", { path: "/404" });
    }
    if (!this.currentUser) {
      return this.replaceWith("login");
    }
  }

  titleToken() {
    return i18n("isbf_resume.title");
  }
}
