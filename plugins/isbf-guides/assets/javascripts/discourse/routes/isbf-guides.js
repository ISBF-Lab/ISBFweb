import { service } from "@ember/service";
import cookie from "discourse/lib/cookie";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class IsbfGuidesRoute extends DiscourseRoute {
  @service router;
  @service siteSettings;

  beforeModel(transition) {
    if (!this.siteSettings.isbf_guides_enabled) {
      return this.router.replaceWith("unknown", { path: "/404" });
    }
    if (!this.currentUser) {
      const slug = transition.to.params.slug;
      const destination = slug
        ? `/guides/${encodeURIComponent(slug)}`
        : "/guides";
      const fragment = window.location.pathname.startsWith("/guides")
        ? window.location.hash
        : "";
      const target = destination + fragment;
      window.sessionStorage.setItem("isbf-guides-return", target);
      cookie("destination_url", target);
      return this.router.replaceWith("login");
    }
  }

  titleToken() {
    return i18n("isbf_guides.title");
  }
}
